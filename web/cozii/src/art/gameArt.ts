// Hình vẽ của Sân chơi — chuyển từ GameArt.swift (bản iOS) bằng scripts/port/swift2ts.mjs rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, linear, type Pt, type Rect } from './gc'
import type { DropKind } from '../games/basket'

// MARK: Nhảy Mây

// Bầu trời đổi màu dần theo độ cao (pastel tím → xanh đêm có sao).
export function sky(ctx: GC, size: { width: number; height: number }, altitude: number, reduceMotion: boolean) {
    const t = Math.min(1, Math.max(0, altitude / 3000))
    function mix(a: number[], b: number[]): Color {
        return Color.rgb01((a[0] + (b[0] - a[0]) * t) / 255, (a[1] + (b[1] - a[1]) * t) / 255, (a[2] + (b[2] - a[2]) * t) / 255)
    }
    const top = mix([0xC9, 0xBD, 0xF0], [0x5C, 0x5A, 0x9E])
    const bottom = mix([0xFD, 0xEB, 0xDD], [0xB8, 0xA4, 0xE0])
    ctx.fill(Path.rect(R(0, 0, size.width, size.height)), linear([top, bottom], pt(0, 0), pt(0, size.height)))
    // Sao nhỏ xuất hiện khi lên cao, trôi chậm (không trôi khi bật Giảm chuyển động).
    if ((!(t > 0.15))) { return }
    const drift = reduceMotion ? 0 : altitude * 0.05
    for (let i = 0; i < 18; i++) {
        const x = ((i * 37.7) % 100) / 100 * size.width
        const y = ((i * 53.1 + drift) % 160) / 160 * size.height
        ctx.circle(x, y, i % 3 == 0 ? 1.6 : 1, Color.white.opacity(0.35 + 0.5 * t))
    }
}

// Đồi xa ở mặt đất (chỉ thấy lúc đầu).
export function hills(ctx: GC, w: number, groundY: number) {
    let back = new Path()
    back.move(pt(0, groundY))
    back.addQuadCurve(pt(w * 0.55, groundY - 4), pt(w * 0.25, groundY - w * 0.32))
    back.addQuadCurve(pt(w, groundY), pt(w * 0.85, groundY - w * 0.25))
    back.addLine(pt(w, groundY + 400)); back.addLine(pt(0, groundY + 400)); back.closeSubpath()
    ctx.fill(back, (rgb(0xBFDDB9)))
    ctx.rect(0, groundY, w, 400, rgb(0x9CCB98))
    ctx.rect(0, groundY, w, 3, rgb(0x86B884))
    for (let i = 0; i < 7; i++) {
        const x = w * (0.08 + 0.14 * (i))
        ctx.circle(x, groundY + 10 + (i % 2) * 6, 2.2, i % 2 == 0 ? rgb(0xF6C3D0) : rgb(0xFFF4C4))
    }
}

// Đám mây bệ: `rect` là mép trên/trái/phải theo điểm màn hình. Mây di chuyển màu bạc hà có vệt gió.
export function cloud(ctx: GC, r: Rect, moving: boolean) {
    const body = moving ? rgb(0xDDF3E6) : Color.white
    const shade = moving ? rgb(0xA9DDB8) : rgb(0xD9CFF2)
    const h = r.height
    ctx.fill(Path.roundedRect(R(r.minX, r.minY + h * 0.35, r.width, h * 0.75), h * 0.37), (shade))
    ctx.fill(Path.roundedRect(R(r.minX, r.minY + h * 0.1, r.width, h * 0.8), h * 0.4), (body))
    const bumps = Math.max(2, Math.trunc(r.width / (h * 1.1)))
    for (let i = 0; i < bumps; i++) {
        const cx = r.minX + r.width * ((i) + 0.5) / (bumps)
        const rad = h * (i % 2 == 0 ? 0.42 : 0.34)
        ctx.circle(cx, r.minY + h * 0.22, rad, body)
    }
    ctx.ellipse(r.minX + r.width * 0.18, r.minY + h * 0.18, r.width * 0.22, h * 0.18, Color.white.opacity(0.8))
    if (moving) {
        ctx.strokePath(rgb(0x7FBF93).opacity(0.8), 1.4, (p) => {
            p.move(pt(r.minX - h * 0.9, r.minY + h * 0.45)); p.addLine(pt(r.minX - h * 0.25, r.minY + h * 0.45))
            p.move(pt(r.maxX + h * 0.25, r.minY + h * 0.65)); p.addLine(pt(r.maxX + h * 0.9, r.minY + h * 0.65))
        })
    }
}

