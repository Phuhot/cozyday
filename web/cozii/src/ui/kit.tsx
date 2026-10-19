import { useEffect, useRef, type ReactNode } from 'react'
import { paintItem, paintPet } from '../art'
import { restPose, NATURAL_FUR, type PetSpecies, type FurColor } from '../content/pet'
import { item as catalogItem, isThemeSlot } from '../content/catalog'
import { fitCanvas } from './anim'
import { sfx } from '../app/sound'
import { GC, rgb, pt, Color } from '../art/gc'
import { crop as cropDef, cropByProduce, cropBySeed, food as foodDef } from '../content/farm'

// ---------------- Biểu tượng (SVG nét tròn) ----------------

const P = { fill: 'none', stroke: 'currentColor', strokeWidth: 2.2, strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const }

export const Icon = {
  home: () => <svg viewBox="0 0 24 24" {...P}><path d="M3 11.5 12 4l9 7.5" /><path d="M5.5 10v9.5h13V10" /><path d="M10 19.5v-5h4v5" /></svg>,
  town: () => <svg viewBox="0 0 24 24" {...P}><path d="M3 20h18" /><path d="M5 20V9l4-3 4 3v11" /><path d="M13 20v-7h6v7" /><path d="M8 12h2M8 15.5h2" /></svg>,
  friends: () => <svg viewBox="0 0 24 24" {...P}><circle cx="8.5" cy="9" r="3.2" /><circle cx="16.5" cy="10" r="2.6" /><path d="M3 19c.6-3 3-4.6 5.5-4.6S13.4 16 14 19" /><path d="M14.5 15.2c.6-.4 1.3-.6 2-.6 2 0 3.6 1.4 4 4.4" /></svg>,
  gear: () => <svg viewBox="0 0 24 24" {...P}><circle cx="12" cy="12" r="3" /><path d="M12 2.8v2.4M12 18.8v2.4M4.2 7.5l2.1 1.2M17.7 15.3l2.1 1.2M4.2 16.5l2.1-1.2M17.7 8.7l2.1-1.2" /><circle cx="12" cy="12" r="7" /></svg>,
  close: () => <svg viewBox="0 0 24 24" {...P}><path d="M6 6l12 12M18 6 6 18" /></svg>,
  back: () => <svg viewBox="0 0 24 24" {...P}><path d="M15 5l-7 7 7 7" /></svg>,
  food: () => <svg viewBox="0 0 24 24" {...P}><path d="M4 12h16a8 8 0 0 1-16 0Z" /><path d="M9 8c0-2 1.5-2 1.5-4M13 8c0-2 1.5-2 1.5-4" /></svg>,
  broom: () => <svg viewBox="0 0 24 24" {...P}><path d="M14 4 9.5 12.5" /><path d="M6 13.5 12 16.5 9.5 21H4.5Z" /><path d="M7.5 17.5 6.5 21M10 18l-1.2 3" /></svg>,
  heart: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 20s-7.5-4.5-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.5-7.5 10-7.5 10Z" /></svg>,
  brush: () => <svg viewBox="0 0 24 24" {...P}><path d="M14.5 4.5 19.5 9.5 11 18 6 13Z" /><path d="M6 13c-2.5 0-3 2.5-3 5.5 3 0 5.5-.5 5.5-3" /></svg>,
  shirt: () => <svg viewBox="0 0 24 24" {...P}><path d="M8.5 4 4 7l2 4 2-1v10h8V10l2 1 2-4-4.5-3c-.5 1.5-2 2.5-3.5 2.5S9 5.5 8.5 4Z" /></svg>,
  camera: () => <svg viewBox="0 0 24 24" {...P}><rect x="3" y="7" width="18" height="13" rx="3.5" /><circle cx="12" cy="13.5" r="3.5" /><path d="M8.5 7 10 4.5h4L15.5 7" /></svg>,
  sprout: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 21v-9" /><path d="M12 12c0-4 2.5-6.5 7-6.5 0 4-2.5 6.5-7 6.5Z" /><path d="M12 14c0-3-2-5-6-5 0 3 2 5 6 5Z" /></svg>,
  mail: () => <svg viewBox="0 0 24 24" {...P}><rect x="3" y="5.5" width="18" height="13" rx="3" /><path d="m4 7 8 6 8-6" /></svg>,
  star: () => <svg viewBox="0 0 24 24" {...P}><path d="m12 3.5 2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.8Z" /></svg>,
  flip: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 3v18" strokeDasharray="2 3" /><path d="M9 7 4 12l5 5Z" /><path d="M15 7l5 5-5 5Z" /></svg>,
  left: () => <svg viewBox="0 0 24 24" {...P}><path d="M14 6l-6 6 6 6" /></svg>,
  right: () => <svg viewBox="0 0 24 24" {...P}><path d="M10 6l6 6-6 6" /></svg>,
  trash: () => <svg viewBox="0 0 24 24" {...P}><path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13" /></svg>,
  save: () => <svg viewBox="0 0 24 24" {...P}><path d="M5 4h11l3 3v13H5Z" /><path d="M8 4v5h7V4M8 20v-6h8v6" /></svg>,
  water: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 3.5s6 6.4 6 10.5a6 6 0 0 1-12 0c0-4.1 6-10.5 6-10.5Z" /></svg>,
  play: () => <svg viewBox="0 0 24 24" {...P}><path d="M7 4.5v15l12-7.5Z" /></svg>,
  pause: () => <svg viewBox="0 0 24 24" {...P}><path d="M8 5v14M16 5v14" /></svg>,
  trophy: () => <svg viewBox="0 0 24 24" {...P}><path d="M7 4h10v5a5 5 0 0 1-10 0Z" /><path d="M7 6H4c0 3 1.5 4.5 3.5 4.5M17 6h3c0 3-1.5 4.5-3.5 4.5M12 14v3.5M8.5 20.5h7M9.5 17.5h5" /></svg>,
  share: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 15V3.5M7.5 8 12 3.5 16.5 8" /><path d="M5 12.5V20h14v-7.5" /></svg>,
  download: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 3.5V15M7.5 10.5 12 15l4.5-4.5" /><path d="M5 19.5h14" /></svg>,
  copy: () => <svg viewBox="0 0 24 24" {...P}><rect x="8" y="8" width="12" height="12" rx="3" /><path d="M16 8V5.5A1.5 1.5 0 0 0 14.5 4h-9A1.5 1.5 0 0 0 4 5.5v9A1.5 1.5 0 0 0 5.5 16H8" /></svg>,
  plus: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 5v14M5 12h14" /></svg>,
  check: () => <svg viewBox="0 0 24 24" {...P}><path d="m5 12.5 4.5 4.5L19 7.5" /></svg>,
  lock: () => <svg viewBox="0 0 24 24" {...P}><rect x="5" y="10.5" width="14" height="10" rx="2.5" /><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" /></svg>,
  book: () => <svg viewBox="0 0 24 24" {...P}><path d="M4 5.5C6.5 4 9.5 4 12 6c2.5-2 5.5-2 8-.5V19c-2.5-1.5-5.5-1.5-8 .5-2.5-2-5.5-2-8-.5Z" /><path d="M12 6v13.5" /></svg>,
  refresh: () => <svg viewBox="0 0 24 24" {...P}><path d="M19 12a7 7 0 1 1-2.1-5" /><path d="M19 4.5V9h-4.5" /></svg>,
  wifiOff: () => <svg viewBox="0 0 24 24" {...P}><path d="M3 3l18 18" /><path d="M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 4-2.4M19 13a10 10 0 0 0-3.4-2.2M2 9.5A15 15 0 0 1 7.5 6.3M22 9.5a15 15 0 0 0-9.6-4" /><circle cx="12" cy="19.5" r="0.8" /></svg>,
  flag: () => <svg viewBox="0 0 24 24" {...P}><path d="M5 21V4" /><path d="M5 4.5h11l-2 3.5 2 3.5H5" /></svg>,
  ban: () => <svg viewBox="0 0 24 24" {...P}><circle cx="12" cy="12" r="8.5" /><path d="m6 6 12 12" /></svg>,
  sparkle: () => <svg viewBox="0 0 24 24" {...P}><path d="M12 3c.6 4.5 2.5 6.4 7 7-4.5.6-6.4 2.5-7 7-.6-4.5-2.5-6.4-7-7 4.5-.6 6.4-2.5 7-7Z" /></svg>,
}

