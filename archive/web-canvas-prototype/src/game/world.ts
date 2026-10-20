import { emptyMaterials } from './furniture'
import { fbm } from './noise'
import type {
  Creature,
  CreatureKind,
  Season,
  Tile,
  TileKind,
  Tree,
  WorldState,
} from './types'

const SPECIES: Tree['species'][] = ['oak', 'birch', 'cedar', 'sakura', 'maple']

function idx(width: number, x: number, y: number): number {
  return y * width + x
}

function pickSpecies(x: number, y: number, season: Season): Tree['species'] {
  const n = fbm(x * 0.2, y * 0.2, 9)
  if (season === 'spring' && n > 0.72) return 'sakura'
  if (n > 0.8) return 'maple'
  if (n > 0.55) return 'oak'
  if (n > 0.35) return 'cedar'
  return 'birch'
}

function creatureForBiome(
  fertility: number,
  canopy: number,
  nearWater: boolean,
  timeOfDay: number,
): CreatureKind | null {
  const night = timeOfDay < 0.22 || timeOfDay > 0.78
  if (night && canopy > 0.4 && Math.random() < 0.4) return 'owl'
  if (night && fertility > 0.5 && Math.random() < 0.35) return 'firefly'
  if (nearWater && fertility > 0.55 && Math.random() < 0.25) return 'deer'
  if (canopy < 0.35 && Math.random() < 0.3) return 'rabbit'
  if (canopy > 0.5 && Math.random() < 0.18) return 'fox'
  if (fertility > 0.7 && Math.random() < 0.08) return 'spirit'
  return null
}

export function createWorld(width = 48, height = 36): WorldState {
  const tiles: Tile[] = []
  const trees: Tree[] = []
  let treeId = 1

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const elev = fbm(x / 14, y / 14, 2)
      const moist = fbm(x / 10, y / 10, 5)
      const river =
        Math.abs(fbm(x / 22, y / 8, 11) - 0.48) < 0.045 + moist * 0.02

      let kind: TileKind = 'grass'
      if (river) kind = 'water'
      else if (moist > 0.72) kind = 'moss'
      else if (elev < 0.32) kind = 'soil'
      else if (elev > 0.78 && moist < 0.4) kind = 'clearing'
      else if (fbm(x / 6, y / 6, 21) > 0.86) kind = 'mushroom'

      const fertility = river ? 0.2 : 0.35 + moist * 0.45 + elev * 0.15
      const canopy = river ? 0 : Math.max(0, elev * 0.4 + moist * 0.2 - 0.1)

      tiles.push({
        kind,
        moisture: river ? 1 : moist,
        fertility: Math.min(1, fertility),
        memory: 0,
        canopy,
        age: 0,
      })

      if (
        !river &&
        kind !== 'clearing' &&
        fbm(x / 3.5, y / 3.5, 7) > 0.62 &&
        Math.random() < 0.55
      ) {
        trees.push({
          id: treeId++,
          x: x + 0.35 + Math.random() * 0.3,
          y: y + 0.35 + Math.random() * 0.3,
          species: pickSpecies(x, y, 'spring'),
          height: 0.45 + Math.random() * 0.55,
          health: 0.7 + Math.random() * 0.3,
          plantedByPlayer: false,
        })
      }
    }
  }

  // Refresh canopy from surrounding trees
  for (const tree of trees) {
    const tx = Math.floor(tree.x)
    const ty = Math.floor(tree.y)
    for (let dy = -2; dy <= 2; dy++) {
      for (let dx = -2; dx <= 2; dx++) {
        const nx = tx + dx
        const ny = ty + dy
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue
        const t = tiles[idx(width, nx, ny)]!
        const dist = Math.hypot(dx, dy) + 0.1
        t.canopy = Math.min(1, t.canopy + (tree.height * 0.35) / dist)
      }
    }
  }

  const spawnX = Math.floor(width / 2)
  const spawnY = Math.floor(height / 2)
  // Ensure a soft clearing near spawn
  for (let dy = -2; dy <= 2; dy++) {
    for (let dx = -2; dx <= 2; dx++) {
      const nx = spawnX + dx
      const ny = spawnY + dy
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue
      const t = tiles[idx(width, nx, ny)]!
      if (t.kind === 'water') continue
      if (Math.hypot(dx, dy) <= 1.5) {
        t.kind = 'clearing'
        t.canopy *= 0.4
      }
    }
  }

  const creatures = seedCreatures(tiles, width, height, 0.35)

  const materials = emptyMaterials()
  materials.bark = 3
  materials.moss_clump = 3
  materials.fallen_leaf = 2
  materials.soft_clay = 1

  return {
    width,
    height,
    tiles,
    trees,
    creatures,
    furniture: [],
    memory: {
      careEvents: 0,
      neglectDays: 0,
      pathsFormed: 0,
      spiritsMet: 0,
      name: '名もなき森',
      furnitureCrafted: 0,
      furniturePlaced: 0,
    },
    player: {
      x: spawnX + 0.5,
      y: spawnY + 0.5,
      stamina: 100,
      bond: 12,
      seeds: 8,
      journal: [
        '森に足を踏み入れた。空気が湿って、静かに呼吸している。',
        'ここでは貨幣より、絆が生きる指標になる。',
        '材料を採り、生きた家具を育て、森に還そう。',
      ],
      facing: { x: 0, y: 1 },
      materials,
      furnitureBag: {},
      knownRecipes: ['moss_sofa', 'living_fence', 'glow_stump'],
    },
    day: 1,
    timeOfDay: 0.28,
    season: 'spring',
    weather: 'mist',
  }
}