// Mây mỏng: trong suốt hơn, viền nét đứt, có vết nứt — nảy một lần là tan.
export function thinCloud(ctx: GC, r: Rect) {
    const h = r.height
    let shape = Path.roundedRect(R(r.minX, r.minY + h * 0.1, r.width, h * 0.8), h * 0.4)
    const bumps = Math.max(2, Math.trunc(r.width / (h * 1.1)))
    for (let i = 0; i < bumps; i++) {
        const cx = r.minX + r.width * ((i) + 0.5) / (bumps)
        const rad = h * (i % 2 == 0 ? 0.38 : 0.3)
        shape.addEllipse(R(cx - rad, r.minY + h * 0.22 - rad, rad * 2, rad * 2))
    }
    ctx.fill(shape, (Color.white.opacity(0.55)))
    ctx.stroke(Path.roundedRect(R(r.minX, r.minY + h * 0.1, r.width, h * 0.8), h * 0.4), (rgb(0xB7A6F0).opacity(0.9)), Math.max(1, h * 0.12), { dash: [h * 0.35, h * 0.3] })
    ctx.strokePath(rgb(0xB7A6F0).opacity(0.9), Math.max(0.8, h * 0.08), (p) => {
        p.move(pt(r.midX - h * 0.3, r.minY + h * 0.2))
        p.addLine(pt(r.midX, r.minY + h * 0.5))
        p.addLine(pt(r.midX - h * 0.15, r.minY + h * 0.8))
    })
}

// Mây giông mặt cau có, có tia chớp nhỏ.
export function stormCloud(ctx: GC, c: Pt, r: number, t: number) {
    const wobble = (Math.sin(t * 2)) * r * 0.05
    const body = rgb(0x8E87A8), shade = rgb(0x6F6889)
    const bolt = [pt(c.x + r * 0.1, c.y + r * 0.45), pt(c.x - r * 0.2, c.y + r * 0.95),
                pt(c.x + r * 0.05, c.y + r * 0.9), pt(c.x - r * 0.12, c.y + r * 1.35),
                pt(c.x + r * 0.35, c.y + r * 0.75), pt(c.x + r * 0.1, c.y + r * 0.8),
                pt(c.x + r * 0.3, c.y + r * 0.45)]
    if (t == 0 || Math.sin(t * 5) > -0.3) { ctx.polygon(bolt, rgb(0xFFD45E)) }
    ctx.ellipse(c.x - r * 1.1, c.y - r * 0.2 + wobble, r * 2.2, r * 0.9, shade)
    ctx.circle(c.x - r * 0.45, c.y - r * 0.2 + wobble, r * 0.55, body)
    ctx.circle(c.x + r * 0.2, c.y - r * 0.4 + wobble, r * 0.7, body)
    ctx.circle(c.x + r * 0.7, c.y - r * 0.05 + wobble, r * 0.42, body)
    ctx.ellipse(c.x - r * 1.0, c.y - r * 0.25 + wobble, r * 2.0, r * 0.7, body)
    // Mặt cau có
    const ink = rgb(0x3E3550)
    ctx.strokePath(ink, Math.max(0.8, r * 0.09), (p) => {
        p.move(pt(c.x - r * 0.42, c.y - r * 0.32 + wobble)); p.addLine(pt(c.x - r * 0.18, c.y - r * 0.22 + wobble))
        p.move(pt(c.x + r * 0.42, c.y - r * 0.32 + wobble)); p.addLine(pt(c.x + r * 0.18, c.y - r * 0.22 + wobble))
        p.move(pt(c.x - r * 0.15, c.y + r * 0.08 + wobble))
        p.addQuadCurve(pt(c.x + r * 0.15, c.y + r * 0.08 + wobble), pt(c.x, c.y - r * 0.05 + wobble))
    })
    ctx.circle(c.x - r * 0.3, c.y - r * 0.1 + wobble, r * 0.07, ink)
    ctx.circle(c.x + r * 0.3, c.y - r * 0.1 + wobble, r * 0.07, ink)
}