// ---------------- Xu, vé, mảnh (vẽ bằng SVG) ----------------

export function CoinIcon({ size = 20 }: { size?: number }) {
  return (
    <svg className="ico" viewBox="0 0 24 24" width={size} height={size} aria-hidden>
      <circle cx="12" cy="12" r="10" fill="#f2c45a" />
      <circle cx="12" cy="12" r="7.2" fill="#f7d77e" stroke="#d9a441" strokeWidth="1.4" />
      <path d="M12 8.2v7.6M9.8 10c.4-1 1.2-1.4 2.2-1.4 1.3 0 2.1.6 2.1 1.6 0 2.3-4.4 1.2-4.4 3.6 0 1 .9 1.7 2.3 1.7 1 0 1.8-.4 2.2-1.3" fill="none" stroke="#b9862a" strokeWidth="1.3" strokeLinecap="round" />
    </svg>
  )
}
export function TicketIcon({ size = 20 }: { size?: number }) {
  return (
    <svg className="ico" viewBox="0 0 24 24" width={size} height={size} aria-hidden>
      <path d="M3 8a2 2 0 0 0 0 4v0a2 2 0 0 0 0 4v2h18v-2a2 2 0 0 1 0-4 2 2 0 0 1 0-4V6H3Z" fill="#c9b6f0" stroke="#8d78cf" strokeWidth="1.4" />
      <path d="M9 6v12" stroke="#8d78cf" strokeWidth="1.3" strokeDasharray="1.6 1.8" />
      <circle cx="15" cy="12" r="2.4" fill="#fff" />
    </svg>
  )
}
export function ShardIcon({ size = 20 }: { size?: number }) {
  return (
    <svg className="ico" viewBox="0 0 24 24" width={size} height={size} aria-hidden>
      <path d="M12 3 19 9.5 15 21H9L5 9.5Z" fill="#a9ddd6" stroke="#5aa69b" strokeWidth="1.4" strokeLinejoin="round" />
      <path d="M12 3v18M5 9.5h14" stroke="#5aa69b" strokeWidth="0.9" opacity="0.6" />
    </svg>
  )
}

