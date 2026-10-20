import { useEffect, useRef, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import { paintItem, paintPet } from '../../art'
import { drawOrder, room as roomDef, SPOTS, type RoomId } from '../../content/catalog'
import { restPose, type PetMood, type PetPose } from '../../content/pet'
import { affectionLevel } from '../../core/state'
import { GC, rgb, Color, pt, R, Path, linear, FONT_STACK } from '../../art/gc'
import * as T from '../../art/town'
import { petAppearance } from './Home'
import { Icon } from '../kit'
import { sfx } from '../../app/sound'

interface PoseDef { id: string; name: string; level?: number; series?: string; mood: PetMood; pose: Partial<PetPose>; fx?: 'stars' | 'bubbles' | 'petals' | 'confetti' | 'sparkle' | 'zzz' }

export const POSES: PoseDef[] = [
  { id: 'relax', name: 'Thư giãn', level: 1, mood: 'idle', pose: {} },
  { id: 'happy', name: 'Vui vẻ', level: 1, mood: 'happy', pose: { tilt: 4 } },
  { id: 'sleepy', name: 'Ngủ say', level: 2, mood: 'rest', pose: { z: 0.4 }, fx: 'zzz' },
  { id: 'hearts', name: 'Tim bay', level: 3, mood: 'happy', pose: { petted: 1, hearts: 0.45 } },
  { id: 'surprised', name: 'Ngạc nhiên', level: 4, mood: 'idle', pose: { lifted: true, hop: 6 } },
  { id: 'hop', name: 'Nhún nhảy', level: 5, mood: 'happy', pose: { hop: 9, tilt: -6 } },
  { id: 'reading', name: 'Chăm chú', level: 6, mood: 'focus', pose: {} },
  { id: 'sparkle', name: 'Lấp lánh', level: 7, mood: 'happy', pose: { tilt: 3 }, fx: 'sparkle' },
  { id: 'stargaze', name: 'Ngắm sao', series: 'stargaze', mood: 'rest', pose: {}, fx: 'stars' },
  { id: 'splash', name: 'Té nước', series: 'splash', mood: 'happy', pose: { hop: 5 }, fx: 'bubbles' },
  { id: 'petals', name: 'Mưa hoa', series: 'petals', mood: 'happy', pose: {}, fx: 'petals' },
  { id: 'confetti', name: 'Pháo giấy', series: 'confetti', mood: 'happy', pose: { petted: 1 }, fx: 'confetti' },
]

const BACKDROPS = [
  { id: 'room', name: 'Phòng' },
  { id: 'peach', name: 'Đào', stops: [0xffe3da, 0xffc9d4, 0xf7afc6] },
  { id: 'lavender', name: 'Oải hương', stops: [0xf1e8fd, 0xdccbf6, 0xc5b1ec] },
  { id: 'mint', name: 'Bạc hà', stops: [0xe8f7ee, 0xc6ead5, 0x9ed4b6] },
  { id: 'sunset', name: 'Hoàng hôn', stops: [0xffd9a8, 0xfba6b4, 0xa994e8] },
  { id: 'night', name: 'Đêm', stops: [0x4e3f98, 0x7a68c4, 0xb5a2e8] },
] as const

export function unlockedPoses(level: number, poses: string[]): PoseDef[] {
  return POSES.filter(p => (p.level != null && level >= p.level) || (p.series != null && poses.includes(p.series)))
}

/** Vẽ ảnh chụp lên canvas vuông `size`. Mọi thứ vẽ bằng code nên xuất PNG không vướng CORS. */
function composePhoto(c: CanvasRenderingContext2D, size: number, opts: { roomId: RoomId; backdrop: string; pose: PoseDef; caption: boolean }, s: ReturnType<typeof useGame>['state']) {
  const g = new GC(c)
  c.clearRect(0, 0, size, size)
  if (opts.backdrop === 'room') {
    const def = roomDef(opts.roomId)
    const rs = s.home.rooms[opts.roomId]!
    // cắt phòng 125×100 thành khung vuông, căn theo chỗ pet đứng
    const k = size / 100
    const ox = -Math.max(0, Math.min(25, def.petHome * 125 - 30)) * k
    paintItem(c, rs.theme, ox, 0, 125 * k, 100 * k, true)
    for (const slot of drawOrder(def)) {
      const pl = rs.slots[slot]
      if (!pl) continue
      const sp = SPOTS[slot]!
      paintItem(c, pl.item, ox + (sp.x + pl.dx) * k, sp.y * k, sp.size * k, sp.size * k, false, pl.flip)
    }
  } else {
    const b = BACKDROPS.find(x => x.id === opts.backdrop)
    const stops = b && 'stops' in b ? b.stops : [0xfef6ec, 0xfef6ec]
    g.fill(Path.rect(R(0, 0, size, size)), linear(stops.map(rgb), pt(0, 0), pt(0, size)))
    g.ellipse(size * 0.08, size * 0.7, size * 0.84, size * 0.22, Color.white.opacity(0.35))
  }
  const fx = opts.pose.fx
  const u = size / 100
  if (fx === 'stars') for (let i = 0; i < 22; i++) T.sparkle(g, ((i * 37) % 100) * u, ((i * 23) % 50) * u, (i % 3 ? 4 : 6) * u, rgb(0xfff4c4))
  if (fx === 'bubbles') for (let i = 0; i < 10; i++) {
    const x = ((i * 29) % 90 + 5) * u, y = ((i * 41) % 60 + 5) * u, r = (2 + (i % 3) * 1.6) * u
    g.circle(x, y, r, rgb(0xbfe3ef).opacity(0.35))
    g.strokePath(rgb(0x8fcde6), 0.4 * u, q => q.addEllipse(R(x - r, y - r, r * 2, r * 2)))
  }
  if (fx === 'petals') for (let i = 0; i < 18; i++) g.rotated(i * 37, pt(((i * 31) % 100) * u, ((i * 17) % 80) * u), q => q.ellipse(((i * 31) % 100) * u, ((i * 17) % 80) * u, 3 * u, 1.8 * u, rgb(0xf6b3c6)))
  if (fx === 'confetti') for (let i = 0; i < 26; i++) g.rotated(i * 23, pt(((i * 29) % 100) * u, ((i * 13) % 70) * u), q => q.rect(((i * 29) % 100) * u, ((i * 13) % 70) * u, 2.4 * u, 1.2 * u, rgb([0xf2a3b8, 0xf0c26a, 0x9ed4b6, 0xc9b6f0, 0x8fcde6][i % 5])))
  const petSize = size * 0.62
  const pose = { ...restPose(), ...opts.pose.pose }
  paintPet(c, size * 0.19, size * 0.86 - petSize * 0.95, petSize, petAppearance(s), opts.pose.mood, pose)
  if (fx === 'sparkle') for (const [x, y, k] of [[20, 30, 7], [80, 26, 6], [72, 60, 5], [26, 64, 5]] as const) T.sparkle(g, x * u, y * u, k * u, rgb(0xf0c26a))
  if (opts.caption) {
    g.rect(size * 0.04, size * 0.86, size * 0.92, size * 0.11, Color.white.opacity(0.88), size * 0.04)
    c.save()
    c.fillStyle = '#3e3550'
    c.font = `800 ${size * 0.052}px ${FONT_STACK}`
    c.textBaseline = 'middle'
    c.fillText(s.pet.name + (s.profile.title ? ` · ${s.profile.title}` : ''), size * 0.08, size * 0.915)
    c.fillStyle = '#6f5ab8'
    c.font = `900 ${size * 0.04}px ${FONT_STACK}`
    c.textAlign = 'right'
    c.fillText('Cozii!', size * 0.92, size * 0.915)
    c.restore()
  }
}

export function Photo({ roomId }: { roomId: RoomId }) {
  const { state, act, toast } = useGame()
  const level = affectionLevel(state.pet.affection)
  const poses = unlockedPoses(level, state.poses)
  const [pose, setPose] = useState(poses[0]?.id ?? 'relax')
  const [backdrop, setBackdrop] = useState('room')
  const [hideUi, setHideUi] = useState(false)
  const [caption, setCaption] = useState(true)
  const ref = useRef<HTMLCanvasElement>(null)
  const size = 1080
  const p = POSES.find(x => x.id === pose) ?? POSES[0]

  useEffect(() => {
    const cv = ref.current
    if (!cv) return
    cv.width = size
    cv.height = size
    composePhoto(cv.getContext('2d')!, size, { roomId, backdrop, pose: p, caption }, state)
  }, [roomId, backdrop, p, caption, state])

  const blob = () => new Promise<Blob | null>(res => ref.current?.toBlob(b => res(b), 'image/png'))
  const fileName = `cozii-${state.pet.name || 'pet'}.png`.replace(/\s+/g, '-')

  const share = async () => {
    const b = await blob()
    if (!b) return
    void act({ type: 'photo' }, { quiet: true })
    const file = new File([b], fileName, { type: 'image/png' })
    const nav = navigator as Navigator & { canShare?: (d: ShareData) => boolean }
    if (nav.share && nav.canShare?.({ files: [file] })) {
      try {
        await nav.share({ files: [file], title: 'Cozii!', text: `${state.pet.name} ở Cozii!` })
        return
      } catch {
        /* người dùng hủy chia sẻ */
        return
      }
    }
    download(b)
  }
  const download = (b: Blob) => {
    const url = URL.createObjectURL(b)
    const a = document.createElement('a')
    a.href = url
    a.download = fileName
    a.click()
    setTimeout(() => URL.revokeObjectURL(url), 2000)
    toast('Đã lưu ảnh.', 'good')
  }

  return (
    <div className="photo-stage" onClick={() => hideUi && setHideUi(false)}>
      {!hideUi && (
        <div className="row" style={{ padding: 'calc(10px + var(--safe-t)) 12px 6px' }}>
          <button className="icon-btn" onClick={() => back('home')} aria-label="Đóng"><Icon.close /></button>
          <b style={{ color: '#fff', flex: 1 }}>Chụp ảnh</b>
          <button className="btn small" onClick={e => { e.stopPropagation(); setHideUi(true) }}>Ẩn giao diện</button>
        </div>
      )}
      <canvas ref={ref} style={{ width: 'min(92vw, 70dvh)', height: 'min(92vw, 70dvh)' }} aria-label="Ảnh xem trước" />
      {!hideUi && (
        <div className="stack" style={{ padding: '10px 14px calc(14px + var(--safe-b))', background: 'var(--cream)', borderRadius: '24px 24px 0 0', maxWidth: 640, width: '100%', margin: '0 auto' }}>
          <div className="pill-tabs">{BACKDROPS.map(b => <button key={b.id} className="pill" aria-pressed={backdrop === b.id} onClick={() => setBackdrop(b.id)}>{b.name}</button>)}</div>
          <div className="pill-tabs">
            {POSES.map(x => {
              const ok = poses.includes(x)
              return <button key={x.id} className="pill" disabled={!ok} aria-pressed={pose === x.id} onClick={() => { sfx('tap'); setPose(x.id) }} title={ok ? '' : x.level ? `Mở ở thân thiết bậc ${x.level}` : 'Quà hoàn thành bộ capsule'}>{x.name}{!ok && <span className="lock">🔒</span>}</button>
            })}
          </div>
          <label className="row small"><input type="checkbox" checked={caption} onChange={e => setCaption(e.target.checked)} /> In tên {state.pet.name} và logo Cozii!</label>
          <div className="row">
            <button className="btn primary" style={{ flex: 1 }} onClick={() => void share()}><Icon.share />Chia sẻ</button>
            <button className="btn" style={{ flex: 1 }} onClick={async () => { const b = await blob(); if (b) { void act({ type: 'photo' }, { quiet: true }); download(b) } }}><Icon.download />Tải ảnh PNG</button>
          </div>
          <p className="tiny muted">Tư thế mở theo độ thân thiết (đang bậc {level}) và khi hoàn thành bộ capsule.</p>
        </div>
      )}
    </div>
  )
}