// Chim tròn vỗ cánh, quay đầu theo hướng bay.
export function bird(ctx: GC, c: Pt, r: number, t: number, facingLeft: boolean) {
    const l = ctx.copy()
    if (facingLeft) {
        l.translateBy(c.x * 2, 0)
        l.scaleBy(-1, 1)
    }
    const flap = (Math.sin(t * 14))
    const body = rgb(0x8EC5FF), belly = rgb(0xDDEEFF), wing = rgb(0x5FA3E8)
    // Đuôi
    l.polygon([pt(c.x - r * 0.8, c.y), pt(c.x - r * 1.5, c.y - r * 0.4), pt(c.x - r * 1.4, c.y + r * 0.35)], wing)
    l.circle(c.x, c.y, r, body)
    l.ellipse(c.x - r * 0.4, c.y, r * 1.0, r * 0.75, belly)
    // Cánh vỗ
    l.ellipse(c.x - r * 0.55, c.y - r * (0.35 + 0.55 * flap), r * 1.0, r * (0.5 + 0.35 * Math.abs(flap)), wing)
    // Mỏ + mắt + má
    l.polygon([pt(c.x + r * 0.9, c.y - r * 0.1), pt(c.x + r * 1.45, c.y + r * 0.05), pt(c.x + r * 0.9, c.y + r * 0.22)], rgb(0xF6A04D))
    l.circle(c.x + r * 0.45, c.y - r * 0.25, r * 0.13, rgb(0x3E3550))
    l.circle(c.x + r * 0.42, c.y + r * 0.15, r * 0.14, rgb(0xF4B0B0).opacity(0.9))
}

export function star(ctx: GC, c: Pt, r: number, color: Color = rgb(0xF6C445), glow: boolean = true) {
    if (glow) { ctx.circle(c.x, c.y, r * 1.45, rgb(0xFFF1B8).opacity(0.3)) }
    let p = new Path()
    for (let i = 0; i < 10; i++) {
        const rr = i % 2 == 0 ? r : r * 0.48
        const a = (i) * Math.PI / 5 - Math.PI / 2
        const q = pt(c.x + rr * Math.cos(a), c.y + rr * Math.sin(a))
        if (i == 0) { p.move(q) } else { p.addLine(q) }
    }
    p.closeSubpath()
    ctx.fill(p, (color))
    ctx.stroke(p, (rgb(0xD99A2B)), Math.max(1, r * 0.12))
    ctx.circle(c.x - r * 0.2, c.y - r * 0.25, r * 0.16, Color.white.opacity(0.8))
}

// MARK: Giỏ Quà

export function garden(ctx: GC, size: { width: number; height: number }, groundY: number) {
    ctx.fill(Path.rect(R(0, 0, size.width, size.height)), linear([rgb(0xD8E9FB), rgb(0xFDEFE2)], pt(0, 0), pt(0, groundY)))
    for (const [x, y, s] of [[0.18, 0.12, 1.0], [0.72, 0.2, 0.8], [0.45, 0.33, 0.6]] as const) {
        const w = size.width * 0.28 * s
        cloud(ctx, R(size.width * x - w / 2, size.height * y, w, w * 0.3), false)
    }
    let hill = new Path()
    hill.move(pt(0, groundY - size.width * 0.05))
    hill.addQuadCurve(pt(size.width, groundY - size.width * 0.08), pt(size.width * 0.5, groundY - size.width * 0.2))
    hill.addLine(pt(size.width, size.height)); hill.addLine(pt(0, size.height)); hill.closeSubpath()
    ctx.fill(hill, (rgb(0xC3E2BC)))
    ctx.rect(0, groundY, size.width, size.height - groundY, rgb(0xA4D2A0))
    ctx.rect(0, groundY, size.width, 3, rgb(0x8BBF88))
    for (let i = 0; i < 9; i++) {
        const x = size.width * (0.05 + 0.11 * (i))
        const y = groundY + 12 + (i % 3) * 7
        ctx.circle(x, y, 2.4, [rgb(0xF6C3D0), rgb(0xFFF4C4), rgb(0xD3C1EE)][i % 3])
    }
}

// Giỏ đan cầm trước người bạn nhỏ. `rect`: miệng giỏ ở mép trên.
export function basket(ctx: GC, r: Rect, handle: boolean = true) {
    const wood = rgb(0xC98F5A), dark = rgb(0x9C6A3D), light = rgb(0xE2B47E)
    if (handle) { basketHandle(ctx, r) }
    let body = new Path()
    body.move(pt(r.minX, r.minY + r.height * 0.12))
    body.addLine(pt(r.maxX, r.minY + r.height * 0.12))
    body.addLine(pt(r.maxX - r.width * 0.1, r.maxY))
    body.addQuadCurve(pt(r.minX + r.width * 0.1, r.maxY), pt(r.midX, r.maxY + r.height * 0.12))
    body.closeSubpath()
    ctx.fill(body, (wood))
    const weave = ctx.copy()
    weave.clip(body)
    for (let i = 0; i < 4; i++) {
        const y = r.minY + r.height * (0.32 + 0.2 * (i))
        weave.rect(r.minX, y, r.width, r.height * 0.07, dark.opacity(0.55))
    }
    for (let i = 0; i < 7; i++) {
        const x = r.minX + r.width * ((i) + 0.5) / 7
        weave.rect(x - r.width * 0.015, r.minY, r.width * 0.03, r.height, light.opacity(0.5))
    }
    ctx.fill(Path.roundedRect(R(r.minX - r.width * 0.04, r.minY, r.width * 1.08, r.height * 0.2), r.height * 0.1), (light))
}