export function Coins({ n }: { n: number }) {
  return <span className="price"><CoinIcon size={16} />{n}</span>
}

// ---------------- Ảnh đồ vật ----------------

const thumbCache = new Map<string, HTMLCanvasElement>()

function stockArt(c: CanvasRenderingContext2D, id: string, size: number) {
  const g = new GC(c)
  g.scaleBy(size / 100, size / 100)
  if (id.startsWith('seed.')) {
    const cr = cropBySeed(id)
    g.rect(24, 30, 52, 56, rgb(0xe8d3b0), 8)
    g.rect(24, 30, 52, 12, rgb(0xd4b98d), 6)
    if (cr) drawCrop(g, cr.id, 50, 78, 1, 0.55)
    return
  }
  if (id.startsWith('crop.')) {
    const cr = cropByProduce(id)
    if (cr) drawProduce(g, cr.id, 50, 54, 1.25)
    return
  }
  drawFood(g, id)
}

/** Ảnh tĩnh của một món (đồ nội thất, trang phục, hạt, nông sản, đồ ăn). */
export function ItemThumb({ id, size = 64, label }: { id: string; size?: number; label?: string }) {
  const ref = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const cv = ref.current
    if (!cv) return
    const dpr = Math.min(2, window.devicePixelRatio || 1)
    const key = `${id}@${size}@${dpr}`
    let src = thumbCache.get(key)
    if (!src) {
      src = document.createElement('canvas')
      src.width = Math.round(size * dpr)
      src.height = Math.round(size * dpr)
      const c = src.getContext('2d')!
      c.scale(dpr, dpr)
      const it = catalogItem(id)
      if (it) {
        if (it.slot === 'species' || it.slot === 'fur') drawPetChoice(c, id, size)
        else if (['hat', 'glasses', 'neck', 'outfit', 'back'].includes(it.slot)) drawWear(c, id, size)
        else paintItem(c, id, 0, 0, size, size, isThemeSlot(it.slot))
      } else stockArt(c, id, size)
      thumbCache.set(key, src)
      if (thumbCache.size > 400) thumbCache.delete(thumbCache.keys().next().value!)
    }
    const c = fitCanvas(cv, size, size)
    c.clearRect(0, 0, size, size)
    c.drawImage(src, 0, 0, size, size)
  }, [id, size])
  return <canvas ref={ref} style={{ width: size, height: size }} role="img" aria-label={label ?? catalogItem(id)?.name ?? id} />
}

