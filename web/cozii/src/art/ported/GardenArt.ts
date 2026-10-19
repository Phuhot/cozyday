// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'

// Hình vẽ đồ trong Garden. Trả về false nếu không phải ID của phòng này.
export function draw(id: string, ctx: GC): boolean {
    switch (id) {
    // Bầu trời (cả cảnh 125×100)
    case "gardenTheme.day": { scene(ctx,  'day')
    } break; case "gardenTheme.sunset": { scene(ctx,  'sunset')
    } break; case "gardenTheme.night": { scene(ctx,  'night')
    } break; case "gardenTheme.snow": { scene(ctx,  'snow')
    // Cây
    } break; case "tree.sapling": { sapling(ctx)
    } break; case "tree.apple": { appleTree(ctx)
    } break; case "tree.pine": { pineTree(ctx)
    } break; case "tree.sakura": { sakuraTree(ctx)
    // Luống hoa
    } break; case "flowerBed.daisy": { daisyBed(ctx)
    } break; case "flowerBed.tulip": { tulipBed(ctx)
    } break; case "flowerBed.mushroom": { mushroomBed(ctx)
    } break; case "flowerBed.sunflower": { sunflowerBed(ctx)
    // Chỗ ngồi
    } break; case "gardenSeat.stump": { stump(ctx)
    } break; case "gardenSeat.bench": { bench(ctx)
    } break; case "gardenSeat.swing": { swing(ctx)
    } break; case "gardenSeat.hammock": { hammock(ctx)
    // Hồ nước
    } break; case "pond.puddle": { puddle(ctx)
    } break; case "pond.lily": { lilyPond(ctx)
    } break; case "pond.koi": { koiPond(ctx)
    } break; case "pond.fountain": { fountain(ctx)
    // Trang trí
    } break; case "gardenDeco.fence": { fence(ctx)
    } break; case "gardenDeco.mailbox": { mailbox(ctx)
    } break; case "gardenDeco.birdhouse": { birdhouse(ctx)
    } break; case "gardenDeco.lantern": { lantern(ctx)
    } break; case "gardenDeco.tent": { tent(ctx)
    } break; default: { return false
    } }
    return true
}

// MARK: - Tiện ích
// Bóng đổ nhẹ dưới chân đồ đặt trên cỏ.
function shadow(ctx: GC, cx: number, cy: number, w: number, h: number) {
    ctx.ellipse(cx - w / 2, cy - h / 2, w, h, Color.black.opacity(0.1))
}

function sparkle(ctx: GC, x: number, y: number, size: number, color: Color) {
    ctx.text("✦", size, color, pt(x, y))
}

// Lá hình bầu dục xoay theo góc.
function leaf(ctx: GC, cx: number, cy: number, w: number, h: number, angle: number, color: Color) {
    ctx.rotated(angle, pt(cx, cy), (c) => {
        c.ellipse(cx - w / 2, cy - h / 2, w, h, color)
    })
}

// Cụm cỏ nhỏ hình chữ "w".
function tuft(ctx: GC, x: number, y: number, s: number, color: Color) {
    ctx.strokePath(color, Math.max(0.6, s * 0.28), (p) => {
        p.move(pt(x - s, y - s * 1.1)); p.addLine(pt(x - s * 0.4, y))
        p.move(pt(x, y - s * 1.5)); p.addLine(pt(x, y))
        p.move(pt(x + s, y - s * 1.1)); p.addLine(pt(x + s * 0.4, y))
    })
}

function cloud(ctx: GC, x: number, y: number, s: number, color: Color) {
    ctx.rect(x, y + 3 * s, 20 * s, 5 * s, color, 2.5 * s)
    ctx.circle(x + 6 * s, y + 3.6 * s, 3.6 * s, color)
    ctx.circle(x + 11.5 * s, y + 2.6 * s, 4.6 * s, color)
    ctx.circle(x + 16 * s, y + 4.4 * s, 3 * s, color)
}

// MARK: - Bầu trời

type Sky = 'day' | 'sunset' | 'night' | 'snow'

