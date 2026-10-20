import type {
  CreatureKind,
  FurnitureDef,
  FurnitureId,
  MaterialId,
  PlacedFurniture,
  WorldState,
} from './types'
import { getTile, idx } from './world'

export const MATERIAL_META: Record<
  MaterialId,
  { name: string; emoji: string }
> = {
  bark: { name: '樹皮', emoji: '🟫' },
  resin: { name: '樹液', emoji: '🟡' },
  moss_clump: { name: '苔玉', emoji: '🟢' },
  mushroom: { name: 'きのこ', emoji: '🍄' },
  fallen_leaf: { name: '落ち葉', emoji: '🍂' },
  spirit_dew: { name: '精霊の露', emoji: '✨' },
  driftwood: { name: '流木', emoji: '🪵' },
  soft_clay: { name: '柔土', emoji: '🟤' },
  seed_pod: { name: '種莢', emoji: '🌱' },
}

/** 本家の「置くだけ家具」を超える：すべて生態効果つき */
export const FURNITURE_CATALOG: FurnitureDef[] = [
  {
    id: 'moss_sofa',
    name: '苔ソファ',
    blurb: '湿度で茂る。座るほど周囲が潤う。',
    category: 'seat',
    eco: { moisture: 0.04, attract: ['rabbit'], bondOnUse: 1, staminaOnSit: 18 },
    recipe: { moss_clump: 4, bark: 2, soft_clay: 1 },
    unlockBond: 0,
    size: 2,
  },
  {
    id: 'mycelium_lamp',
    name: '菌糸ランプ',
    blurb: '夜に森の活力で光る。ホタルを呼ぶ。',
    category: 'light',
    eco: { attract: ['firefly', 'owl'], fertility: 0.02 },
    recipe: { mushroom: 3, resin: 2, bark: 1 },
    unlockBond: 8,
    size: 1,
  },
  {
    id: 'root_shelf',
    name: '根の棚',
    blurb: '絆が深まるほど収納が広がる生き棚。',
    category: 'storage',
    eco: { fertility: 0.01 },
    recipe: { bark: 5, resin: 1, driftwood: 2 },
    unlockBond: 12,
    size: 1,
  },
  {
    id: 'dew_basin',
    name: '露の鉢',
    blurb: '周囲の土をゆっくり潤す水場家具。',
    category: 'water',
    eco: { moisture: 0.08, attract: ['deer'] },
    recipe: { soft_clay: 4, spirit_dew: 1, moss_clump: 1 },
    unlockBond: 15,
    size: 1,
  },
  {
    id: 'sakura_bench',
    name: '桜ベンチ',
    blurb: '春に咲き、座るたび絆が芽吹く。',
    category: 'seat',
    eco: { bondOnUse: 3, staminaOnSit: 22, attract: ['spirit'] },
    recipe: { bark: 3, seed_pod: 2, fallen_leaf: 3 },
    unlockBond: 20,
    size: 2,
  },
  {
    id: 'wind_chime',
    name: '風鳴り',
    blurb: '風で精霊を誘う。霧の日に特に強い。',
    category: 'decor',
    eco: { attract: ['spirit', 'owl'] },
    recipe: { driftwood: 2, resin: 2, spirit_dew: 2 },
    unlockBond: 25,
    size: 1,
  },
  {
    id: 'hollow_bed',
    name: 'うろの寝床',
    blurb: '休むと体力が大きく戻り、夢が日誌に残る。',
    category: 'bed',
    eco: { bondOnUse: 2, staminaOnSit: 45 },
    recipe: { moss_clump: 5, fallen_leaf: 4, bark: 2 },
    unlockBond: 18,
    size: 2,
  },
  {
    id: 'spore_carpet',
    name: '胞子カーペット',
    blurb: '踏む地面の肥沃を底上げする床もの。',
    category: 'decor',
    eco: { fertility: 0.06 },
    recipe: { mushroom: 5, moss_clump: 2, fallen_leaf: 2 },
    unlockBond: 10,
    size: 2,
  },
  {
    id: 'amber_table',
    name: '琥珀テーブル',
    blurb: 'そばでクラフトすると材料が少し戻る。',
    category: 'craft',
    eco: { fertility: 0.015 },
    recipe: { resin: 4, driftwood: 3, bark: 2 },
    unlockBond: 22,
    size: 1,
  },
  {
    id: 'living_fence',
    name: '生き垣',
    blurb: '獣道を導き、記憶を留める生け垣。',
    category: 'decor',
    eco: { fertility: 0.02 },
    recipe: { seed_pod: 3, bark: 2, moss_clump: 2 },
    unlockBond: 5,
    size: 1,
  },
  {
    id: 'glow_stump',
    name: 'ほたる切株',
    blurb: '夜間の小さな灯火。動物の休憩所。',
    category: 'light',
    eco: { attract: ['firefly', 'fox', 'rabbit'], moisture: 0.01 },
    recipe: { driftwood: 2, mushroom: 2, resin: 1 },
    unlockBond: 6,
    size: 1,
  },
  {
    id: 'fern_screen',
    name: 'シダ衝立',
    blurb: '葉陰をつくり樹冠ストレスを和らげる。',
    category: 'decor',
    eco: { moisture: 0.03, fertility: 0.02 },
    recipe: { fallen_leaf: 5, moss_clump: 2, soft_clay: 1 },
    unlockBond: 14,
    size: 1,
  },
]

