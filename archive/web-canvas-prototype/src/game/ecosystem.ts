import {
  discoverRecipes,
  furnitureDef,
  furnitureSymbiosisScore,
  gatherHere,
  tickFurniture,
  useNearestSeat,
} from './furniture'
import type { Creature, Interaction, Tree, WorldState } from './types'
import { getTile, idx, seasonFromDay, weatherFor } from './world'

function clamp(n: number, min = 0, max = 1): number {
  return Math.max(min, Math.min(max, n))
}

function refreshCanopy(world: WorldState): void {
  for (const tile of world.tiles) tile.canopy *= 0.92
  for (const tree of world.trees) {
    const tx = Math.floor(tree.x)
    const ty = Math.floor(tree.y)
    for (let dy = -2; dy <= 2; dy++) {
      for (let dx = -2; dx <= 2; dx++) {
        const nx = tx + dx
        const ny = ty + dy
        if (nx < 0 || ny < 0 || nx >= world.width || ny >= world.height) continue
        const t = world.tiles[idx(world.width, nx, ny)]!
        const dist = Math.hypot(dx, dy) + 0.15
        t.canopy = clamp(t.canopy + (tree.height * tree.health * 0.38) / dist)
      }
    }
  }
}

function growTrees(world: WorldState, dtDays: number): void {
  const seasonBoost =
    world.season === 'summer' ? 1.25 : world.season === 'winter' ? 0.35 : 1
  for (const tree of world.trees) {
    const tile = getTile(world, tree.x, tree.y)
    if (!tile) continue
    const growth =
      dtDays * 0.02 * seasonBoost * (0.5 + tile.moisture * 0.5) * tree.health
    tree.height = clamp(tree.height + growth, 0.15, 1.35)
    if (tile.moisture < 0.2 && world.weather !== 'rain') {
      tree.health = clamp(tree.health - dtDays * 0.04)
    } else if (tile.moisture > 0.45) {
      tree.health = clamp(tree.health + dtDays * 0.02)
    }
  }
}

function ageTiles(world: WorldState, dtDays: number): void {
  for (let y = 0; y < world.height; y++) {
    for (let x = 0; x < world.width; x++) {
      const tile = world.tiles[idx(world.width, x, y)]!
      tile.age += dtDays
      if (tile.kind === 'water') {
        tile.moisture = 1
        continue
      }

      const evaporate =
        world.weather === 'rain'
          ? -0.08
          : world.weather === 'snow'
            ? -0.02
            : world.season === 'summer'
              ? 0.05
              : 0.02
      tile.moisture = clamp(tile.moisture - evaporate * dtDays)

      // Memory fades slowly unless walked/tended
      tile.memory = clamp(tile.memory - dtDays * 0.01)

      if (tile.kind === 'path' && tile.memory < 0.15) {
        tile.kind = tile.fertility > 0.55 ? 'moss' : 'grass'
      }
      if (tile.kind === 'soil' && tile.fertility > 0.65 && tile.moisture > 0.5) {
        tile.kind = 'moss'
      }
      if (
        tile.kind === 'grass' &&
        tile.canopy > 0.55 &&
        tile.moisture > 0.55 &&
        Math.random() < dtDays * 0.08
      ) {
        tile.kind = 'mushroom'
      }
    }
  }
}