function scene(base: GC, sky: Sky) {
    const ctx = base.copy()
    ctx.clip(Path.rect(R(0, 0, 125, 100)))
    // Bảng màu theo thời tiết
    let top = rgb(0xAEDCF2), mid = rgb(0xC4E6F5), low = rgb(0xDDF1F8)
    let farHill = rgb(0xB9DDB0), midHill = rgb(0xA3D19C), bush = rgb(0x8EC48D), bushLight = rgb(0xA6D4A1)
    let grass = rgb(0xB8E0A2), grassLow = rgb(0xAAD796), tuftColor = rgb(0x93C784), stone = rgb(0xE6E0CF)
    switch (sky) {
    case 'day': { 
        break
    } break; case 'sunset': { 
        top = rgb(0xF2A7A0); mid = rgb(0xF8BFA0); low = rgb(0xFCDDB0)
        farHill = rgb(0xD9A9B5); midHill = rgb(0xC7B48F); bush = rgb(0x9DB27A); bushLight = rgb(0xB3C287)
        grass = rgb(0xC4D594); grassLow = rgb(0xB6CB88); tuftColor = rgb(0xA0B776); stone = rgb(0xEBD6BE)
    } break; case 'night': { 
        top = rgb(0x2F3260); mid = rgb(0x3A3D6E); low = rgb(0x4A4B7C)
        farHill = rgb(0x3D4A6A); midHill = rgb(0x3A5A60); bush = rgb(0x2F5452); bushLight = rgb(0x3B6560)
        grass = rgb(0x48715C); grassLow = rgb(0x416954); tuftColor = rgb(0x5A8A6C); stone = rgb(0x6E7F84)
    } break; case 'snow': { 
        top = rgb(0xC9DCEC); mid = rgb(0xD8E6F1); low = rgb(0xE6EFF6)
        farHill = rgb(0xEEF3F8); midHill = rgb(0xE2EBF3); bush = rgb(0x8DB39A); bushLight = rgb(0xF6F9FC)
        grass = rgb(0xF6F9FC); grassLow = rgb(0xECF2F8); tuftColor = rgb(0xD6E2EE); stone = rgb(0xDCE5EE)
    } }

    // Trời thành các dải mềm
    ctx.rect(0, 0, 125, 62, top)
    ctx.ellipse(-30, 18, 185, 70, mid)
    ctx.ellipse(-30, 34, 185, 60, low)

    // Mặt trời / trăng / mây ở góc trên phải
    switch (sky) {
    case 'day': { 
        ctx.circle(104, 14, 11, rgb(0xFFF2B8).opacity(0.55))
        ctx.circle(104, 14, 7, rgb(0xFFD66B))
        ctx.circle(102, 12, 2, Color.white.opacity(0.6))
        cloud(ctx, 70, 8, 0.85, Color.white.opacity(0.95))
        cloud(ctx, 100, 24, 0.6, Color.white.opacity(0.85))
        cloud(ctx, 60, 26, 0.45, Color.white.opacity(0.7))
    } break; case 'sunset': { 
        ctx.circle(100, 20, 14, rgb(0xFFE0A8).opacity(0.5))
        ctx.circle(100, 20, 9, rgb(0xFFB870))
        ctx.rect(88, 18, 24, 1.4, top.opacity(0.7), 0.7)
        ctx.rect(90, 22, 20, 1.4, top.opacity(0.7), 0.7)
        cloud(ctx, 68, 8, 0.8, rgb(0xFCD2C4).opacity(0.95))
        cloud(ctx, 106, 30, 0.5, rgb(0xFCE0C8).opacity(0.85))
        ctx.strokePath(rgb(0x8A5E6E).opacity(0.6), 0.8, (p) => {
            p.move(pt(76, 24)); p.addQuadCurve(pt(79, 24), pt(77.5, 22.5))
            p.addQuadCurve(pt(82, 24), pt(80.5, 22.5))
            p.move(pt(84, 19)); p.addQuadCurve(pt(86.4, 19), pt(85.2, 17.8))
            p.addQuadCurve(pt(88.8, 19), pt(87.6, 17.8))
        })
    } break; case 'night': { 
        ctx.circle(102, 14, 12, rgb(0xFFF3C4).opacity(0.12))
        ctx.circle(102, 14, 9.5, rgb(0xFFF3C4).opacity(0.18))
        ctx.circle(102, 14, 7, rgb(0xFFF1C2))
        ctx.circle(99.5, 12, 1.6, rgb(0xEFDFA6))
        ctx.circle(104.5, 16.5, 1.2, rgb(0xEFDFA6))
        ctx.circle(105, 11.5, 0.8, rgb(0xEFDFA6))
        const stars = [[70, 8, 4], [84, 20, 3], [118, 6, 3.5], [114, 28, 3], [64, 18, 2.5],
                                                   [90, 6, 2.5], [76, 32, 2.5], [40, 6, 3], [12, 10, 2.5], [54, 30, 2]] as const
        for (const [x, y, s] of stars) { sparkle(ctx, x, y, s, rgb(0xFFF6D0).opacity(0.9)) }
        const dots = [[80, 12], [94, 30], [122, 18], [58, 10], [26, 4], [110, 38], [68, 40]] as const
        for (const [x, y] of dots) { ctx.circle(x, y, 0.5, Color.white.opacity(0.7)) }
        cloud(ctx, 108, 30, 0.5, rgb(0x5B5D8E).opacity(0.7))
    } break; case 'snow': { 
        ctx.circle(104, 14, 10, Color.white.opacity(0.35))
        ctx.circle(104, 14, 6.5, rgb(0xFFF4D8))
        cloud(ctx, 70, 8, 0.85, Color.white.opacity(0.9))
        cloud(ctx, 102, 24, 0.6, rgb(0xF4F7FB).opacity(0.9))
    } }

    // Đồi xa
    ctx.ellipse(-30, 36, 90, 44, farHill)
    ctx.ellipse(36, 40, 70, 34, farHill)
    ctx.ellipse(84, 34, 70, 40, farHill)
    ctx.ellipse(-10, 46, 70, 24, midHill)
    ctx.ellipse(56, 45, 90, 26, midHill)

    // Hàng bụi cây xa ở đường chân trời
    const bushes = [[4, 54, 5], [12, 52, 6.5], [20, 54, 4.5], [56, 53, 5], [64, 51, 6.5],
                                                [72, 53.5, 4.5], [92, 52, 6], [101, 53, 5], [110, 51, 6.5], [119, 53, 5.5]] as const
    for (const [x, y, r] of bushes) { ctx.circle(x, y, r, bush) }
    for (const [x, y, r] of bushes) { ctx.circle(x - r * 0.3, y - r * 0.4, r * 0.45, bushLight.opacity(sky == 'snow' ? 0.95 : 0.7)) }
    if (sky == 'snow') {
        for (const [x, y, r] of bushes) { ctx.ellipse(x - r * 0.8, y - r * 1.02, r * 1.6, r * 1.0, rgb(0xF6F9FC)) }
    }

    // Cỏ / tuyết
    let ground = new Path()
    ground.move(pt(0, 57))
    ground.addQuadCurve(pt(125, 55.5), pt(62, 52.5))
    ground.addLine(pt(125, 100)); ground.addLine(pt(0, 100)); ground.closeSubpath()
    ctx.fill(ground, (grass))
    ctx.ellipse(-20, 74, 100, 40, grassLow)
    ctx.ellipse(70, 80, 90, 36, grassLow)

    // Lối đá nhỏ dẫn vào vườn
    const stones = [[60, 92, 14, 5.5], [66, 83, 11, 4.5], [70, 75.5, 9, 3.6], [73, 69.5, 7, 3]] as const
    for (const [x, y, w, h] of stones) {
        ctx.ellipse(x, y + 0.8, w, h, Color.black.opacity(0.06))
        ctx.ellipse(x, y, w, h, stone)
    }

    const tufts = [[40, 62, 1.4], [88, 64, 1.3], [110, 60, 1.2], [50, 96, 1.8], [30, 64, 1.2],
                                               [66, 64, 1.2], [12, 62, 1.3], [118, 66, 1.4], [44, 84, 1.5], [82, 96, 1.7]] as const
    for (const [x, y, s] of tufts) { tuft(ctx, x, y, s, tuftColor) }

    switch (sky) {
    case 'day': { 
        const flowers = [[36, 66, 0xFFFFFF], [58, 60, 0xF7B6C8], [92, 61, 0xFFFFFF], [54, 88, 0xF9D86E],
                                                    [114, 63, 0xF7B6C8], [22, 60, 0xF9D86E]] as const
        for (const [x, y, c] of flowers) {
            ctx.circle(x, y, 1.1, rgb(c))
            ctx.circle(x, y, 0.4, rgb(0xF2B84B))
        }
    } break; case 'sunset': { 
        const flowers = [[36, 66], [92, 61], [54, 88], [114, 63]] as const
        for (const [x, y] of flowers) { ctx.circle(x, y, 1, rgb(0xFCE3C0)) }
    } break; case 'night': { 
        const flies = [[30, 44], [66, 38], [84, 48], [116, 44], [20, 70], [54, 62], [96, 72], [40, 90],
                                           [110, 86], [8, 40], [74, 58]] as const
        for (const [x, y] of flies) {
            ctx.circle(x, y, 2.6, rgb(0xF6E88A).opacity(0.18))
            ctx.circle(x, y, 1.4, rgb(0xF6E88A).opacity(0.35))
            ctx.circle(x, y, 0.7, rgb(0xFFF9C8))
        }
    } break; case 'snow': { 
        // Gờ tuyết nhấp nhô và bông tuyết rơi
        const bumps = [[30, 70, 24], [96, 66, 26], [14, 88, 22], [70, 98, 30]] as const
        for (const [x, y, w] of bumps) {
            ctx.ellipse(x - w / 2, y, w, 6, rgb(0xE2EAF2))
            ctx.ellipse(x - w / 2 + 1, y - 1.6, w - 2, 6, rgb(0xF9FBFD))
        }
        const flakes = [[8, 8, 0.9], [22, 20, 0.7], [36, 12, 1], [50, 24, 0.7], [62, 4, 0.9],
                                                    [66, 40, 0.8], [80, 32, 1], [92, 6, 0.7], [96, 44, 0.9], [112, 36, 0.8],
                                                    [120, 10, 0.9], [16, 42, 0.8], [44, 46, 0.7], [86, 58, 0.8], [108, 76, 0.9],
                                                    [28, 80, 0.8], [6, 60, 0.7], [56, 72, 0.7], [118, 54, 0.8], [74, 18, 0.6]] as const
        for (const [x, y, r] of flakes) { ctx.circle(x, y, r, Color.white.opacity(0.95)) }
        sparkle(ctx, 40, 72, 3, Color.white.opacity(0.9))
        sparkle(ctx, 100, 90, 3, Color.white.opacity(0.9))
    } }
}

// MARK: - Cây

const bark = rgb(0xA87454)
const barkDark = rgb(0x8C5E43)