export function furnitureDef(id: FurnitureId): FurnitureDef {
  return FURNITURE_CATALOG.find((f) => f.id === id)!
}

export function emptyMaterials(): Record<MaterialId, number> {
  return {
    bark: 0,
    resin: 0,
    moss_clump: 0,
    mushroom: 0,
    fallen_leaf: 0,
    spirit_dew: 0,
    driftwood: 0,
    soft_clay: 0,
    seed_pod: 0,
  }
}

function clamp(n: number, min = 0, max = 1): number {
  return Math.max(min, Math.min(max, n))
}

export function canCraft(world: WorldState, id: FurnitureId): { ok: boolean; reason?: string } {
  const def = furnitureDef(id)
  if (world.player.bond < def.unlockBond) {
    return { ok: false, reason: `絆 ${def.unlockBond} が必要` }
  }
  if (!world.player.knownRecipes.includes(id) && def.unlockBond > 0) {
    // starter recipes always known; others unlock by bond discovery
  }
  for (const [mat, need] of Object.entries(def.recipe) as [MaterialId, number][]) {
    if ((world.player.materials[mat] ?? 0) < need) {
      return { ok: false, reason: `${MATERIAL_META[mat].name}が足りない` }
    }
  }
  return { ok: true }
}

export function discoverRecipes(world: WorldState): FurnitureId[] {
  const newly: FurnitureId[] = []
  for (const def of FURNITURE_CATALOG) {
    if (world.player.bond >= def.unlockBond && !world.player.knownRecipes.includes(def.id)) {
      world.player.knownRecipes.push(def.id)
      newly.push(def.id)
    }
  }
  return newly
}

export function craftFurniture(
  world: WorldState,
  id: FurnitureId,
): { ok: boolean; message: string } {
  const check = canCraft(world, id)
  if (!check.ok) return { ok: false, message: check.reason ?? '作れない' }

  const def = furnitureDef(id)
  const nearTable = world.furniture.some(
    (f) =>
      f.kind === 'amber_table' &&
      Math.hypot(f.x - world.player.x, f.y - world.player.y) < 2.2,
  )

  for (const [mat, need] of Object.entries(def.recipe) as [MaterialId, number][]) {
    world.player.materials[mat] -= need
    // 琥珀テーブル：材料の一部が森に還元（本家にないクラフト恩恵）
    if (nearTable && Math.random() < 0.35) {
      world.player.materials[mat] += 1
    }
  }

  world.player.furnitureBag[id] = (world.player.furnitureBag[id] ?? 0) + 1
  world.memory.furnitureCrafted += 1
  world.player.bond += 2
  world.memory.careEvents += 1
  world.memory.neglectDays = 0

  const refund = nearTable ? '琥珀テーブルが材料を少し戻した。' : ''
  const msg = `${def.name}を育て上げた。${refund}`
  world.player.journal.unshift(msg)
  return { ok: true, message: msg }
}

