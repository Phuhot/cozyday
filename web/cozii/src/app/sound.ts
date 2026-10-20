// Âm thanh tự tổng hợp bằng Web Audio (không dùng file âm thanh ngoài).
// Chỉ bật sau khi người chơi chạm/nhấn (trình duyệt yêu cầu); tắt được trong Cài đặt. Game chơi được khi tắt tiếng.

type Sfx = 'tap' | 'pop' | 'coin' | 'good' | 'nope' | 'jump' | 'star' | 'hit' | 'water' | 'harvest' | 'open' | 'rare' | 'special' | 'swish' | 'stamp'

let ctx: AudioContext | null = null
let master: GainNode | null = null
let enabled = readEnabled()
let unlocked = false

function readEnabled(): boolean {
  try {
    return localStorage.getItem('cozii:sound') !== 'off'
  } catch {
    return true
  }
}

export function soundEnabled() {
  return enabled
}

export function setSoundEnabled(v: boolean) {
  enabled = v
  try {
    localStorage.setItem('cozii:sound', v ? 'on' : 'off')
  } catch {
    /* bỏ qua */
  }
  if (master) master.gain.value = v ? 0.5 : 0
}

/** Gọi trong một trình xử lý chạm/nhấn để mở khóa âm thanh. */
export function unlockAudio() {
  if (unlocked && ctx?.state === 'running') return
  try {
    const AC = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext
    if (!AC) return
    if (!ctx) {
      ctx = new AC()
      master = ctx.createGain()
      master.gain.value = enabled ? 0.5 : 0
      master.connect(ctx.destination)
    }
    if (ctx.state === 'suspended') void ctx.resume()
    unlocked = true
  } catch {
    ctx = null
  }
}

export function audioContext(): AudioContext | null {
  return ctx
}
export function masterNode(): GainNode | null {
  return master
}

/** Tạm dừng toàn bộ âm thanh (khi app vào nền). */
export function suspendAudio() {
  if (ctx && ctx.state === 'running') void ctx.suspend()
}
export function resumeAudio() {
  if (ctx && ctx.state === 'suspended' && unlocked) void ctx.resume()
}

function tone(freq: number, start: number, dur: number, type: OscillatorType = 'sine', vol = 0.25, slideTo?: number) {
  if (!ctx || !master) return
  const t0 = ctx.currentTime + start
  const o = ctx.createOscillator()
  const g = ctx.createGain()
  o.type = type
  o.frequency.setValueAtTime(freq, t0)
  if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t0 + dur)
  g.gain.setValueAtTime(0.0001, t0)
  g.gain.exponentialRampToValueAtTime(vol, t0 + 0.012)
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur)
  o.connect(g)
  g.connect(master)
  o.start(t0)
  o.stop(t0 + dur + 0.02)
}

export function playNote(freq: number, dur = 0.25, type: OscillatorType = 'triangle', vol = 0.22) {
  if (!enabled) return
  tone(freq, 0, dur, type, vol)
}

export function sfx(name: Sfx) {
  if (!enabled || !ctx || ctx.state !== 'running') return
  switch (name) {
    case 'tap': tone(880, 0, 0.06, 'triangle', 0.12); break
    case 'pop': tone(520, 0, 0.09, 'sine', 0.2, 900); break
    case 'coin': tone(988, 0, 0.08, 'square', 0.08); tone(1319, 0.07, 0.14, 'square', 0.08); break
    case 'good': tone(659, 0, 0.1, 'triangle', 0.18); tone(784, 0.09, 0.1, 'triangle', 0.18); tone(1047, 0.18, 0.18, 'triangle', 0.18); break
    case 'nope': tone(300, 0, 0.12, 'sine', 0.15, 220); break
    case 'jump': tone(440, 0, 0.12, 'sine', 0.14, 880); break
    case 'star': tone(1175, 0, 0.08, 'triangle', 0.14); tone(1568, 0.06, 0.12, 'triangle', 0.12); break
    case 'hit': tone(200, 0, 0.18, 'sawtooth', 0.08, 110); break
    case 'water': tone(700, 0, 0.08, 'sine', 0.12, 400); tone(600, 0.08, 0.1, 'sine', 0.1, 350); break
    case 'harvest': tone(523, 0, 0.08, 'triangle', 0.16); tone(784, 0.07, 0.14, 'triangle', 0.16); break
    case 'open': tone(392, 0, 0.12, 'triangle', 0.16, 523); tone(659, 0.12, 0.2, 'triangle', 0.16); break
    case 'rare': tone(523, 0, 0.12, 'triangle', 0.18); tone(784, 0.1, 0.12, 'triangle', 0.18); tone(1047, 0.2, 0.3, 'triangle', 0.18); break
    case 'special': [523, 659, 784, 1047, 1319].forEach((f, i) => tone(f, i * 0.08, 0.3, 'triangle', 0.16)); break
    case 'swish': tone(300, 0, 0.1, 'sine', 0.06, 600); break
    case 'stamp': tone(160, 0, 0.12, 'square', 0.1, 90); tone(880, 0.1, 0.2, 'triangle', 0.14); break
  }
}