function sapling(ctx: GC) {
    shadow(ctx, 50, 94, 44, 6)
    ctx.ellipse(32, 87, 36, 10, rgb(0xA27A5C))
    ctx.ellipse(36, 87, 28, 5, rgb(0xB58C6C))
    // Cọc đỡ và dây buộc
    ctx.rect(61, 48, 3.5, 46, rgb(0xDDB78C), 1.5)
    ctx.strokePath(barkDark, 4, (p) => {
        p.move(pt(49, 91)); p.addQuadCurve(pt(50, 44), pt(46, 68))
    })
    ctx.strokePath(barkDark, 2.4, (p) => {
        p.move(pt(48.5, 66)); p.addQuadCurve(pt(38, 54), pt(42, 62))
        p.move(pt(49.5, 58)); p.addQuadCurve(pt(60, 48), pt(56, 56))
    })
    ctx.rect(47, 70, 17, 2.4, Palette.lavender, 1.2)
    ctx.circle(62.5, 71.2, 2, Palette.lavender)
    // Tán lá nhỏ tròn
    const green = rgb(0x86C784), dark = rgb(0x70B373), light = rgb(0xA8DCA2)
    ctx.circle(50, 42, 15, dark)
    ctx.circle(37, 50, 10, dark)
    ctx.circle(63, 47, 11, dark)
    ctx.circle(50, 39, 15, green)
    ctx.circle(37, 47, 9.5, green)
    ctx.circle(63, 44, 10.5, green)
    ctx.circle(44, 33, 5, light)
    ctx.circle(34, 44, 3, light)
    ctx.circle(59, 39, 3.5, light)
    leaf(ctx, 54, 21, 7, 12, 35, green)
    ctx.strokePath(dark, 1, (p) => {
        p.move(pt(51, 26)); p.addLine(pt(56, 17))
    })
    ctx.circle(48, 37, 1.4, Color.white.opacity(0.6))
}

function roundCanopy(ctx: GC, blobs: ReadonlyArray<readonly [number, number, number]>, base: Color, dark: Color, light: Color) {
    for (const [x, y, r] of blobs) { ctx.circle(x, y + 3, r, dark) }
    for (const [x, y, r] of blobs) { ctx.circle(x, y, r, base) }
    for (const [x, y, r] of blobs) { ctx.circle(x - r * 0.35, y - r * 0.4, r * 0.38, light.opacity(0.8)) }
}

function appleTree(ctx: GC) {
    shadow(ctx, 50, 94, 72, 8)
    let trunk = new Path()
    trunk.move(pt(38, 95))
    trunk.addQuadCurve(pt(44, 78), pt(44, 92))
    trunk.addLine(pt(45, 50)); trunk.addLine(pt(55, 50)); trunk.addLine(pt(56, 78))
    trunk.addQuadCurve(pt(62, 95), pt(56, 92))
    trunk.closeSubpath()
    ctx.fill(trunk, (bark))
    ctx.strokePath(barkDark, 1.4, (p) => {
        p.move(pt(52, 88)); p.addLine(pt(52, 66))
        p.move(pt(47.5, 78)); p.addLine(pt(47.5, 70))
    })
    ctx.strokePath(bark, 4, (p) => {
        p.move(pt(48, 56)); p.addLine(pt(36, 46))
        p.move(pt(53, 54)); p.addLine(pt(66, 44))
    })
    const blobs = [[28, 40, 17], [72, 40, 17], [36, 20, 16], [64, 20, 16], [50, 32, 22],
                                               [50, 12, 13], [50, 48, 15], [16, 30, 11], [84, 30, 11]] as const
    roundCanopy(ctx, blobs, rgb(0x82C47F), rgb(0x6BAE6E), rgb(0xA4DB9C))
    const apples = [[28, 38], [48, 24], [68, 32], [60, 50], [38, 52], [78, 46], [40, 10], [18, 28], [84, 24]] as const
    for (const [x, y] of apples) { apple(ctx, x, y, 4.4) }
    // Táo rụng trên cỏ
    apple(ctx, 72, 91, 4.2)
}

function apple(ctx: GC, x: number, y: number, r: number) {
    ctx.circle(x - r * 0.3, y, r, rgb(0xE8585A))
    ctx.circle(x + r * 0.3, y, r, rgb(0xE8585A))
    ctx.circle(x - r * 0.5, y - r * 0.35, r * 0.32, Color.white.opacity(0.6))
    ctx.strokePath(barkDark, 1, (p) => {
        p.move(pt(x, y - r * 0.7)); p.addLine(pt(x + r * 0.2, y - r * 1.4))
    })
    leaf(ctx, x + r * 0.7, y - r * 1.2, r * 0.9, r * 0.5, -20, rgb(0x6BAE6E))
}

function pineTier(ctx: GC, top: number, bottom: number, hw: number, color: Color, shade: Color) {
    let p = new Path()
    p.move(pt(50, top))
    p.addQuadCurve(pt(50 - hw, bottom), pt(50 - hw * 0.35, bottom - (bottom - top) * 0.3))
    p.addQuadCurve(pt(50 + hw, bottom), pt(50, bottom + 7))
    p.addQuadCurve(pt(50, top), pt(50 + hw * 0.35, bottom - (bottom - top) * 0.3))
    p.closeSubpath()
    ctx.fill(p, (color))
    ctx.strokePath(shade, 2.4, (q) => {
        q.move(pt(50 - hw + 3, bottom + 0.6)); q.addQuadCurve(pt(50 + hw - 3, bottom + 0.6), pt(50, bottom + 6.4))
    })
    let hl = new Path()
    hl.move(pt(50, top + 3))
    hl.addQuadCurve(pt(50 - hw * 0.55, bottom - 1), pt(50 - hw * 0.3, bottom - (bottom - top) * 0.3))
    hl.addQuadCurve(pt(50 - hw * 0.15, bottom), pt(50 - hw * 0.4, bottom + 1))
    hl.closeSubpath()
    ctx.fill(hl, (Color.white.opacity(0.14)))
}

function pineTree(ctx: GC) {
    shadow(ctx, 50, 94, 58, 7)
    ctx.rect(44, 78, 12, 17, bark, 2)
    ctx.rect(45, 92, 10, 3, barkDark, 1)
    const base = rgb(0x67AA86), shade = rgb(0x55977A)
    pineTier(ctx, 44, 80, 36, base, shade)
    pineTier(ctx, 28, 62, 29, base, shade)
    pineTier(ctx, 14, 44, 22, base, shade)
    pineTier(ctx, 3, 27, 14, base, shade)
    // Quả thông nhỏ
    for (const [x, y] of ([[30, 84], [66, 66], [40, 48]] as const)) {
        ctx.ellipse(x - 2, y - 1, 4, 6, rgb(0xB0805A))
        ctx.rect(x - 2, y + 0.5, 4, 0.8, rgb(0x8C5E43), 0.4)
    }
    ctx.circle(44, 22, 1.4, Color.white.opacity(0.55))
}

function blossom(ctx: GC, cx: number, cy: number, r: number, color: Color) {
    for (let i = 0; i < 5; i++) {
        const a = (i) * 72.0 - 90.0
        const x = cx + r * (Math.cos(a * Math.PI / 180))
        const y = cy + r * (Math.sin(a * Math.PI / 180))
        ctx.circle(x, y, r * 0.75, color)
    }
    ctx.circle(cx, cy, r * 0.55, rgb(0xE77FA0))
}