export function placeFurniture(
  world: WorldState,
  id: FurnitureId,
  tx: number,
  ty: number,
): { ok: boolean; message: string } {
  const bag = world.player.furnitureBag[id] ?? 0
  if (bag <= 0) return { ok: false, message: '持ち物にない。' }

  const ix = Math.floor(tx)
  const iy = Math.floor(ty)
  if (ix < 0 || iy < 0 || ix >= world.width || iy >= world.height) {
    return { ok: false, message: '範囲外。' }
  }

  const tile = world.tiles[idx(world.width, ix, iy)]!
  if (tile.kind === 'water') return { ok: false, message: '水の上には置けない。' }

  const def = furnitureDef(id)
  const occupied = world.furniture.some(
    (f) => Math.hypot(f.x - (ix + 0.5), f.y - (iy + 0.5)) < (def.size === 2 ? 1.2 : 0.85),
  )
  if (occupied) return { ok: false, message: 'すでに家具がある。' }

  const treeHit = world.trees.some(
    (t) => Math.hypot(t.x - (ix + 0.5), t.y - (iy + 0.5)) < 0.7,
  )
  if (treeHit) return { ok: false, message: '木と重なる。' }

  world.player.furnitureBag[id] = bag - 1
  if (world.player.furnitureBag[id] === 0) delete world.player.furnitureBag[id]

  world.furniture.push({
    id: Date.now() + Math.floor(Math.random() * 999),
    kind: id,
    x: ix + 0.5,
    y: iy + 0.5,
    vitality: 0.35,
    ageDays: 0,
    visits: 0,
    rotation: 0,
  })
  world.memory.furniturePlaced += 1
  world.player.bond += 1
  tile.memory = clamp(tile.memory + 0.2)

  const msg = `${def.name}を置いた。森が受け入れ始める。`
  world.player.journal.unshift(msg)
  return { ok: true, message: msg }
}

export function pickupNearestFurniture(world: WorldState): { ok: boolean; message: string } {
  let best: PlacedFurniture | null = null
  let bestDist = 1.4
  for (const f of world.furniture) {
    const d = Math.hypot(f.x - world.player.x, f.y - world.player.y)
    if (d < bestDist) {
      best = f
      bestDist = d
    }
  }
  if (!best) return { ok: false, message: '近くに家具がない。' }

  world.furniture = world.furniture.filter((f) => f.id !== best!.id)
  world.player.furnitureBag[best.kind] = (world.player.furnitureBag[best.kind] ?? 0) + 1
  const def = furnitureDef(best.kind)
  return { ok: true, message: `${def.name}をしまった。（成長度 ${Math.round(best.vitality * 100)}%）` }
}

export function useNearestSeat(world: WorldState): { ok: boolean; message: string } {
  const seats = world.furniture.filter((f) => {
    const cat = furnitureDef(f.kind).category
    return (cat === 'seat' || cat === 'bed') && Math.hypot(f.x - world.player.x, f.y - world.player.y) < 1.5
  })
  seats.sort(
    (a, b) =>
      Math.hypot(a.x - world.player.x, a.y - world.player.y) -
      Math.hypot(b.x - world.player.x, b.y - world.player.y),
  )
  const seat = seats[0]
  if (!seat) return { ok: false, message: '座れる家具が近くにない。' }

  const def = furnitureDef(seat.kind)
  const stamina = def.eco.staminaOnSit ?? 12
  const bond = def.eco.bondOnUse ?? 1
  world.player.stamina = Math.min(100, world.player.stamina + stamina)
  world.player.bond += bond
  seat.visits += 1
  seat.vitality = clamp(seat.vitality + 0.05)

  // 季節ブルーム
  if (seat.kind === 'sakura_bench' && world.season === 'spring') {
    world.player.bond += 2
    world.player.journal.unshift('桜ベンチが満開だ。花びらが肩に落ちる。')
    return { ok: true, message: '満開の桜ベンチに腰を下ろす。絆が大きく芽吹いた。' }
  }

  if (seat.kind === 'hollow_bed') {
    const dreams = [
      'うろの寝床で見た夢——根が川のように光っていた。',
      '夢の中でシカが名前を呼んだ気がする。',
      '森全体がひとつの肺になって呼吸していた。',
    ]
    const dream = dreams[Math.floor(Math.random() * dreams.length)]!
    world.player.journal.unshift(dream)
    return { ok: true, message: `深く眠った。${dream}` }
  }

  return {
    ok: true,
    message: `${def.name}に座った。体力+${stamina}、絆+${bond}。`,
  }
}