// Quai giỏ (vẽ phía sau bạn nhỏ trong game).
export function basketHandle(ctx: GC, r: Rect) {
    ctx.strokePath(rgb(0x9C6A3D), Math.max(2, r.height * 0.09), (p) => {
        p.move(pt(r.minX + r.width * 0.12, r.minY + r.height * 0.1))
        p.addQuadCurve(pt(r.maxX - r.width * 0.12, r.minY + r.height * 0.1), pt(r.midX, r.minY - r.height * 0.75))
    })
}

// Món rơi. Món cần tránh có hình dạng riêng (vệt bùn / mây xám có giọt mưa) và huy hiệu "✕";
// món tốt có dấu "+" nhỏ — không chỉ khác nhau bằng màu.
export function drop(ctx: GC, kind: DropKind, c: Pt, r: number) {
    switch (kind) {
    case 'apple': { 
        ctx.circle(c.x, c.y + r * 0.08, r, rgb(0xEF6B6B))
        ctx.circle(c.x - r * 0.35, c.y - r * 0.25, r * 0.22, Color.white.opacity(0.55))
        ctx.strokePath(rgb(0x7A5234), Math.max(1.2, r * 0.14), (p) => {
            p.move(pt(c.x, c.y - r * 0.75)); p.addLine(pt(c.x + r * 0.1, c.y - r * 1.2))
        })
        ctx.rotated(-30, pt(c.x + r * 0.35, c.y - r * 1.05), (l) => {
            l.ellipse(c.x + r * 0.1, c.y - r * 1.2, r * 0.6, r * 0.3, rgb(0x7FBF6A))
        })
    } break; case 'cherry': { 
        ctx.strokePath(rgb(0x6E9A50), Math.max(1.2, r * 0.13), (p) => {
            p.move(pt(c.x - r * 0.45, c.y + r * 0.2)); p.addQuadCurve(pt(c.x + r * 0.15, c.y - r * 1.05), pt(c.x - r * 0.3, c.y - r * 0.6))
            p.move(pt(c.x + r * 0.5, c.y + r * 0.25)); p.addQuadCurve(pt(c.x + r * 0.15, c.y - r * 1.05), pt(c.x + r * 0.5, c.y - r * 0.5))
        })
        for (const dx of [-0.45, 0.5]) {
            ctx.circle(c.x + r * dx, c.y + r * 0.45, r * 0.55, rgb(0xD94F6A))
            ctx.circle(c.x + r * dx - r * 0.18, c.y + r * 0.28, r * 0.15, Color.white.opacity(0.6))
        }
    } break; case 'star': { 
        star(ctx, c, r * 1.05)
    } break; case 'gift': { 
        const box = R(c.x - r, c.y - r * 0.6, r * 2, r * 1.6)
        ctx.fill(Path.roundedRect(box, r * 0.25), (rgb(0xF4A9C4)))
        ctx.rect(box.minX - r * 0.1, box.minY - r * 0.35, box.width + r * 0.2, r * 0.45, rgb(0xE88AAE), r * 0.15)
        ctx.rect(c.x - r * 0.15, box.minY - r * 0.35, r * 0.3, box.height + r * 0.35, rgb(0xFFF4C4))
        ctx.ellipse(c.x - r * 0.75, box.minY - r * 0.9, r * 0.7, r * 0.55, rgb(0xFFF4C4))
        ctx.ellipse(c.x + r * 0.05, box.minY - r * 0.9, r * 0.7, r * 0.55, rgb(0xFFF4C4))
    } break; case 'mud': { 
        let splat = new Path()
        const n = 9
        for (let i = 0; i <= n; i++) {
            const a = (i) / (n) * 2 * Math.PI
            const rr = r * (i % 2 == 0 ? 1.05 : 0.78)
            const q = pt(c.x + rr * Math.cos(a), c.y + rr * 0.85 * Math.sin(a))
            if (i == 0) { splat.move(q) } else { splat.addLine(q) }
        }
        splat.closeSubpath()
        ctx.fill(splat, (rgb(0x8A6A52)))
        ctx.circle(c.x - r * 0.3, c.y - r * 0.2, r * 0.22, rgb(0x6E523F))
        ctx.circle(c.x + r * 0.35, c.y + r * 0.25, r * 0.16, rgb(0x6E523F))
        ctx.circle(c.x + r * 0.1, c.y + r * 1.2, r * 0.16, rgb(0x8A6A52))
        badge(ctx, pt(c.x + r * 0.85, c.y - r * 0.75), r * 0.42)
    } break; case 'rain': { 
        const cr = R(c.x - r * 1.1, c.y - r * 0.75, r * 2.2, r * 1.0)
        ctx.fill(Path.roundedRect(R(cr.minX, cr.minY + cr.height * 0.35, cr.width, cr.height * 0.65), cr.height * 0.32), (rgb(0x9C9AAE)))
        ctx.circle(cr.minX + cr.width * 0.35, cr.minY + cr.height * 0.4, cr.height * 0.42, rgb(0x9C9AAE))
        ctx.circle(cr.minX + cr.width * 0.65, cr.minY + cr.height * 0.32, cr.height * 0.5, rgb(0x9C9AAE))
        for (const [i, dx] of ([-0.6, 0, 0.6]).entries()) {
            const y = c.y + r * (0.55 + (i % 2) * 0.3)
            let d = new Path()
            d.move(pt(c.x + r * dx, y - r * 0.3))
            d.addQuadCurve(pt(c.x + r * dx, y + r * 0.25), pt(c.x + r * dx + r * 0.25, y + r * 0.1))
            d.addQuadCurve(pt(c.x + r * dx, y - r * 0.3), pt(c.x + r * dx - r * 0.25, y + r * 0.1))
            ctx.fill(d, (rgb(0x6FA5E0)))
        }
        badge(ctx, pt(c.x + r * 0.95, c.y - r * 0.8), r * 0.42)
    } }
    if (kind !== 'mud' && kind !== 'rain' && kind !== 'star') {
        ctx.text('+', Math.max(7, r * 0.9), Color.white, pt(c.x + r * 0.05, c.y + r * 0.1), 'bold')
    }
}

