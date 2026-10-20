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
        // Đồ thêm
        case "gardenTheme.rainbow": scene(ctx, .rainbow)
        case "gardenTheme.autumn": scene(ctx, .autumn)
        case "gardenTheme.aurora": scene(ctx, .aurora)
        case "tree.palm": palmTree(ctx)
        case "tree.maple": mapleTree(ctx)
        case "tree.willow": willowTree(ctx)
        case "flowerBed.veggie": veggieBed(ctx)
        case "flowerBed.lavender": lavenderBed(ctx)
        case "flowerBed.strawberry": strawberryBed(ctx)
        case "gardenSeat.picnic": picnic(ctx)
        case "gardenSeat.parasol": parasolChair(ctx)
        case "gardenSeat.mushroom": mushroomTable(ctx)
        case "pond.duck": duckPond(ctx)
        case "pond.bridge": bridgePond(ctx)
        case "pond.well": wishingWell(ctx)
        case "gardenDeco.windmill": windmill(ctx)
        case "gardenDeco.gnome": gnome(ctx)
        case "gardenDeco.scarecrow": scarecrow(ctx)
        case "gardenDeco.beehive": beehive(ctx)
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

    private enum Sky { case day, sunset, night, snow, rainbow, autumn, aurora }

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
        case .rainbow:
            top = rgb(0xA6D8F0); mid = rgb(0xC0E4F4); low = rgb(0xE2F3F9)
            grass = rgb(0xB2DE9C); grassLow = rgb(0xA2D48E)
        case .autumn:
            top = rgb(0xBFDCEB); mid = rgb(0xDCE8E4); low = rgb(0xF6E8CC)
            farHill = rgb(0xEBC08A); midHill = rgb(0xE0A870); bush = rgb(0xD9824F); bushLight = rgb(0xF0B06A)
            grass = rgb(0xE6CF8E); grassLow = rgb(0xDBC27E); tuftColor = rgb(0xC9A562); stone = rgb(0xEFE6D4)
        case .aurora:
            top = rgb(0x1F2550); mid = rgb(0x2A3462); low = rgb(0x354474)
            farHill = rgb(0x33476A); midHill = rgb(0x2F5560); bush = rgb(0x284C4C); bushLight = rgb(0x35605A)
            grass = rgb(0x416C58); grassLow = rgb(0x3A6450); tuftColor = rgb(0x568669); stone = rgb(0x687C82)
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
        case .rainbow:
            let bands: [UInt32] = [0xF4A0A0, 0xF8C58A, 0xF6E08A, 0xA8DA9C, 0x9CC8EE, 0xB9A6EA]
            for (i, c) in bands.enumerated() {
                ctx.strokePath(rgb(c).opacity(0.75), width: 3.2) { p in
                    p.addArc(center: pt(78, 62), radius: 46 - CGFloat(i) * 3.1, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                }
            }
            ctx.circle(112, 12, 6, rgb(0xFFD66B))
            ctx.circle(112, 12, 9, rgb(0xFFF2B8).opacity(0.4))
            cloud(ctx, 22, 38, 0.8, Color.white.opacity(0.95))
            cloud(ctx, 104, 34, 0.75, Color.white.opacity(0.95))
            cloud(ctx, 40, 8, 0.5, Color.white.opacity(0.8))
        case .autumn:
            ctx.circle(100, 16, 11, rgb(0xFFF0C8).opacity(0.5))
            ctx.circle(100, 16, 7, rgb(0xFFCF7A))
            cloud(ctx, 64, 10, 0.75, Color.white.opacity(0.9))
            cloud(ctx, 104, 28, 0.5, Color.white.opacity(0.8))
            // đàn chim bay về nam
            ctx.strokePath(rgb(0x7A6A6E).opacity(0.6), width: 0.8) { p in
                for (x, y) in [(CGFloat(30), CGFloat(14)), (36, 18), (24, 18), (42, 22), (18, 22)] {
                    p.move(to: pt(x - 1.6, y)); p.addQuadCurve(to: pt(x, y), control: pt(x - 0.8, y - 1.2))
                    p.addQuadCurve(to: pt(x + 1.6, y), control: pt(x + 0.8, y - 1.2))
                }
            }
        case .aurora:
            // dải cực quang uốn lượn
            let ribbons: [(CGFloat, UInt32, CGFloat)] = [(16, 0x8EF0C0, 7), (24, 0xA9E8D8, 5), (30, 0xC79BF0, 6)]
            for (y, c, w) in ribbons {
                ctx.strokePath(rgb(c).opacity(0.28), width: w * 2.2) { p in
                    p.move(to: pt(-4, y + 8)); p.addCurve(to: pt(130, y - 4), control1: pt(36, y - 18), control2: pt(80, y + 22))
                }
                ctx.strokePath(rgb(c).opacity(0.45), width: w) { p in
                    p.move(to: pt(-4, y + 8)); p.addCurve(to: pt(130, y - 4), control1: pt(36, y - 18), control2: pt(80, y + 22))
                }
            }
            let stars: [(CGFloat, CGFloat, CGFloat)] = [(12, 6, 3), (52, 4, 2.5), (90, 8, 3), (118, 34, 2.5), (8, 40, 2.5), (66, 42, 2)]
            for (x, y, s) in stars { sparkle(ctx, x, y, s, rgb(0xFFF6D0).opacity(0.9)) }
            let dots: [(CGFloat, CGFloat)] = [(30, 4), (74, 6), (104, 4), (40, 44), (96, 40), (122, 14)]
            for (x, y) in dots { ctx.circle(x, y, 0.5, Color.white.opacity(0.75)) }
            ctx.circle(110, 12, 4, rgb(0xFFF1C2))
            ctx.circle(112, 10.6, 3.4, top)
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
        case .rainbow:
            // vũng nước sau mưa và hoa còn đọng giọt
            ctx.ellipse(86, 70, 16, 4, rgb(0xA6D8EC))
            ctx.ellipse(89, 70.6, 7, 1.4, Color.white.opacity(0.6))
            ctx.ellipse(28, 88, 14, 3.4, rgb(0xA6D8EC))
            let flowers: [(CGFloat, CGFloat, UInt32)] = [(36, 66, 0xFFFFFF), (58, 60, 0xF7B6C8), (92, 61, 0xF9D86E), (114, 63, 0xB9A6EA),
                                                        (22, 60, 0xF7B6C8), (54, 88, 0xFFFFFF)]
            for (x, y, c) in flowers {
                ctx.circle(x, y, 1.1, rgb(c))
                ctx.circle(x, y, 0.4, rgb(0xF2B84B))
                ctx.circle(x + 1.6, y - 1.4, 0.45, rgb(0xCDEBF7))
            }
        case .autumn:
            let leaves: [(CGFloat, CGFloat, Double, UInt32)] = [(20, 40, 20, 0xE8685A), (48, 34, -30, 0xF29A55), (70, 46, 40, 0xF6C255),
                                                               (110, 44, -10, 0xE8685A), (36, 66, 30, 0xF29A55), (96, 76, -40, 0xF6C255),
                                                               (14, 82, 10, 0xE8685A), (60, 92, 50, 0xF29A55), (116, 90, -20, 0xE8685A)]
            for (x, y, a, c) in leaves { mapleLeaf(ctx, x, y, 2, a, rgb(c)) }
            ctx.ellipse(100, 84, 18, 5, rgb(0xEFA25A).opacity(0.8))
            ctx.ellipse(104, 83, 8, 3, rgb(0xF6C255).opacity(0.8))
        case .aurora:
            let flies: [(CGFloat, CGFloat)] = [(30, 50), (84, 52), (20, 74), (96, 76), (54, 90)]
            for (x, y) in flies {
                ctx.circle(x, y, 2.4, rgb(0xB8F5D8).opacity(0.2))
                ctx.circle(x, y, 0.8, rgb(0xE8FFF4))
            }
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

    // MARK: - Đồ thêm: Cây

    private static func palmTree(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 60, 7)
        // thân cong thành từng đốt
        let trunk = rgb(0xC9A27A), ring = rgb(0xA98260)
        let p0 = pt(46, 94), c = pt(40, 56), p1 = pt(60, 26)
        var t: CGFloat = 0
        while t <= 1.001 {
            let x = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * c.x + t * t * p1.x
            let y = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * c.y + t * t * p1.y
            let w = 13 - t * 4
            ctx.ellipse(x - w / 2, y - 3.6, w, 7.2, ring)
            ctx.ellipse(x - w / 2 + 0.6, y - 4.4, w - 1.2, 6, trunk)
            t += 0.085
        }
        // dừa
        ctx.circle(55, 31, 4.6, rgb(0x8C5E43))
        ctx.circle(63, 32, 4.4, rgb(0x7A4E38))
        ctx.circle(59, 36, 4.4, rgb(0x8C5E43))
        ctx.circle(54, 29.5, 1.2, Color.white.opacity(0.4))
        // tàu lá
        func frond(_ tip: CGPoint, _ ctrl: CGPoint, _ w: CGFloat, _ color: Color) {
            let base = pt(60, 26)
            var f = Path()
            f.move(to: base)
            f.addQuadCurve(to: tip, control: pt(ctrl.x, ctrl.y - w))
            f.addQuadCurve(to: base, control: pt(ctrl.x, ctrl.y + w))
            f.closeSubpath()
            ctx.fill(f, with: .color(color))
            ctx.strokePath(rgb(0x5E9E62), width: 1) { p in
                p.move(to: base); p.addQuadCurve(to: tip, control: ctrl)
            }
        }
        let dark = rgb(0x6DB46F), light = rgb(0x86C784)
        frond(pt(4, 50), pt(26, 10), 13, dark)
        frond(pt(98, 52), pt(88, 10), 13, dark)
        frond(pt(10, 30), pt(30, 12), 12, light)
        frond(pt(98, 32), pt(84, 14), 12, light)
        frond(pt(24, 4), pt(40, 6), 10, light)
        frond(pt(92, 4), pt(78, 4), 10, light)
        frond(pt(58, 0), pt(56, 10), 7, rgb(0x9AD394))
        ctx.circle(50, 18, 1.4, Color.white.opacity(0.5))
    }

    private static func mapleLeaf(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ angle: Double, _ color: Color) {
        ctx.rotated(angle, around: pt(cx, cy)) { c in
            var pts: [CGPoint] = []
            for i in 0..<10 {
                let a = (Double(i) * 36.0 - 90.0) * Double.pi / 180
                let r = i % 2 == 0 ? s : s * 0.45
                pts.append(pt(cx + r * CGFloat(cos(a)), cy + r * CGFloat(sin(a))))
            }
            c.polygon(pts, color)
            c.strokePath(color, width: max(0.5, s * 0.15)) { p in
                p.move(to: pt(cx, cy)); p.addLine(to: pt(cx, cy + s * 1.2))
            }
        }
    }

    private static func mapleTree(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 76, 8)
        // đống lá dưới gốc
        ctx.ellipse(20, 86, 60, 10, rgb(0xEFA25A))
        ctx.ellipse(28, 84, 30, 7, rgb(0xF6BE6A))
        var trunk = Path()
        trunk.move(to: pt(40, 92))
        trunk.addQuadCurve(to: pt(45, 76), control: pt(45, 88))
        trunk.addLine(to: pt(46, 50)); trunk.addLine(to: pt(55, 50)); trunk.addLine(to: pt(56, 76))
        trunk.addQuadCurve(to: pt(61, 92), control: pt(56, 88))
        trunk.closeSubpath()
        ctx.fill(trunk, with: .color(rgb(0x9C6A4E)))
        ctx.strokePath(rgb(0x9C6A4E), width: 4) { p in
            p.move(to: pt(48, 58)); p.addLine(to: pt(34, 46))
            p.move(to: pt(53, 56)); p.addLine(to: pt(68, 46))
        }
        ctx.strokePath(rgb(0x7E5340), width: 1.3) { p in
            p.move(to: pt(52, 86)); p.addLine(to: pt(52, 64))
        }
        let blobs: [(CGFloat, CGFloat, CGFloat)] = [(28, 40, 17), (72, 40, 17), (36, 20, 16), (64, 20, 16), (50, 32, 22),
                                                   (50, 12, 13), (50, 48, 14), (16, 30, 11), (84, 30, 11)]
        roundCanopy(ctx, blobs, rgb(0xF29A55), rgb(0xE07F3E), rgb(0xF9C27A))
        // mảng đỏ và vàng xen kẽ
        let patches: [(CGFloat, CGFloat, CGFloat, UInt32)] = [(30, 26, 8, 0xE8685A), (66, 38, 9, 0xE8685A), (46, 44, 7, 0xF6C255),
                                                             (60, 14, 7, 0xF6C255), (20, 40, 6, 0xF6C255), (80, 26, 6, 0xE8685A)]
        for (x, y, r, col) in patches { ctx.circle(x, y, r, rgb(col).opacity(0.85)) }
        let leaves: [(CGFloat, CGFloat, CGFloat, Double, UInt32)] = [(36, 30, 3.6, 10, 0xFBD48A), (58, 24, 3.4, -20, 0xFBD48A),
                                                                    (44, 14, 3, 30, 0xFCE0A8), (70, 46, 3, 0, 0xF6C255)]
        for (x, y, s, a, col) in leaves { mapleLeaf(ctx, x, y, s, a, rgb(col)) }
        // lá rơi
        let falling: [(CGFloat, CGFloat, CGFloat, Double, UInt32)] = [(14, 62, 3.4, -20, 0xE8685A), (86, 58, 3.6, 25, 0xF29A55),
                                                                     (24, 76, 3, 40, 0xF6C255), (80, 74, 3.2, -35, 0xE8685A),
                                                                     (70, 88, 3, 15, 0xF6C255)]
        for (x, y, s, a, col) in falling { mapleLeaf(ctx, x, y, s, a, rgb(col)) }
    }

    private static func willowTree(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 84, 8)
        let trunkC = rgb(0x8E6A52)
        ctx.strokePath(trunkC, width: 11) { p in
            p.move(to: pt(50, 92)); p.addQuadCurve(to: pt(52, 40), control: pt(44, 66))
        }
        ctx.ellipse(38, 88, 26, 7, trunkC)
        ctx.strokePath(trunkC, width: 4) { p in
            p.move(to: pt(50, 50)); p.addQuadCurve(to: pt(30, 30), control: pt(38, 46))
            p.move(to: pt(52, 46)); p.addQuadCurve(to: pt(72, 28), control: pt(66, 42))
        }
        // vòm lá
        let base = rgb(0x9CCB82), dark = rgb(0x86B970), light = rgb(0xBCDFA0)
        ctx.ellipse(10, 6, 80, 44, dark)
        ctx.ellipse(12, 4, 76, 40, base)
        ctx.ellipse(24, 8, 30, 14, light.opacity(0.8))
        // cành rủ
        let strands: [(CGFloat, CGFloat, CGFloat)] = [(12, 30, 66), (18, 38, 80), (25, 40, 72), (32, 42, 84), (40, 42, 64),
                                                     (60, 42, 66), (68, 42, 84), (75, 40, 74), (82, 38, 80), (88, 30, 66),
                                                     (46, 40, 52), (55, 40, 54)]
        for (i, s) in strands.enumerated() {
            let (x, top, bottom) = s
            let sway: CGFloat = i % 2 == 0 ? 3 : -3
            let color = i % 3 == 0 ? light : (i % 3 == 1 ? base : dark)
            ctx.strokePath(color, width: 3.2) { p in
                p.move(to: pt(x, top)); p.addQuadCurve(to: pt(x + sway, bottom), control: pt(x - sway, (top + bottom) / 2))
            }
            var y = top + 6
            while y < bottom - 2 {
                let k = (y - top) / (bottom - top)
                let xx = x + sway * (2 * k - 1) * 0.5
                leaf(ctx, xx - 2, y, 4.5, 2.2, 50, color)
                leaf(ctx, xx + 2, y + 3, 4.5, 2.2, -50, color)
                y += 7
            }
        }
        ctx.circle(36, 14, 1.6, Color.white.opacity(0.55))
    }

    // MARK: - Đồ thêm: Luống hoa

    private static func veggieBed(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 94, 96, 8)
        let plank = rgb(0xC9A27A), plankDark = rgb(0xA98260)
        // thành sau + đất
        ctx.rect(4, 60, 92, 8, plankDark, radius: 2)
        ctx.rect(6, 64, 88, 14, rgb(0x93694F))
        // bắp cải
        for (x, y) in [(CGFloat(24), CGFloat(64)), (76, 64)] {
            ctx.circle(x, y, 12, rgb(0x9CCB82))
            ctx.circle(x, y + 1, 9, rgb(0xB7DCA0))
            ctx.circle(x, y + 2, 5.5, rgb(0xCDE8B8))
            ctx.strokePath(rgb(0x86B970), width: 1) { p in
                p.move(to: pt(x, y - 8)); p.addLine(to: pt(x, y + 6))
            }
        }
        // cà rốt nhú lên
        for x in [CGFloat(42), 52, 62] {
            ctx.polygon([pt(x - 4, 72), pt(x + 4, 72), pt(x, 82)], rgb(0xF29A55))
            ctx.rect(x - 4, 71, 8, 2.5, rgb(0xF6B070), radius: 1.2)
            for (dx, a) in [(CGFloat(-3), -25.0), (0, 0), (3, 25)] {
                leaf(ctx, x + dx, 62, 3.4, 13, a, rgb(0x6FAE6C))
            }
        }
        // thành trước
        ctx.rect(2, 76, 96, 16, plank, radius: 3)
        ctx.rect(2, 84, 96, 1.2, plankDark)
        ctx.rect(4, 77.5, 92, 1.6, Color.white.opacity(0.35), radius: 0.8)
        ctx.circle(8, 80, 1, plankDark)
        ctx.circle(92, 80, 1, plankDark)
        ctx.circle(8, 88.5, 1, plankDark)
        ctx.circle(92, 88.5, 1, plankDark)
        // biển cắm hình cà rốt
        ctx.rect(85, 46, 2.6, 24, Palette.woodDark, radius: 1)
        ctx.rect(78, 40, 17, 11, rgb(0xFBF4E8), radius: 2)
        ctx.polygon([pt(81, 45.5), pt(91, 43.5), pt(91, 47.5)], rgb(0xF29A55))
        leaf(ctx, 92.5, 45.5, 4, 2, 0, rgb(0x6FAE6C))
    }

    private static func lavenderBed(_ ctx: GraphicsContext) {
        soilBed(ctx)
        let stemC = rgb(0x8FAE8A)
        let purple = rgb(0xA58ADB), purpleLight = rgb(0xC3AEEB)
        let spikes: [(CGFloat, CGFloat, CGFloat)] = [(14, 46, 82), (22, 36, 84), (30, 42, 84), (38, 30, 85), (46, 38, 86),
                                                    (54, 28, 86), (62, 36, 86), (70, 32, 85), (78, 40, 84), (86, 46, 82)]
        ctx.strokePath(stemC, width: 1.8) { p in
            for (x, top, bottom) in spikes {
                p.move(to: pt(x, top + 4)); p.addQuadCurve(to: pt(50 + (x - 50) * 0.7, bottom), control: pt(x, (top + bottom) / 2))
            }
        }
        for (x, top, _) in spikes {
            var y = top
            var i = 0
            while y < top + 18 {
                let w: CGFloat = 4.4 - CGFloat(i) * 0.15
                ctx.ellipse(x - w - 0.2, y, w, 4, i % 2 == 0 ? purple : purpleLight)
                ctx.ellipse(x + 0.2, y + 1.6, w, 4, i % 2 == 0 ? purpleLight : purple)
                y += 3.4
                i += 1
            }
            ctx.circle(x, top - 1, 1.8, purpleLight)
        }
        // lá bạc dưới gốc
        let leaves: [(CGFloat, CGFloat, Double)] = [(20, 72, -40), (34, 74, 30), (50, 72, -20), (64, 74, 30), (80, 72, -30)]
        for (x, y, a) in leaves { leaf(ctx, x, y, 5, 16, a, rgb(0xA9C2A4)) }
        bedFront(ctx)
        // chú ong nhỏ
        ctx.ellipse(70, 16, 8, 6, rgb(0xF8D45C))
        ctx.rect(72.5, 16, 1.4, 6, Palette.catInk.opacity(0.8))
        ctx.rect(75, 16.5, 1.4, 5, Palette.catInk.opacity(0.8))
        ctx.ellipse(71, 11, 5, 5, Color.white.opacity(0.8))
        ctx.ellipse(74, 11.5, 4.5, 4.5, Color.white.opacity(0.7))
        ctx.strokePath(Palette.catInk.opacity(0.35), width: 0.7) { p in
            p.move(to: pt(68, 19)); p.addQuadCurve(to: pt(58, 14), control: pt(62, 22))
        }
    }

    private static func strawberry(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
        var b = Path()
        b.move(to: pt(cx - 5 * s, cy - 3 * s))
        b.addQuadCurve(to: pt(cx + 5 * s, cy - 3 * s), control: pt(cx, cy - 6 * s))
        b.addQuadCurve(to: pt(cx, cy + 6 * s), control: pt(cx + 5 * s, cy + 3 * s))
        b.addQuadCurve(to: pt(cx - 5 * s, cy - 3 * s), control: pt(cx - 5 * s, cy + 3 * s))
        b.closeSubpath()
        ctx.fill(b, with: .color(rgb(0xE8585A)))
        for (dx, dy) in [(CGFloat(-2), CGFloat(0)), (2, 0), (0, 2.5), (-1, -2), (1.6, -2.4)] {
            ctx.ellipse(cx + dx * s - 0.4 * s, cy + dy * s - 0.5 * s, 0.8 * s, 1 * s, rgb(0xFCE3A0))
        }
        ctx.polygon([pt(cx - 4 * s, cy - 4 * s), pt(cx, cy - 2.4 * s), pt(cx + 4 * s, cy - 4 * s), pt(cx, cy - 5.4 * s)], rgb(0x6FAE6C))
        ctx.circle(cx - 2.4 * s, cy - 1 * s, 0.9 * s, Color.white.opacity(0.5))
    }

    private static func strawberryBed(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 94, 8)
        // rơm phủ gốc
        ctx.ellipse(4, 70, 92, 22, rgb(0xE6CE8E))
        ctx.strokePath(rgb(0xD4B872), width: 0.8) { p in
            for (x, y) in [(CGFloat(12), CGFloat(80)), (26, 86), (44, 84), (64, 86), (80, 82), (88, 76), (18, 74)] {
                p.move(to: pt(x, y)); p.addLine(to: pt(x + 6, y - 2))
            }
        }
        // bụi lá ba thùy
        let clumps: [(CGFloat, CGFloat)] = [(22, 60), (50, 54), (78, 60), (36, 70), (64, 70)]
        for (x, y) in clumps {
            for (dx, dy) in [(CGFloat(-6), CGFloat(2)), (6, 2), (0, -5)] {
                ctx.circle(x + dx, y + dy, 7, rgb(0x6FAE6C))
                ctx.circle(x + dx - 1, y + dy - 1, 5.6, rgb(0x84C27C))
                ctx.strokePath(rgb(0x6FAE6C), width: 0.8) { p in
                    p.move(to: pt(x + dx, y + dy - 4)); p.addLine(to: pt(x + dx, y + dy + 4))
                }
            }
        }
        // hoa trắng nhỏ
        for (x, y) in [(CGFloat(14), CGFloat(52)), (60, 46), (88, 54)] {
            for i in 0..<5 {
                let a = Double(i) * 72.0 * Double.pi / 180
                ctx.circle(x + 2.2 * CGFloat(cos(a)), y + 2.2 * CGFloat(sin(a)), 1.8, Color.white)
            }
            ctx.circle(x, y, 1.2, rgb(0xF6C744))
        }
        // dâu chín rủ xuống
        strawberry(ctx, 30, 72, 1.2)
        strawberry(ctx, 44, 64, 1.1)
        strawberry(ctx, 58, 78, 1.3)
        strawberry(ctx, 72, 70, 1.1)
        strawberry(ctx, 18, 80, 1.0)
        // giỏ nhỏ
        ctx.polygon([pt(74, 82), pt(96, 82), pt(93, 94), pt(77, 94)], rgb(0xD9B07A))
        ctx.strokePath(rgb(0xB88D5C), width: 1.6) { p in
            p.move(to: pt(76, 83)); p.addQuadCurve(to: pt(94, 83), control: pt(85, 68))
        }
        strawberry(ctx, 80, 81, 0.8)
        strawberry(ctx, 88, 80, 0.8)
        ctx.rect(74, 86, 22, 1.2, rgb(0xB88D5C))
    }

    // MARK: - Đồ thêm: Chỗ ngồi

    private static func picnic(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 90, 96, 10)
        // khăn ca rô phối cảnh
        var cloth = Path()
        cloth.move(to: pt(16, 64)); cloth.addLine(to: pt(86, 64)); cloth.addLine(to: pt(98, 90)); cloth.addLine(to: pt(2, 90))
        cloth.closeSubpath()
        ctx.fill(cloth, with: .color(Color.white))
        var c = ctx
        c.clip(to: cloth)
        let red = rgb(0xF08C8C).opacity(0.75)
        for i in 0..<8 {
            let tTop = CGFloat(i) / 7
            let xt = 16 + 70 * tTop, xb = 2 + 96 * tTop
            c.polygon([pt(xt - 2.6, 64), pt(xt + 2.6, 64), pt(xb + 3.6, 90), pt(xb - 3.6, 90)], red)
        }
        for y in [CGFloat(66), 72, 79.5, 87] {
            c.rect(0, y - 1.6 - (y - 64) * 0.05, 100, 3.2 + (y - 64) * 0.1, red)
        }
        ctx.rect(2, 89, 96, 3, rgb(0xE07F7F), radius: 1.2)
        // giỏ mây
        let wicker = rgb(0xD9B07A), wickerDark = rgb(0xB88D5C)
        ctx.strokePath(wickerDark, width: 2.4) { p in
            p.move(to: pt(28, 60)); p.addQuadCurve(to: pt(56, 60), control: pt(42, 34))
        }
        ctx.polygon([pt(24, 60), pt(60, 60), pt(56, 80), pt(28, 80)], wicker)
        ctx.strokePath(wickerDark, width: 0.9) { p in
            for y in [CGFloat(65), 70, 75] {
                p.move(to: pt(26, y)); p.addLine(to: pt(58, y))
            }
            for x in stride(from: CGFloat(31), to: 56, by: 5) {
                p.move(to: pt(x, 60)); p.addLine(to: pt(x, 80))
            }
        }
        ctx.rect(22, 57, 40, 5, wickerDark, radius: 2)
        // khăn ló ra khỏi giỏ
        ctx.polygon([pt(48, 57), pt(58, 52), pt(60, 58)], rgb(0xF4B0B0))
        // bánh mì kẹp và chai nước
        ctx.polygon([pt(66, 80), pt(80, 80), pt(72, 70)], rgb(0xF6DDB0))
        ctx.rect(66, 77.5, 14, 1.6, rgb(0x8EC48D))
        ctx.rect(66, 79.6, 14, 1.2, rgb(0xE8585A))
        ctx.rect(84, 62, 7, 16, rgb(0xFCE6A8), radius: 2)
        ctx.rect(85.5, 58, 4, 5, rgb(0xFCE6A8), radius: 1)
        ctx.rect(85, 56.5, 5, 2.4, rgb(0xE8585A), radius: 1)
        ctx.rect(84, 67, 7, 5, rgb(0xF6C255))
        ctx.rect(85.5, 63, 1.4, 12, Color.white.opacity(0.5), radius: 0.7)
        apple(ctx, 14, 82, 3.4)
    }

    private static func parasolChair(_ ctx: GraphicsContext) {
        shadow(ctx, 46, 92, 90, 9)
        // cán dù
        ctx.strokePath(rgb(0xE9E2D6), width: 2.4) { p in
            p.move(to: pt(72, 92)); p.addLine(to: pt(56, 18))
        }
        ctx.ellipse(66, 89, 12, 5, rgb(0xCFC6B8))
        // tán dù sọc
        var canopy = Path()
        canopy.move(to: pt(10, 32))
        canopy.addQuadCurve(to: pt(96, 26), control: pt(54, -6))
        canopy.addLine(to: pt(10, 32))
        canopy.closeSubpath()
        var cc = ctx
        cc.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 100)))
        cc.fill(canopy, with: .color(rgb(0xFBF4EA)))
        var stripes = cc
        stripes.clip(to: canopy)
        for (i, x) in stride(from: CGFloat(10), to: 96, by: 14.4).enumerated() where i % 2 == 0 {
            stripes.polygon([pt(54, 6), pt(x, 36), pt(x + 14.4, 36)], rgb(0xF4A9A0))
        }
        // diềm lượn
        var x: CGFloat = 10
        var i = 0
        while x < 92 {
            let y = 32 - (x - 10) * 0.071
            cc.ellipse(x, y - 2.4, 7.5, 5, i % 2 == 0 ? rgb(0xF4A9A0) : rgb(0xFBF4EA))
            x += 7.5
            i += 1
        }
        ctx.circle(54, 6, 2.2, rgb(0xE07F7F))
        // ghế xếp
        let frame = Palette.woodDark
        ctx.strokePath(frame, width: 3) { p in
            p.move(to: pt(14, 92)); p.addLine(to: pt(44, 50))
            p.move(to: pt(54, 92)); p.addLine(to: pt(24, 54))
            p.move(to: pt(44, 50)); p.addLine(to: pt(50, 50))
        }
        var sling = Path()
        sling.move(to: pt(18, 46)); sling.addLine(to: pt(32, 46))
        sling.addQuadCurve(to: pt(52, 78), control: pt(30, 72))
        sling.addLine(to: pt(38, 80))
        sling.addQuadCurve(to: pt(18, 46), control: pt(18, 74))
        sling.closeSubpath()
        ctx.fill(sling, with: .color(rgb(0x9CD3C0)))
        var sc = ctx
        sc.clip(to: sling)
        for y in stride(from: CGFloat(48), to: 82, by: 8) {
            sc.rect(10, y, 50, 3.6, Color.white.opacity(0.85))
        }
        ctx.strokePath(frame, width: 3) { p in
            p.move(to: pt(16, 44)); p.addLine(to: pt(34, 44))
            p.move(to: pt(36, 82)); p.addLine(to: pt(56, 80))
        }
        // ly nước chanh trên bàn nhỏ
        ctx.rect(76, 70, 18, 3, Palette.wood, radius: 1.5)
        ctx.rect(84, 72, 2.4, 20, Palette.woodDark, radius: 1)
        ctx.rect(80, 60, 8, 10, rgb(0xFCEFA8).opacity(0.95), radius: 1.5)
        ctx.circle(88, 61, 3, rgb(0xF6D55A))
        ctx.circle(88, 61, 1.8, rgb(0xFCEFA8))
        ctx.strokePath(rgb(0xF4A9A0), width: 1) { p in p.move(to: pt(83, 60)); p.addLine(to: pt(80, 53)) }
    }

    private static func mushroomTable(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 92, 96, 9)
        // bàn nấm lớn ở giữa
        ctx.rect(42, 44, 16, 46, rgb(0xF8EBD6), radius: 6)
        ctx.ellipse(38, 85, 24, 8, rgb(0xEEDCC2))
        ctx.rect(46, 50, 3, 34, Color.white.opacity(0.5), radius: 1.5)
        ctx.ellipse(16, 40, 68, 14, rgb(0xC98E62))
        ctx.ellipse(16, 36, 68, 14, rgb(0xE6B485))
        ctx.ellipse(22, 37, 56, 9, rgb(0xEFC79C))
        for (x, y, w) in [(CGFloat(26), CGFloat(39), CGFloat(6)), (64, 38.5, 7), (44, 45, 5)] {
            ctx.ellipse(x, y, w, w * 0.45, rgb(0xFBEFD9))
        }
        // ấm trà và tách
        ctx.ellipse(36, 22, 18, 16, rgb(0xB7A6F0))
        ctx.rect(42, 19, 6, 3, rgb(0x9D8FD6), radius: 1.5)
        ctx.strokePath(rgb(0xB7A6F0), width: 2) { p in
            p.move(to: pt(36, 30)); p.addQuadCurve(to: pt(31, 23), control: pt(31, 28))
            p.addEllipse(in: CGRect(x: 51, y: 25, width: 5, height: 6))
        }
        ctx.circle(41, 26, 1.6, Color.white.opacity(0.6))
        ctx.rect(58, 32, 9, 7, Color.white, radius: 2)
        ctx.ellipse(56, 37, 13, 3, rgb(0xEDE4F8))
        // hai ghế nấm nhỏ
        for (x, cap) in [(CGFloat(14), UInt32(0xE5574F)), (86, 0xF29A55)] {
            ctx.rect(x - 5, 76, 10, 16, rgb(0xF8EBD6), radius: 4)
            var c = Path()
            c.move(to: pt(x - 13, 78))
            c.addCurve(to: pt(x + 13, 78), control1: pt(x - 13, 62), control2: pt(x + 13, 62))
            c.addQuadCurve(to: pt(x - 13, 78), control: pt(x, 82))
            c.closeSubpath()
            ctx.fill(c, with: .color(rgb(cap)))
            ctx.circle(x - 5, 72, 2, Color.white)
            ctx.circle(x + 4, 70, 1.6, Color.white)
            ctx.circle(x + 8, 75, 1.2, Color.white)
        }
        tuft(ctx, 30, 92, 2.4, stem)
        tuft(ctx, 70, 92, 2.4, stem)
    }

    // MARK: - Đồ thêm: Hồ nước

    private static func duck(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ body: Color) {
        ctx.ellipse(cx - 10 * s, cy - 2 * s, 20 * s, 4 * s, Color.white.opacity(0.35))
        ctx.polygon([pt(cx - 8 * s, cy - 2 * s), pt(cx - 13 * s, cy - 8 * s), pt(cx - 4 * s, cy - 4 * s)], body)
        ctx.ellipse(cx - 9 * s, cy - 8 * s, 17 * s, 10 * s, body)
        ctx.circle(cx + 5 * s, cy - 11 * s, 5 * s, body)
        ctx.ellipse(cx + 8.5 * s, cy - 11 * s, 6 * s, 3 * s, rgb(0xF29A4A))
        ctx.circle(cx + 6 * s, cy - 12.5 * s, 0.9 * s, Palette.catInk)
        ctx.ellipse(cx + 2.6 * s, cy - 10 * s, 2.4 * s, 1.4 * s, Palette.blush)
        leaf(ctx, cx - 1 * s, cy - 4.5 * s, 9 * s, 4.5 * s, -10, Color.white.opacity(0.35))
    }

    private static func duckPond(_ ctx: GraphicsContext) {
        // cỏ nến phía sau
        ctx.strokePath(rgb(0x7DB06E), width: 1.6) { p in
            p.move(to: pt(10, 70)); p.addQuadCurve(to: pt(8, 40), control: pt(12, 54))
            p.move(to: pt(16, 70)); p.addQuadCurve(to: pt(18, 34), control: pt(14, 52))
            p.move(to: pt(22, 70)); p.addQuadCurve(to: pt(26, 44), control: pt(22, 56))
        }
        for (x, y) in [(CGFloat(8), CGFloat(44)), (18, 38), (25.6, 48)] {
            ctx.rect(x - 2, y, 4, 10, rgb(0x9C6A4E), radius: 2)
        }
        leaf(ctx, 6, 56, 3, 16, -15, rgb(0x8EC48D))
        leaf(ctx, 26, 58, 3, 16, 20, rgb(0x8EC48D))
        _ = stonePond(ctx, water)
        lilyPad(ctx, 66, 62, 16, 7, water)
        ripple(ctx, 40, 76, 16)
        ripple(ctx, 62, 78, 9)
        ripple(ctx, 74, 75, 7)
        duck(ctx, 40, 74, 1.2, rgb(0xFFFBF2))
        duck(ctx, 62, 77, 0.6, rgb(0xF8D45C))
        duck(ctx, 74, 74, 0.55, rgb(0xF8D45C))
    }

    private static func bridgePond(_ ctx: GraphicsContext) {
        let surface = stonePond(ctx, water)
        var c = ctx
        c.clip(to: surface)
        // bóng cầu dưới nước
        c.strokePath(rgb(0xE8685A).opacity(0.25), width: 5) { p in
            p.move(to: pt(14, 72)); p.addQuadCurve(to: pt(86, 72), control: pt(50, 98))
        }
        lilyPad(ctx, 16, 74, 14, 6, water)
        lilyPad(ctx, 70, 76, 12, 5, water)
        let red = rgb(0xE8685A), redDark = rgb(0xC9524A)
        // chân cầu
        ctx.rect(12, 66, 6, 12, redDark, radius: 1.5)
        ctx.rect(82, 66, 6, 12, redDark, radius: 1.5)
        // mặt cầu cong
        ctx.strokePath(redDark, width: 8) { p in
            p.move(to: pt(6, 72)); p.addQuadCurve(to: pt(94, 72), control: pt(50, 34))
        }
        ctx.strokePath(red, width: 6) { p in
            p.move(to: pt(6, 70)); p.addQuadCurve(to: pt(94, 70), control: pt(50, 32))
        }
        ctx.strokePath(rgb(0xF4A9A0), width: 1.2) { p in
            p.move(to: pt(8, 68)); p.addQuadCurve(to: pt(92, 68), control: pt(50, 30))
        }
        // lan can
        func arcY(_ x: CGFloat) -> CGFloat {
            let t = (x - 6) / 88
            return (1 - t) * (1 - t) * 70 + 2 * (1 - t) * t * 32 + t * t * 70
        }
        ctx.strokePath(red, width: 2.6) { p in
            for x in [CGFloat(12), 31, 50, 69, 88] {
                let y = arcY(x)
                p.move(to: pt(x, y - 2)); p.addLine(to: pt(x, y - 14))
            }
            p.move(to: pt(12, arcY(12) - 12)); p.addQuadCurve(to: pt(88, arcY(88) - 12), control: pt(50, 20))
        }
        for x in [CGFloat(12), 50, 88] {
            ctx.circle(x, arcY(x) - 15, 2, rgb(0xF6C255))
        }
    }

    private static func wishingWell(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 92, 84, 9)
        let stoneA = rgb(0xCBC6BF), stoneB = rgb(0xB9B4AD)
        // trụ gỗ
        ctx.rect(20, 18, 6, 50, Palette.woodDark, radius: 2)
        ctx.rect(74, 18, 6, 50, Palette.woodDark, radius: 2)
        // mái
        ctx.polygon([pt(10, 26), pt(50, 4), pt(90, 26)], rgb(0xE08070))
        ctx.polygon([pt(50, 4), pt(90, 26), pt(76, 26)], rgb(0xC96A5C))
        ctx.strokePath(rgb(0xF4A9A0), width: 1) { p in
            p.move(to: pt(24, 22)); p.addLine(to: pt(76, 22))
            p.move(to: pt(36, 15)); p.addLine(to: pt(64, 15))
        }
        // trục quay + dây + gầu
        ctx.rect(22, 34, 56, 3, Palette.wood, radius: 1.5)
        ctx.strokePath(Palette.woodDark, width: 2) { p in
            p.move(to: pt(80, 35.5)); p.addLine(to: pt(88, 35.5)); p.addLine(to: pt(88, 42))
        }
        ctx.strokePath(rgb(0xEADBBE), width: 1.2) { p in
            p.move(to: pt(50, 37)); p.addLine(to: pt(50, 48))
        }
        ctx.polygon([pt(44, 48), pt(56, 48), pt(54, 58), pt(46, 58)], Palette.wood)
        ctx.rect(43.5, 47, 13, 2.4, Palette.woodDark, radius: 1)
        // miệng giếng
        ctx.ellipse(14, 58, 72, 16, stoneB)
        ctx.ellipse(20, 61, 60, 10, rgb(0x5E8FA8))
        ctx.ellipse(30, 63, 24, 3.4, Color.white.opacity(0.3))
        sparkle(ctx, 62, 65, 4, rgb(0xFFE6A0))
        // thân đá
        ctx.rect(14, 66, 72, 24, stoneA, radius: 4)
        var w = ctx
        w.clip(to: Path(roundedRect: CGRect(x: 14, y: 66, width: 72, height: 24), cornerRadius: 4))
        for row in 0..<3 {
            let y = 66 + CGFloat(row) * 8
            var x: CGFloat = row % 2 == 0 ? 10 : 18
            while x < 90 {
                w.rect(x + 0.6, y + 0.6, 14.8, 6.8, (Int(x) / 16 + row) % 2 == 0 ? stoneB : stoneA, radius: 2.4)
                x += 16
            }
        }
        ctx.ellipse(14, 64, 72, 6, rgb(0xDCD6CD))
        // dây leo hoa
        ctx.strokePath(stem, width: 1.4) { p in
            p.move(to: pt(18, 90)); p.addQuadCurve(to: pt(30, 70), control: pt(16, 76))
        }
        for (x, y) in [(CGFloat(20), CGFloat(80)), (27, 72)] {
            leaf(ctx, x + 3, y + 1, 5, 2.6, 30, leafGreen)
            ctx.circle(x, y, 2.2, rgb(0xF7B6C8))
            ctx.circle(x, y, 0.8, rgb(0xF2B84B))
        }
    }

    // MARK: - Đồ thêm: Trang trí

    private static func windmill(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 50, 7)
        // tháp
        ctx.polygon([pt(38, 42), pt(62, 42), pt(70, 93), pt(30, 93)], rgb(0xF6E3C6))
        ctx.polygon([pt(56, 42), pt(62, 42), pt(70, 93), pt(62, 93)], rgb(0xEACFAC))
        ctx.rect(44, 76, 12, 17, Palette.woodDark, radius: 6)
        ctx.circle(50, 60, 4, rgb(0x9CC6EB))
        ctx.strokePath(Palette.woodDark, width: 1) { p in
            p.move(to: pt(46, 60)); p.addLine(to: pt(54, 60))
            p.move(to: pt(50, 56)); p.addLine(to: pt(50, 64))
        }
        // mái chóp
        var cap = Path()
        cap.move(to: pt(34, 44))
        cap.addQuadCurve(to: pt(66, 44), control: pt(50, 20))
        cap.closeSubpath()
        ctx.fill(cap, with: .color(rgb(0xE08070)))
        ctx.rect(33, 42, 34, 4, rgb(0xC96A5C), radius: 2)
        // cánh quạt
        func blade(_ angle: Double) {
            ctx.rotated(angle, around: pt(50, 36)) { c in
                c.rect(48.8, 4, 2.4, 32, Palette.woodDark, radius: 1)
                c.rect(51, 6, 10, 26, rgb(0xFBF7F0), radius: 1.5)
                c.strokePath(rgb(0xD8C7A8), width: 0.8) { p in
                    for y in stride(from: CGFloat(11), to: 32, by: 5) {
                        p.move(to: pt(51, y)); p.addLine(to: pt(61, y))
                    }
                    p.move(to: pt(56, 6)); p.addLine(to: pt(56, 32))
                }
            }
        }
        for a in [20.0, 110.0, 200.0, 290.0] { blade(a) }
        ctx.circle(50, 36, 3.6, rgb(0xC96A5C))
        ctx.circle(49, 35, 1.2, Color.white.opacity(0.5))
        tuft(ctx, 30, 93, 2.4, stem)
        tuft(ctx, 72, 93, 2.4, stem)
        ctx.circle(26, 88, 2.2, rgb(0xF9D86E))
        ctx.circle(26, 88, 0.8, rgb(0xFFFFFF))
    }

    private static func gnome(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 50, 7)
        let coat = rgb(0x7FAFD9), coatDark = rgb(0x6A9AC6), hat = rgb(0xE5574F)
        // ủng
        ctx.ellipse(34, 86, 16, 8, Palette.woodDark)
        ctx.ellipse(50, 86, 16, 8, Palette.woodDark)
        // thân áo
        var body = Path()
        body.move(to: pt(38, 54)); body.addLine(to: pt(62, 54))
        body.addQuadCurve(to: pt(66, 88), control: pt(68, 70))
        body.addLine(to: pt(34, 88))
        body.addQuadCurve(to: pt(38, 54), control: pt(32, 70))
        body.closeSubpath()
        ctx.fill(body, with: .color(coat))
        ctx.rect(34, 74, 32, 5, rgb(0x8C5E43), radius: 2)
        ctx.rect(47, 73.5, 6, 6, rgb(0xF6C255), radius: 1.5)
        ctx.rect(48.6, 75, 2.8, 3, rgb(0x8C5E43), radius: 0.6)
        // tay ôm cái xẻng nhỏ
        ctx.strokePath(rgb(0xBFA488), width: 2) { p in p.move(to: pt(70, 52)); p.addLine(to: pt(70, 86)) }
        ctx.polygon([pt(66, 84), pt(74, 84), pt(72, 93), pt(68, 93)], rgb(0xB8BCC6))
        ctx.circle(70, 64, 4, coatDark)
        ctx.circle(71, 64, 2.6, rgb(0xF8CBB0))
        ctx.circle(31, 66, 4, coatDark)
        // râu
        var beard = Path()
        beard.move(to: pt(36, 46))
        beard.addQuadCurve(to: pt(50, 76), control: pt(36, 70))
        beard.addQuadCurve(to: pt(64, 46), control: pt(64, 70))
        beard.closeSubpath()
        ctx.fill(beard, with: .color(Color.white))
        ctx.strokePath(rgb(0xE8E2DA), width: 1) { p in
            p.move(to: pt(44, 58)); p.addQuadCurve(to: pt(48, 70), control: pt(44, 66))
            p.move(to: pt(56, 58)); p.addQuadCurve(to: pt(52, 70), control: pt(56, 66))
        }
        // mặt
        ctx.ellipse(38, 38, 24, 16, rgb(0xF8CBB0))
        ctx.circle(44, 44, 1.4, Palette.catInk)
        ctx.circle(56, 44, 1.4, Palette.catInk)
        ctx.circle(50, 48, 4, rgb(0xF4A08C))
        ctx.circle(48.8, 46.8, 1.2, Color.white.opacity(0.6))
        ctx.ellipse(38.5, 46, 5, 3, Palette.blush)
        ctx.ellipse(56.5, 46, 5, 3, Palette.blush)
        // mũ chóp nhọn hơi cong
        var h = Path()
        h.move(to: pt(34, 42))
        h.addQuadCurve(to: pt(62, 6), control: pt(40, 14))
        h.addQuadCurve(to: pt(66, 42), control: pt(60, 22))
        h.closeSubpath()
        ctx.fill(h, with: .color(hat))
        ctx.rect(33, 38, 34, 6, rgb(0xC9483F), radius: 3)
        ctx.strokePath(Color.white.opacity(0.4), width: 1.6) { p in
            p.move(to: pt(42, 34)); p.addQuadCurve(to: pt(52, 18), control: pt(44, 24))
        }
        // nấm nhỏ bên cạnh
        mushroom(ctx, 22, 93, 16, face: false)
    }

    private static func scarecrow(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 40, 6)
        let pole = Palette.woodDark
        ctx.rect(47.5, 20, 5, 74, pole, radius: 2)
        ctx.rect(10, 42, 80, 4, pole, radius: 2)
        let straw = rgb(0xF2CF6A)
        // rơm ló ở tay và gấu áo
        for (x, dir) in [(CGFloat(14), CGFloat(-1)), (86, 1)] {
            ctx.strokePath(straw, width: 1.4) { p in
                for dy in [CGFloat(-3), 0, 3] {
                    p.move(to: pt(x, 44 + dy)); p.addLine(to: pt(x + dir * 7, 44 + dy * 1.8))
                }
            }
        }
        ctx.strokePath(straw, width: 1.4) { p in
            for x in stride(from: CGFloat(38), to: 64, by: 4) {
                p.move(to: pt(x, 72)); p.addLine(to: pt(x + (x - 50) * 0.15, 80))
            }
        }
        // áo kẻ ô
        let shirt = rgb(0x8EB4D9)
        ctx.rect(14, 38, 72, 12, shirt, radius: 5)
        ctx.polygon([pt(34, 40), pt(66, 40), pt(64, 74), pt(36, 74)], shirt)
        var sc = ctx
        var shirtPath = Path(roundedRect: CGRect(x: 14, y: 38, width: 72, height: 12), cornerRadius: 5)
        shirtPath.addLines([pt(34, 40), pt(66, 40), pt(64, 74), pt(36, 74)])
        shirtPath.closeSubpath()
        sc.clip(to: shirtPath)
        for x in stride(from: CGFloat(18), to: 86, by: 8) { sc.rect(x, 36, 2.4, 40, Color.white.opacity(0.4)) }
        for y in stride(from: CGFloat(42), to: 76, by: 8) { sc.rect(10, y, 80, 2.4, Color.white.opacity(0.4)) }
        // miếng vá
        ctx.rect(54, 58, 8, 8, rgb(0xF4B0B0), radius: 1)
        ctx.strokePath(Palette.catInk.opacity(0.4), width: 0.6) { p in
            p.addRect(CGRect(x: 55, y: 59, width: 6, height: 6))
        }
        // đầu bao bố
        ctx.circle(50, 28, 12, rgb(0xEBD3A8))
        ctx.strokePath(rgb(0xC9A475), width: 0.8) { p in
            p.move(to: pt(40, 36)); p.addLine(to: pt(60, 36))
        }
        ctx.circle(45, 26, 2, Palette.catInk)
        ctx.circle(55, 26, 2, Palette.catInk)
        ctx.strokePath(Palette.catInk, width: 1) { p in
            p.move(to: pt(44, 31)); p.addQuadCurve(to: pt(56, 31), control: pt(50, 36))
            for x in [CGFloat(46.5), 50, 53.5] {
                p.move(to: pt(x, 32)); p.addLine(to: pt(x, 34.5))
            }
        }
        ctx.ellipse(39, 28, 5, 3, Palette.blush)
        ctx.ellipse(56, 28, 5, 3, Palette.blush)
        // mũ rơm
        ctx.ellipse(30, 15, 40, 9, rgb(0xE9B95A))
        ctx.rect(39, 4, 22, 14, rgb(0xF2CF6A), radius: 6)
        ctx.rect(39, 13, 22, 3.4, rgb(0xE8685A))
        // chú quạ nhỏ đậu trên tay
        let crow = rgb(0x5E5A72)
        ctx.ellipse(74, 30, 14, 11, crow)
        ctx.circle(84, 31, 5, crow)
        ctx.polygon([pt(88, 30), pt(94, 32), pt(88, 33.5)], rgb(0xF2B84B))
        ctx.circle(85, 30, 1, Color.white)
        ctx.polygon([pt(74, 34), pt(66, 32), pt(70, 38)], crow)
        ctx.strokePath(rgb(0xF2B84B), width: 1) { p in
            p.move(to: pt(79, 40)); p.addLine(to: pt(79, 42))
            p.move(to: pt(82, 40)); p.addLine(to: pt(82, 42))
        }
    }

    private static func beehive(_ ctx: GraphicsContext) {
        shadow(ctx, 50, 93, 60, 7)
        // giá gỗ
        ctx.rect(26, 72, 48, 5, Palette.wood, radius: 2)
        ctx.rect(30, 76, 5, 17, Palette.woodDark, radius: 1.5)
        ctx.rect(65, 76, 5, 17, Palette.woodDark, radius: 1.5)
        // tổ rơm hình chuông xếp vòng
        let straw = rgb(0xE9B95A), strawDark = rgb(0xD39E42)
        let rings: [(CGFloat, CGFloat)] = [(64, 30), (57, 28), (50, 25), (43, 21), (36, 15), (30, 8)]
        for (y, hw) in rings {
            ctx.ellipse(50 - hw, y - 5, hw * 2, 11, strawDark)
            ctx.ellipse(50 - hw, y - 6.5, hw * 2, 10, straw)
        }
        ctx.circle(50, 24, 3, straw)
        ctx.ellipse(36, 34, 8, 14, Color.white.opacity(0.2))
        // cửa tổ
        var door = Path()
        door.move(to: pt(42, 68))
        door.addQuadCurve(to: pt(58, 68), control: pt(50, 56))
        door.closeSubpath()
        ctx.fill(door, with: .color(rgb(0x6E4F38)))
        // mật nhỏ giọt
        ctx.rect(62, 52, 5, 10, rgb(0xF6C255), radius: 2.5)
        ctx.circle(64.5, 63, 3, rgb(0xF6C255))
        // ong bay
        func bee(_ x: CGFloat, _ y: CGFloat) {
            ctx.ellipse(x - 1, y - 6, 4, 4, Color.white.opacity(0.85))
            ctx.ellipse(x + 2, y - 5.5, 3.6, 3.6, Color.white.opacity(0.7))
            ctx.ellipse(x - 3, y - 3, 9, 6.4, rgb(0xF8D45C))
            ctx.rect(x - 0.4, y - 3, 1.4, 6.4, Palette.catInk.opacity(0.8))
            ctx.rect(x + 2.4, y - 2.6, 1.3, 5.6, Palette.catInk.opacity(0.8))
            ctx.circle(x - 1.4, y - 0.6, 0.6, Palette.catInk)
        }
        var trail = Path()
        trail.move(to: pt(58, 64)); trail.addQuadCurve(to: pt(80, 30), control: pt(92, 56))
        trail.move(to: pt(44, 64)); trail.addQuadCurve(to: pt(16, 40), control: pt(14, 62))
        ctx.stroke(trail, with: .color(Palette.catInk.opacity(0.3)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round, dash: [1.6, 2]))
        bee(84, 28)
        bee(16, 38)
        bee(76, 8)
        // hoa quanh chân giá
        tuft(ctx, 22, 93, 2.4, stem)
        tuft(ctx, 78, 93, 2.4, stem)
        for (x, y, c) in [(CGFloat(18), CGFloat(86), UInt32(0xF7B6C8)), (82, 87, 0xFFFFFF)] {
            ctx.circle(x, y, 2.4, rgb(c))
            ctx.circle(x, y, 0.9, rgb(0xF2B84B))
        }
    }
}