function sakuraTree(ctx: GC) {
    shadow(ctx, 50, 94, 72, 8)
    const trunkC = rgb(0x8E5E4E)
    ctx.strokePath(trunkC, 10, (p) => {
        p.move(pt(50, 92)); p.addQuadCurve(pt(46, 52), pt(54, 70))
    })
    ctx.ellipse(40, 88, 20, 7, trunkC)
    ctx.strokePath(trunkC, 5, (p) => {
        p.move(pt(48, 62)); p.addQuadCurve(pt(70, 40), pt(62, 58))
        p.move(pt(47, 56)); p.addQuadCurve(pt(26, 40), pt(34, 54))
    })
    ctx.strokePath(rgb(0x7A4E40), 1.4, (p) => {
        p.move(pt(51, 86)); p.addQuadCurve(pt(49, 66), pt(53, 74))
    })
    const blobs = [[28, 38, 16], [72, 38, 16], [36, 20, 16], [64, 20, 15], [50, 30, 20],
                                               [50, 12, 12], [16, 30, 10], [84, 28, 11], [40, 46, 11], [62, 46, 11]] as const
    roundCanopy(ctx, blobs, rgb(0xF6BED0), rgb(0xEC9FB8), rgb(0xFCDDE7))
    const flowers = [[30, 36], [46, 22], [66, 30], [56, 44], [38, 46], [76, 42], [40, 10], [18, 28],
                                         [84, 24], [58, 12], [28, 18], [50, 34]] as const
    for (const [x, y] of flowers) { blossom(ctx, x, y, 2.6, Color.white.opacity(0.85)) }
    // Cánh hoa rơi
    const petals = [[20, 60, 20], [82, 56, -30], [30, 74, 60], [72, 70, 10], [24, 90, -20],
                                                [78, 92, 40], [64, 88, -50], [88, 80, 30]] as const
    for (const [x, y, a] of petals) { leaf(ctx, x, y, 4, 2.4, a, rgb(0xF4A9C0)) }
}

// MARK: - Luống hoa

const stem = rgb(0x6FAE6C)
const leafGreen = rgb(0x84C27C)

function soilBed(ctx: GC) {
    shadow(ctx, 50, 93, 94, 8)
    ctx.ellipse(4, 72, 92, 22, rgb(0x93694F))
    ctx.ellipse(10, 72, 80, 13, rgb(0xA97F60))
}

function bedFront(ctx: GC) {
    // Viền lá phía trước che chân thân hoa
    const leaves = [[14, 82, -30], [28, 86, 20], [44, 84, -15], [58, 87, 25], [72, 84, -20], [86, 82, 30]] as const
    for (const [x, y, a] of leaves) { leaf(ctx, x, y, 14, 7, a, leafGreen) }
    for (const [x, y, _] of leaves) { ctx.circle(x - 2, y - 1.4, 1, Color.white.opacity(0.35)) }
}

function daisy(ctx: GC, cx: number, cy: number, r: number) {
    for (let i = 0; i < 8; i++) {
        const a = (i) * 45.0
        ctx.rotated(a, pt(cx, cy), (c) => {
            c.ellipse(cx - r * 0.32, cy - r, r * 0.64, r, rgb(0xEDE7DE))
            c.ellipse(cx - r * 0.28, cy - r * 0.98, r * 0.56, r * 0.9, Color.white)
        })
    }
    ctx.circle(cx, cy, r * 0.42, rgb(0xF6C744))
    ctx.circle(cx - r * 0.14, cy - r * 0.14, r * 0.13, Color.white.opacity(0.7))
}

function daisyBed(ctx: GC) {
    soilBed(ctx)
    const heads = [[22, 50, 11], [50, 34, 12], [78, 48, 11], [36, 64, 10], [64, 62, 10]] as const
    ctx.strokePath(stem, 3, (p) => {
        for (const [x, y, _] of heads) {
            p.move(pt(x, y)); p.addQuadCurve(pt(50 + (x - 50) * 0.7, 84), pt(x + 2, (y + 84) / 2))
        }
    })
    leaf(ctx, 40, 66, 12, 6, -30, leafGreen)
    leaf(ctx, 62, 72, 12, 6, 30, leafGreen)
    for (const [x, y, r] of heads) { daisy(ctx, x, y, r) }
    bedFront(ctx)
}

function tulip(ctx: GC, cx: number, cy: number, s: number, color: Color, dark: Color) {
    ctx.ellipse(cx - 7 * s, cy - 6 * s, 14 * s, 16 * s, color)
    ctx.polygon([pt(cx - 7 * s, cy), pt(cx - 6 * s, cy - 11 * s), pt(cx - 2 * s, cy - 4 * s)], color)
    ctx.polygon([pt(cx + 7 * s, cy), pt(cx + 6 * s, cy - 11 * s), pt(cx + 2 * s, cy - 4 * s)], color)
    ctx.polygon([pt(cx - 3.5 * s, cy - 4 * s), pt(cx, cy - 12 * s), pt(cx + 3.5 * s, cy - 4 * s)], dark)
    ctx.ellipse(cx - 4.5 * s, cy - 3 * s, 3 * s, 7 * s, Color.white.opacity(0.4))
}

function tulipBed(ctx: GC) {
    soilBed(ctx)
    const heads = [[18, 50, 0xEE6E6E, 0xD95757], [36, 36, 0xF7CD55, 0xE9B53A],
                                                      [54, 46, 0xF4A2BE, 0xE587A6], [72, 34, 0xEE6E6E, 0xD95757],
                                                      [86, 52, 0xF7CD55, 0xE9B53A], [44, 62, 0xF4A2BE, 0xE587A6],
                                                      [66, 60, 0xF7CD55, 0xE9B53A]] as const
    ctx.strokePath(stem, 2.8, (p) => {
        for (const [x, y] of heads) {
            p.move(pt(x, y + 6)); p.addLine(pt(50 + (x - 50) * 0.8, 84))
        }
    })
    const leaves = [[22, 70, -25], [40, 72, 20], [60, 72, -20], [80, 70, 25]] as const
    for (const [x, y, a] of leaves) { leaf(ctx, x, y, 7, 22, a, leafGreen) }
    for (const [x, y, c, d] of heads) { tulip(ctx, x, y, 1, rgb(c), rgb(d)) }
    bedFront(ctx)
}

function mushroom(ctx: GC, cx: number, base: number, w: number, face: boolean) {
    const h = w * 0.62
    const stemW = w * 0.38
    const capY = base - h * 1.15
    ctx.rect(cx - stemW / 2, capY + h * 0.3, stemW, base - capY - h * 0.3, rgb(0xF8EBD6), stemW * 0.4)
    ctx.ellipse(cx - stemW / 2, base - stemW * 0.25, stemW, stemW * 0.3, rgb(0xEEDCC2))
    let cap = new Path()
    cap.move(pt(cx - w / 2, capY + h * 0.5))
    cap.addCurve(pt(cx + w / 2, capY + h * 0.5), pt(cx - w / 2, capY - h * 0.55), pt(cx + w / 2, capY - h * 0.55))
    cap.addQuadCurve(pt(cx - w / 2, capY + h * 0.5), pt(cx, capY + h * 0.8))
    cap.closeSubpath()
    ctx.fill(cap, (rgb(0xE5574F)))
    ctx.circle(cx - w * 0.2, capY + h * 0.02, w * 0.09, Color.white)
    ctx.circle(cx + w * 0.17, capY - h * 0.1, w * 0.07, Color.white)
    ctx.circle(cx + w * 0.32, capY + h * 0.3, w * 0.06, Color.white)
    ctx.circle(cx - w * 0.38, capY + h * 0.36, w * 0.05, Color.white)
    ctx.circle(cx + w * 0.02, capY + h * 0.3, w * 0.05, Color.white)
    if (face) {
        const fy = capY + h * 0.95
        ctx.circle(cx - stemW * 0.22, fy, w * 0.03, Palette.catInk)
        ctx.circle(cx + stemW * 0.22, fy, w * 0.03, Palette.catInk)
        ctx.ellipse(cx - stemW * 0.45, fy + w * 0.03, w * 0.07, w * 0.04, Palette.blush)
        ctx.ellipse(cx + stemW * 0.45 - w * 0.07, fy + w * 0.03, w * 0.07, w * 0.04, Palette.blush)
    }
}

