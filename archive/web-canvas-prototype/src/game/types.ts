export type Season = 'spring' | 'summer' | 'autumn' | 'winter'

export type TileKind =
  | 'grass'
  | 'moss'
  | 'soil'
  | 'path'
  | 'water'
  | 'clearing'
  | 'mushroom'

export type CreatureKind =
  | 'deer'
  | 'fox'
  | 'owl'
  | 'rabbit'
  | 'firefly'
  | 'spirit'

export type Interaction =
  | 'observe'
  | 'water'
  | 'plant'
  | 'tend'
  | 'listen'
  | 'rest'
  | 'gather'
  | 'sit'

export type MaterialId =
  | 'bark'
  | 'resin'
  | 'moss_clump'
  | 'mushroom'
  | 'fallen_leaf'
  | 'spirit_dew'
  | 'driftwood'
  | 'soft_clay'
  | 'seed_pod'

export type FurnitureId =
  | 'moss_sofa'
  | 'mycelium_lamp'
  | 'root_shelf'
  | 'dew_basin'
  | 'sakura_bench'
  | 'wind_chime'
  | 'hollow_bed'
  | 'spore_carpet'
  | 'amber_table'
  | 'living_fence'
  | 'glow_stump'
  | 'fern_screen'

export type FurnitureCategory = 'seat' | 'light' | 'storage' | 'water' | 'decor' | 'bed' | 'craft'

export interface Vec2 {
  x: number
  y: number
}

export interface Tile {
  kind: TileKind
  moisture: number
  fertility: number
  memory: number
  canopy: number
  age: number
}

export interface Tree {
  id: number
  x: number
  y: number
  species: 'oak' | 'birch' | 'cedar' | 'sakura' | 'maple'
  height: number
  health: number
  plantedByPlayer: boolean
}

export interface Creature {
  id: number
  kind: CreatureKind
  x: number
  y: number
  vx: number
  vy: number
  mood: number
  age: number
  homeX: number
  homeY: number
}

/** Placed furniture — keeps growing / reacting (AC家具を超える核). */
export interface PlacedFurniture {
  id: number
  kind: FurnitureId
  x: number
  y: number
  /** 0–1 growth / bloom / charge */
  vitality: number
  /** seasons survived while placed */
  ageDays: number
  /** how often creatures used it */
  visits: number
  rotation: 0 | 1 | 2 | 3
}

export interface FurnitureDef {
  id: FurnitureId
  name: string
  blurb: string
  category: FurnitureCategory
  /** ACにない：配置後も生態に効く */
  eco: {
    moisture?: number
    fertility?: number
    attract?: CreatureKind[]
    bondOnUse?: number
    staminaOnSit?: number
  }
  recipe: Partial<Record<MaterialId, number>>
  unlockBond: number
  size: 1 | 2
}

export interface ForestMemory {
  careEvents: number
  neglectDays: number
  pathsFormed: number
  spiritsMet: number
  name: string
  furnitureCrafted: number
  furniturePlaced: number
}

export interface PlayerState {
  x: number
  y: number
  stamina: number
  bond: number
  seeds: number
  journal: string[]
  facing: Vec2
  /** bag of living materials */
  materials: Record<MaterialId, number>
  /** crafted but not yet placed */
  furnitureBag: Partial<Record<FurnitureId, number>>
  /** discovered recipe ids */
  knownRecipes: FurnitureId[]
}

export interface WorldState {
  width: number
  height: number
  tiles: Tile[]
  trees: Tree[]
  creatures: Creature[]
  furniture: PlacedFurniture[]
  memory: ForestMemory
  player: PlayerState
  day: number
  timeOfDay: number
  season: Season
  weather: 'clear' | 'mist' | 'rain' | 'snow'
}

export type Panel =
  | 'none'
  | 'journal'
  | 'bag'
  | 'craft'
  | 'place'
  | 'hollow'