function updateCreatures(world: WorldState, dt: number): void {
  const night = world.timeOfDay < 0.22 || world.timeOfDay > 0.78
  for (const c of world.creatures) {
    c.age += dt
    const homePull = 0.15
    const wander = night && c.kind !== 'owl' && c.kind !== 'firefly' ? 0.35 : 1
    const angle = Math.sin(c.age * 0.7 + c.id) * Math.PI * 2
    const speed =
      (c.kind === 'firefly' ? 0.9 : c.kind === 'rabbit' ? 1.4 : 0.7) * wander

    c.vx =
      Math.cos(angle) * speed * 0.35 + (c.homeX - c.x) * homePull * dt
    c.vy =
      Math.sin(angle * 0.9) * speed * 0.35 + (c.homeY - c.y) * homePull * dt

    c.x = clamp(c.x + c.vx * dt, 0.3, world.width - 0.3)
    c.y = clamp(c.y + c.vy * dt, 0.3, world.height - 0.3)

    const tile = getTile(world, c.x, c.y)
    if (tile?.kind === 'water') {
      c.x -= c.vx * dt * 2
      c.y -= c.vy * dt * 2
    }

    // Mood tracks forest health nearby
    if (tile) {
      const target = tile.fertility * 0.5 + tile.canopy * 0.3 + world.player.bond / 200
      c.mood += (target - c.mood) * dt * 0.2
    }

    if (c.kind === 'spirit' && c.mood > 0.7) {
      // Spirits slowly raise nearby fertility — unique to Forests
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const t = getTile(world, c.x + dx, c.y + dy)
          if (t && t.kind !== 'water') t.fertility = clamp(t.fertility + dt * 0.01)
        }
      }
    }
  }

  // Cull unhappy nocturnal creatures at dawn; invite new ones at dusk
  if (world.timeOfDay > 0.24 && world.timeOfDay < 0.26) {
    world.creatures = world.creatures.filter(
      (c) => c.kind !== 'firefly' && (c.kind !== 'owl' || Math.random() > 0.4),
    )
  }
}

function maybeSpawn(world: WorldState): void {
  if (world.creatures.length > 40) return
  if (Math.random() > 0.02 + world.player.bond / 800) return

  const x = Math.random() * world.width
  const y = Math.random() * world.height
  const tile = getTile(world, x, y)
  if (!tile || tile.kind === 'water') return

  const forestHealth = averageFertility(world)
  let kind: Creature['kind'] | null = null
  const night = world.timeOfDay < 0.22 || world.timeOfDay > 0.78

  if (night && forestHealth > 0.45) {
    kind = Math.random() > 0.5 ? 'firefly' : 'owl'
  } else if (forestHealth > 0.7 && world.player.bond > 40 && Math.random() < 0.2) {
    kind = 'spirit'
  } else if (forestHealth > 0.5) {
    kind = Math.random() > 0.5 ? 'deer' : 'rabbit'
  } else if (Math.random() < 0.3) {
    kind = 'fox'
  }

  if (!kind) return
  world.creatures.push({
    id: Date.now() + Math.floor(Math.random() * 1000),
    kind,
    x,
    y,
    vx: 0,
    vy: 0,
    mood: 0.55,
    age: 0,
    homeX: x,
    homeY: y,
  })
}

function averageFertility(world: WorldState): number {
  let sum = 0
  for (const t of world.tiles) sum += t.fertility
  return sum / world.tiles.length
}

export function forestVitality(world: WorldState): number {
  const fert = averageFertility(world)
  const canopy =
    world.tiles.reduce((s, t) => s + t.canopy, 0) / world.tiles.length
  const creatureJoy =
    world.creatures.reduce((s, c) => s + c.mood, 0) /
    Math.max(1, world.creatures.length)
  const symbiosis = furnitureSymbiosisScore(world)
  return clamp(
    fert * 0.32 +
      canopy * 0.22 +
      creatureJoy * 0.16 +
      symbiosis * 0.18 +
      world.player.bond / 500,
  )
}

export function tickWorld(world: WorldState, dtSeconds: number): void {
  // 1 real second ≈ 48 in-game minutes → full day ~ 30 real seconds for prototype feel
  const daySpeed = 1 / 30
  world.timeOfDay += dtSeconds * daySpeed
  if (world.timeOfDay >= 1) {
    world.timeOfDay -= 1
    world.day += 1
    world.season = seasonFromDay(world.day)
    world.memory.neglectDays += 1
    if (world.memory.neglectDays > 3) {
      world.player.bond = Math.max(0, world.player.bond - 1)
      pushJournal(world, '森が少し寂しそうだ。足跡が薄れていく。')
    }
  }

  world.weather = weatherFor(world.season, world.timeOfDay)
  const dtDays = dtSeconds * daySpeed

  ageTiles(world, dtDays)
  growTrees(world, dtDays)
  tickFurniture(world, dtDays)
  refreshCanopy(world)
  updateCreatures(world, dtSeconds)
  maybeSpawn(world)

  const unlocked = discoverRecipes(world)
  if (unlocked.length > 0) {
    pushJournal(
      world,
      `新しい生き家具のレシピ——${unlocked.map((id) => furnitureDef(id).name).join('、')}`,
    )
  }

  // Passive stamina recover when resting near high-memory tiles
  const under = getTile(world, world.player.x, world.player.y)
  if (under && under.memory > 0.4) {
    world.player.stamina = Math.min(100, world.player.stamina + dtSeconds * 2)
  }
}