function seedCreatures(
  tiles: Tile[],
  width: number,
  height: number,
  timeOfDay: number,
): Creature[] {
  const creatures: Creature[] = []
  let id = 1
  const attempts = Math.floor((width * height) / 38)

  for (let i = 0; i < attempts; i++) {
    const x = Math.floor(Math.random() * width)
    const y = Math.floor(Math.random() * height)
    const tile = tiles[idx(width, x, y)]!
    if (tile.kind === 'water') continue
    const nearWater = neighborsWater(tiles, width, height, x, y)
    const kind = creatureForBiome(
      tile.fertility,
      tile.canopy,
      nearWater,
      timeOfDay,
    )
    if (!kind) continue
    creatures.push({
      id: id++,
      kind,
      x: x + 0.5,
      y: y + 0.5,
      vx: 0,
      vy: 0,
      mood: 0.5 + Math.random() * 0.4,
      age: Math.random() * 100,
      homeX: x + 0.5,
      homeY: y + 0.5,
    })
  }
  return creatures
}

function neighborsWater(
  tiles: Tile[],
  width: number,
  height: number,
  x: number,
  y: number,
): boolean {
  for (let dy = -2; dy <= 2; dy++) {
    for (let dx = -2; dx <= 2; dx++) {
      const nx = x + dx
      const ny = y + dy
      if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue
      if (tiles[idx(width, nx, ny)]!.kind === 'water') return true
    }
  }
  return false
}

export function getTile(world: WorldState, x: number, y: number): Tile | null {
  const ix = Math.floor(x)
  const iy = Math.floor(y)
  if (ix < 0 || iy < 0 || ix >= world.width || iy >= world.height) return null
  return world.tiles[idx(world.width, ix, iy)]!
}

export function seasonFromDay(day: number): Season {
  const cycle = ((day - 1) % 28) + 1
  if (cycle <= 7) return 'spring'
  if (cycle <= 14) return 'summer'
  if (cycle <= 21) return 'autumn'
  return 'winter'
}

export function weatherFor(season: Season, timeOfDay: number): WorldState['weather'] {
  const roll = fbm(timeOfDay * 8, season.length, 33)
  if (season === 'winter' && roll > 0.55) return 'snow'
  if (roll > 0.72) return 'rain'
  if (roll > 0.45 || timeOfDay < 0.25) return 'mist'
  return 'clear'
}

export { idx, SPECIES }
