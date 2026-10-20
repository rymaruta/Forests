import { forestVitality, interact, tickWorld, tryMove } from './ecosystem'
import { Input } from './input'
import { Renderer } from './renderer'
import type { Interaction, WorldState } from './types'
import { createWorld } from './world'

export type Screen = 'title' | 'play' | 'journal'

export class Game {
  world: WorldState
  renderer: Renderer
  input = new Input()
  screen: Screen = 'title'
  toast = ''
  toastTimer = 0
  private last = 0
  private running = false
  private raf = 0

  constructor(canvas: HTMLCanvasElement) {
    this.world = createWorld()
    this.renderer = new Renderer(canvas)
  }

  start(): void {
    if (this.running) return
    this.running = true
    this.last = performance.now()
    const loop = (now: number) => {
      const dt = Math.min(0.05, (now - this.last) / 1000)
      this.last = now
      this.update(dt)
      this.renderer.draw(this.world, dt)
      this.raf = requestAnimationFrame(loop)
    }
    this.raf = requestAnimationFrame(loop)
  }

  stop(): void {
    this.running = false
    cancelAnimationFrame(this.raf)
  }

  enterForest(name: string): void {
    this.world = createWorld()
    this.world.memory.name = name.trim() || '名もなき森'
    this.world.player.journal.unshift(
      `「${this.world.memory.name}」——この森と、今日から共生を始める。`,
    )
    this.screen = 'play'
    this.showToast(`${this.world.memory.name}へようこそ。WASDで歩く。`)
  }

  private update(dt: number): void {
    if (this.toastTimer > 0) {
      this.toastTimer -= dt
      if (this.toastTimer <= 0) this.toast = ''
    }

    if (this.screen !== 'play') return

    if (this.input.consume('j')) {
      this.screen = 'journal'
      return
    }

    const axis = this.input.axis()
    tryMove(this.world, axis.x, axis.y, dt)
    tickWorld(this.world, dt)

    const bindings: [string, Interaction][] = [
      ['e', 'observe'],
      ['f', 'water'],
      ['g', 'plant'],
      ['t', 'tend'],
      ['q', 'listen'],
      ['r', 'rest'],
    ]
    for (const [key, action] of bindings) {
      if (this.input.consume(key)) {
        const result = interact(this.world, action)
        this.showToast(result.message)
      }
    }
  }

  closeJournal(): void {
    if (this.screen === 'journal') this.screen = 'play'
  }

  showToast(message: string): void {
    this.toast = message
    this.toastTimer = 3.2
  }

  hud() {
    const w = this.world
    return {
      name: w.memory.name,
      day: w.day,
      season: w.season,
      weather: w.weather,
      timeOfDay: w.timeOfDay,
      bond: Math.floor(w.player.bond),
      stamina: Math.floor(w.player.stamina),
      seeds: w.player.seeds,
      vitality: Math.round(forestVitality(w) * 100),
      creatures: w.creatures.length,
      spirits: w.memory.spiritsMet,
      paths: w.memory.pathsFormed,
      care: w.memory.careEvents,
      journal: w.player.journal,
      toast: this.toast,
      screen: this.screen,
    }
  }
}

export const seasonJa: Record<string, string> = {
  spring: '春',
  summer: '夏',
  autumn: '秋',
  winter: '冬',
}

export const weatherJa: Record<string, string> = {
  clear: '晴れ',
  mist: '霧',
  rain: '雨',
  snow: '雪',
}

export function clockLabel(t: number): string {
  const minutes = Math.floor(t * 24 * 60)
  const h = String(Math.floor(minutes / 60)).padStart(2, '0')
  const m = String(minutes % 60).padStart(2, '0')
  return `${h}:${m}`
}