export function leaveFootprint(world: WorldState): void {
  const tile = getTile(world, world.player.x, world.player.y)
  if (!tile || tile.kind === 'water') return
  tile.memory = clamp(tile.memory + 0.08)
  if (tile.memory > 0.55 && tile.kind !== 'path' && tile.kind !== 'clearing') {
    tile.kind = 'path'
    world.memory.pathsFormed += 1
  }
}

export function interact(
  world: WorldState,
  action: Interaction,
): { ok: boolean; message: string } {
  if (action === 'gather') {
    const result = gatherHere(world)
    if (result.ok) {
      const unlocked = discoverRecipes(world)
      if (unlocked.length) {
        result.message += ` / レシピ解放`
      }
    }
    return result
  }
  if (action === 'sit') {
    return useNearestSeat(world)
  }

  const tile = getTile(world, world.player.x, world.player.y)
  if (!tile) return { ok: false, message: 'ここには何もない。' }

  const cost =
    action === 'observe' || action === 'listen' || action === 'rest' ? 2 : 8
  if (world.player.stamina < cost) {
    return { ok: false, message: '疲れている。少し休もう。' }
  }

  world.player.stamina -= cost
  world.memory.careEvents += 1
  world.memory.neglectDays = 0

  switch (action) {
    case 'water': {
      if (tile.kind === 'water') {
        return { ok: false, message: 'すでに水がある。' }
      }
      tile.moisture = clamp(tile.moisture + 0.35)
      tile.fertility = clamp(tile.fertility + 0.05)
      world.player.bond += 1
      const msg = '土が潤い、小さな根が息を吹き返した。'
      pushJournal(world, msg)
      return { ok: true, message: msg }
    }
    case 'plant': {
      if (world.player.seeds <= 0) {
        return { ok: false, message: '種がない。森の贈り物を待とう。' }
      }
      if (tile.kind === 'water' || tile.kind === 'path') {
        return { ok: false, message: 'ここには植えられない。' }
      }
      const nearby = world.trees.some(
        (t) => Math.hypot(t.x - world.player.x, t.y - world.player.y) < 0.9,
      )
      if (nearby) return { ok: false, message: 'すでに木が近い。' }
      world.player.seeds -= 1
      const species: Tree['species'] =
        world.season === 'spring'
          ? 'sakura'
          : world.season === 'autumn'
            ? 'maple'
            : world.season === 'winter'
              ? 'cedar'
              : 'oak'
      world.trees.push({
        id: Date.now(),
        x: world.player.x,
        y: world.player.y,
        species,
        height: 0.2,
        health: 0.9,
        plantedByPlayer: true,
      })
      tile.kind = 'soil'
      tile.memory = clamp(tile.memory + 0.2)
      world.player.bond += 3
      const msg = `${speciesLabel(species)}の苗を植えた。この森の記憶になる。`
      pushJournal(world, msg)
      return { ok: true, message: msg }
    }
    case 'tend': {
      tile.fertility = clamp(tile.fertility + 0.12)
      tile.memory = clamp(tile.memory + 0.15)
      for (const tree of world.trees) {
        if (Math.hypot(tree.x - world.player.x, tree.y - world.player.y) < 1.6) {
          tree.health = clamp(tree.health + 0.08)
        }
      }
      world.player.bond += 2
      if (Math.random() < 0.25) world.player.seeds += 1
      const msg = '落ち葉を梳き、菌糸に光を通した。森が応えてくれた。'
      pushJournal(world, msg)
      return { ok: true, message: msg }
    }
    case 'listen': {
      const nearSpirit = world.creatures.find(
        (c) =>
          c.kind === 'spirit' &&
          Math.hypot(c.x - world.player.x, c.y - world.player.y) < 2.5,
      )
      if (nearSpirit) {
        world.memory.spiritsMet += 1
        world.player.bond += 5
        nearSpirit.mood = 1
        const msg =
          '森の精霊が囁いた——「足跡は道になり、世話は季節になる。」'
        pushJournal(world, msg)
        return { ok: true, message: msg }
      }
      const vitality = forestVitality(world)
      const msg =
        vitality > 0.65
          ? '葉擦れが歌になって聞こえる。森は満ちている。'
          : vitality > 0.4
            ? '遠くで水音。森はまだ、あなたを測っている。'
            : '沈黙が深い。世話が足りないのかもしれない。'
      pushJournal(world, msg)
      world.player.bond += 1
      return { ok: true, message: msg }
    }
    case 'observe': {
      const near = world.creatures
        .filter(
          (c) => Math.hypot(c.x - world.player.x, c.y - world.player.y) < 3,
        )
        .sort(
          (a, b) =>
            Math.hypot(a.x - world.player.x, a.y - world.player.y) -
            Math.hypot(b.x - world.player.x, b.y - world.player.y),
        )[0]
      if (!near) {
        return {
          ok: true,
          message: `足元は${tileLabel(tile.kind)}。湿度 ${(tile.moisture * 100) | 0}%、肥沃 ${(tile.fertility * 100) | 0}%。`,
        }
      }
      near.mood = clamp(near.mood + 0.1)
      world.player.bond += 1
      const msg = `${creatureLabel(near.kind)}を見つけた。気配に気づかれないよう息を潜める。`
      pushJournal(world, msg)
      return { ok: true, message: msg }
    }
    case 'rest': {
      world.player.stamina = Math.min(100, world.player.stamina + 25)
      tile.memory = clamp(tile.memory + 0.05)
      return { ok: true, message: '木漏れ日の下で目を閉じる。心拍が森のリズムに寄っていく。' }
    }
  }
}

