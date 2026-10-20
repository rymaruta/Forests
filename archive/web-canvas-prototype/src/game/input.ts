export class Input {
  private keys = new Set<string>()
  private pressed = new Set<string>()

  constructor() {
    window.addEventListener('keydown', (e) => {
      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(e.key)) {
        e.preventDefault()
      }
      const k = e.key.toLowerCase()
      if (!this.keys.has(k)) this.pressed.add(k)
      this.keys.add(k)
    })
    window.addEventListener('keyup', (e) => {
      this.keys.delete(e.key.toLowerCase())
    })
    window.addEventListener('blur', () => {
      this.keys.clear()
      this.pressed.clear()
    })
  }

  axis(): { x: number; y: number } {
    let x = 0
    let y = 0
    if (this.keys.has('a') || this.keys.has('arrowleft')) x -= 1
    if (this.keys.has('d') || this.keys.has('arrowright')) x += 1
    if (this.keys.has('w') || this.keys.has('arrowup')) y -= 1
    if (this.keys.has('s') || this.keys.has('arrowdown')) y += 1
    return { x, y }
  }

  consume(key: string): boolean {
    const k = key.toLowerCase()
    if (this.pressed.has(k)) {
      this.pressed.delete(k)
      return true
    }
    return false
  }

  clearPressed(): void {
    this.pressed.clear()
  }
}