function drawPetChoice(c: CanvasRenderingContext2D, id: string, size: number) {
  const [slot, v] = id.split('.')
  if (slot === 'species') paintPet(c, 0, 0, size, { species: v as PetSpecies, fur: NATURAL_FUR[v as PetSpecies], stage: 'grown' }, 'idle', restPose())
  else paintPet(c, 0, 0, size, { species: 'cat', fur: v as FurColor, stage: 'grown' }, 'idle', restPose())
}

function drawWear(c: CanvasRenderingContext2D, id: string, size: number) {
  const slot = id.split('.')[0]
  // Mặc thử lên một bạn mèo kem mờ để thấy hình dáng món đồ.
  c.save()
  c.globalAlpha = 1
  paintPet(c, 0, 0, size, { species: 'cat', fur: 'snow', stage: 'grown', [slot]: id } as never, 'idle', restPose())
  c.restore()
}

// ---------------- Vẽ cây & đồ ăn (dùng ở vườn, kho, đơn hàng) ----------------

export function drawProduce(g: GC, cropId: string, cx: number, cy: number, s: number) {
  const cr = cropDef(cropId)
  if (!cr) return
  const col = rgb(cr.color), leaf = rgb(cr.leaf)
  switch (cropId === 'sprout' ? 'radish' : cropId) {
    case 'radish':
      g.ellipse(cx - 13 * s, cy - 10 * s, 26 * s, 24 * s, col)
      g.polygon([pt(cx - 6 * s, cy + 12 * s), pt(cx + 6 * s, cy + 12 * s), pt(cx, cy + 24 * s)], col)
      g.rotated(-20, pt(cx, cy - 10 * s), r => r.ellipse(cx - 9 * s, cy - 28 * s, 8 * s, 18 * s, leaf))
      g.rotated(20, pt(cx, cy - 10 * s), r => r.ellipse(cx + 1 * s, cy - 28 * s, 8 * s, 18 * s, leaf))
      g.ellipse(cx - 7 * s, cy - 5 * s, 6 * s, 9 * s, Color.white.opacity(0.35))
      break
    case 'carrot':
      g.polygon([pt(cx - 10 * s, cy - 10 * s), pt(cx + 10 * s, cy - 10 * s), pt(cx, cy + 26 * s)], col)
      g.strokePath(rgb(0xd98a3e), 1.4 * s, q => { q.move(pt(cx - 6 * s, cy)); q.addLine(pt(cx - 1 * s, cy)); q.move(pt(cx + 2 * s, cy + 8 * s)); q.addLine(pt(cx + 5 * s, cy + 8 * s)) })
      g.rotated(-18, pt(cx, cy - 10 * s), r => r.ellipse(cx - 7 * s, cy - 28 * s, 7 * s, 18 * s, leaf))
      g.rotated(18, pt(cx, cy - 10 * s), r => r.ellipse(cx, cy - 28 * s, 7 * s, 18 * s, leaf))
      break
    case 'strawberry':
      g.polygon([pt(cx - 14 * s, cy - 8 * s), pt(cx + 14 * s, cy - 8 * s), pt(cx, cy + 18 * s)], col)
      g.ellipse(cx - 14 * s, cy - 16 * s, 28 * s, 18 * s, col)
      for (const [x, y] of [[-6, -6], [4, -8], [0, 2], [-3, 8], [6, 0]]) g.ellipse(cx + x * s - 0.8 * s, cy + y * s - 1.2 * s, 1.6 * s, 2.4 * s, rgb(0xfde9a6))
      g.polygon([pt(cx - 10 * s, cy - 16 * s), pt(cx, cy - 22 * s), pt(cx + 10 * s, cy - 16 * s), pt(cx, cy - 12 * s)], leaf)
      break
    case 'pumpkin':
      g.ellipse(cx - 18 * s, cy - 14 * s, 20 * s, 28 * s, rgb(0xe08f30))
      g.ellipse(cx - 2 * s, cy - 14 * s, 20 * s, 28 * s, rgb(0xe08f30))
      g.ellipse(cx - 10 * s, cy - 15 * s, 20 * s, 30 * s, col)
      g.rect(cx - 2 * s, cy - 22 * s, 4 * s, 8 * s, rgb(0x7a6040), 1.5 * s)
      g.ellipse(cx + 2 * s, cy - 22 * s, 10 * s, 5 * s, leaf)
      break
    case 'corn':
      g.ellipse(cx - 8 * s, cy - 22 * s, 16 * s, 42 * s, col)
      for (let i = 0; i < 4; i++) for (let j = 0; j < 2; j++) g.circle(cx - 3 * s + j * 6 * s, cy - 14 * s + i * 7 * s, 1.8 * s, rgb(0xfbe28f))
      g.rotated(-14, pt(cx, cy + 16 * s), r => r.ellipse(cx - 14 * s, cy - 12 * s, 9 * s, 32 * s, leaf))
      g.rotated(14, pt(cx, cy + 16 * s), r => r.ellipse(cx + 5 * s, cy - 12 * s, 9 * s, 32 * s, leaf))
      break
    case 'sunflower':
      for (let i = 0; i < 12; i++) g.rotated(i * 30, pt(cx, cy - 8 * s), r => r.ellipse(cx - 4 * s, cy - 30 * s, 8 * s, 14 * s, col))
      g.circle(cx, cy - 8 * s, 10 * s, rgb(0x8a5a32))
      for (const [x, y] of [[-3, -3], [3, -2], [0, 3], [-4, 4], [4, 4]]) g.circle(cx + x * s, cy - 8 * s + y * s, 1.2 * s, rgb(0x5e3b20))
      break
  }
}