function mushroomBed(ctx: GC) {
    shadow(ctx, 50, 93, 90, 8)
    ctx.ellipse(6, 74, 88, 20, rgb(0x8BBF7C))
    ctx.ellipse(12, 74, 72, 11, rgb(0x9FCE8D))
    mushroom(ctx, 42, 86, 46, true)
    mushroom(ctx, 75, 86, 26, false)
    mushroom(ctx, 18, 87, 16, false)
    const blades = [[28, 88, 2.4], [60, 89, 2.6], [88, 86, 2.2], [10, 86, 2]] as const
    for (const [x, y, s] of blades) { tuft(ctx, x, y, s, rgb(0x6FAE6C)) }
    ctx.circle(60, 79, 1.3, Color.white.opacity(0.7))
    ctx.circle(62.5, 80.5, 0.8, Color.white.opacity(0.5))
}

function sunflower(ctx: GC, cx: number, cy: number, r: number) {
    for (let i = 0; i < 12; i++) {
        const a = (i) * 30.0
        ctx.rotated(a, pt(cx, cy), (c) => {
            c.ellipse(cx - r * 0.28, cy - r * 1.05, r * 0.56, r * 0.75, rgb(0xF2B530))
        })
    }
    for (let i = 0; i < 12; i++) {
        const a = (i) * 30.0 + 15.0
        ctx.rotated(a, pt(cx, cy), (c) => {
            c.ellipse(cx - r * 0.26, cy - r * 0.98, r * 0.52, r * 0.7, rgb(0xFAD04A))
        })
    }
    ctx.circle(cx, cy, r * 0.5, rgb(0x8B5A3C))
    ctx.circle(cx + r * 0.06, cy + r * 0.04, r * 0.36, rgb(0x6F4430))
    for (const [dx, dy] of ([[-0.2, -0.15], [0.18, -0.2], [0.24, 0.14], [-0.1, 0.22], [0.02, 0.0]] as const)) {
        ctx.circle(cx + r * dx, cy + r * dy, r * 0.05, rgb(0xA87454))
    }
    ctx.circle(cx - r * 0.22, cy - r * 0.25, r * 0.09, Color.white.opacity(0.5))
}

function sunflowerBed(ctx: GC) {
    soilBed(ctx)
    const heads = [[24, 34, 13], [56, 18, 15], [80, 42, 12]] as const
    ctx.strokePath(stem, 4, (p) => {
        for (const [x, y, _] of heads) {
            p.move(pt(x, y)); p.addQuadCurve(pt(50 + (x - 50) * 0.6, 84), pt(x - 3, (y + 84) / 2))
        }
    })
    const leaves = [[34, 58, -35], [16, 66, 30], [64, 44, 35], [48, 62, -30], [70, 62, 30], [88, 66, -30]] as const
    for (const [x, y, a] of leaves) { leaf(ctx, x, y, 16, 8, a, leafGreen) }
    for (const [x, y, r] of heads) { sunflower(ctx, x, y, r) }
    bedFront(ctx)
}

// MARK: - Chỗ ngồi

function stump(ctx: GC) {
    shadow(ctx, 50, 92, 72, 9)
    ctx.ellipse(14, 80, 26, 12, bark)
    ctx.ellipse(60, 80, 26, 12, bark)
    ctx.ellipse(40, 84, 20, 10, barkDark)
    ctx.rect(24, 52, 52, 36, bark, 8)
    ctx.strokePath(barkDark, 2, (p) => {
        p.move(pt(34, 62)); p.addLine(pt(34, 82))
        p.move(pt(48, 66)); p.addLine(pt(48, 86))
        p.move(pt(63, 60)); p.addLine(pt(63, 80))
    })
    ctx.ellipse(22, 44, 56, 18, rgb(0xEACB9F))
    ctx.strokePath(rgb(0xCDA67A), 1.4, (p) => {
        p.addEllipse(R(30, 47, 40, 12))
        p.addEllipse(R(38, 50, 24, 6.5))
    })
    ctx.circle(50, 53, 1.4, rgb(0xCDA67A))
    ctx.ellipse(28, 46, 10, 3.5, Color.white.opacity(0.45))
    // Mầm non mọc bên cạnh
    ctx.strokePath(stem, 1.6, (p) => {
        p.move(pt(76, 66)); p.addQuadCurve(pt(84, 54), pt(84, 62))
    })
    leaf(ctx, 86, 52, 8, 4.5, -30, leafGreen)
    leaf(ctx, 80, 57, 7, 4, 30, leafGreen)
    mushroom(ctx, 20, 90, 14, false)
}

function bench(ctx: GC) {
    const wood = Palette.wood, dark = Palette.woodDark
    shadow(ctx, 50, 93, 88, 8)
    // Chân sau và trụ tựa
    ctx.rect(18, 28, 7, 62, dark, 2)
    ctx.rect(75, 28, 7, 62, dark, 2)
    // Thanh tựa lưng
    ctx.rect(10, 30, 80, 9, wood, 4)
    ctx.rect(10, 43, 80, 9, wood, 4)
    ctx.rect(14, 31.5, 72, 2, Color.white.opacity(0.35), 1)
    ctx.heart(pt(50, 35), 6, Palette.blush)
    // Mặt ghế
    ctx.rect(6, 60, 88, 10, wood, 4)
    ctx.rect(6, 67, 88, 4, dark, 2)
    ctx.rect(10, 61.5, 80, 2, Color.white.opacity(0.35), 1)
    // Chân trước
    ctx.rect(12, 70, 7, 22, dark, 2)
    ctx.rect(81, 70, 7, 22, dark, 2)
    // Tay vịn
    ctx.strokePath(dark, 4, (p) => {
        p.move(pt(10, 60)); p.addQuadCurve(pt(6, 46), pt(4, 54))
        p.move(pt(90, 60)); p.addQuadCurve(pt(94, 46), pt(96, 54))
    })
}

function swing(ctx: GC) {
    const wood = Palette.wood, dark = Palette.woodDark
    shadow(ctx, 50, 92, 92, 8)
    shadow(ctx, 50, 86, 40, 5)
    // Khung chữ A hai bên
    ctx.strokePath(dark, 5, (p) => {
        p.move(pt(8, 92)); p.addLine(pt(18, 10))
        p.move(pt(28, 92)); p.addLine(pt(18, 10))
        p.move(pt(72, 92)); p.addLine(pt(82, 10))
        p.move(pt(92, 92)); p.addLine(pt(82, 10))
    })
    ctx.rect(10, 6, 80, 8, wood, 4)
    ctx.rect(14, 7.5, 72, 2, Color.white.opacity(0.35), 1)
    // Dây và ván ngồi
    const rope = rgb(0xEADBBE)
    ctx.strokePath(rope, 1.8, (p) => {
        p.move(pt(34, 14)); p.addLine(pt(34, 68))
        p.move(pt(66, 14)); p.addLine(pt(66, 68))
    })
    ctx.rect(26, 66, 48, 8, Palette.peach, 4)
    ctx.rect(30, 67.5, 40, 2, Color.white.opacity(0.4), 1)
    // Dây leo hoa nhỏ
    const buds = [[34, 24, 0xF7B6C8], [34, 38, 0xFFFFFF], [34, 52, 0xF7B6C8],
                                             [66, 30, 0xFFFFFF], [66, 44, 0xF7B6C8], [66, 58, 0xFFFFFF]] as const
    for (const [x, y, c] of buds) {
        leaf(ctx, x - 2.5, y + 3, 5, 2.6, 30, leafGreen)
        leaf(ctx, x + 2.5, y - 3, 5, 2.6, -30, leafGreen)
        ctx.circle(x, y, 2.2, rgb(c))
        ctx.circle(x, y, 0.8, rgb(0xF2B84B))
    }
}

