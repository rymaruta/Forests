import { forestVitality } from './ecosystem'
import { furnitureDef } from './furniture'
import type { Creature, PlacedFurniture, Season, Tree, WorldState } from './types'

const TILE = 28

interface Palette {
  skyTop: string
  skyBot: string
  grass: string
  moss: string
  soil: string
  path: string
  water: string
  clearing: string
  mushroom: string
  fog: string
}

function palette(season: Season, time: number, weather: WorldState['weather']): Palette {
  const night = time < 0.2 || time > 0.8
  const dusk = (time > 0.7 && time < 0.85) || (time > 0.15 && time < 0.28)

  const bases: Record<Season, Palette> = {
    spring: {
      skyTop: night ? '#0d1f24' : dusk ? '#c4785a' : '#8ec9c4',
      skyBot: night ? '#1a3330' : dusk ? '#e8b86d' : '#d5e8c8',
      grass: '#5f8f4e',
      moss: '#3d6b45',
      soil: '#6b5344',
      path: '#8a7358',
      water: '#3a7a8c',
      clearing: '#7aa35f',
      mushroom: '#4a6350',
      fog: 'rgba(220,235,220,0.35)',
    },
    summer: {
      skyTop: night ? '#0a1820' : dusk ? '#d4654a' : '#5eb0d4',
      skyBot: night ? '#132a28' : dusk ? '#f0a45a' : '#b8d99a',
      grass: '#3f7a38',
      moss: '#2f5c3a',
      soil: '#5c4638',
      path: '#7a6548',
      water: '#2f6f88',
      clearing: '#6a9a48',
      mushroom: '#3d5644',
      fog: 'rgba(200,230,210,0.2)',
    },
    autumn: {
      skyTop: night ? '#1a1218' : dusk ? '#b54530' : '#d4a06a',
      skyBot: night ? '#241820' : dusk ? '#e89050' : '#e8c89a',
      grass: '#8a6a38',
      moss: '#5a4a30',
      soil: '#5a3e30',
      path: '#7a5a40',
      water: '#3a5a68',
      clearing: '#a87840',
      mushroom: '#6a5038',
      fog: 'rgba(230,200,160,0.28)',
    },
    winter: {
      skyTop: night ? '#0c1218' : dusk ? '#8a6a78' : '#a8c0d0',
      skyBot: night ? '#151e28' : dusk ? '#c0a090' : '#e8eef2',
      grass: '#6a7a68',
      moss: '#4a5a50',
      soil: '#5a5854',
      path: '#8a8680',
      water: '#4a6878',
      clearing: '#c8d0d4',
      mushroom: '#5a6058',
      fog: 'rgba(240,245,250,0.4)',
    },
  }

  const p = { ...bases[season] }
  if (weather === 'rain') {
    p.skyTop = night ? '#0a1418' : '#6a8088'
    p.skyBot = night ? '#121c20' : '#9aac98'
  }
  if (weather === 'snow') {
    p.fog = 'rgba(250,252,255,0.5)'
  }
  return p
}

function treeColors(species: Tree['species'], season: Season, health: number): { trunk: string; leaf: string } {
  const trunk = health > 0.4 ? '#4a3428' : '#3a2a22'
  const leaves: Record<Tree['species'], Record<Season, string>> = {
    oak: { spring: '#3d7a3a', summer: '#2f6b32', autumn: '#b85a28', winter: '#4a5a48' },
    birch: { spring: '#6a9a58', summer: '#5a8a48', autumn: '#d4a040', winter: '#6a7068' },
    cedar: { spring: '#2a5a38', summer: '#1e4a30', autumn: '#2a4a34', winter: '#243e30' },
    sakura: { spring: '#e8a0b8', summer: '#6a9a58', autumn: '#c07080', winter: '#8a7880' },
    maple: { spring: '#4a8a40', summer: '#3a7a38', autumn: '#d43828', winter: '#5a4840' },
  }
  return { trunk, leaf: leaves[species][season] }
}

