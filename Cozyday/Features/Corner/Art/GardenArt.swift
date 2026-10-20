import SwiftUI

/// Hình vẽ đồ trong Garden. Trả về false nếu không phải ID của phòng này.
enum GardenArt {
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        // Bầu trời (cả cảnh 125×100)
        case "gardenTheme.day": scene(ctx, .day)
        case "gardenTheme.sunset": scene(ctx, .sunset)
        case "gardenTheme.night": scene(ctx, .night)
        case "gardenTheme.snow": scene(ctx, .snow)
        // Cây
        case "tree.sapling": sapling(ctx)
        case "tree.apple": appleTree(ctx)
        case "tree.pine": pineTree(ctx)
        case "tree.sakura": sakuraTree(ctx)
        // Luống hoa
        case "flowerBed.daisy": daisyBed(ctx)
        case "flowerBed.tulip": tulipBed(ctx)
        case "flowerBed.mushroom": mushroomBed(ctx)
        case "flowerBed.sunflower": sunflowerBed(ctx)
        // Chỗ ngồi
        case "gardenSeat.stump": stump(ctx)
        case "gardenSeat.bench": bench(ctx)
        case "gardenSeat.swing": swing(ctx)
        case "gardenSeat.hammock": hammock(ctx)
        // Hồ nước
        case "pond.puddle": puddle(ctx)
        case "pond.lily": lilyPond(ctx)
        case "pond.koi": koiPond(ctx)
        case "pond.fountain": fountain(ctx)
        // Trang trí
        case "gardenDeco.fence": fence(ctx)
        case "gardenDeco.mailbox": mailbox(ctx)
        case "gardenDeco.birdhouse": birdhouse(ctx)
        case "gardenDeco.lantern": lantern(ctx)
        case "gardenDeco.tent": tent(ctx)
        default: return false
        }
        return true
    }

    // MARK: - Tiện ích

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    /// Bóng đổ nhẹ dưới chân đồ đặt trên cỏ.
    private static func shadow(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        ctx.ellipse(cx - w / 2, cy - h / 2, w, h, Color.black.opacity(0.1))
    }

    private static func sparkle(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: Color) {
        ctx.draw(Text("✦").font(.system(size: size)).foregroundColor(color), at: pt(x, y))
    }

    /// Lá hình bầu dục xoay theo góc.
    private static func leaf(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat,
                             _ angle: Double, _ color: Color) {
        ctx.rotated(angle, around: pt(cx, cy)) { c in
            c.ellipse(cx - w / 2, cy - h / 2, w, h, color)
        }
    }

    /// Cụm cỏ nhỏ hình chữ "w".
    private static func tuft(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ color: Color) {
        ctx.strokePath(color, width: max(0.6, s * 0.28)) { p in
            p.move(to: pt(x - s, y - s * 1.1)); p.addLine(to: pt(x - s * 0.4, y))
            p.move(to: pt(x, y - s * 1.5)); p.addLine(to: pt(x, y))
            p.move(to: pt(x + s, y - s * 1.1)); p.addLine(to: pt(x + s * 0.4, y))
        }
    }

    private static func cloud(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ color: Color) {
        ctx.rect(x, y + 3 * s, 20 * s, 5 * s, color, radius: 2.5 * s)
        ctx.circle(x + 6 * s, y + 3.6 * s, 3.6 * s, color)
        ctx.circle(x + 11.5 * s, y + 2.6 * s, 4.6 * s, color)
        ctx.circle(x + 16 * s, y + 4.4 * s, 3 * s, color)
    }

    // MARK: - Bầu trời

    private enum Sky { case day, sunset, night, snow }

    private static func scene(_ base: GraphicsContext, _ sky: Sky) {
        var ctx = base
        ctx.clip(to: Path(CGRect(x: 0, y: 0, width: 125, height: 100)))
        // Bảng màu theo thời tiết
        var top = rgb(0xAEDCF2), mid = rgb(0xC4E6F5), low = rgb(0xDDF1F8)
        var farHill = rgb(0xB9DDB0), midHill = rgb(0xA3D19C), bush = rgb(0x8EC48D), bushLight = rgb(0xA6D4A1)
        var grass = rgb(0xB8E0A2), grassLow = rgb(0xAAD796), tuftColor = rgb(0x93C784), stone = rgb(0xE6E0CF)
        switch sky {
        case .day:
            break
        case .sunset:
            top = rgb(0xF2A7A0); mid = rgb(0xF8BFA0); low = rgb(0xFCDDB0)
            farHill = rgb(0xD9A9B5); midHill = rgb(0xC7B48F); bush = rgb(0x9DB27A); bushLight = rgb(0xB3C287)
            grass = rgb(0xC4D594); grassLow = rgb(0xB6CB88); tuftColor = rgb(0xA0B776); stone = rgb(0xEBD6BE)
        case .night:
            top = rgb(0x2F3260); mid = rgb(0x3A3D6E); low = rgb(0x4A4B7C)
            farHill = rgb(0x3D4A6A); midHill = rgb(0x3A5A60); bush = rgb(0x2F5452); bushLight = rgb(0x3B6560)
            grass = rgb(0x48715C); grassLow = rgb(0x416954); tuftColor = rgb(0x5A8A6C); stone = rgb(0x6E7F84)
        case .snow:
            top = rgb(0xC9DCEC); mid = rgb(0xD8E6F1); low = rgb(0xE6EFF6)
            farHill = rgb(0xEEF3F8); midHill = rgb(0xE2EBF3); bush = rgb(0x8DB39A); bushLight = rgb(0xF6F9FC)
            grass = rgb(0xF6F9FC); grassLow = rgb(0xECF2F8); tuftColor = rgb(0xD6E2EE); stone = rgb(0xDCE5EE)
        }

        // Trời thành các dải mềm
        ctx.rect(0, 0, 125, 62, top)
        ctx.ellipse(-30, 18, 185, 70, mid)
        ctx.ellipse(-30, 34, 185, 60, low)

        // Mặt trời / trăng / mây ở góc trên phải
        switch sky {
        case .day:
            ctx.circle(104, 14, 11, rgb(0xFFF2B8).opacity(0.55))
            ctx.circle(104, 14, 7, rgb(0xFFD66B))
            ctx.circle(102, 12, 2, Color.white.opacity(0.6))
            cloud(ctx, 70, 8, 0.85, Color.white.opacity(0.95))
            cloud(ctx, 100, 24, 0.6, Color.white.opacity(0.85))
            cloud(ctx, 60, 26, 0.45, Color.white.opacity(0.7))
        case .sunset:
            ctx.circle(100, 20, 14, rgb(0xFFE0A8).opacity(0.5))
            ctx.circle(100, 20, 9, rgb(0xFFB870))
            ctx.rect(88, 18, 24, 1.4, top.opacity(0.7), radius: 0.7)
            ctx.rect(90, 22, 20, 1.4, top.opacity(0.7), radius: 0.7)
            cloud(ctx, 68, 8, 0.8, rgb(0xFCD2C4).opacity(0.95))
            cloud(ctx, 106, 30, 0.5, rgb(0xFCE0C8).opacity(0.85))
            ctx.strokePath(rgb(0x8A5E6E).opacity(0.6), width: 0.8) { p in
                p.move(to: pt(76, 24)); p.addQuadCurve(to: pt(79, 24), control: pt(77.5, 22.5))
                p.addQuadCurve(to: pt(82, 24), control: pt(80.5, 22.5))
                p.move(to: pt(84, 19)); p.addQuadCurve(to: pt(86.4, 19), control: pt(85.2, 17.8))
                p.addQuadCurve(to: pt(88.8, 19), control: pt(87.6, 17.8))
            }
        case .night:
            ctx.circle(102, 14, 12, rgb(0xFFF3C4).opacity(0.12))
            ctx.circle(102, 14, 9.5, rgb(0xFFF3C4).opacity(0.18))
            ctx.circle(102, 14, 7, rgb(0xFFF1C2))
            ctx.circle(99.5, 12, 1.6, rgb(0xEFDFA6))
            ctx.circle(104.5, 16.5, 1.2, rgb(0xEFDFA6))
            ctx.circle(105, 11.5, 0.8, rgb(0xEFDFA6))
            let stars: [(CGFloat, CGFloat, CGFloat)] = [(70, 8, 4), (84, 20, 3), (118, 6, 3.5), (114, 28, 3), (64, 18, 2.5),
                                                       (90, 6, 2.5), (76, 32, 2.5), (40, 6, 3), (12, 10, 2.5), (54, 30, 2)]
            for (x, y, s) in stars { sparkle(ctx, x, y, s, rgb(0xFFF6D0).opacity(0.9)) }
            let dots: [(CGFloat, CGFloat)] = [(80, 12), (94, 30), (122, 18), (58, 10), (26, 4), (110, 38), (68, 40)]
            for (x, y) in dots { ctx.circle(x, y, 0.5, Color.white.opacity(0.7)) }
            cloud(ctx, 108, 30, 0.5, rgb(0x5B5D8E).opacity(0.7))
        case .snow:
            ctx.circle(104, 14, 10, Color.white.opacity(0.35))
            ctx.circle(104, 14, 6.5, rgb(0xFFF4D8))
            cloud(ctx, 70, 8, 0.85, Color.white.opacity(0.9))
            cloud(ctx, 102, 24, 0.6, rgb(0xF4F7FB).opacity(0.9))
        }

        // Đồi xa
        ctx.ellipse(-30, 36, 90, 44, farHill)
        ctx.ellipse(36, 40, 70, 34, farHill)
        ctx.ellipse(84, 34, 70, 40, farHill)
        ctx.ellipse(-10, 46, 70, 24, midHill)
        ctx.ellipse(56, 45, 90, 26, midHill)

        // Hàng bụi cây xa ở đường chân trời
        let bushes: [(CGFloat, CGFloat, CGFloat)] = [(4, 54, 5), (12, 52, 6.5), (20, 54, 4.5), (56, 53, 5), (64, 51, 6.5),
                                                    (72, 53.5, 4.5), (92, 52, 6), (101, 53, 5), (110, 51, 6.5), (119, 53, 5.5)]
        for (x, y, r) in bushes { ctx.circle(x, y, r, bush) }
        for (x, y, r) in bushes { ctx.circle(x - r * 0.3, y - r * 0.4, r * 0.45, bushLight.opacity(sky == .snow ? 0.95 : 0.7)) }
        if sky == .snow {
            for (x, y, r) in bushes { ctx.ellipse(x - r * 0.8, y - r * 1.02, r * 1.6, r * 1.0, rgb(0xF6F9FC)) }
        }

        // Cỏ / tuyết
        var ground = Path()
        ground.move(to: pt(0, 57))
        ground.addQuadCurve(to: pt(125, 55.5), control: pt(62, 52.5))
        ground.addLine(to: pt(125, 100)); ground.addLine(to: pt(0, 100)); ground.closeSubpath()
        ctx.fill(ground, with: .color(grass))
        ctx.ellipse(-20, 74, 100, 40, grassLow)
        ctx.ellipse(70, 80, 90, 36, grassLow)

        // Lối đá nhỏ dẫn vào vườn
        let stones: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(60, 92, 14, 5.5), (66, 83, 11, 4.5), (70, 75.5, 9, 3.6), (73, 69.5, 7, 3)]
        for (x, y, w, h) in stones {
            ctx.ellipse(x, y + 0.8, w, h, Color.black.opacity(0.06))
            ctx.ellipse(x, y, w, h, stone)
        }

        let tufts: [(CGFloat, CGFloat, CGFloat)] = [(40, 62, 1.4), (88, 64, 1.3), (110, 60, 1.2), (50, 96, 1.8), (30, 64, 1.2),
                                                   (66, 64, 1.2), (12, 62, 1.3), (118, 66, 1.4), (44, 84, 1.5), (82, 96, 1.7)]
        for (x, y, s) in tufts { tuft(ctx, x, y, s, tuftColor) }

        switch sky {
        case .day:
            let flowers: [(CGFloat, CGFloat, UInt32)] = [(36, 66, 0xFFFFFF), (58, 60, 0xF7B6C8), (92, 61, 0xFFFFFF), (54, 88, 0xF9D86E),
                                                        (114, 63, 0xF7B6C8), (22, 60, 0xF9D86E)]
            for (x, y, c) in flowers {
                ctx.circle(x, y, 1.1, rgb(c))
                ctx.circle(x, y, 0.4, rgb(0xF2B84B))
            }
        case .sunset:
            let flowers: [(CGFloat, CGFloat)] = [(36, 66), (92, 61), (54, 88), (114, 63)]
            for (x, y) in flowers { ctx.circle(x, y, 1, rgb(0xFCE3C0)) }
        case .night:
            let flies: [(CGFloat, CGFloat)] = [(30, 44), (66, 38), (84, 48), (116, 44), (20, 70), (54, 62), (96, 72), (40, 90),
                                               (110, 86), (8, 40), (74, 58)]
            for (x, y) in flies {
                ctx.circle(x, y, 2.6, rgb(0xF6E88A).opacity(0.18))
                ctx.circle(x, y, 1.4, rgb(0xF6E88A).opacity(0.35))
                ctx.circle(x, y, 0.7, rgb(0xFFF9C8))
            }
        case .snow:
            // Gờ tuyết nhấp nhô và bông tuyết rơi
            let bumps: [(CGFloat, CGFloat, CGFloat)] = [(30, 70, 24), (96, 66, 26), (14, 88, 22), (70, 98, 30)]
            for (x, y, w) in bumps {
                ctx.ellipse(x - w / 2, y, w, 6, rgb(0xE2EAF2))
                ctx.ellipse(x - w / 2 + 1, y - 1.6, w - 2, 6, rgb(0xF9FBFD))
            }
            let flakes: [(CGFloat, CGFloat, CGFloat)] = [(8, 8, 0.9), (22, 20, 0.7), (36, 12, 1), (50, 24, 0.7), (62, 4, 0.9),
                                                        (66, 40, 0.8), (80, 32, 1), (92, 6, 0.7), (96, 44, 0.9), (112, 36, 0.8),
                                                        (120, 10, 0.9), (16, 42, 0.8), (44, 46, 0.7), (86, 58, 0.8), (108, 76, 0.9),
                                                        (28, 80, 0.8), (6, 60, 0.7), (56, 72, 0.7), (118, 54, 0.8), (74, 18, 0.6)]
            for (x, y, r) in flakes { ctx.circle(x, y, r, Color.white.opacity(0.95)) }
            sparkle(ctx, 40, 72, 3, Color.white.opacity(0.9))
            sparkle(ctx, 100, 90, 3, Color.white.opacity(0.9))
        }
    }

    // MARK: - Cây

    private static let bark = rgb(0xA87454)
    private static let barkDark = rgb(0x8C5E43)

    private static func sapling(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 44, 6)
        ctx.ellipse(32, 87, 36, 10, rgb(0xA27A5C))
        ctx.ellipse(36, 87, 28, 5, rgb(0xB58C6C))
        // Cọc đỡ và dây buộc
        ctx.rect(61, 48, 3.5, 46, rgb(0xDDB78C), radius: 1.5)
        ctx.strokePath(barkDark, width: 4) { p in
            p.move(to: pt(49, 91)); p.addQuadCurve(to: pt(50, 44), control: pt(46, 68))
        }
        ctx.strokePath(barkDark, width: 2.4) { p in
            p.move(to: pt(48.5, 66)); p.addQuadCurve(to: pt(38, 54), control: pt(42, 62))
            p.move(to: pt(49.5, 58)); p.addQuadCurve(to: pt(60, 48), control: pt(56, 56))
        }
        ctx.rect(47, 70, 17, 2.4, Palette.lavender, radius: 1.2)
        ctx.circle(62.5, 71.2, 2, Palette.lavender)
        // Tán lá nhỏ tròn
        let green = rgb(0x86C784), dark = rgb(0x70B373), light = rgb(0xA8DCA2)
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
        ctx.strokePath(dark, width: 1) { p in
            p.move(to: pt(51, 26)); p.addLine(to: pt(56, 17))
        }
        ctx.circle(48, 37, 1.4, Color.white.opacity(0.6))
    }

    private static func roundCanopy(_ ctx: GraphicsContext, _ blobs: [(CGFloat, CGFloat, CGFloat)],
                                    _ base: Color, _ dark: Color, _ light: Color) {
        for (x, y, r) in blobs { ctx.circle(x, y + 3, r, dark) }
        for (x, y, r) in blobs { ctx.circle(x, y, r, base) }
        for (x, y, r) in blobs { ctx.circle(x - r * 0.35, y - r * 0.4, r * 0.38, light.opacity(0.8)) }
    }

    private static func appleTree(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 72, 8)
        var trunk = Path()
        trunk.move(to: pt(38, 95))
        trunk.addQuadCurve(to: pt(44, 78), control: pt(44, 92))
        trunk.addLine(to: pt(45, 50)); trunk.addLine(to: pt(55, 50)); trunk.addLine(to: pt(56, 78))
        trunk.addQuadCurve(to: pt(62, 95), control: pt(56, 92))
        trunk.closeSubpath()
        ctx.fill(trunk, with: .color(bark))
        ctx.strokePath(barkDark, width: 1.4) { p in
            p.move(to: pt(52, 88)); p.addLine(to: pt(52, 66))
            p.move(to: pt(47.5, 78)); p.addLine(to: pt(47.5, 70))
        }
        ctx.strokePath(bark, width: 4) { p in
            p.move(to: pt(48, 56)); p.addLine(to: pt(36, 46))
            p.move(to: pt(53, 54)); p.addLine(to: pt(66, 44))
        }
        let blobs: [(CGFloat, CGFloat, CGFloat)] = [(28, 40, 17), (72, 40, 17), (36, 20, 16), (64, 20, 16), (50, 32, 22),
                                                   (50, 12, 13), (50, 48, 15), (16, 30, 11), (84, 30, 11)]
        roundCanopy(ctx, blobs, rgb(0x82C47F), rgb(0x6BAE6E), rgb(0xA4DB9C))
        let apples: [(CGFloat, CGFloat)] = [(28, 38), (48, 24), (68, 32), (60, 50), (38, 52), (78, 46), (40, 10), (18, 28), (84, 24)]
        for (x, y) in apples { apple(ctx, x, y, 4.4) }
        // Táo rụng trên cỏ
        apple(ctx, 72, 91, 4.2)
    }

    private static func apple(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        ctx.circle(x - r * 0.3, y, r, rgb(0xE8585A))
        ctx.circle(x + r * 0.3, y, r, rgb(0xE8585A))
        ctx.circle(x - r * 0.5, y - r * 0.35, r * 0.32, Color.white.opacity(0.6))
        ctx.strokePath(barkDark, width: 1) { p in
            p.move(to: pt(x, y - r * 0.7)); p.addLine(to: pt(x + r * 0.2, y - r * 1.4))
        }
        leaf(ctx, x + r * 0.7, y - r * 1.2, r * 0.9, r * 0.5, -20, rgb(0x6BAE6E))
    }

    private static func pineTier(_ ctx: GraphicsContext, _ top: CGFloat, _ bottom: CGFloat, _ hw: CGFloat,
                                 _ color: Color, _ shade: Color) {
        var p = Path()
        p.move(to: pt(50, top))
        p.addQuadCurve(to: pt(50 - hw, bottom), control: pt(50 - hw * 0.35, bottom - (bottom - top) * 0.3))
        p.addQuadCurve(to: pt(50 + hw, bottom), control: pt(50, bottom + 7))
        p.addQuadCurve(to: pt(50, top), control: pt(50 + hw * 0.35, bottom - (bottom - top) * 0.3))
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
        ctx.strokePath(shade, width: 2.4) { q in
            q.move(to: pt(50 - hw + 3, bottom + 0.6)); q.addQuadCurve(to: pt(50 + hw - 3, bottom + 0.6), control: pt(50, bottom + 6.4))
        }
        var hl = Path()
        hl.move(to: pt(50, top + 3))
        hl.addQuadCurve(to: pt(50 - hw * 0.55, bottom - 1), control: pt(50 - hw * 0.3, bottom - (bottom - top) * 0.3))
        hl.addQuadCurve(to: pt(50 - hw * 0.15, bottom), control: pt(50 - hw * 0.4, bottom + 1))
        hl.closeSubpath()
        ctx.fill(hl, with: .color(Color.white.opacity(0.14)))
    }

    private static func pineTree(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 58, 7)
        ctx.rect(44, 78, 12, 17, bark, radius: 2)
        ctx.rect(45, 92, 10, 3, barkDark, radius: 1)
        let base = rgb(0x67AA86), shade = rgb(0x55977A)
        pineTier(ctx, 44, 80, 36, base, shade)
        pineTier(ctx, 28, 62, 29, base, shade)
        pineTier(ctx, 14, 44, 22, base, shade)
        pineTier(ctx, 3, 27, 14, base, shade)
        // Quả thông nhỏ
        for (x, y) in [(CGFloat(30), CGFloat(84)), (66, 66), (40, 48)] {
            ctx.ellipse(x - 2, y - 1, 4, 6, rgb(0xB0805A))
            ctx.rect(x - 2, y + 0.5, 4, 0.8, rgb(0x8C5E43), radius: 0.4)
        }
        ctx.circle(44, 22, 1.4, Color.white.opacity(0.55))
    }

    private static func blossom(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        for i in 0..<5 {
            let a = Double(i) * 72.0 - 90.0
            let x = cx + r * CGFloat(cos(a * Double.pi / 180))
            let y = cy + r * CGFloat(sin(a * Double.pi / 180))
            ctx.circle(x, y, r * 0.75, color)
        }
        ctx.circle(cx, cy, r * 0.55, rgb(0xE77FA0))
    }

    private static func sakuraTree(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 72, 8)
        let trunkC = rgb(0x8E5E4E)
        ctx.strokePath(trunkC, width: 10) { p in
            p.move(to: pt(50, 92)); p.addQuadCurve(to: pt(46, 52), control: pt(54, 70))
        }
        ctx.ellipse(40, 88, 20, 7, trunkC)
        ctx.strokePath(trunkC, width: 5) { p in
            p.move(to: pt(48, 62)); p.addQuadCurve(to: pt(70, 40), control: pt(62, 58))
            p.move(to: pt(47, 56)); p.addQuadCurve(to: pt(26, 40), control: pt(34, 54))
        }
        ctx.strokePath(rgb(0x7A4E40), width: 1.4) { p in
            p.move(to: pt(51, 86)); p.addQuadCurve(to: pt(49, 66), control: pt(53, 74))
        }
        let blobs: [(CGFloat, CGFloat, CGFloat)] = [(28, 38, 16), (72, 38, 16), (36, 20, 16), (64, 20, 15), (50, 30, 20),
                                                   (50, 12, 12), (16, 30, 10), (84, 28, 11), (40, 46, 11), (62, 46, 11)]
        roundCanopy(ctx, blobs, rgb(0xF6BED0), rgb(0xEC9FB8), rgb(0xFCDDE7))
        let flowers: [(CGFloat, CGFloat)] = [(30, 36), (46, 22), (66, 30), (56, 44), (38, 46), (76, 42), (40, 10), (18, 28),
                                             (84, 24), (58, 12), (28, 18), (50, 34)]
        for (x, y) in flowers { blossom(ctx, x, y, 2.6, Color.white.opacity(0.85)) }
        // Cánh hoa rơi
        let petals: [(CGFloat, CGFloat, Double)] = [(20, 60, 20), (82, 56, -30), (30, 74, 60), (72, 70, 10), (24, 90, -20),
                                                    (78, 92, 40), (64, 88, -50), (88, 80, 30)]
        for (x, y, a) in petals { leaf(ctx, x, y, 4, 2.4, a, rgb(0xF4A9C0)) }
    }

    // MARK: - Luống hoa

    private static let stem = rgb(0x6FAE6C)
    private static let leafGreen = rgb(0x84C27C)

    private static func soilBed(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 94, 8)
        ctx.ellipse(4, 72, 92, 22, rgb(0x93694F))
        ctx.ellipse(10, 72, 80, 13, rgb(0xA97F60))
    }

    private static func bedFront(_ ctx: GraphicsContext) {
        // Viền lá phía trước che chân thân hoa
        let leaves: [(CGFloat, CGFloat, Double)] = [(14, 82, -30), (28, 86, 20), (44, 84, -15), (58, 87, 25), (72, 84, -20), (86, 82, 30)]
        for (x, y, a) in leaves { leaf(ctx, x, y, 14, 7, a, leafGreen) }
        for (x, y, _) in leaves { ctx.circle(x - 2, y - 1.4, 1, Color.white.opacity(0.35)) }
    }

    private static func daisy(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        for i in 0..<8 {
            let a = Double(i) * 45.0
            ctx.rotated(a, around: pt(cx, cy)) { c in
                c.ellipse(cx - r * 0.32, cy - r, r * 0.64, r, rgb(0xEDE7DE))
                c.ellipse(cx - r * 0.28, cy - r * 0.98, r * 0.56, r * 0.9, Color.white)
            }
        }
        ctx.circle(cx, cy, r * 0.42, rgb(0xF6C744))
        ctx.circle(cx - r * 0.14, cy - r * 0.14, r * 0.13, Color.white.opacity(0.7))
    }

    private static func daisyBed(_ ctx: GraphicsContext) {
        soilBed(ctx)
        let heads: [(CGFloat, CGFloat, CGFloat)] = [(22, 50, 11), (50, 34, 12), (78, 48, 11), (36, 64, 10), (64, 62, 10)]
        ctx.strokePath(stem, width: 3) { p in
            for (x, y, _) in heads {
                p.move(to: pt(x, y)); p.addQuadCurve(to: pt(50 + (x - 50) * 0.7, 84), control: pt(x + 2, (y + 84) / 2))
            }
        }
        leaf(ctx, 40, 66, 12, 6, -30, leafGreen)
        leaf(ctx, 62, 72, 12, 6, 30, leafGreen)
        for (x, y, r) in heads { daisy(ctx, x, y, r) }
        bedFront(ctx)
    }

    private static func tulip(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ color: Color, _ dark: Color) {
        ctx.ellipse(cx - 7 * s, cy - 6 * s, 14 * s, 16 * s, color)
        ctx.polygon([pt(cx - 7 * s, cy), pt(cx - 6 * s, cy - 11 * s), pt(cx - 2 * s, cy - 4 * s)], color)
        ctx.polygon([pt(cx + 7 * s, cy), pt(cx + 6 * s, cy - 11 * s), pt(cx + 2 * s, cy - 4 * s)], color)
        ctx.polygon([pt(cx - 3.5 * s, cy - 4 * s), pt(cx, cy - 12 * s), pt(cx + 3.5 * s, cy - 4 * s)], dark)
        ctx.ellipse(cx - 4.5 * s, cy - 3 * s, 3 * s, 7 * s, Color.white.opacity(0.4))
    }

    private static func tulipBed(_ ctx: GraphicsContext) {
        soilBed(ctx)
        let heads: [(CGFloat, CGFloat, UInt32, UInt32)] = [(18, 50, 0xEE6E6E, 0xD95757), (36, 36, 0xF7CD55, 0xE9B53A),
                                                          (54, 46, 0xF4A2BE, 0xE587A6), (72, 34, 0xEE6E6E, 0xD95757),
                                                          (86, 52, 0xF7CD55, 0xE9B53A), (44, 62, 0xF4A2BE, 0xE587A6),
                                                          (66, 60, 0xF7CD55, 0xE9B53A)]
        ctx.strokePath(stem, width: 2.8) { p in
            for (x, y, _, _) in heads {
                p.move(to: pt(x, y + 6)); p.addLine(to: pt(50 + (x - 50) * 0.8, 84))
            }
        }
        let leaves: [(CGFloat, CGFloat, Double)] = [(22, 70, -25), (40, 72, 20), (60, 72, -20), (80, 70, 25)]
        for (x, y, a) in leaves { leaf(ctx, x, y, 7, 22, a, leafGreen) }
        for (x, y, c, d) in heads { tulip(ctx, x, y, 1, rgb(c), rgb(d)) }
        bedFront(ctx)
    }

    private static func mushroom(_ ctx: GraphicsContext, _ cx: CGFloat, _ base: CGFloat, _ w: CGFloat, face: Bool) {
        let h = w * 0.62
        let stemW = w * 0.38
        let capY = base - h * 1.15
        ctx.rect(cx - stemW / 2, capY + h * 0.3, stemW, base - capY - h * 0.3, rgb(0xF8EBD6), radius: stemW * 0.4)
        ctx.ellipse(cx - stemW / 2, base - stemW * 0.25, stemW, stemW * 0.3, rgb(0xEEDCC2))
        var cap = Path()
        cap.move(to: pt(cx - w / 2, capY + h * 0.5))
        cap.addCurve(to: pt(cx + w / 2, capY + h * 0.5), control1: pt(cx - w / 2, capY - h * 0.55), control2: pt(cx + w / 2, capY - h * 0.55))
        cap.addQuadCurve(to: pt(cx - w / 2, capY + h * 0.5), control: pt(cx, capY + h * 0.8))
        cap.closeSubpath()
        ctx.fill(cap, with: .color(rgb(0xE5574F)))
        ctx.circle(cx - w * 0.2, capY + h * 0.02, w * 0.09, Color.white)
        ctx.circle(cx + w * 0.17, capY - h * 0.1, w * 0.07, Color.white)
        ctx.circle(cx + w * 0.32, capY + h * 0.3, w * 0.06, Color.white)
        ctx.circle(cx - w * 0.38, capY + h * 0.36, w * 0.05, Color.white)
        ctx.circle(cx + w * 0.02, capY + h * 0.3, w * 0.05, Color.white)
        if face {
            let fy = capY + h * 0.95
            ctx.circle(cx - stemW * 0.22, fy, w * 0.03, Palette.catInk)
            ctx.circle(cx + stemW * 0.22, fy, w * 0.03, Palette.catInk)
            ctx.ellipse(cx - stemW * 0.45, fy + w * 0.03, w * 0.07, w * 0.04, Palette.blush)
            ctx.ellipse(cx + stemW * 0.45 - w * 0.07, fy + w * 0.03, w * 0.07, w * 0.04, Palette.blush)
        }
    }

    private static func mushroomBed(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 90, 8)
        ctx.ellipse(6, 74, 88, 20, rgb(0x8BBF7C))
        ctx.ellipse(12, 74, 72, 11, rgb(0x9FCE8D))
        mushroom(ctx, 42, 86, 46, face: true)
        mushroom(ctx, 75, 86, 26, face: false)
        mushroom(ctx, 18, 87, 16, face: false)
        let blades: [(CGFloat, CGFloat, CGFloat)] = [(28, 88, 2.4), (60, 89, 2.6), (88, 86, 2.2), (10, 86, 2)]
        for (x, y, s) in blades { tuft(ctx, x, y, s, rgb(0x6FAE6C)) }
        ctx.circle(60, 79, 1.3, Color.white.opacity(0.7))
        ctx.circle(62.5, 80.5, 0.8, Color.white.opacity(0.5))
    }

    private static func sunflower(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        for i in 0..<12 {
            let a = Double(i) * 30.0
            ctx.rotated(a, around: pt(cx, cy)) { c in
                c.ellipse(cx - r * 0.28, cy - r * 1.05, r * 0.56, r * 0.75, rgb(0xF2B530))
            }
        }
        for i in 0..<12 {
            let a = Double(i) * 30.0 + 15.0
            ctx.rotated(a, around: pt(cx, cy)) { c in
                c.ellipse(cx - r * 0.26, cy - r * 0.98, r * 0.52, r * 0.7, rgb(0xFAD04A))
            }
        }
        ctx.circle(cx, cy, r * 0.5, rgb(0x8B5A3C))
        ctx.circle(cx + r * 0.06, cy + r * 0.04, r * 0.36, rgb(0x6F4430))
        for (dx, dy) in [(CGFloat(-0.2), CGFloat(-0.15)), (0.18, -0.2), (0.24, 0.14), (-0.1, 0.22), (0.02, 0.0)] {
            ctx.circle(cx + r * dx, cy + r * dy, r * 0.05, rgb(0xA87454))
        }
        ctx.circle(cx - r * 0.22, cy - r * 0.25, r * 0.09, Color.white.opacity(0.5))
    }

    private static func sunflowerBed(_ ctx: GraphicsContext) {
        soilBed(ctx)
        let heads: [(CGFloat, CGFloat, CGFloat)] = [(24, 34, 13), (56, 18, 15), (80, 42, 12)]
        ctx.strokePath(stem, width: 4) { p in
            for (x, y, _) in heads {
                p.move(to: pt(x, y)); p.addQuadCurve(to: pt(50 + (x - 50) * 0.6, 84), control: pt(x - 3, (y + 84) / 2))
            }
        }
        let leaves: [(CGFloat, CGFloat, Double)] = [(34, 58, -35), (16, 66, 30), (64, 44, 35), (48, 62, -30), (70, 62, 30), (88, 66, -30)]
        for (x, y, a) in leaves { leaf(ctx, x, y, 16, 8, a, leafGreen) }
        for (x, y, r) in heads { sunflower(ctx, x, y, r) }
        bedFront(ctx)
    }

    // MARK: - Chỗ ngồi

    private static func stump(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 92, 72, 9)
        ctx.ellipse(14, 80, 26, 12, bark)
        ctx.ellipse(60, 80, 26, 12, bark)
        ctx.ellipse(40, 84, 20, 10, barkDark)
        ctx.rect(24, 52, 52, 36, bark, radius: 8)
        ctx.strokePath(barkDark, width: 2) { p in
            p.move(to: pt(34, 62)); p.addLine(to: pt(34, 82))
            p.move(to: pt(48, 66)); p.addLine(to: pt(48, 86))
            p.move(to: pt(63, 60)); p.addLine(to: pt(63, 80))
        }
        ctx.ellipse(22, 44, 56, 18, rgb(0xEACB9F))
        ctx.strokePath(rgb(0xCDA67A), width: 1.4) { p in
            p.addEllipse(in: CGRect(x: 30, y: 47, width: 40, height: 12))
            p.addEllipse(in: CGRect(x: 38, y: 50, width: 24, height: 6.5))
        }
        ctx.circle(50, 53, 1.4, rgb(0xCDA67A))
        ctx.ellipse(28, 46, 10, 3.5, Color.white.opacity(0.45))
        // Mầm non mọc bên cạnh
        ctx.strokePath(stem, width: 1.6) { p in
            p.move(to: pt(76, 66)); p.addQuadCurve(to: pt(84, 54), control: pt(84, 62))
        }
        leaf(ctx, 86, 52, 8, 4.5, -30, leafGreen)
        leaf(ctx, 80, 57, 7, 4, 30, leafGreen)
        mushroom(ctx, 20, 90, 14, face: false)
    }

    private static func bench(_ ctx: GraphicsContext) {
        let wood = Palette.wood, dark = Palette.woodDark
        shadow(ctx, 50, 93, 88, 8)
        // Chân sau và trụ tựa
        ctx.rect(18, 28, 7, 62, dark, radius: 2)
        ctx.rect(75, 28, 7, 62, dark, radius: 2)
        // Thanh tựa lưng
        ctx.rect(10, 30, 80, 9, wood, radius: 4)
        ctx.rect(10, 43, 80, 9, wood, radius: 4)
        ctx.rect(14, 31.5, 72, 2, Color.white.opacity(0.35), radius: 1)
        ctx.heart(center: pt(50, 35), size: 6, Palette.blush)
        // Mặt ghế
        ctx.rect(6, 60, 88, 10, wood, radius: 4)
        ctx.rect(6, 67, 88, 4, dark, radius: 2)
        ctx.rect(10, 61.5, 80, 2, Color.white.opacity(0.35), radius: 1)
        // Chân trước
        ctx.rect(12, 70, 7, 22, dark, radius: 2)
        ctx.rect(81, 70, 7, 22, dark, radius: 2)
        // Tay vịn
        ctx.strokePath(dark, width: 4) { p in
            p.move(to: pt(10, 60)); p.addQuadCurve(to: pt(6, 46), control: pt(4, 54))
            p.move(to: pt(90, 60)); p.addQuadCurve(to: pt(94, 46), control: pt(96, 54))
        }
    }

    private static func swing(_ ctx: GraphicsContext) {
        let wood = Palette.wood, dark = Palette.woodDark
        shadow(ctx, 50, 92, 92, 8)
        shadow(ctx, 50, 86, 40, 5)
        // Khung chữ A hai bên
        ctx.strokePath(dark, width: 5) { p in
            p.move(to: pt(8, 92)); p.addLine(to: pt(18, 10))
            p.move(to: pt(28, 92)); p.addLine(to: pt(18, 10))
            p.move(to: pt(72, 92)); p.addLine(to: pt(82, 10))
            p.move(to: pt(92, 92)); p.addLine(to: pt(82, 10))
        }
        ctx.rect(10, 6, 80, 8, wood, radius: 4)
        ctx.rect(14, 7.5, 72, 2, Color.white.opacity(0.35), radius: 1)
        // Dây và ván ngồi
        let rope = rgb(0xEADBBE)
        ctx.strokePath(rope, width: 1.8) { p in
            p.move(to: pt(34, 14)); p.addLine(to: pt(34, 68))
            p.move(to: pt(66, 14)); p.addLine(to: pt(66, 68))
        }
        ctx.rect(26, 66, 48, 8, Palette.peach, radius: 4)
        ctx.rect(30, 67.5, 40, 2, Color.white.opacity(0.4), radius: 1)
        // Dây leo hoa nhỏ
        let buds: [(CGFloat, CGFloat, UInt32)] = [(34, 24, 0xF7B6C8), (34, 38, 0xFFFFFF), (34, 52, 0xF7B6C8),
                                                 (66, 30, 0xFFFFFF), (66, 44, 0xF7B6C8), (66, 58, 0xFFFFFF)]
        for (x, y, c) in buds {
            leaf(ctx, x - 2.5, y + 3, 5, 2.6, 30, leafGreen)
            leaf(ctx, x + 2.5, y - 3, 5, 2.6, -30, leafGreen)
            ctx.circle(x, y, 2.2, rgb(c))
            ctx.circle(x, y, 0.8, rgb(0xF2B84B))
        }
    }

    private static func hammock(_ ctx: GraphicsContext) {
        let dark = Palette.woodDark
        shadow(ctx, 50, 92, 94, 8)
        shadow(ctx, 50, 86, 50, 5)
        ctx.rect(6, 24, 8, 70, dark, radius: 3)
        ctx.rect(86, 24, 8, 70, dark, radius: 3)
        ctx.circle(10, 24, 4.5, dark)
        ctx.circle(90, 24, 4.5, dark)
        let rope = rgb(0xEADBBE)
        ctx.strokePath(rope, width: 1.6) { p in
            p.move(to: pt(12, 32)); p.addLine(to: pt(22, 50))
            p.move(to: pt(12, 32)); p.addLine(to: pt(20, 54))
            p.move(to: pt(88, 32)); p.addLine(to: pt(78, 50))
            p.move(to: pt(88, 32)); p.addLine(to: pt(80, 54))
        }
        var fabric = Path()
        fabric.move(to: pt(20, 50))
        fabric.addQuadCurve(to: pt(80, 50), control: pt(50, 60))
        fabric.addQuadCurve(to: pt(20, 50), control: pt(50, 98))
        fabric.closeSubpath()
        var c = ctx
        c.clip(to: fabric)
        c.fill(fabric, with: .color(rgb(0xF4B6A4)))
        for x in stride(from: CGFloat(22), to: 80, by: 12) {
            c.rect(x, 40, 5, 50, rgb(0xFCEBD9))
        }
        c.ellipse(16, 46, 70, 16, Color.black.opacity(0.06))
        // Gối nhỏ
        ctx.rotated(-12, around: pt(32, 56)) { g in
            g.ellipse(22, 51, 20, 10, Palette.lavenderSoft)
            g.ellipse(25, 52.5, 8, 3, Color.white.opacity(0.6))
        }
        // Tua rua viền dưới
        ctx.strokePath(rgb(0xE59A88), width: 1) { p in
            for x in stride(from: CGFloat(34), to: 68, by: 5) {
                let dy = 73 - abs(x - 50) * 0.4
                p.move(to: pt(x, dy)); p.addLine(to: pt(x, dy + 4))
            }
        }
    }

    // MARK: - Hồ nước

    private static let water = rgb(0x93D0E6)
    private static let waterDeep = rgb(0x7FC2DB)

    /// Hồ bầu dục có viền đá; trả về hình mặt nước để cắt.
    private static func stonePond(_ ctx: GraphicsContext, _ waterColor: Color) -> Path {
        shadow(ctx, 50, 86, 96, 12)
        let cx: CGFloat = 50, cy: CGFloat = 70, rx: CGFloat = 42, ry: CGFloat = 17
        for i in 0..<16 {
            let a = Double(i) * 22.5 * Double.pi / 180
            let x = cx + (rx + 1) * CGFloat(cos(a))
            let y = cy + (ry + 1) * CGFloat(sin(a))
            let color = i % 2 == 0 ? rgb(0xCBC6BF) : rgb(0xB9B4AD)
            ctx.ellipse(x - 7, y - 4.5, 14, 9, color)
            ctx.ellipse(x - 4.5, y - 4, 6, 2.6, Color.white.opacity(0.4))
        }
        let surface = Path(ellipseIn: CGRect(x: cx - rx + 2, y: cy - ry + 1, width: (rx - 2) * 2, height: (ry - 1) * 2))
        ctx.fill(surface, with: .color(waterColor))
        var c = ctx
        c.clip(to: surface)
        c.ellipse(cx - rx, cy - ry - 4, rx * 2, ry * 0.9, Color.black.opacity(0.08))
        c.ellipse(cx - rx * 0.4, cy + 2, rx * 1.1, ry * 0.9, Color.white.opacity(0.15))
        return surface
    }

    private static func ripple(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat) {
        ctx.strokePath(Color.white.opacity(0.6), width: 1) { p in
            p.addEllipse(in: CGRect(x: x - w / 2, y: y - w * 0.15, width: w, height: w * 0.3))
        }
    }

    private static func puddle(_ ctx: GraphicsContext) {
        shadow(ctx, 44, 86, 86, 10)
        let blobs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(4, 64, 52, 24), (30, 60, 46, 28), (14, 72, 58, 18)]
        for (x, y, w, h) in blobs { ctx.ellipse(x - 1.5, y - 1, w + 3, h + 3, rgb(0x7EB6CE)) }
        for (x, y, w, h) in blobs { ctx.ellipse(x, y, w, h, rgb(0xA6D8EC)) }
        ctx.ellipse(16, 66, 30, 6, Color.white.opacity(0.4))
        ctx.ellipse(52, 78, 12, 3, Color.white.opacity(0.35))
        ripple(ctx, 36, 74, 16)
        ripple(ctx, 36, 74, 7)
        ripple(ctx, 58, 68, 9)
        // Giọt mưa đang rơi
        for (x, y) in [(CGFloat(26), CGFloat(44)), (46, 36), (62, 48), (14, 54)] {
            var d = Path()
            d.move(to: pt(x, y - 4))
            d.addQuadCurve(to: pt(x, y + 2.4), control: pt(x + 3.2, y + 1))
            d.addQuadCurve(to: pt(x, y - 4), control: pt(x - 3.2, y + 1))
            ctx.fill(d, with: .color(rgb(0x8CCBE4)))
        }
        // Đôi ủng vàng
        shadow(ctx, 84, 85, 24, 5)
        for bx in [CGFloat(74), 84] {
            ctx.rect(bx, 60, 8.5, 22, rgb(0xF6C64A), radius: 3)
            ctx.rect(bx, 76, 13, 7, rgb(0xF6C64A), radius: 3.5)
            ctx.rect(bx - 0.5, 59, 9.5, 3.5, rgb(0xE9AE30), radius: 1.5)
            ctx.rect(bx + 0.5, 81, 12, 2, rgb(0xE9AE30), radius: 1)
            ctx.rect(bx + 1.6, 64, 2, 9, Color.white.opacity(0.5), radius: 1)
        }
    }

    private static func lilyPad(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ notch: Color) {
        ctx.ellipse(x, y, w, h, rgb(0x79BC76))
        ctx.ellipse(x + w * 0.12, y + h * 0.1, w * 0.6, h * 0.45, rgb(0x8ECB86))
        let cx = x + w / 2, cy = y + h / 2
        ctx.polygon([pt(cx, cy), pt(cx + w * 0.45, cy - h * 0.12), pt(cx + w * 0.45, cy + h * 0.2)], notch)
    }

    private static func lilyPond(_ ctx: GraphicsContext) {
        _ = stonePond(ctx, water)
        lilyPad(ctx, 14, 62, 24, 10, water)
        lilyPad(ctx, 62, 74, 18, 8, water)
        lilyPad(ctx, 30, 74, 14, 6, water)
        // Hoa súng hồng
        for i in 0..<6 {
            let a = Double(i) * 60.0
            ctx.rotated(a, around: pt(26, 64)) { c in
                c.ellipse(24, 57, 4, 7, rgb(0xF6A9C3))
            }
        }
        ctx.circle(26, 64, 2.4, rgb(0xFBE07A))
        ripple(ctx, 46, 70, 12)
        // Ếch ngồi trên lá
        frog(ctx, 70, 76)
    }

    private static func frog(_ ctx: GraphicsContext, _ cx: CGFloat, _ bottom: CGFloat) {
        let body = rgb(0x8FD07A), dark = rgb(0x76BB66)
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
        ctx.strokePath(Palette.catInk, width: 0.8) { p in
            p.move(to: pt(cx - 2, bottom - 11.6)); p.addQuadCurve(to: pt(cx + 2, bottom - 11.6), control: pt(cx, bottom - 10))
        }
    }

    private static func koi(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ angle: Double, _ base: Color, _ patch: Color) {
        ctx.rotated(angle, around: pt(cx, cy)) { c in
            c.polygon([pt(cx - 7, cy), pt(cx - 13, cy - 4), pt(cx - 12, cy), pt(cx - 13, cy + 4)], patch)
            c.ellipse(cx - 9, cy - 3.6, 18, 7.2, base)
            c.ellipse(cx - 2, cy - 3.4, 6, 4, patch)
            c.ellipse(cx + 4, cy - 1.4, 4, 3.6, patch)
            leaf(c, cx - 1, cy + 4, 5, 2.2, 30, base.opacity(0.9))
            leaf(c, cx - 1, cy - 4, 5, 2.2, -30, base.opacity(0.9))
            c.circle(cx + 6.5, cy - 1, 0.7, Palette.catInk)
        }
    }

    private static func koiPond(_ ctx: GraphicsContext) {
        _ = stonePond(ctx, waterDeep)
        let white = rgb(0xFFFBF5), red = rgb(0xF0674A)
        koi(ctx, 36, 68, -12, white, red)
        koi(ctx, 62, 74, 168, red, white)
        lilyPad(ctx, 66, 60, 16, 7, waterDeep)
        ripple(ctx, 48, 66, 10)
        ripple(ctx, 24, 76, 8)
        ctx.circle(46, 60, 0.9, Color.white.opacity(0.7))
        ctx.circle(48, 58, 0.6, Color.white.opacity(0.6))
    }

    private static func fountain(_ ctx: GraphicsContext) {
        let stoneC = rgb(0xDCD6CD), stoneDark = rgb(0xC6BFB4), stoneLight = rgb(0xEDE9E2)
        shadow(ctx, 50, 91, 94, 9)
        // Bồn dưới
        ctx.rect(8, 66, 84, 22, stoneC, radius: 10)
        ctx.rect(8, 80, 84, 8, stoneDark, radius: 6)
        ctx.ellipse(5, 59, 90, 15, stoneLight)
        ctx.ellipse(11, 61.5, 78, 9.5, water)
        ctx.ellipse(18, 62.5, 34, 3, Color.white.opacity(0.35))
        // Trụ và bồn trên
        ctx.rect(44, 36, 12, 28, stoneC, radius: 3)
        ctx.rect(41, 60, 18, 4, stoneDark, radius: 2)
        var bowl = Path()
        bowl.move(to: pt(27, 31))
        bowl.addQuadCurve(to: pt(73, 31), control: pt(50, 48))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(stoneC))
        ctx.ellipse(27, 27, 46, 8, stoneLight)
        ctx.ellipse(31, 28.2, 38, 5, water)
        // Tia nước
        let jet = rgb(0xBFE6F5)
        ctx.strokePath(jet, width: 3) { p in
            p.move(to: pt(50, 29)); p.addLine(to: pt(50, 10))
        }
        ctx.strokePath(jet, width: 2) { p in
            p.move(to: pt(50, 10)); p.addQuadCurve(to: pt(34, 28), control: pt(38, 6))
            p.move(to: pt(50, 10)); p.addQuadCurve(to: pt(66, 28), control: pt(62, 6))
            p.move(to: pt(28, 31)); p.addQuadCurve(to: pt(18, 62), control: pt(18, 38))
            p.move(to: pt(72, 31)); p.addQuadCurve(to: pt(82, 62), control: pt(82, 38))
        }
        ctx.circle(50, 9, 2.6, jet)
        let drops: [(CGFloat, CGFloat)] = [(42, 4), (58, 4), (30, 20), (70, 20), (14, 48), (86, 48), (22, 56), (78, 56)]
        for (x, y) in drops { ctx.circle(x, y, 1.3, jet) }
        ctx.circle(49, 8, 0.9, Color.white.opacity(0.8))
        ripple(ctx, 18, 64, 8)
        ripple(ctx, 82, 64, 8)
        // Hoa văn trên bồn
        for x in stride(from: CGFloat(20), to: 90, by: 15) {
            ctx.circle(x, 73, 1.6, stoneDark)
        }
    }

    // MARK: - Trang trí

    private static func fence(_ ctx: GraphicsContext) {
        let white = rgb(0xFBF7F0), shade = rgb(0xE8DFD2)
        shadow(ctx, 50, 92, 98, 7)
        ctx.rect(0, 46, 97, 6, shade, radius: 2)
        ctx.rect(0, 72, 97, 6, shade, radius: 2)
        for x in stride(from: CGFloat(3), to: 92, by: 15) {
            ctx.polygon([pt(x, 36), pt(x + 5.5, 27), pt(x + 11, 36)], white)
            ctx.rect(x, 34, 11, 57, white, radius: 2)
            ctx.rect(x, 82, 11, 9, shade, radius: 2)
            ctx.rect(x + 2, 38, 2, 30, Color.white.opacity(0.9), radius: 1)
        }
        // Dây leo hoa nhỏ trên rào
        ctx.strokePath(stem, width: 1.4) { p in
            p.move(to: pt(4, 50)); p.addQuadCurve(to: pt(40, 50), control: pt(22, 58))
            p.addQuadCurve(to: pt(72, 48), control: pt(56, 42))
        }
        let buds: [(CGFloat, CGFloat, UInt32)] = [(12, 53, 0xF7B6C8), (28, 54, 0xF9D86E), (46, 48, 0xF7B6C8), (62, 46, 0xF9D86E)]
        for (x, y, c) in buds {
            leaf(ctx, x + 3.5, y + 2, 6, 3, 30, leafGreen)
            ctx.circle(x, y, 2.6, rgb(c))
            ctx.circle(x, y, 0.9, rgb(0xFFF6E0))
        }
        tuft(ctx, 20, 92, 2.6, stem)
        tuft(ctx, 66, 92, 2.6, stem)
    }

    private static func mailbox(_ ctx: GraphicsContext) {
        let blue = rgb(0x9CC6EB), blueDark = rgb(0x7FAFD9)
        shadow(ctx, 50, 93, 40, 7)
        ctx.rect(44, 54, 12, 40, Palette.woodDark, radius: 2)
        ctx.rect(46, 56, 2.5, 34, Color.white.opacity(0.2), radius: 1)
        // Thân hộp thư
        ctx.rect(18, 26, 64, 32, blue, radius: 14)
        ctx.rect(18, 40, 64, 18, blue, radius: 3)
        ctx.rect(14, 26, 12, 32, blueDark, radius: 6)
        ctx.rect(14, 40, 12, 18, blueDark, radius: 2)
        ctx.rect(30, 30, 40, 3, Color.white.opacity(0.45), radius: 1.5)
        ctx.heart(center: pt(52, 45), size: 9, Palette.blush)
        // Lá thư thò ra
        ctx.rotated(-14, around: pt(14, 40)) { c in
            c.rect(6, 34, 16, 11, rgb(0xFFFDF8), radius: 1.5)
            c.strokePath(rgb(0xE3D6C4), width: 0.9) { p in
                p.move(to: pt(6.5, 34.5)); p.addLine(to: pt(14, 40)); p.addLine(to: pt(21.5, 34.5))
            }
            c.heart(center: pt(14, 41), size: 4, rgb(0xE8585A))
        }
        // Cờ đỏ dựng lên
        ctx.rect(78, 18, 3.5, 30, rgb(0xE8585A), radius: 1.5)
        ctx.rect(78, 16, 14, 9, rgb(0xE8585A), radius: 2)
        ctx.circle(79.7, 46, 2.4, rgb(0xC8463F))
        // Hoa dưới chân cột
        tuft(ctx, 40, 93, 2.6, stem)
        tuft(ctx, 60, 93, 2.6, stem)
        ctx.circle(36, 86, 2.4, rgb(0xFFFFFF))
        ctx.circle(36, 86, 0.9, rgb(0xF2B84B))
        ctx.circle(64, 87, 2.4, rgb(0xF7B6C8))
        ctx.circle(64, 87, 0.9, rgb(0xF2B84B))
    }

    private static func birdhouse(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 36, 7)
        ctx.rect(45, 58, 10, 36, Palette.woodDark, radius: 2)
        // Thân nhà
        ctx.rect(28, 32, 44, 30, rgb(0xF6E3C6), radius: 4)
        ctx.rect(28, 56, 44, 6, rgb(0xEACFAC), radius: 3)
        // Mái
        let roof = rgb(0xE08070)
        ctx.polygon([pt(22, 36), pt(50, 14), pt(78, 36)], roof)
        ctx.strokePath(roof, width: 5) { p in
            p.move(to: pt(22, 36)); p.addLine(to: pt(50, 14)); p.addLine(to: pt(78, 36))
        }
        ctx.strokePath(Color.white.opacity(0.35), width: 1.4) { p in
            p.move(to: pt(28, 33)); p.addLine(to: pt(48, 18))
        }
        // Lỗ tròn và que đậu
        ctx.circle(50, 44, 6, rgb(0x5E4A3E))
        ctx.rect(46, 53, 8, 2.6, Palette.woodDark, radius: 1.3)
        ctx.heart(center: pt(36, 50), size: 5, Palette.blush)
        // Chim vàng đậu trên mái
        let yellow = rgb(0xF8D45C), yDark = rgb(0xEDBB3C)
        ctx.ellipse(56, 4, 20, 15, yellow)
        ctx.polygon([pt(57, 12), pt(50, 9), pt(54, 15)], yDark)
        leaf(ctx, 64, 13, 10, 6, -15, yDark)
        ctx.polygon([pt(75, 9), pt(80, 10.5), pt(75, 12)], rgb(0xF29A4A))
        ctx.circle(71, 8.5, 1.3, Palette.catInk)
        ctx.ellipse(68.5, 11, 3.6, 2, Palette.blush)
        ctx.circle(62, 7, 1.4, Color.white.opacity(0.6))
        ctx.strokePath(rgb(0xF29A4A), width: 1) { p in
            p.move(to: pt(63, 18.5)); p.addLine(to: pt(63, 21))
            p.move(to: pt(68, 18.5)); p.addLine(to: pt(68, 21))
        }
    }

    private static func lantern(_ ctx: GraphicsContext) {
        let iron = rgb(0x6E5E62)
        shadow(ctx, 40, 93, 34, 6)
        // Quầng sáng dịu
        ctx.circle(62, 46, 26, rgb(0xFFDE8E).opacity(0.18))
        ctx.circle(62, 46, 19, rgb(0xFFDE8E).opacity(0.25))
        // Cột móc
        ctx.strokePath(iron, width: 3.5) { p in
            p.move(to: pt(36, 93)); p.addLine(to: pt(36, 18))
            p.addQuadCurve(to: pt(62, 16), control: pt(48, 6))
            p.addLine(to: pt(62, 26))
        }
        ctx.rect(32, 89, 8, 5, iron, radius: 2)
        // Đèn lồng giấy
        ctx.rect(54, 25, 16, 5, iron, radius: 2)
        ctx.ellipse(46, 27, 32, 36, rgb(0xF29A80))
        ctx.ellipse(52, 33, 20, 24, rgb(0xFFD7A0).opacity(0.65))
        ctx.strokePath(rgb(0xDE7E66), width: 1.1) { p in
            p.move(to: pt(62, 27.5)); p.addLine(to: pt(62, 62.5))
            p.move(to: pt(54, 29)); p.addQuadCurve(to: pt(54, 61), control: pt(48, 45))
            p.move(to: pt(70, 29)); p.addQuadCurve(to: pt(70, 61), control: pt(76, 45))
        }
        ctx.rect(54, 60, 16, 5, iron, radius: 2)
        ctx.ellipse(50, 33, 5, 10, Color.white.opacity(0.45))
        // Tua đèn
        ctx.strokePath(rgb(0xE8585A), width: 1.4) { p in
            p.move(to: pt(62, 65)); p.addLine(to: pt(62, 74))
            p.move(to: pt(60, 68)); p.addLine(to: pt(60, 74))
            p.move(to: pt(64, 68)); p.addLine(to: pt(64, 74))
        }
        ctx.circle(62, 66, 1.8, rgb(0xE8585A))
        sparkle(ctx, 80, 28, 5, rgb(0xFFE6A0))
        sparkle(ctx, 44, 54, 4, rgb(0xFFE6A0))
        // Hoa dưới chân cột
        tuft(ctx, 28, 93, 2.6, stem)
        tuft(ctx, 46, 93, 2.6, stem)
        ctx.circle(26, 86, 2.4, rgb(0xF7B6C8))
        ctx.circle(26, 86, 0.9, rgb(0xF2B84B))
    }

    private static func tent(_ ctx: GraphicsContext) {
        let body = rgb(0xF5B48A), side = rgb(0xE79C76), inside = rgb(0x6B5165)
        shadow(ctx, 50, 91, 96, 9)
        // Dây néo và cọc
        ctx.strokePath(rgb(0xD8C7A8), width: 1) { p in
            p.move(to: pt(22, 62)); p.addLine(to: pt(4, 90))
            p.move(to: pt(78, 62)); p.addLine(to: pt(95, 90))
        }
        ctx.rect(2.5, 87, 3, 5, Palette.woodDark, radius: 1)
        ctx.rect(93.5, 87, 3, 5, Palette.woodDark, radius: 1)
        // Thân lều
        ctx.polygon([pt(8, 90), pt(50, 20), pt(92, 90)], body)
        ctx.polygon([pt(50, 20), pt(92, 90), pt(72, 90)], side)
        // Viền sọc
        ctx.strokePath(rgb(0xFCE3CF), width: 2.6) { p in
            p.move(to: pt(14, 82)); p.addLine(to: pt(86, 82))
        }
        // Cửa lều mở
        ctx.polygon([pt(34, 90), pt(50, 46), pt(66, 90)], inside)
        ctx.circle(50, 78, 6, rgb(0xFFDE8E).opacity(0.35))
        ctx.circle(50, 78, 2.4, rgb(0xFFE6A0))
        ctx.polygon([pt(50, 46), pt(34, 90), pt(30, 90), pt(38, 66)], rgb(0xFCE3CF))
        ctx.polygon([pt(50, 46), pt(66, 90), pt(70, 90), pt(62, 66)], rgb(0xF2D2BA))
        ctx.circle(38, 66, 1.8, Palette.lavender)
        ctx.circle(62, 66, 1.8, Palette.lavender)
        ctx.strokePath(Color.white.opacity(0.4), width: 1.6) { p in
            p.move(to: pt(46, 28)); p.addLine(to: pt(24, 66))
        }
        // Cột và cờ đuôi nheo
        ctx.strokePath(Palette.woodDark, width: 1.6) { p in
            p.move(to: pt(50, 22)); p.addLine(to: pt(50, 6))
        }
        ctx.polygon([pt(50, 6), pt(63, 9.5), pt(50, 13)], Palette.lavender)
        ctx.circle(50, 5.5, 1.4, Palette.honey)
    }
}