function hammock(ctx: GC) {
    const dark = Palette.woodDark
    shadow(ctx, 50, 92, 94, 8)
    shadow(ctx, 50, 86, 50, 5)
    ctx.rect(6, 24, 8, 70, dark, 3)
    ctx.rect(86, 24, 8, 70, dark, 3)
    ctx.circle(10, 24, 4.5, dark)
    ctx.circle(90, 24, 4.5, dark)
    const rope = rgb(0xEADBBE)
    ctx.strokePath(rope, 1.6, (p) => {
        p.move(pt(12, 32)); p.addLine(pt(22, 50))
        p.move(pt(12, 32)); p.addLine(pt(20, 54))
        p.move(pt(88, 32)); p.addLine(pt(78, 50))
        p.move(pt(88, 32)); p.addLine(pt(80, 54))
    })
    let fabric = new Path()
    fabric.move(pt(20, 50))
    fabric.addQuadCurve(pt(80, 50), pt(50, 60))
    fabric.addQuadCurve(pt(20, 50), pt(50, 98))
    fabric.closeSubpath()
    const c = ctx.copy()
    c.clip(fabric)
    c.fill(fabric, (rgb(0xF4B6A4)))
    for (let x = (22); x < 80; x += 12) {
        c.rect(x, 40, 5, 50, rgb(0xFCEBD9))
    }
    c.ellipse(16, 46, 70, 16, Color.black.opacity(0.06))
    // Gối nhỏ
    ctx.rotated(-12, pt(32, 56), (g) => {
        g.ellipse(22, 51, 20, 10, Palette.lavenderSoft)
        g.ellipse(25, 52.5, 8, 3, Color.white.opacity(0.6))
    })
    // Tua rua viền dưới
    ctx.strokePath(rgb(0xE59A88), 1, (p) => {
        for (let x = (34); x < 68; x += 5) {
            const dy = 73 - Math.abs(x - 50) * 0.4
            p.move(pt(x, dy)); p.addLine(pt(x, dy + 4))
        }
    })
}

// MARK: - Hồ nước

const water = rgb(0x93D0E6)
const waterDeep = rgb(0x7FC2DB)

// Hồ bầu dục có viền đá; trả về hình mặt nước để cắt.
function stonePond(ctx: GC, waterColor: Color): Path {
    shadow(ctx, 50, 86, 96, 12)
    const cx = 50, cy: number = 70, rx: number = 42, ry: number = 17
    for (let i = 0; i < 16; i++) {
        const a = (i) * 22.5 * Math.PI / 180
        const x = cx + (rx + 1) * (Math.cos(a))
        const y = cy + (ry + 1) * (Math.sin(a))
        const color = i % 2 == 0 ? rgb(0xCBC6BF) : rgb(0xB9B4AD)
        ctx.ellipse(x - 7, y - 4.5, 14, 9, color)
        ctx.ellipse(x - 4.5, y - 4, 6, 2.6, Color.white.opacity(0.4))
    }
    const surface = Path.ellipse(R(cx - rx + 2, cy - ry + 1, (rx - 2) * 2, (ry - 1) * 2))
    ctx.fill(surface, (waterColor))
    const c = ctx.copy()
    c.clip(surface)
    c.ellipse(cx - rx, cy - ry - 4, rx * 2, ry * 0.9, Color.black.opacity(0.08))
    c.ellipse(cx - rx * 0.4, cy + 2, rx * 1.1, ry * 0.9, Color.white.opacity(0.15))
    return surface
}

function ripple(ctx: GC, x: number, y: number, w: number) {
    ctx.strokePath(Color.white.opacity(0.6), 1, (p) => {
        p.addEllipse(R(x - w / 2, y - w * 0.15, w, w * 0.3))
    })
}

function puddle(ctx: GC) {
    shadow(ctx, 44, 86, 86, 10)
    const blobs = [[4, 64, 52, 24], [30, 60, 46, 28], [14, 72, 58, 18]] as const
    for (const [x, y, w, h] of blobs) { ctx.ellipse(x - 1.5, y - 1, w + 3, h + 3, rgb(0x7EB6CE)) }
    for (const [x, y, w, h] of blobs) { ctx.ellipse(x, y, w, h, rgb(0xA6D8EC)) }
    ctx.ellipse(16, 66, 30, 6, Color.white.opacity(0.4))
    ctx.ellipse(52, 78, 12, 3, Color.white.opacity(0.35))
    ripple(ctx, 36, 74, 16)
    ripple(ctx, 36, 74, 7)
    ripple(ctx, 58, 68, 9)
    // Giọt mưa đang rơi
    for (const [x, y] of ([[26, 44], [46, 36], [62, 48], [14, 54]] as const)) {
        let d = new Path()
        d.move(pt(x, y - 4))
        d.addQuadCurve(pt(x, y + 2.4), pt(x + 3.2, y + 1))
        d.addQuadCurve(pt(x, y - 4), pt(x - 3.2, y + 1))
        ctx.fill(d, (rgb(0x8CCBE4)))
    }
    // Đôi ủng vàng
    shadow(ctx, 84, 85, 24, 5)
    for (const bx of [(74), 84]) {
        ctx.rect(bx, 60, 8.5, 22, rgb(0xF6C64A), 3)
        ctx.rect(bx, 76, 13, 7, rgb(0xF6C64A), 3.5)
        ctx.rect(bx - 0.5, 59, 9.5, 3.5, rgb(0xE9AE30), 1.5)
        ctx.rect(bx + 0.5, 81, 12, 2, rgb(0xE9AE30), 1)
        ctx.rect(bx + 1.6, 64, 2, 9, Color.white.opacity(0.5), 1)
    }
}

function lilyPad(ctx: GC, x: number, y: number, w: number, h: number, notch: Color) {
    ctx.ellipse(x, y, w, h, rgb(0x79BC76))
    ctx.ellipse(x + w * 0.12, y + h * 0.1, w * 0.6, h * 0.45, rgb(0x8ECB86))
    const cx = x + w / 2, cy = y + h / 2
    ctx.polygon([pt(cx, cy), pt(cx + w * 0.45, cy - h * 0.12), pt(cx + w * 0.45, cy + h * 0.2)], notch)
}

function lilyPond(ctx: GC) {
    stonePond(ctx, water)
    lilyPad(ctx, 14, 62, 24, 10, water)
    lilyPad(ctx, 62, 74, 18, 8, water)
    lilyPad(ctx, 30, 74, 14, 6, water)
    // Hoa súng hồng
    for (let i = 0; i < 6; i++) {
        const a = (i) * 60.0
        ctx.rotated(a, pt(26, 64), (c) => {
            c.ellipse(24, 57, 4, 7, rgb(0xF6A9C3))
        })
    }
    ctx.circle(26, 64, 2.4, rgb(0xFBE07A))
    ripple(ctx, 46, 70, 12)
    // Ếch ngồi trên lá
    frog(ctx, 70, 76)
}