export class Renderer {
  canvas: HTMLCanvasElement
  ctx: CanvasRenderingContext2D
  camera = { x: 0, y: 0 }
  private particles: { x: number; y: number; vx: number; vy: number; life: number; kind: string }[] = []
  private t = 0

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas unsupported')
    this.ctx = ctx
  }

  resize(width: number, height: number): void {
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    this.canvas.width = Math.floor(width * dpr)
    this.canvas.height = Math.floor(height * dpr)
    this.canvas.style.width = `${width}px`
    this.canvas.style.height = `${height}px`
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  }

  follow(world: WorldState): void {
    const w = this.canvas.clientWidth
    const h = this.canvas.clientHeight
    const targetX = world.player.x * TILE - w / 2
    const targetY = world.player.y * TILE - h / 2
    this.camera.x += (targetX - this.camera.x) * 0.12
    this.camera.y += (targetY - this.camera.y) * 0.12
  }

  private spawnAtmosphere(world: WorldState, dt: number): void {
    this.t += dt
    const rate =
      world.weather === 'rain' ? 40 : world.weather === 'snow' ? 25 : world.weather === 'mist' ? 8 : 3
    for (let i = 0; i < rate * dt; i++) {
      const kind =
        world.weather === 'rain'
          ? 'rain'
          : world.weather === 'snow'
            ? 'snow'
            : Math.random() > 0.7
              ? 'pollen'
              : 'leaf'
      this.particles.push({
        x: this.camera.x + Math.random() * this.canvas.clientWidth,
        y: this.camera.y - 10 + Math.random() * 20,
        vx: (Math.random() - 0.5) * (kind === 'rain' ? 40 : 20),
        vy: kind === 'rain' ? 180 + Math.random() * 80 : 20 + Math.random() * 40,
        life: 1,
        kind,
      })
    }
    // Firefly glow particles near creatures
    for (const c of world.creatures) {
      if (c.kind !== 'firefly') continue
      if (Math.random() > 0.3) continue
      this.particles.push({
        x: c.x * TILE + (Math.random() - 0.5) * 10,
        y: c.y * TILE + (Math.random() - 0.5) * 10,
        vx: 0,
        vy: -8,
        life: 1,
        kind: 'glow',
      })
    }
  }

  draw(world: WorldState, dt: number): void {
    const { ctx } = this
    const w = this.canvas.clientWidth
    const h = this.canvas.clientHeight
    const pal = palette(world.season, world.timeOfDay, world.weather)

    this.follow(world)
    this.spawnAtmosphere(world, dt)

    // Sky gradient
    const sky = ctx.createLinearGradient(0, 0, 0, h)
    sky.addColorStop(0, pal.skyTop)
    sky.addColorStop(1, pal.skyBot)
    ctx.fillStyle = sky
    ctx.fillRect(0, 0, w, h)

    ctx.save()
    ctx.translate(-this.camera.x, -this.camera.y)

    const startX = Math.max(0, Math.floor(this.camera.x / TILE) - 1)
    const startY = Math.max(0, Math.floor(this.camera.y / TILE) - 1)
    const endX = Math.min(world.width, Math.ceil((this.camera.x + w) / TILE) + 1)
    const endY = Math.min(world.height, Math.ceil((this.camera.y + h) / TILE) + 1)

    for (let y = startY; y < endY; y++) {
      for (let x = startX; x < endX; x++) {
        const tile = world.tiles[y * world.width + x]!
        const px = x * TILE
        const py = y * TILE
        let color = pal.grass
        if (tile.kind === 'moss') color = pal.moss
        else if (tile.kind === 'soil') color = pal.soil
        else if (tile.kind === 'path') color = pal.path
        else if (tile.kind === 'water') color = pal.water
        else if (tile.kind === 'clearing') color = pal.clearing
        else if (tile.kind === 'mushroom') color = pal.mushroom

        ctx.fillStyle = color
        ctx.fillRect(px, py, TILE + 0.5, TILE + 0.5)

        // Memory shimmer — unique Forests visual: cared ground glows softly
        if (tile.memory > 0.2) {
          ctx.fillStyle = `rgba(180, 220, 160, ${tile.memory * 0.22})`
          ctx.beginPath()
          ctx.ellipse(
            px + TILE / 2,
            py + TILE / 2,
            TILE * 0.35,
            TILE * 0.28,
            0,
            0,
            Math.PI * 2,
          )
          ctx.fill()
        }

        if (tile.kind === 'water') {
          const wave = Math.sin(this.t * 2 + x * 0.4 + y * 0.3) * 2
          ctx.strokeStyle = 'rgba(200,240,255,0.25)'
          ctx.beginPath()
          ctx.moveTo(px + 4, py + TILE / 2 + wave)
          ctx.quadraticCurveTo(px + TILE / 2, py + TILE / 2 - wave, px + TILE - 4, py + TILE / 2 + wave)
          ctx.stroke()
        }

        if (tile.kind === 'mushroom') {
          ctx.fillStyle = '#c87868'
          ctx.beginPath()
          ctx.arc(px + 10, py + 16, 3.5, 0, Math.PI * 2)
          ctx.fill()
          ctx.fillStyle = '#e8d0b0'
          ctx.fillRect(px + 9, py + 16, 2, 5)
        }
      }
    }

    // Sort drawable entities by y for soft depth
    const drawables: { y: number; draw: () => void }[] = []

    for (const furn of world.furniture) {
      drawables.push({
        y: furn.y,
        draw: () => this.drawFurniture(furn, world),
      })
    }
    for (const tree of world.trees) {
      drawables.push({
        y: tree.y,
        draw: () => this.drawTree(tree, world.season),
      })
    }
    for (const c of world.creatures) {
      drawables.push({
        y: c.y,
        draw: () => this.drawCreature(c, world),
      })
    }
    drawables.push({
      y: world.player.y,
      draw: () => this.drawPlayer(world),
    })

    drawables.sort((a, b) => a.y - b.y)
    for (const d of drawables) d.draw()

    // Particles in world space
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i]!
      p.x += p.vx * dt
      p.y += p.vy * dt
      p.life -= dt * (p.kind === 'glow' ? 1.2 : 0.35)
      if (p.life <= 0) {
        this.particles.splice(i, 1)
        continue
      }
      if (p.kind === 'rain') {
        ctx.strokeStyle = `rgba(180,210,230,${p.life * 0.5})`
        ctx.beginPath()
        ctx.moveTo(p.x, p.y)
        ctx.lineTo(p.x - 2, p.y + 10)
        ctx.stroke()
      } else if (p.kind === 'snow') {
        ctx.fillStyle = `rgba(255,255,255,${p.life * 0.8})`
        ctx.beginPath()
        ctx.arc(p.x, p.y, 2, 0, Math.PI * 2)
        ctx.fill()
      } else if (p.kind === 'glow') {
        ctx.fillStyle = `rgba(200,255,140,${p.life * 0.7})`
        ctx.beginPath()
        ctx.arc(p.x, p.y, 3 + (1 - p.life) * 4, 0, Math.PI * 2)
        ctx.fill()
      } else {
        ctx.fillStyle =
          world.season === 'autumn'
            ? `rgba(200,100,40,${p.life * 0.6})`
            : `rgba(160,200,100,${p.life * 0.45})`
        ctx.fillRect(p.x, p.y, 3, 2)
      }
    }

    ctx.restore()

    // Screen-space fog / night veil
    const night = world.timeOfDay < 0.2 || world.timeOfDay > 0.8
    const dusk = (world.timeOfDay > 0.7 && world.timeOfDay < 0.85) || (world.timeOfDay > 0.15 && world.timeOfDay < 0.28)
    if (night) {
      ctx.fillStyle = 'rgba(4, 12, 16, 0.45)'
      ctx.fillRect(0, 0, w, h)
    } else if (dusk) {
      ctx.fillStyle = 'rgba(80, 30, 20, 0.12)'
      ctx.fillRect(0, 0, w, h)
    }

    if (world.weather === 'mist' || world.weather === 'snow') {
      const fog = ctx.createRadialGradient(w * 0.5, h * 0.55, 40, w * 0.5, h * 0.5, h * 0.75)
      fog.addColorStop(0, 'rgba(0,0,0,0)')
      fog.addColorStop(1, pal.fog)
      ctx.fillStyle = fog
      ctx.fillRect(0, 0, w, h)
    }

    // Subtle vignette tied to vitality — dying forest feels heavier
    const vit = forestVitality(world)
    if (vit < 0.45) {
      ctx.fillStyle = `rgba(20, 10, 8, ${(0.45 - vit) * 0.5})`
      ctx.fillRect(0, 0, w, h)
    }
  }

  private drawTree(tree: Tree, season: Season): void {
    const { ctx } = this
    const { trunk, leaf } = treeColors(tree.species, season, tree.health)
    const px = tree.x * TILE
    const py = tree.y * TILE
    const h = 10 + tree.height * 22
    const r = 6 + tree.height * 10

    // Soft shadow
    ctx.fillStyle = 'rgba(20,30,20,0.18)'
    ctx.beginPath()
    ctx.ellipse(px, py + 4, r * 0.7, r * 0.28, 0, 0, Math.PI * 2)
    ctx.fill()

    ctx.fillStyle = trunk
    ctx.fillRect(px - 2, py - h * 0.55, 4, h * 0.55)

    ctx.fillStyle = leaf
    ctx.beginPath()
    if (tree.species === 'cedar') {
      ctx.moveTo(px, py - h)
      ctx.lineTo(px + r * 0.7, py - h * 0.25)
      ctx.lineTo(px - r * 0.7, py - h * 0.25)
      ctx.closePath()
    } else {
      ctx.arc(px, py - h * 0.55, r, 0, Math.PI * 2)
    }
    ctx.fill()

    if (tree.plantedByPlayer) {
      ctx.strokeStyle = 'rgba(220, 240, 180, 0.55)'
      ctx.lineWidth = 1.5
      ctx.beginPath()
      ctx.arc(px, py - h * 0.55, r + 3, 0, Math.PI * 2)
      ctx.stroke()
    }
  }

  private drawCreature(c: Creature, world: WorldState): void {
    const { ctx } = this
    const px = c.x * TILE
    const py = c.y * TILE
    const bob = Math.sin(this.t * 3 + c.id) * 1.5

    const colors: Record<Creature['kind'], string> = {
      deer: '#c4a078',
      fox: '#d4783a',
      owl: '#7a6a58',
      rabbit: '#e8e0d4',
      firefly: '#c8ff80',
      spirit: '#a8e8d0',
    }

    if (c.kind === 'spirit') {
      const g = ctx.createRadialGradient(px, py - 8 + bob, 2, px, py - 8 + bob, 16)
      g.addColorStop(0, 'rgba(180,255,220,0.85)')
      g.addColorStop(1, 'rgba(180,255,220,0)')
      ctx.fillStyle = g
      ctx.beginPath()
      ctx.arc(px, py - 8 + bob, 16, 0, Math.PI * 2)
      ctx.fill()
    }

    if (c.kind === 'firefly') {
      ctx.fillStyle = `rgba(200,255,120,${0.5 + Math.sin(this.t * 6 + c.id) * 0.4})`
      ctx.beginPath()
      ctx.arc(px, py - 4 + bob, 3.5, 0, Math.PI * 2)
      ctx.fill()
      return
    }

    ctx.fillStyle = colors[c.kind]
    ctx.beginPath()
    ctx.ellipse(px, py - 4 + bob, c.kind === 'deer' ? 7 : 5, c.kind === 'deer' ? 9 : 6, 0, 0, Math.PI * 2)
    ctx.fill()

    if (c.kind === 'deer') {
      ctx.strokeStyle = colors.deer
      ctx.lineWidth = 1.5
      ctx.beginPath()
      ctx.moveTo(px - 3, py - 12 + bob)
      ctx.lineTo(px - 5, py - 18 + bob)
      ctx.moveTo(px + 3, py - 12 + bob)
      ctx.lineTo(px + 5, py - 18 + bob)
      ctx.stroke()
    }

    // Mood ring when forest bond is high and creature is happy
    if (c.mood > 0.7 && world.player.bond > 25) {
      ctx.strokeStyle = `rgba(160,220,160,${c.mood * 0.4})`
      ctx.beginPath()
      ctx.arc(px, py - 4 + bob, 10, 0, Math.PI * 2)
      ctx.stroke()
    }
  }

  private drawFurniture(f: PlacedFurniture, world: WorldState): void {
    const { ctx } = this
    const px = f.x * TILE
    const py = f.y * TILE
    const def = furnitureDef(f.kind)
    const v = f.vitality
    const night = world.timeOfDay < 0.22 || world.timeOfDay > 0.78

    ctx.fillStyle = 'rgba(20,30,20,0.2)'
    ctx.beginPath()
    ctx.ellipse(px, py + 2, 10 + def.size * 4, 4, 0, 0, Math.PI * 2)
    ctx.fill()

    switch (f.kind) {
      case 'moss_sofa': {
        ctx.fillStyle = `rgb(${40 + v * 40 | 0}, ${90 + v * 50 | 0}, ${55 + v * 30 | 0})`
        ctx.fillRect(px - 14, py - 10, 28, 12)
        ctx.fillStyle = '#3a5a40'
        ctx.fillRect(px - 14, py - 14, 6, 6)
        ctx.fillRect(px + 8, py - 14, 6, 6)
        break
      }
      case 'mycelium_lamp': {
        ctx.fillStyle = '#5a4030'
        ctx.fillRect(px - 2, py - 8, 4, 10)
        const glow = night ? 0.55 + v * 0.4 : 0.15 + v * 0.15
        const g = ctx.createRadialGradient(px, py - 14, 2, px, py - 14, 16)
        g.addColorStop(0, `rgba(180,255,140,${glow})`)
        g.addColorStop(1, 'rgba(180,255,140,0)')
        ctx.fillStyle = g
        ctx.beginPath()
        ctx.arc(px, py - 14, 16, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = `rgba(200,255,160,${0.5 + v * 0.5})`
        ctx.beginPath()
        ctx.arc(px, py - 14, 5, 0, Math.PI * 2)
        ctx.fill()
        break
      }
      case 'root_shelf': {
        ctx.fillStyle = '#6a4a30'
        ctx.fillRect(px - 10, py - 18, 20, 20)
        ctx.strokeStyle = '#8a6a48'
        ctx.strokeRect(px - 8, py - 14, 16, 4)
        ctx.strokeRect(px - 8, py - 8, 16, 4)
        ctx.strokeRect(px - 8, py - 2, 16, 4)
        break
      }
      case 'dew_basin': {
        ctx.fillStyle = '#7a6a58'
        ctx.beginPath()
        ctx.ellipse(px, py - 2, 11, 7, 0, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = `rgba(80,160,180,${0.45 + v * 0.4})`
        ctx.beginPath()
        ctx.ellipse(px, py - 3, 8, 4, 0, 0, Math.PI * 2)
        ctx.fill()
        break
      }
      case 'sakura_bench': {
        ctx.fillStyle = '#8a5a40'
        ctx.fillRect(px - 14, py - 6, 28, 6)
        ctx.fillRect(px - 12, py, 4, 5)
        ctx.fillRect(px + 8, py, 4, 5)
        if (world.season === 'spring' || v > 0.5) {
          ctx.fillStyle = `rgba(232,160,184,${0.4 + v * 0.5})`
          for (let i = 0; i < 5; i++) {
            ctx.beginPath()
            ctx.arc(px - 10 + i * 5, py - 10 - (i % 2), 3, 0, Math.PI * 2)
            ctx.fill()
          }
        }
        break
      }
      case 'wind_chime': {
        ctx.strokeStyle = '#c8b890'
        ctx.beginPath()
        ctx.moveTo(px, py - 22)
        ctx.lineTo(px, py - 6)
        ctx.stroke()
        ctx.fillStyle = `rgba(180,220,200,${0.5 + Math.sin(this.t * 4) * 0.2})`
        ctx.fillRect(px - 5, py - 12, 3, 10)
        ctx.fillRect(px - 1, py - 10, 3, 12)
        ctx.fillRect(px + 3, py - 14, 3, 9)
        break
      }
      case 'hollow_bed': {
        ctx.fillStyle = '#4a3a28'
        ctx.beginPath()
        ctx.ellipse(px, py - 4, 14, 8, 0, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = `rgb(${50 + v * 30 | 0}, ${100 + v * 40 | 0}, ${60 | 0})`
        ctx.beginPath()
        ctx.ellipse(px, py - 5, 11, 5, 0, 0, Math.PI * 2)
        ctx.fill()
        break
      }
      case 'spore_carpet': {
        ctx.fillStyle = `rgba(90, 120, 70, ${0.35 + v * 0.4})`
        ctx.beginPath()
        ctx.ellipse(px, py, 16, 10, 0, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = 'rgba(200,160,100,0.5)'
        for (let i = 0; i < 4; i++) {
          ctx.beginPath()
          ctx.arc(px - 8 + i * 5, py - 2 + (i % 2), 2, 0, Math.PI * 2)
          ctx.fill()
        }
        break
      }
      case 'amber_table': {
        ctx.fillStyle = '#b87830'
        ctx.fillRect(px - 11, py - 8, 22, 8)
        ctx.fillStyle = '#8a5820'
        ctx.fillRect(px - 8, py, 3, 6)
        ctx.fillRect(px + 5, py, 3, 6)
        ctx.fillStyle = `rgba(255,200,80,${0.2 + v * 0.35})`
        ctx.fillRect(px - 9, py - 7, 18, 5)
        break
      }
      case 'living_fence': {
        ctx.fillStyle = `rgb(${40 + v * 20 | 0}, ${80 + v * 50 | 0}, ${45 | 0})`
        ctx.fillRect(px - 3, py - 16, 6, 18)
        ctx.beginPath()
        ctx.arc(px, py - 16, 7, 0, Math.PI * 2)
        ctx.fill()
        break
      }
      case 'glow_stump': {
        ctx.fillStyle = '#5a4030'
        ctx.beginPath()
        ctx.ellipse(px, py - 2, 9, 6, 0, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = '#6a5040'
        ctx.beginPath()
        ctx.ellipse(px, py - 6, 8, 4, 0, 0, Math.PI * 2)
        ctx.fill()
        if (night) {
          ctx.fillStyle = `rgba(200,255,120,${0.3 + v * 0.4})`
          ctx.beginPath()
          ctx.arc(px, py - 8, 6, 0, Math.PI * 2)
          ctx.fill()
        }
        break
      }
      case 'fern_screen': {
        ctx.fillStyle = `rgb(${30 + v * 20 | 0}, ${90 + v * 40 | 0}, ${50 | 0})`
        for (let i = -1; i <= 1; i++) {
          ctx.beginPath()
          ctx.moveTo(px + i * 6, py)
          ctx.quadraticCurveTo(px + i * 10, py - 12, px + i * 4, py - 20)
          ctx.quadraticCurveTo(px + i * 2, py - 10, px + i * 6, py)
          ctx.fill()
        }
        break
      }
    }

    // growth ring — living furniture indicator
    if (v > 0.55) {
      ctx.strokeStyle = `rgba(160,220,150,${(v - 0.55) * 0.8})`
      ctx.lineWidth = 1
      ctx.beginPath()
      ctx.arc(px, py - 4, 12 + def.size * 3, 0, Math.PI * 2)
      ctx.stroke()
    }
  }

  private drawPlayer(world: WorldState): void {
    const { ctx } = this
    const px = world.player.x * TILE
    const py = world.player.y * TILE
    const walk = Math.sin(this.t * 8) * 1.2

    ctx.fillStyle = 'rgba(20,30,20,0.25)'
    ctx.beginPath()
    ctx.ellipse(px, py + 3, 8, 3.5, 0, 0, Math.PI * 2)
    ctx.fill()

    // Cloak — earth tone, not cartoon animal suit
    ctx.fillStyle = '#2c4a3e'
    ctx.beginPath()
    ctx.ellipse(px, py - 6 + walk * 0.2, 7, 10, 0, 0, Math.PI * 2)
    ctx.fill()

    ctx.fillStyle = '#e8d5b8'
    ctx.beginPath()
    ctx.arc(px, py - 16 + walk * 0.2, 4.5, 0, Math.PI * 2)
    ctx.fill()

    // Bond aura
    const bondAlpha = Math.min(0.35, world.player.bond / 200)
    if (bondAlpha > 0.05) {
      ctx.strokeStyle = `rgba(140, 200, 150, ${bondAlpha})`
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.arc(px, py - 8, 14 + Math.sin(this.t * 2) * 2, 0, Math.PI * 2)
      ctx.stroke()
    }
  }
}

export { TILE }