/** Vẽ cây trên ô đất theo tiến độ 0…1 (1 = chín). */
export function drawCrop(g: GC, cropId: string, cx: number, ground: number, progress: number, scale = 1) {
  const cr = cropDef(cropId)
  if (!cr) return
  const leaf = rgb(cr.leaf)
  const s = scale
  if (progress < 0.34) {
    // Mầm nhỏ
    g.strokePath(leaf, 2.4 * s, q => { q.move(pt(cx, ground)); q.addLine(pt(cx, ground - 12 * s)) })
    g.rotated(-30, pt(cx, ground - 12 * s), r => r.ellipse(cx - 9 * s, ground - 16 * s, 9 * s, 6 * s, leaf))
    g.rotated(30, pt(cx, ground - 12 * s), r => r.ellipse(cx, ground - 16 * s, 9 * s, 6 * s, leaf))
  } else if (progress < 1) {
    // Cây đang lớn
    g.strokePath(leaf, 3 * s, q => { q.move(pt(cx, ground)); q.addLine(pt(cx, ground - 26 * s)) })
    for (const [a, y] of [[-35, 8], [35, 14], [-30, 20]]) g.rotated(a, pt(cx, ground - y * s), r => r.ellipse(cx + (a < 0 ? -14 : 0) * s, ground - (y + 5) * s, 14 * s, 8 * s, leaf))
    g.circle(cx, ground - 28 * s, 4 * s, rgb(cr.color).opacity(0.55))
  } else {
    drawProduce(g, cropId, cx, ground - 18 * s, 0.85 * s)
  }
}

