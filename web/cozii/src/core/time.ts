// Ngày của thị trấn tính theo giờ Việt Nam (UTC+7, không đổi giờ mùa hè) — cùng quy ước với máy chủ.
const OFFSET_MS = 7 * 3600 * 1000

export function dayKey(ms: number): string {
  return new Date(ms + OFFSET_MS).toISOString().slice(0, 10)
}

/** Tuần ISO theo giờ Việt Nam, dạng "2026-W43" (khớp to_char(..., 'IYYY-"W"IW') của Postgres). */
export function weekKey(ms: number): string {
  const d = new Date(ms + OFFSET_MS)
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()))
  const dow = date.getUTCDay() || 7
  date.setUTCDate(date.getUTCDate() + 4 - dow)
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
  const week = Math.ceil(((date.getTime() - yearStart.getTime()) / 86400000 + 1) / 7)
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, '0')}`
}

export function formatDuration(ms: number): string {
  const s = Math.max(0, Math.ceil(ms / 1000))
  if (s < 60) return `${s} giây`
  const m = Math.floor(s / 60), rs = s % 60
  if (m < 60) return rs ? `${m} phút ${rs} giây` : `${m} phút`
  const h = Math.floor(m / 60), rm = m % 60
  return rm ? `${h} giờ ${rm} phút` : `${h} giờ`
}

export function formatShort(ms: number): string {
  const s = Math.max(0, Math.ceil(ms / 1000))
  if (s < 60) return `${s}s`
  const m = Math.floor(s / 60)
  if (m < 60) return `${m}:${String(s % 60).padStart(2, '0')}`
  const h = Math.floor(m / 60)
  return `${h}g${String(m % 60).padStart(2, '0')}`
}
