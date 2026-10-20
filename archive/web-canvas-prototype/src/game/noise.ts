/** Compact value-noise helpers for terrain & atmosphere. */

function hash(x: number, y: number, seed: number): number {
  let n = Math.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
  return n - Math.floor(n)
}

export function valueNoise(x: number, y: number, seed = 1): number {
  const x0 = Math.floor(x)
  const y0 = Math.floor(y)
  const fx = x - x0
  const fy = y - y0
  const sx = fx * fx * (3 - 2 * fx)
  const sy = fy * fy * (3 - 2 * fy)
  const a = hash(x0, y0, seed)
  const b = hash(x0 + 1, y0, seed)
  const c = hash(x0, y0 + 1, seed)
  const d = hash(x0 + 1, y0 + 1, seed)
  const u = a + (b - a) * sx
  const v = c + (d - c) * sx
  return u + (v - u) * sy
}

export function fbm(x: number, y: number, seed = 1, octaves = 4): number {
  let amp = 0.5
  let freq = 1
  let sum = 0
  let norm = 0
  for (let i = 0; i < octaves; i++) {
    sum += amp * valueNoise(x * freq, y * freq, seed + i * 17)
    norm += amp
    amp *= 0.5
    freq *= 2
  }
  return sum / norm
}