export function drawFood(g: GC, id: string) {
  const f = foodDef(id)
  if (!f) return
  g.ellipse(18, 70, 64, 18, rgb(0xe8dcca))
  switch (id) {
    case 'food.apple':
      g.circle(50, 52, 20, rgb(0xe8566b)); g.ellipse(36, 40, 10, 12, Color.white.opacity(0.35))
      g.rect(48, 26, 4, 10, rgb(0x7a5a3a), 2); g.ellipse(52, 24, 14, 7, rgb(0x6faf62)); break
    case 'food.oatcookie':
      g.circle(50, 56, 22, rgb(0xd9a865)); for (const [x, y] of [[42, 50], [56, 48], [50, 62], [60, 60], [40, 62]]) g.circle(x, y, 2.6, rgb(0x8a5a32)); break
    case 'food.riceball':
      g.polygon([pt(50, 28), pt(76, 72), pt(24, 72)], Color.white); g.rect(38, 56, 24, 16, rgb(0x3f4a3c), 2); break
    case 'food.veggiesoup':
      g.ellipse(24, 46, 52, 30, rgb(0xf2b27a)); g.ellipse(22, 42, 56, 14, rgb(0xfbe3c8))
      g.ellipse(28, 44, 44, 9, rgb(0xe08f30)); g.circle(40, 47, 3, rgb(0x6faf62)); g.circle(56, 46, 3, rgb(0xe8566b)); break
    case 'food.picnic':
      g.rect(22, 40, 56, 32, rgb(0xc8945e), 6); g.rect(22, 40, 56, 10, rgb(0xe8566b), 4)
      for (let i = 0; i < 4; i++) g.rect(24 + i * 14, 40, 6, 10, Color.white.opacity(0.85)); break
    case 'food.carrot':
      g.rotated(-30, pt(50, 54), r => r.polygon([pt(38, 46), pt(62, 46), pt(50, 80)], rgb(0xe08f30)))
      g.circle(40, 44, 2, rgb(0x8a5a32)); g.circle(56, 60, 2, rgb(0x8a5a32)); break
  }
}

// ---------------- Khung chung ----------------

export function Sheet({ title, onClose, children, wide }: { title: ReactNode; onClose: () => void; children: ReactNode; wide?: boolean }) {
  useEffect(() => {
    const k = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', k)
    return () => window.removeEventListener('keydown', k)
  }, [onClose])
  return (
    <div className="sheet-backdrop" onClick={e => { if (e.target === e.currentTarget) onClose() }} role="presentation">
      <div className="sheet" role="dialog" aria-modal="true" aria-label={typeof title === 'string' ? title : undefined} style={wide ? { width: 'min(100%, 760px)' } : undefined}>
        <div className="sheet-handle" />
        <div className="sheet-head">
          <h2>{title}</h2>
          <button className="icon-btn" onClick={() => { sfx('tap'); onClose() }} aria-label="Đóng"><Icon.close /></button>
        </div>
        {children}
      </div>
    </div>
  )
}

export function ScreenHead({ title, onBack, right }: { title: ReactNode; onBack?: () => void; right?: ReactNode }) {
  return (
    <div className="row" style={{ margin: '4px 0 10px' }}>
      {onBack && <button className="icon-btn" onClick={() => { sfx('tap'); onBack() }} aria-label="Quay lại"><Icon.back /></button>}
      <h1 className="screen-title" style={{ margin: 0, flex: 1, fontSize: 24 }}>{title}</h1>
      {right}
    </div>
  )
}

export function Progress({ value }: { value: number }) {
  return <div className="progress" role="progressbar" aria-valuenow={Math.round(value * 100)} aria-valuemin={0} aria-valuemax={100}><i style={{ width: `${Math.max(0, Math.min(1, value)) * 100}%` }} /></div>
}

export function Empty({ children }: { children: ReactNode }) {
  return <div className="card muted center small" style={{ padding: 18 }}>{children}</div>
}