/** 家具が毎ティック生態へ効く（本家家具にない核） */
export function tickFurniture(world: WorldState, dtDays: number): void {
  const night = world.timeOfDay < 0.22 || world.timeOfDay > 0.78

  for (const f of world.furniture) {
    const def = furnitureDef(f.kind)
    f.ageDays += dtDays

    // 成長：世話された森・適切な天候で育つ
    const tile = getTile(world, f.x, f.y)
    let grow = dtDays * 0.03
    if (tile && tile.moisture > 0.4) grow *= 1.3
    if (world.weather === 'rain' && def.eco.moisture) grow *= 1.2
    if (f.kind === 'sakura_bench' && world.season === 'spring') grow *= 1.8
    if (f.kind === 'mycelium_lamp' && night) grow *= 1.4
    f.vitality = clamp(f.vitality + grow)

    // 生態オーラ
    const radius = 1 + Math.floor(f.vitality * 2)
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        const t = getTile(world, f.x + dx, f.y + dy)
        if (!t || t.kind === 'water') continue
        const falloff = 1 / (1 + Math.hypot(dx, dy))
        if (def.eco.moisture) {
          t.moisture = clamp(t.moisture + def.eco.moisture * f.vitality * dtDays * falloff)
        }
        if (def.eco.fertility) {
          t.fertility = clamp(t.fertility + def.eco.fertility * f.vitality * dtDays * falloff)
        }
        if (f.kind === 'living_fence') {
          t.memory = clamp(t.memory + 0.02 * f.vitality * dtDays * falloff)
        }
      }
    }

    // 動物誘引
    if (def.eco.attract && Math.random() < dtDays * 0.15 * f.vitality) {
      pullCreatures(world, f, def.eco.attract)
    }
  }
}

function pullCreatures(world: WorldState, f: PlacedFurniture, kinds: CreatureKind[]): void {
  for (const c of world.creatures) {
    if (!kinds.includes(c.kind)) continue
    if (Math.hypot(c.x - f.x, c.y - f.y) > 8) continue
    c.homeX = f.x + (Math.random() - 0.5)
    c.homeY = f.y + (Math.random() - 0.5)
    c.mood = clamp(c.mood + 0.05)
    f.visits += 0.1
  }
}

export function gatherHere(world: WorldState): { ok: boolean; message: string } {
  if (world.player.stamina < 6) return { ok: false, message: '疲れている。' }
  const tile = getTile(world, world.player.x, world.player.y)
  if (!tile || tile.kind === 'water') return { ok: false, message: 'ここでは採れない。' }

  world.player.stamina -= 6
  const drops: MaterialId[] = []

  if (tile.kind === 'moss' || tile.moisture > 0.6) drops.push('moss_clump')
  if (tile.kind === 'mushroom') drops.push('mushroom')
  if (tile.kind === 'soil') drops.push('soft_clay')
  if (tile.canopy > 0.45) {
    drops.push('bark')
    if (Math.random() < 0.4) drops.push('resin')
    if (Math.random() < 0.35) drops.push('fallen_leaf')
  }
  if (tile.kind === 'path' || tile.kind === 'clearing') {
    if (Math.random() < 0.3) drops.push('seed_pod')
  }
  // near water → driftwood
  for (let dy = -2; dy <= 2 && !drops.includes('driftwood'); dy++) {
    for (let dx = -2; dx <= 2; dx++) {
      const t = getTile(world, world.player.x + dx, world.player.y + dy)
      if (t?.kind === 'water' && Math.random() < 0.45) {
        drops.push('driftwood')
        break
      }
    }
  }
  if (world.player.bond > 30 && Math.random() < 0.12) drops.push('spirit_dew')
  if (drops.length === 0) drops.push(Math.random() < 0.5 ? 'fallen_leaf' : 'bark')

  const got = drops[Math.floor(Math.random() * drops.length)]!
  const bonus = Math.random() < 0.25 ? 2 : 1
  world.player.materials[got] += bonus
  world.memory.careEvents += 1
  world.memory.neglectDays = 0

  // shelf bonus storage flavor — more materials kept when shelves exist (soft cap raise via bond)
  const shelves = world.furniture.filter((f) => f.kind === 'root_shelf').length
  if (shelves > 0 && Math.random() < 0.2 * shelves) {
    world.player.materials[got] += 1
    return {
      ok: true,
      message: `${MATERIAL_META[got].name}×${bonus + 1}（根の棚が仕舞い直した）`,
    }
  }

  return { ok: true, message: `${MATERIAL_META[got].name}×${bonus} を採った。` }
}

export function furnitureSymbiosisScore(world: WorldState): number {
  if (world.furniture.length === 0) return 0
  const avg =
    world.furniture.reduce((s, f) => s + f.vitality, 0) / world.furniture.length
  const visits = world.furniture.reduce((s, f) => s + f.visits, 0)
  return clamp(avg * 0.7 + Math.min(1, visits / 40) * 0.3)
}