function frog(ctx: GC, cx: number, bottom: number) {
    const body = rgb(0x8FD07A), dark = rgb(0x76BB66)
    lilyPad(ctx, cx - 14, bottom - 6, 28, 10, water)
    ctx.ellipse(cx - 10, bottom - 15, 20, 15, body)
    ctx.ellipse(cx - 12, bottom - 5, 8, 5, dark)
    ctx.ellipse(cx + 4, bottom - 5, 8, 5, dark)
    ctx.ellipse(cx - 6, bottom - 10, 12, 8, rgb(0xD6F0C4))
    ctx.circle(cx - 5, bottom - 15.5, 4, body)
    ctx.circle(cx + 5, bottom - 15.5, 4, body)
    ctx.circle(cx - 5, bottom - 16, 2.6, Color.white)
    ctx.circle(cx + 5, bottom - 16, 2.6, Color.white)
    ctx.circle(cx - 4.6, bottom - 15.6, 1.4, Palette.catInk)
    ctx.circle(cx + 5.4, bottom - 15.6, 1.4, Palette.catInk)
    ctx.ellipse(cx - 8.5, bottom - 12, 3.4, 2, Palette.blush)
    ctx.ellipse(cx + 5.1, bottom - 12, 3.4, 2, Palette.blush)
    ctx.strokePath(Palette.catInk, 0.8, (p) => {
        p.move(pt(cx - 2, bottom - 11.6)); p.addQuadCurve(pt(cx + 2, bottom - 11.6), pt(cx, bottom - 10))
    })
}

function koi(ctx: GC, cx: number, cy: number, angle: number, base: Color, patch: Color) {
    ctx.rotated(angle, pt(cx, cy), (c) => {
        c.polygon([pt(cx - 7, cy), pt(cx - 13, cy - 4), pt(cx - 12, cy), pt(cx - 13, cy + 4)], patch)
        c.ellipse(cx - 9, cy - 3.6, 18, 7.2, base)
        c.ellipse(cx - 2, cy - 3.4, 6, 4, patch)
        c.ellipse(cx + 4, cy - 1.4, 4, 3.6, patch)
        leaf(c, cx - 1, cy + 4, 5, 2.2, 30, base.opacity(0.9))
        leaf(c, cx - 1, cy - 4, 5, 2.2, -30, base.opacity(0.9))
        c.circle(cx + 6.5, cy - 1, 0.7, Palette.catInk)
    })
}

function koiPond(ctx: GC) {
    stonePond(ctx, waterDeep)
    const white = rgb(0xFFFBF5), red = rgb(0xF0674A)
    koi(ctx, 36, 68, -12, white, red)
    koi(ctx, 62, 74, 168, red, white)
    lilyPad(ctx, 66, 60, 16, 7, waterDeep)
    ripple(ctx, 48, 66, 10)
    ripple(ctx, 24, 76, 8)
    ctx.circle(46, 60, 0.9, Color.white.opacity(0.7))
    ctx.circle(48, 58, 0.6, Color.white.opacity(0.6))
}

function fountain(ctx: GC) {
    const stoneC = rgb(0xDCD6CD), stoneDark = rgb(0xC6BFB4), stoneLight = rgb(0xEDE9E2)
    shadow(ctx, 50, 91, 94, 9)
    // Bồn dưới
    ctx.rect(8, 66, 84, 22, stoneC, 10)
    ctx.rect(8, 80, 84, 8, stoneDark, 6)
    ctx.ellipse(5, 59, 90, 15, stoneLight)
    ctx.ellipse(11, 61.5, 78, 9.5, water)
    ctx.ellipse(18, 62.5, 34, 3, Color.white.opacity(0.35))
    // Trụ và bồn trên
    ctx.rect(44, 36, 12, 28, stoneC, 3)
    ctx.rect(41, 60, 18, 4, stoneDark, 2)
    let bowl = new Path()
    bowl.move(pt(27, 31))
    bowl.addQuadCurve(pt(73, 31), pt(50, 48))
    bowl.closeSubpath()
    ctx.fill(bowl, (stoneC))
    ctx.ellipse(27, 27, 46, 8, stoneLight)
    ctx.ellipse(31, 28.2, 38, 5, water)
    // Tia nước
    const jet = rgb(0xBFE6F5)
    ctx.strokePath(jet, 3, (p) => {
        p.move(pt(50, 29)); p.addLine(pt(50, 10))
    })
    ctx.strokePath(jet, 2, (p) => {
        p.move(pt(50, 10)); p.addQuadCurve(pt(34, 28), pt(38, 6))
        p.move(pt(50, 10)); p.addQuadCurve(pt(66, 28), pt(62, 6))
        p.move(pt(28, 31)); p.addQuadCurve(pt(18, 62), pt(18, 38))
        p.move(pt(72, 31)); p.addQuadCurve(pt(82, 62), pt(82, 38))
    })
    ctx.circle(50, 9, 2.6, jet)
    const drops = [[42, 4], [58, 4], [30, 20], [70, 20], [14, 48], [86, 48], [22, 56], [78, 56]] as const
    for (const [x, y] of drops) { ctx.circle(x, y, 1.3, jet) }
    ctx.circle(49, 8, 0.9, Color.white.opacity(0.8))
    ripple(ctx, 18, 64, 8)
    ripple(ctx, 82, 64, 8)
    // Hoa văn trên bồn
    for (let x = (20); x < 90; x += 15) {
        ctx.circle(x, 73, 1.6, stoneDark)
    }
}

// MARK: - Trang trí

function fence(ctx: GC) {
    const white = rgb(0xFBF7F0), shade = rgb(0xE8DFD2)
    shadow(ctx, 50, 92, 98, 7)
    ctx.rect(0, 46, 97, 6, shade, 2)
    ctx.rect(0, 72, 97, 6, shade, 2)
    for (let x = (3); x < 92; x += 15) {
        ctx.polygon([pt(x, 36), pt(x + 5.5, 27), pt(x + 11, 36)], white)
        ctx.rect(x, 34, 11, 57, white, 2)
        ctx.rect(x, 82, 11, 9, shade, 2)
        ctx.rect(x + 2, 38, 2, 30, Color.white.opacity(0.9), 1)
    }
    // Dây leo hoa nhỏ trên rào
    ctx.strokePath(stem, 1.4, (p) => {
        p.move(pt(4, 50)); p.addQuadCurve(pt(40, 50), pt(22, 58))
        p.addQuadCurve(pt(72, 48), pt(56, 42))
    })
    const buds = [[12, 53, 0xF7B6C8], [28, 54, 0xF9D86E], [46, 48, 0xF7B6C8], [62, 46, 0xF9D86E]] as const
    for (const [x, y, c] of buds) {
        leaf(ctx, x + 3.5, y + 2, 6, 3, 30, leafGreen)
        ctx.circle(x, y, 2.6, rgb(c))
        ctx.circle(x, y, 0.9, rgb(0xFFF6E0))
    }
    tuft(ctx, 20, 92, 2.6, stem)
    tuft(ctx, 66, 92, 2.6, stem)
}

function mailbox(ctx: GC) {
    const blue = rgb(0x9CC6EB), blueDark = rgb(0x7FAFD9)
    shadow(ctx, 50, 93, 40, 7)
    ctx.rect(44, 54, 12, 40, Palette.woodDark, 2)
    ctx.rect(46, 56, 2.5, 34, Color.white.opacity(0.2), 1)
    // Thân hộp thư
    ctx.rect(18, 26, 64, 32, blue, 14)
    ctx.rect(18, 40, 64, 18, blue, 3)
    ctx.rect(14, 26, 12, 32, blueDark, 6)
    ctx.rect(14, 40, 12, 18, blueDark, 2)
    ctx.rect(30, 30, 40, 3, Color.white.opacity(0.45), 1.5)
    ctx.heart(pt(52, 45), 9, Palette.blush)
    // Lá thư thò ra
    ctx.rotated(-14, pt(14, 40), (c) => {
        c.rect(6, 34, 16, 11, rgb(0xFFFDF8), 1.5)
        c.strokePath(rgb(0xE3D6C4), 0.9, (p) => {
            p.move(pt(6.5, 34.5)); p.addLine(pt(14, 40)); p.addLine(pt(21.5, 34.5))
        })
        c.heart(pt(14, 41), 4, rgb(0xE8585A))
    })
    // Cờ đỏ dựng lên
    ctx.rect(78, 18, 3.5, 30, rgb(0xE8585A), 1.5)
    ctx.rect(78, 16, 14, 9, rgb(0xE8585A), 2)
    ctx.circle(79.7, 46, 2.4, rgb(0xC8463F))
    // Hoa dưới chân cột
    tuft(ctx, 40, 93, 2.6, stem)
    tuft(ctx, 60, 93, 2.6, stem)
    ctx.circle(36, 86, 2.4, rgb(0xFFFFFF))
    ctx.circle(36, 86, 0.9, rgb(0xF2B84B))
    ctx.circle(64, 87, 2.4, rgb(0xF7B6C8))
    ctx.circle(64, 87, 0.9, rgb(0xF2B84B))
}