function pushJournal(world: WorldState, line: string): void {
  world.player.journal.unshift(line)
  if (world.player.journal.length > 24) world.player.journal.pop()
}

function speciesLabel(s: Tree['species']): string {
  const map = {
    oak: 'オーク',
    birch: '白樺',
    cedar: '杉',
    sakura: '桜',
    maple: '楓',
  }
  return map[s]
}

function tileLabel(kind: string): string {
  const map: Record<string, string> = {
    grass: '草地',
    moss: '苔',
    soil: '土',
    path: '獣道',
    water: '水辺',
    clearing: '空き地',
    mushroom: '菌糸の床',
  }
  return map[kind] ?? kind
}

function creatureLabel(kind: Creature['kind']): string {
  const map = {
    deer: 'シカ',
    fox: 'キツネ',
    owl: 'フクロウ',
    rabbit: 'ウサギ',
    firefly: 'ホタル',
    spirit: '森の精霊',
  }
  return map[kind]
}

export function tryMove(
  world: WorldState,
  dx: number,
  dy: number,
  dt: number,
): void {
  if (dx === 0 && dy === 0) return
  const speed = 2.6
  const len = Math.hypot(dx, dy) || 1
  const nx = world.player.x + (dx / len) * speed * dt
  const ny = world.player.y + (dy / len) * speed * dt
  const tile = getTile(world, nx, ny)
  if (!tile || tile.kind === 'water') return
  world.player.x = clamp(nx, 0.2, world.width - 0.2)
  world.player.y = clamp(ny, 0.2, world.height - 0.2)
  world.player.facing = { x: dx / len, y: dy / len }
  world.player.stamina = Math.max(0, world.player.stamina - dt * 1.2)
  leaveFootprint(world)
}