// Huy hiệu "✕" trên món cần tránh.
function badge(ctx: GC, p: Pt, r: number) {
    ctx.circle(p.x, p.y, r, Color.white)
    ctx.circle(p.x, p.y, r * 0.82, rgb(0x6B5A7A))
    ctx.strokePath(Color.white, Math.max(1.2, r * 0.3), (path) => {
        path.move(pt(p.x - r * 0.38, p.y - r * 0.38)); path.addLine(pt(p.x + r * 0.38, p.y + r * 0.38))
        path.move(pt(p.x + r * 0.38, p.y - r * 0.38)); path.addLine(pt(p.x - r * 0.38, p.y + r * 0.38))
    })
}

// Hạt lấp lánh nhỏ khi hứng/nhặt được (bỏ qua khi bật Giảm chuyển động).
export function sparkle(ctx: GC, c: Pt, t: number, color: Color) {
    const fade = (Math.max(0, 1 - t))
    for (let i = 0; i < 6; i++) {
        const a = (i) / 6 * 2 * Math.PI
        const d = 6 + t * 18
        ctx.circle(c.x + d * Math.cos(a), c.y + d * Math.sin(a) - t * 6, 2.2 * (1 - t * 0.5), color.opacity(fade))
    }
}

// MARK: Lật thẻ

// Mặt sau của thẻ: lavender có họa tiết dấu chân.
export function cardBack(ctx: GC, size: { width: number; height: number }) {
    const r = R(0, 0, size.width, size.height)
    ctx.fill(Path.roundedRect(r, Math.min(size.width, size.height) * 0.16), linear([rgb(0xB7A6F0), rgb(0x8D78CF)], pt(0, 0), pt(size.width, size.height)))
    ctx.stroke(Path.roundedRect(r.insetBy(4, 4), Math.min(size.width, size.height) * 0.12), (Color.white.opacity(0.45)), 1.5, { dash: [4, 3] })
    const c = pt(size.width / 2, size.height / 2)
    const k = Math.min(size.width, size.height) / 60
    const color = Color.white.opacity(0.8)
    ctx.ellipse(c.x - 8 * k, c.y - 2 * k, 16 * k, 13 * k, color)
    for (const [dx, dy] of [[-9.0, -8.0], [-3.0, -13.0], [3.0, -13.0], [9.0, -8.0]] as const) {
        ctx.circle(c.x + dx * k, c.y + dy * k, 3.4 * k, color)
    }
}