function birdhouse(ctx: GC) {
    shadow(ctx, 50, 93, 36, 7)
    ctx.rect(45, 58, 10, 36, Palette.woodDark, 2)
    // Thân nhà
    ctx.rect(28, 32, 44, 30, rgb(0xF6E3C6), 4)
    ctx.rect(28, 56, 44, 6, rgb(0xEACFAC), 3)
    // Mái
    const roof = rgb(0xE08070)
    ctx.polygon([pt(22, 36), pt(50, 14), pt(78, 36)], roof)
    ctx.strokePath(roof, 5, (p) => {
        p.move(pt(22, 36)); p.addLine(pt(50, 14)); p.addLine(pt(78, 36))
    })
    ctx.strokePath(Color.white.opacity(0.35), 1.4, (p) => {
        p.move(pt(28, 33)); p.addLine(pt(48, 18))
    })
    // Lỗ tròn và que đậu
    ctx.circle(50, 44, 6, rgb(0x5E4A3E))
    ctx.rect(46, 53, 8, 2.6, Palette.woodDark, 1.3)
    ctx.heart(pt(36, 50), 5, Palette.blush)
    // Chim vàng đậu trên mái
    const yellow = rgb(0xF8D45C), yDark = rgb(0xEDBB3C)
    ctx.ellipse(56, 4, 20, 15, yellow)
    ctx.polygon([pt(57, 12), pt(50, 9), pt(54, 15)], yDark)
    leaf(ctx, 64, 13, 10, 6, -15, yDark)
    ctx.polygon([pt(75, 9), pt(80, 10.5), pt(75, 12)], rgb(0xF29A4A))
    ctx.circle(71, 8.5, 1.3, Palette.catInk)
    ctx.ellipse(68.5, 11, 3.6, 2, Palette.blush)
    ctx.circle(62, 7, 1.4, Color.white.opacity(0.6))
    ctx.strokePath(rgb(0xF29A4A), 1, (p) => {
        p.move(pt(63, 18.5)); p.addLine(pt(63, 21))
        p.move(pt(68, 18.5)); p.addLine(pt(68, 21))
    })
}

function lantern(ctx: GC) {
    const iron = rgb(0x6E5E62)
    shadow(ctx, 40, 93, 34, 6)
    // Quầng sáng dịu
    ctx.circle(62, 46, 26, rgb(0xFFDE8E).opacity(0.18))
    ctx.circle(62, 46, 19, rgb(0xFFDE8E).opacity(0.25))
    // Cột móc
    ctx.strokePath(iron, 3.5, (p) => {
        p.move(pt(36, 93)); p.addLine(pt(36, 18))
        p.addQuadCurve(pt(62, 16), pt(48, 6))
        p.addLine(pt(62, 26))
    })
    ctx.rect(32, 89, 8, 5, iron, 2)
    // Đèn lồng giấy
    ctx.rect(54, 25, 16, 5, iron, 2)
    ctx.ellipse(46, 27, 32, 36, rgb(0xF29A80))
    ctx.ellipse(52, 33, 20, 24, rgb(0xFFD7A0).opacity(0.65))
    ctx.strokePath(rgb(0xDE7E66), 1.1, (p) => {
        p.move(pt(62, 27.5)); p.addLine(pt(62, 62.5))
        p.move(pt(54, 29)); p.addQuadCurve(pt(54, 61), pt(48, 45))
        p.move(pt(70, 29)); p.addQuadCurve(pt(70, 61), pt(76, 45))
    })
    ctx.rect(54, 60, 16, 5, iron, 2)
    ctx.ellipse(50, 33, 5, 10, Color.white.opacity(0.45))
    // Tua đèn
    ctx.strokePath(rgb(0xE8585A), 1.4, (p) => {
        p.move(pt(62, 65)); p.addLine(pt(62, 74))
        p.move(pt(60, 68)); p.addLine(pt(60, 74))
        p.move(pt(64, 68)); p.addLine(pt(64, 74))
    })
    ctx.circle(62, 66, 1.8, rgb(0xE8585A))
    sparkle(ctx, 80, 28, 5, rgb(0xFFE6A0))
    sparkle(ctx, 44, 54, 4, rgb(0xFFE6A0))
    // Hoa dưới chân cột
    tuft(ctx, 28, 93, 2.6, stem)
    tuft(ctx, 46, 93, 2.6, stem)
    ctx.circle(26, 86, 2.4, rgb(0xF7B6C8))
    ctx.circle(26, 86, 0.9, rgb(0xF2B84B))
}

function tent(ctx: GC) {
    const body = rgb(0xF5B48A), side = rgb(0xE79C76), inside = rgb(0x6B5165)
    shadow(ctx, 50, 91, 96, 9)
    // Dây néo và cọc
    ctx.strokePath(rgb(0xD8C7A8), 1, (p) => {
        p.move(pt(22, 62)); p.addLine(pt(4, 90))
        p.move(pt(78, 62)); p.addLine(pt(95, 90))
    })
    ctx.rect(2.5, 87, 3, 5, Palette.woodDark, 1)
    ctx.rect(93.5, 87, 3, 5, Palette.woodDark, 1)
    // Thân lều
    ctx.polygon([pt(8, 90), pt(50, 20), pt(92, 90)], body)
    ctx.polygon([pt(50, 20), pt(92, 90), pt(72, 90)], side)
    // Viền sọc
    ctx.strokePath(rgb(0xFCE3CF), 2.6, (p) => {
        p.move(pt(14, 82)); p.addLine(pt(86, 82))
    })
    // Cửa lều mở
    ctx.polygon([pt(34, 90), pt(50, 46), pt(66, 90)], inside)
    ctx.circle(50, 78, 6, rgb(0xFFDE8E).opacity(0.35))
    ctx.circle(50, 78, 2.4, rgb(0xFFE6A0))
    ctx.polygon([pt(50, 46), pt(34, 90), pt(30, 90), pt(38, 66)], rgb(0xFCE3CF))
    ctx.polygon([pt(50, 46), pt(66, 90), pt(70, 90), pt(62, 66)], rgb(0xF2D2BA))
    ctx.circle(38, 66, 1.8, Palette.lavender)
    ctx.circle(62, 66, 1.8, Palette.lavender)
    ctx.strokePath(Color.white.opacity(0.4), 1.6, (p) => {
        p.move(pt(46, 28)); p.addLine(pt(24, 66))
    })
    // Cột và cờ đuôi nheo
    ctx.strokePath(Palette.woodDark, 1.6, (p) => {
        p.move(pt(50, 22)); p.addLine(pt(50, 6))
    })
    ctx.polygon([pt(50, 6), pt(63, 9.5), pt(50, 13)], Palette.lavender)
    ctx.circle(50, 5.5, 1.4, Palette.honey)
}

export const GardenArt = { draw }
