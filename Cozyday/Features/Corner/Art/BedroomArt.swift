import SwiftUI

/// Hình vẽ đồ trong Bedroom. Trả về false nếu không phải ID của phòng này.
enum BedroomArt {
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        case "bedroomTheme.lilac", "bedroomTheme.cloud", "bedroomTheme.candy", "bedroomTheme.galaxy", "bedroomTheme.forest":
            theme(id, ctx)
        case "bed.mat": bedMat(ctx)
        case "bed.wood": bedWood(ctx)
        case "bed.canopy": bedCanopy(ctx)
        case "bed.cloud": bedCloud(ctx)
        case "nightstand.crate": standCrate(ctx)
        case "nightstand.lamp": standLamp(ctx)
        case "nightstand.radio": standRadio(ctx)
        case "nightstand.moon": standMoon(ctx)
        case "bedroomWall.garland": wallGarland(ctx)
        case "bedroomWall.fairy": wallFairy(ctx)
        case "bedroomWall.moon": wallMoon(ctx)
        case "bedroomWall.dreamcatcher": wallDreamcatcher(ctx)
        case "closet.dresser": closetDresser(ctx)
        case "closet.mirror": closetMirror(ctx)
        case "closet.wardrobe": closetWardrobe(ctx)
        case "closet.vanity": closetVanity(ctx)
        case "bedroomRug.round": rugRound(rugSpace(ctx))
        case "bedroomRug.heart": rugHeart(rugSpace(ctx))
        case "bedroomRug.cloud": rugCloud(rugSpace(ctx))
        case "bedroomRug.rainbow": rugRainbow(rugSpace(ctx))
        case "plush.yarn": plushYarn(ctx)
        case "plush.ball": plushBall(ctx)
        case "plush.teddy": plushTeddy(ctx)
        case "plush.dino": plushDino(ctx)
        default: return drawMore(id, in: ctx)
        }
        return true
    }

    // MARK: - Tiện ích

    private static let shine = Color.white.opacity(0.65)
    private static let ink = rgb(0x4A3C5C)

    private static func shadow(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        ctx.ellipse(x, y, w, h, Color.black.opacity(0.1))
    }

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    /// Điểm trên đường cong bậc hai.
    private static func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                       y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }

    private static func sparkle(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: Color) {
        ctx.draw(Text("✦").font(.system(size: size)).foregroundColor(color), at: CGPoint(x: x, y: y))
    }

    /// Đám mây nhỏ gồm ba vòng tròn; (x, y) là góc trên-trái, s là tỉ lệ.
    private static func puff(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ color: Color) {
        ctx.ellipse(x, y + 4 * s, 18 * s, 7 * s, color)
        ctx.circle(x + 6 * s, y + 4.5 * s, 4 * s, color)
        ctx.circle(x + 11 * s, y + 3.5 * s, 5 * s, color)
    }

    // MARK: - Tường & sàn

    private static func theme(_ id: String, _ ctx: GraphicsContext) {
        var wall = rgb(0xEFE6F8)
        var deco = rgb(0xDCCDF1)
        var trim = rgb(0xD5C4EC)
        var floor = rgb(0xEDD8BE)
        var plank = rgb(0xDDC3A3)
        var curtain = rgb(0xC9B6EC)
        var curtainFold = rgb(0xB49FE0)
        var tie = rgb(0xF4B0C0)
        var frame = rgb(0xFFFCF7)
        var sky = rgb(0xCFE7F8)
        let night = id == "bedroomTheme.galaxy"
        switch id {
        case "bedroomTheme.cloud":
            wall = rgb(0xD8EAFA); deco = rgb(0xF7FBFF); trim = rgb(0xBCD6EF)
            floor = rgb(0xEBDDC9); plank = rgb(0xDCC9B0)
            curtain = rgb(0xFFFFFF); curtainFold = rgb(0xD9E8F6); tie = rgb(0xA9CBEB)
        case "bedroomTheme.candy":
            wall = rgb(0xFFF3F5); deco = rgb(0xFAD3DE); trim = rgb(0xF4B6C8)
            floor = rgb(0xF3DCCB); plank = rgb(0xE6C6B1)
            curtain = rgb(0xF6AFC4); curtainFold = rgb(0xEC93AE); tie = rgb(0xFFFFFF)
        case "bedroomTheme.galaxy":
            wall = rgb(0x3D3770); deco = rgb(0xFFF1C2); trim = rgb(0x2F2A5C)
            floor = rgb(0x544C86); plank = rgb(0x463F78)
            curtain = rgb(0x9C8BDB); curtainFold = rgb(0x8473CC); tie = rgb(0xF7D27A)
            frame = rgb(0xE6E0F7); sky = rgb(0x241F4A)
        case "bedroomTheme.forest":
            wall = rgb(0xE6F1DE); deco = rgb(0xB9D9AE); trim = rgb(0xA8CC9C)
            floor = rgb(0xEEDCC2); plank = rgb(0xDCC4A3)
            curtain = rgb(0xFFF6E6); curtainFold = rgb(0xEADCC4); tie = rgb(0xF2A98F)
            sky = rgb(0xFFE6CF)
        default: break
        }

        // Tường + hoa văn
        ctx.rect(0, 0, 125, 62, wall)
        switch id {
        case "bedroomTheme.cloud":
            for (x, y, s) in [(CGFloat(4), CGFloat(6), CGFloat(1.0)), (26, 16, 0.8), (98, 4, 0.95), (80, 26, 0.7),
                              (106, 36, 0.8), (16, 40, 0.75), (72, 46, 0.6), (40, 44, 0.55)] {
                puff(ctx, x, y, s, deco)
            }
        case "bedroomTheme.candy":
            for i in 0..<13 {
                ctx.rect(CGFloat(i) * 10 + 2, 0, 5, 62, deco)
            }
            // Viền ren phía trên
            ctx.rect(0, 0, 125, 3, trim)
            for i in 0..<26 {
                ctx.circle(CGFloat(i) * 5 + 2.5, 3, 2.5, trim)
            }
        case "bedroomTheme.galaxy":
            let dots: [(CGFloat, CGFloat, CGFloat)] = [(8, 6, 0.7), (20, 14, 0.5), (33, 5, 0.6), (14, 30, 0.5), (6, 46, 0.6),
                                                       (36, 26, 0.45), (78, 6, 0.6), (92, 18, 0.5), (118, 8, 0.6),
                                                       (104, 28, 0.45), (120, 44, 0.6), (84, 40, 0.5), (30, 52, 0.45),
                                                       (98, 52, 0.5), (74, 30, 0.4), (112, 20, 0.4)]
            for (x, y, r) in dots {
                ctx.circle(x, y, r, deco.opacity(0.85))
            }
            for (x, y, s) in [(CGFloat(26), CGFloat(18), CGFloat(5)), (100, 10, 6), (86, 46, 4.5), (12, 54, 4), (116, 36, 5)] {
                sparkle(ctx, x, y, s, deco)
            }
            // Hành tinh nhỏ có vành
            ctx.circle(110, 52, 3.6, rgb(0xF4B0C0))
            ctx.strokePath(rgb(0xF7D27A), width: 0.8) { p in
                p.addEllipse(in: CGRect(x: 104, y: 50.6, width: 12, height: 3))
            }
            ctx.circle(109, 51, 0.9, shine)
            // Sao băng
            ctx.strokePath(deco.opacity(0.5), width: 0.7) { p in
                p.move(to: pt(4, 20)); p.addLine(to: pt(12, 24))
            }
            ctx.circle(12.5, 24.2, 0.9, deco)
        case "bedroomTheme.forest":
            // Hàng thông nhỏ so le, xen chấm nấm đỏ
            for row in 0..<3 {
                for col in 0..<9 {
                    let x = CGFloat(col) * 14 + 6 + (row % 2 == 0 ? 0 : 7)
                    let y = CGFloat(row) * 18 + 9
                    if (row + col) % 3 == 1 {
                        ctx.ellipse(x - 2.6, y - 0.5, 5.2, 3, rgb(0xF2A98F))
                        ctx.rect(x - 0.9, y + 2, 1.8, 2.4, rgb(0xFFF6E6), radius: 0.6)
                        ctx.circle(x - 0.8, y + 0.4, 0.5, Color.white.opacity(0.9))
                    } else {
                        let c = (row + col) % 2 == 0 ? deco : trim
                        ctx.polygon([pt(x, y - 6), pt(x - 3.6, y), pt(x + 3.6, y)], c)
                        ctx.polygon([pt(x, y - 3), pt(x - 4.8, y + 4), pt(x + 4.8, y + 4)], c)
                        ctx.rect(x - 0.7, y + 4, 1.4, 2, rgb(0xCDB08E))
                    }
                }
            }
        default:
            for row in 0..<6 {
                for col in 0..<12 {
                    let x = CGFloat(col) * 11 + 4 + (row % 2 == 0 ? 0 : 5.5)
                    let y = CGFloat(row) * 10 + 5
                    if (row + col) % 2 == 0 {
                        for (dx, dy) in [(CGFloat(0), CGFloat(-1.3)), (1.3, 0), (0, 1.3), (-1.3, 0)] {
                            ctx.circle(x + dx, y + dy, 1, deco)
                        }
                        ctx.circle(x, y, 0.7, Color.white.opacity(0.8))
                    } else {
                        ctx.circle(x, y, 0.6, deco)
                    }
                }
            }
        }

        // Len chân tường
        ctx.rect(0, 57.5, 125, 4.5, trim)
        ctx.rect(0, 57.5, 125, 0.8, Color.white.opacity(night ? 0.12 : 0.45))

        // Sàn gỗ
        ctx.rect(0, 62, 125, 38, floor)
        ctx.rect(0, 62, 125, 1.6, Color.black.opacity(0.06))
        let rows: [CGFloat] = [62, 70.5, 80, 90.5]
        for (i, y) in rows.enumerated() {
            if i > 0 { ctx.rect(0, y, 125, 0.7, plank) }
            let next = i + 1 < rows.count ? rows[i + 1] : 100
            let offset: CGFloat = i % 2 == 0 ? 0 : 14
            var x = offset + 10
            while x < 125 {
                ctx.rect(x, y, 0.7, next - y, plank)
                x += 28
            }
        }
        if night {
            for (x, y) in [(CGFloat(14), CGFloat(76)), (60, 94), (96, 68), (112, 86), (40, 66)] {
                sparkle(ctx, x, y, 3.5, deco.opacity(0.45))
            }
        }

        // Cửa sổ
        ctx.rect(39, 6.8, 34, 1.8, night ? rgb(0xCFC4F0) : rgb(0xB89170), radius: 0.9)
        ctx.circle(39, 7.7, 1.6, night ? rgb(0xF7D27A) : rgb(0xA07448))
        ctx.circle(73, 7.7, 1.6, night ? rgb(0xF7D27A) : rgb(0xA07448))
        ctx.rect(44, 10, 24, 22, frame, radius: 2.5)
        ctx.rect(46, 12, 20, 18, sky, radius: 1.5)
        if night {
            ctx.circle(61, 17, 3.6, rgb(0xFFF1C2))
            ctx.circle(62.8, 15.8, 3.2, sky)
            ctx.circle(50, 15, 0.5, rgb(0xFFF1C2))
            ctx.circle(53, 25, 0.5, rgb(0xFFF1C2))
            ctx.circle(63, 26, 0.5, rgb(0xFFF1C2))
            sparkle(ctx, 50.5, 24, 3, rgb(0xFFF1C2))
        } else if id == "bedroomTheme.forest" {
            var w = ctx
            w.clip(to: Path(roundedRect: CGRect(x: 46, y: 12, width: 20, height: 18), cornerRadius: 1.5))
            w.circle(57, 21, 3.6, rgb(0xFFC98F))
            w.ellipse(40, 22, 22, 12, rgb(0xA8CC9C))
            w.ellipse(52, 24, 22, 12, rgb(0x8FBF85))
            for x in [CGFloat(49), 61] {
                w.polygon([pt(x, 19), pt(x - 2.6, 26), pt(x + 2.6, 26)], rgb(0x6FA77A))
            }
            puff(w, 47.5, 12.5, 0.4, Color.white.opacity(0.9))
        } else {
            puff(ctx, 47.5, 13, 0.45, Color.white)
            puff(ctx, 57, 22, 0.4, Color.white.opacity(0.9))
            ctx.circle(62.5, 15.5, 2, rgb(0xFFE7A0))
        }
        ctx.rect(55.3, 12, 1.4, 18, frame)
        ctx.rect(46, 20.3, 20, 1.4, frame)
        ctx.strokePath(Color.white.opacity(night ? 0.18 : 0.6), width: 0.8) { p in
            p.move(to: pt(47.5, 18)); p.addLine(to: pt(51, 13.5))
            p.move(to: pt(57.8, 28)); p.addLine(to: pt(61, 23.5))
        }
        ctx.rect(42.5, 31, 27, 3, frame, radius: 1.5)
        ctx.rect(43.5, 34, 25, 1, Color.black.opacity(0.07), radius: 0.5)

        // Rèm hai bên
        for flip in [false, true] {
            let fx: (CGFloat) -> CGFloat = { x in flip ? 112 - x : x }
            var p = Path()
            p.move(to: pt(fx(39.5), 8.5))
            p.addLine(to: pt(fx(48.5), 8.5))
            p.addQuadCurve(to: pt(fx(44.5), 23), control: pt(fx(48.5), 17))
            p.addQuadCurve(to: pt(fx(47.5), 37), control: pt(fx(42.5), 30))
            p.addLine(to: pt(fx(39), 37))
            p.addQuadCurve(to: pt(fx(39.5), 8.5), control: pt(fx(40.5), 22))
            p.closeSubpath()
            ctx.fill(p, with: .color(curtain))
            ctx.strokePath(curtainFold, width: 0.7) { q in
                q.move(to: pt(fx(42), 10)); q.addQuadCurve(to: pt(fx(42), 22), control: pt(fx(43), 16))
                q.move(to: pt(fx(42.5), 25)); q.addQuadCurve(to: pt(fx(43), 36), control: pt(fx(41.5), 31))
            }
            ctx.rect(flip ? fx(46.5) : 40.5, 21.8, 6, 2.4, tie, radius: 1.2)
        }
    }

    // MARK: - Giường (đầu giường bên trái, cạnh tủ đầu giường)

    /// Nệm + gối + chăn dùng chung cho các giường có khung.
    private static func mattress(_ ctx: GraphicsContext, blanket: Color, blanketTop: Color, cuff: Color,
                                 pattern: ((GraphicsContext) -> Void)? = nil) {
        // Nệm
        ctx.rect(12, 54, 80, 24, rgb(0xEFE4DA), radius: 5)
        ctx.rect(12, 50, 80, 10, rgb(0xFFFBF5), radius: 5)
        // Gối
        ctx.ellipse(15, 39, 28, 17, rgb(0xFFFDFB))
        ctx.ellipse(18, 47, 22, 6, rgb(0xEEE6F2))
        ctx.ellipse(20, 42, 8, 3.5, shine)
        // Chăn
        var b = ctx
        b.clip(to: Path(roundedRect: CGRect(x: 36, y: 48, width: 56, height: 33), cornerRadius: 6))
        b.rect(36, 48, 56, 33, blanket)
        b.rect(36, 48, 56, 9, blanketTop)
        pattern?(b)
        b.rect(36, 79, 56, 2, Color.black.opacity(0.06))
        // Mép chăn gập
        ctx.rect(33, 47, 9, 34, cuff, radius: 4.5)
        ctx.rect(35, 49, 2, 28, Color.white.opacity(0.45), radius: 1)
    }

    private static func bedMat(_ ctx: GraphicsContext) {
        shadow(ctx, 4, 85, 92, 11)
        ctx.rect(6, 70, 88, 20, rgb(0xE9DCEC), radius: 8)
        ctx.rect(6, 66, 88, 11, rgb(0xFBF6FC), radius: 6)
        // Đường may nệm
        for x in [CGFloat(28), 50, 72] {
            ctx.circle(x, 83, 1.2, rgb(0xD6C4DD))
        }
        // Chăn gập
        ctx.rect(46, 63, 44, 17, rgb(0xB9DCC4), radius: 6)
        ctx.rect(46, 63, 44, 6, rgb(0xD3EBDA), radius: 5)
        ctx.rect(46, 72, 44, 2.2, rgb(0xF6FBF7).opacity(0.9))
        // Gối tròn
        ctx.circle(22, 61, 11, rgb(0xFCE5C8))
        ctx.circle(22, 61, 4, rgb(0xF4C9A0))
        ctx.circle(22, 61, 1.5, rgb(0xFCE5C8))
        ctx.circle(17, 56, 2.4, shine)
    }

    private static func bedWood(_ ctx: GraphicsContext) {
        let wood = rgb(0xCFA175)
        let woodDark = rgb(0xB3845A)
        shadow(ctx, 2, 89, 98, 9)
        // Đầu giường
        ctx.rect(3, 22, 14, 72, wood, radius: 6)
        ctx.rect(6, 28, 8, 20, woodDark.opacity(0.55), radius: 3)
        ctx.rect(5, 24, 3, 18, Color.white.opacity(0.3), radius: 1.5)
        // Thanh giường
        ctx.rect(10, 74, 82, 8, woodDark, radius: 3)
        mattress(ctx, blanket: rgb(0xF2A890), blanketTop: rgb(0xF6BEA9), cuff: rgb(0xFFF4E8)) { b in
            for x in stride(from: CGFloat(44), to: 92, by: 10) {
                b.rect(x, 48, 2.4, 33, Color.white.opacity(0.45))
            }
            for y in stride(from: CGFloat(52), to: 82, by: 8) {
                b.rect(36, y, 56, 2.4, rgb(0xD9806B).opacity(0.45))
            }
        }
        // Chân cuối giường
        ctx.rect(86, 46, 11, 48, wood, radius: 5)
        ctx.rect(88, 52, 7, 14, woodDark.opacity(0.55), radius: 2.5)
        ctx.circle(91.5, 44.5, 4, wood)
        ctx.circle(90, 43, 1.3, Color.white.opacity(0.35))
        ctx.circle(10, 21, 5, wood)
        ctx.circle(8.5, 19.5, 1.6, Color.white.opacity(0.35))
    }

    private static func bedCanopy(_ ctx: GraphicsContext) {
        let post = rgb(0xF2C6D6)
        let postDark = rgb(0xE3A9BF)
        let voile = rgb(0xFFF6FA)
        shadow(ctx, 2, 89, 98, 9)
        // Cột màn
        ctx.rect(5, 6, 5, 88, post, radius: 2.5)
        ctx.rect(90, 6, 5, 88, post, radius: 2.5)
        // Đầu giường hình vòm có trái tim
        ctx.rect(3, 32, 15, 62, post, radius: 7)
        ctx.heart(center: pt(10.5, 44), size: 8, Color.white.opacity(0.8))
        ctx.rect(10, 74, 82, 8, postDark, radius: 3)
        mattress(ctx, blanket: rgb(0xF7BDD0), blanketTop: rgb(0xFBD3E0), cuff: rgb(0xFFFFFF)) { b in
            for i in 0..<12 {
                let x = 40 + CGFloat(i % 4) * 14 + CGFloat((i / 4) % 2) * 7
                let y = 60 + CGFloat(i / 4) * 7
                b.circle(x, y, 1.1, Color.white.opacity(0.8))
            }
        }
        ctx.rect(86, 50, 10, 44, post, radius: 5)
        ctx.heart(center: pt(91, 60), size: 5, Color.white.opacity(0.75))
        // Mái rèm + diềm lượn sóng
        ctx.rect(3, 3, 94, 6, post, radius: 3)
        for i in 0..<10 {
            ctx.circle(8 + CGFloat(i) * 9.4, 9, 4.8, voile)
        }
        ctx.rect(3, 3, 94, 2, Color.white.opacity(0.4), radius: 1)
        // Voan buộc ở hai cột (trong suốt)
        for flip in [false, true] {
            let fx: (CGFloat) -> CGFloat = { x in flip ? 100 - x : x }
            var p = Path()
            p.move(to: pt(fx(4), 9))
            p.addLine(to: pt(fx(22), 9))
            p.addQuadCurve(to: pt(fx(9), 48), control: pt(fx(20), 34))
            p.addQuadCurve(to: pt(fx(15), 84), control: pt(fx(6), 66))
            p.addLine(to: pt(fx(3), 84))
            p.addQuadCurve(to: pt(fx(4), 9), control: pt(fx(1), 46))
            p.closeSubpath()
            ctx.fill(p, with: .color(voile.opacity(0.62)))
            ctx.rect(flip ? fx(12) : 3, 46, 9, 4, rgb(0xF4A9C0), radius: 2)
            ctx.circle(fx(7.5), 48, 2.2, rgb(0xEC8FAE))
        }
        ctx.circle(7.5, 3, 3, postDark)
        ctx.circle(92.5, 3, 3, postDark)
    }

    private static func bedCloud(_ ctx: GraphicsContext) {
        let cloud = rgb(0xFBFDFF)
        let cloudShade = rgb(0xD7E6F6)
        shadow(ctx, 12, 91, 80, 7)
        // Thân mây (lớp bóng rồi lớp trắng)
        for (dy, color) in [(CGFloat(2.5), cloudShade), (0, cloud)] {
            ctx.rect(8, 54 + dy, 86, 26, color, radius: 13)
            for (x, r) in [(CGFloat(16), CGFloat(8)), (31, 9), (49, 9.5), (67, 9), (84, 8)] {
                ctx.circle(x, 80 + dy, r, color)
            }
            ctx.circle(92, 66 + dy, 9, color)
        }
        // Đầu giường: cụm mây
        for (dx, color) in [(CGFloat(1.5), cloudShade), (0, cloud)] {
            ctx.circle(13 + dx, 44, 11, color)
            ctx.circle(22 + dx, 30, 10, color)
            ctx.circle(10 + dx, 58, 9, color)
            ctx.circle(30 + dx, 40, 7, color)
        }
        ctx.circle(18, 26, 3, shine)
        // Gối
        ctx.ellipse(18, 42, 26, 15, rgb(0xE6DEF8))
        ctx.ellipse(22, 44, 8, 3.5, shine)
        // Chăn vàng nhạt có sao
        ctx.rect(40, 48, 52, 24, rgb(0xFFE6A6), radius: 11)
        ctx.rect(40, 48, 52, 8, rgb(0xFFF0C8), radius: 8)
        ctx.rect(37, 47, 8, 26, rgb(0xFFF7E2), radius: 4)
        for (x, y) in [(CGFloat(54), CGFloat(62)), (68, 57), (82, 64)] {
            sparkle(ctx, x, y, 7, rgb(0xF2C25E))
        }
        // Lấp lánh quanh giường
        for (x, y, s) in [(CGFloat(48), CGFloat(32), CGFloat(7)), (90, 40, 6), (4, 78, 5)] {
            sparkle(ctx, x, y, s, rgb(0xB9D4F2))
        }
    }

    // MARK: - Tủ đầu giường (sàn ở y ≈ 77, chân chạm y ≈ 96)

    private static func cabinet(_ ctx: GraphicsContext, body: Color, top: Color, front: Color, knob: Color) {
        shadow(ctx, 14, 91, 72, 8)
        ctx.rect(24, 88, 5, 7, top, radius: 1.5)
        ctx.rect(71, 88, 5, 7, top, radius: 1.5)
        ctx.rect(20, 50, 60, 40, body, radius: 5)
        ctx.rect(16, 46, 68, 7, top, radius: 3)
        ctx.rect(18, 46.8, 30, 1.6, Color.white.opacity(0.35), radius: 0.8)
        ctx.rect(25, 58, 50, 12, front, radius: 3)
        ctx.rect(25, 73, 50, 12, front, radius: 3)
        ctx.circle(50, 64, 2.4, knob)
        ctx.circle(50, 79, 2.4, knob)
        ctx.circle(49.3, 63.3, 0.8, shine)
        ctx.circle(49.3, 78.3, 0.8, shine)
    }

    private static func standCrate(_ ctx: GraphicsContext) {
        let wood = rgb(0xD9B087)
        let dark = rgb(0xBE915F)
        shadow(ctx, 12, 90, 76, 8)
        ctx.rect(18, 50, 64, 44, wood, radius: 3)
        ctx.rect(18, 64, 64, 1.6, dark)
        ctx.rect(18, 79, 64, 1.6, dark)
        ctx.rect(18, 50, 7, 44, dark, radius: 2)
        ctx.rect(75, 50, 7, 44, dark, radius: 2)
        ctx.rect(26, 52, 40, 1.4, Color.white.opacity(0.35))
        for (x, y) in [(CGFloat(21.5), CGFloat(55)), (78.5, 55), (21.5, 89), (78.5, 89)] {
            ctx.circle(x, y, 1, rgb(0x8E6247))
        }
        // Sách
        ctx.rect(24, 42, 30, 8, rgb(0xB9A6EA), radius: 1.5)
        ctx.rect(26, 44, 26, 2.4, rgb(0xFFFBF5))
        ctx.rect(27, 35, 24, 7, rgb(0xA9D8BA), radius: 1.5)
        ctx.rect(29, 37, 20, 2, rgb(0xFFFBF5))
        // Cốc nước
        ctx.rect(58, 26, 15, 24, rgb(0xE4F2FB), radius: 3.5)
        ctx.rect(59.5, 35, 12, 13.5, rgb(0xAED7F2), radius: 2.5)
        ctx.ellipse(58, 24, 15, 4.5, rgb(0xF4FAFE))
        ctx.rect(60.5, 29, 2.2, 16, Color.white.opacity(0.75), radius: 1.1)
    }

    private static func standLamp(_ ctx: GraphicsContext) {
        cabinet(ctx, body: rgb(0xF0DCC6), top: rgb(0xDDBB97), front: rgb(0xF9EBDB), knob: rgb(0xC48F64))
        // Quầng sáng
        ctx.circle(50, 20, 24, rgb(0xFFE08A).opacity(0.22))
        ctx.circle(50, 20, 17, rgb(0xFFE08A).opacity(0.22))
        // Đèn
        ctx.ellipse(38, 41, 24, 7, rgb(0xB9A6EA))
        ctx.rect(48.5, 24, 3, 19, rgb(0xB9A6EA), radius: 1.5)
        ctx.polygon([pt(32, 28), pt(68, 28), pt(61, 6), pt(39, 6)], rgb(0xF7D27A))
        ctx.rect(32, 26, 36, 4, rgb(0xEFC260), radius: 2)
        ctx.rect(39, 5, 22, 3, rgb(0xFBE3A4), radius: 1.5)
        ctx.polygon([pt(42, 10), pt(46, 10), pt(42, 24), pt(37.5, 24)], Color.white.opacity(0.5))
    }

    private static func standRadio(_ ctx: GraphicsContext) {
        cabinet(ctx, body: rgb(0xC9A27C), top: rgb(0xA97F58), front: rgb(0xD9B791), knob: rgb(0xFCEBD0))
        // Ăng-ten
        ctx.strokePath(rgb(0x9A93A8), width: 1.6) { p in
            p.move(to: pt(66, 24)); p.addLine(to: pt(80, 6))
        }
        ctx.circle(80, 6, 2.4, rgb(0xF4A9A0))
        // Radio
        ctx.rect(22, 20, 56, 27, rgb(0xEFA289), radius: 8)
        ctx.rect(22, 20, 56, 6, rgb(0xF5BBA6), radius: 6)
        ctx.circle(37, 34, 9, rgb(0xFBE3D4))
        for (dx, dy) in [(CGFloat(-4), CGFloat(-4)), (0, -4), (4, -4), (-4, 0), (0, 0), (4, 0), (-4, 4), (0, 4), (4, 4)] {
            ctx.circle(37 + dx, 34 + dy, 1.1, rgb(0xDB8A70))
        }
        ctx.rect(51, 28, 21, 8, rgb(0xFFF4E2), radius: 2)
        for i in 0..<5 {
            ctx.rect(53.5 + CGFloat(i) * 4, 30, 0.8, 3, rgb(0xC9A27C))
        }
        ctx.rect(62, 28.5, 1.2, 7, rgb(0xE0625A))
        ctx.circle(56, 41, 2.8, rgb(0xFFF4E2))
        ctx.circle(67, 41, 2.8, rgb(0xFFF4E2))
        ctx.rect(26, 22, 14, 1.8, shine, radius: 0.9)
        // Nốt nhạc
        ctx.draw(Text("♪").font(.system(size: 13)).foregroundColor(rgb(0x9F8BDB)), at: pt(13, 18))
        ctx.draw(Text("♫").font(.system(size: 11)).foregroundColor(rgb(0xE48FAE)), at: pt(90, 22))
    }

    private static func standMoon(_ ctx: GraphicsContext) {
        cabinet(ctx, body: rgb(0xD9CCF2), top: rgb(0xC0AEE8), front: rgb(0xEAE2FA), knob: rgb(0xF7D27A))
        // Quầng sáng trăng
        ctx.circle(50, 22, 25, rgb(0xFFF1C2).opacity(0.3))
        ctx.circle(50, 22, 19, rgb(0xFFF1C2).opacity(0.35))
        // Đế + mặt trăng
        ctx.ellipse(36, 41, 28, 7, rgb(0xCFA175))
        ctx.rect(47.5, 34, 5, 9, rgb(0xCFA175), radius: 1.5)
        ctx.circle(50, 21, 15, rgb(0xFFF1C2))
        ctx.circle(43, 15, 3, rgb(0xF4DFA2))
        ctx.circle(58, 27, 2.4, rgb(0xF4DFA2))
        ctx.circle(56, 13, 1.6, rgb(0xF4DFA2))
        // Mặt ngủ
        ctx.strokePath(ink, width: 1.3) { p in
            p.move(to: pt(42, 22)); p.addQuadCurve(to: pt(47, 22), control: pt(44.5, 24.5))
            p.move(to: pt(53, 22)); p.addQuadCurve(to: pt(58, 22), control: pt(55.5, 24.5))
        }
        ctx.ellipse(39, 25, 5, 3, Palette.blush.opacity(0.8))
        ctx.ellipse(56, 25, 5, 3, Palette.blush.opacity(0.8))
        ctx.circle(44, 11, 2, shine)
        sparkle(ctx, 76, 10, 7, rgb(0xF7D27A))
        sparkle(ctx, 22, 20, 5, rgb(0xF7D27A))
    }

    // MARK: - Trang trí tường (phía trên giường)

    private static func wallGarland(_ ctx: GraphicsContext) {
        let a = pt(4, 22), c = pt(50, 50), b = pt(96, 22)
        ctx.strokePath(rgb(0xA593B8), width: 1.4) { p in
            p.move(to: a); p.addQuadCurve(to: b, control: c)
        }
        let colors = [rgb(0xF4A9A0), rgb(0xF7D27A), rgb(0xA9DDB8), rgb(0xB9A6EA), rgb(0xF6AFC4), rgb(0xAFCFF2), rgb(0xF7C59F)]
        for i in 0..<7 {
            let t = 0.1 + CGFloat(i) * 0.8 / 6
            let m = quad(a, c, b, t)
            ctx.polygon([pt(m.x - 6, m.y - 0.5), pt(m.x + 6, m.y - 0.5), pt(m.x, m.y + 15)], colors[i])
            ctx.polygon([pt(m.x - 4, m.y + 0.5), pt(m.x - 1, m.y + 0.5), pt(m.x - 1.6, m.y + 7)], Color.white.opacity(0.4))
        }
        ctx.circle(a.x, a.y, 2.6, rgb(0xCFA175))
        ctx.circle(b.x, b.y, 2.6, rgb(0xCFA175))
    }

    private static func wallFairy(_ ctx: GraphicsContext) {
        let swags: [(CGPoint, CGPoint, CGPoint)] = [(pt(4, 18), pt(27, 44), pt(50, 22)), (pt(50, 22), pt(73, 44), pt(96, 18))]
        for (a, c, b) in swags {
            ctx.strokePath(rgb(0x8F86A8), width: 1.2) { p in
                p.move(to: a); p.addQuadCurve(to: b, control: c)
            }
        }
        let colors = [rgb(0xFFE08A), rgb(0xF9B8C8), rgb(0xB8E6C4), rgb(0xFFE08A), rgb(0xF9B8C8), rgb(0xB8E6C4)]
        var k = 0
        for (a, c, b) in swags {
            for t in [CGFloat(0.22), 0.5, 0.78] {
                let m = quad(a, c, b, t)
                ctx.circle(m.x, m.y + 6, 8, colors[k].opacity(0.25))
                ctx.circle(m.x, m.y + 6, 5, colors[k].opacity(0.3))
                ctx.rect(m.x - 1.8, m.y - 0.5, 3.6, 3.5, rgb(0x8F86A8), radius: 1)
                ctx.ellipse(m.x - 3, m.y + 2, 6, 8.5, colors[k])
                ctx.ellipse(m.x - 1.6, m.y + 3.5, 1.8, 3, Color.white.opacity(0.75))
                k += 1
            }
        }
        for (x, y, s) in [(CGFloat(16), CGFloat(44), CGFloat(7)), (50, 40, 6), (84, 46, 7), (34, 12, 5), (68, 10, 5)] {
            sparkle(ctx, x, y, s, rgb(0xF7D27A))
        }
        ctx.circle(4, 18, 2.4, rgb(0xCFA175))
        ctx.circle(50, 22, 2.4, rgb(0xCFA175))
        ctx.circle(96, 18, 2.4, rgb(0xCFA175))
    }

    private static func wallMoon(_ ctx: GraphicsContext) {
        let navy = rgb(0x3F3A78)
        // Dây treo
        ctx.strokePath(rgb(0xA593B8), width: 1.2) { p in
            p.move(to: pt(26, 14)); p.addLine(to: pt(50, 3)); p.addLine(to: pt(74, 14))
        }
        ctx.circle(50, 3, 2.2, rgb(0xCFA175))
        // Khung
        ctx.rect(12, 12, 76, 66, rgb(0xF2D7B6), radius: 5)
        ctx.rect(17, 17, 66, 56, navy, radius: 2.5)
        // Sao
        for (x, y) in [(CGFloat(26), CGFloat(26)), (72, 24), (64, 42), (30, 50), (76, 54)] {
            ctx.circle(x, y, 1, rgb(0xFFF1C2))
        }
        sparkle(ctx, 70, 33, 8, rgb(0xFFE08A))
        sparkle(ctx, 25, 36, 6, rgb(0xFFE08A))
        // Trăng khuyết đang ngủ
        ctx.circle(46, 40, 15, rgb(0xFFE7A0))
        ctx.circle(54, 34, 13, navy)
        ctx.strokePath(ink, width: 1.4) { p in
            p.move(to: pt(37, 41)); p.addQuadCurve(to: pt(42, 43), control: pt(39, 44.5))
        }
        ctx.ellipse(36, 45, 5, 2.8, Palette.blush.opacity(0.85))
        ctx.circle(37, 31, 1.8, shine)
        ctx.draw(Text("z").font(.system(size: 8, weight: .bold)).foregroundColor(rgb(0xD9CCF2)), at: pt(58, 30))
        ctx.draw(Text("z").font(.system(size: 6, weight: .bold)).foregroundColor(rgb(0xD9CCF2)), at: pt(64, 24))
        // Mây
        var cl = ctx
        cl.clip(to: Path(roundedRect: CGRect(x: 17, y: 17, width: 66, height: 56), cornerRadius: 2.5))
        cl.ellipse(18, 58, 66, 22, rgb(0xE9E4F8))
        cl.circle(36, 60, 9, rgb(0xE9E4F8))
        cl.circle(52, 56, 10, rgb(0xE9E4F8))
        cl.circle(68, 61, 8, rgb(0xE9E4F8))
        cl.circle(48, 52, 2.5, Color.white.opacity(0.6))
        ctx.rect(14, 13.5, 30, 1.6, Color.white.opacity(0.5), radius: 0.8)
    }

    private static func wallDreamcatcher(_ ctx: GraphicsContext) {
        let hoop = rgb(0xCFA175)
        let web = rgb(0xFFF6EC)
        let center = pt(50, 34)
        ctx.strokePath(rgb(0xA593B8), width: 1.2) { p in
            p.move(to: pt(50, 3)); p.addLine(to: pt(50, 13))
        }
        ctx.circle(50, 3, 2.2, hoop)
        // Lưới
        var pts: [CGPoint] = []
        for i in 0..<7 {
            let a = Double(i) / 7 * 2 * Double.pi - Double.pi / 2
            pts.append(pt(center.x + 20 * CGFloat(cos(a)), center.y + 20 * CGFloat(sin(a))))
        }
        ctx.strokePath(web, width: 0.9) { p in
            for i in 0..<7 {
                p.move(to: pts[i]); p.addLine(to: pts[(i + 3) % 7])
            }
            p.addEllipse(in: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18))
        }
        ctx.circle(center.x, center.y, 3, rgb(0xB9A6EA))
        ctx.strokePath(hoop, width: 4) { p in
            p.addEllipse(in: CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40))
        }
        ctx.strokePath(Color.white.opacity(0.45), width: 1) { p in
            p.addArc(center: center, radius: 20, startAngle: .degrees(200), endAngle: .degrees(250), clockwise: false)
        }
        // Lông vũ
        let feathers: [(CGFloat, CGFloat, Color, Double)] = [(34, 52, rgb(0xF6AFC4), 10), (50, 56, rgb(0xB9A6EA), 0), (66, 52, rgb(0xA9DDB8), -10)]
        for (x, y, color, tilt) in feathers {
            let end = y + 16
            ctx.strokePath(web.opacity(0.9), width: 0.9) { p in
                p.move(to: pt(x, y)); p.addLine(to: pt(x, end))
            }
            ctx.circle(x, y + 8, 2.2, rgb(0xF7D27A))
            ctx.rotated(tilt, around: pt(x, end)) { c in
                c.ellipse(x - 4.5, end, 9, 20, color)
                c.strokePath(Color.white.opacity(0.6), width: 0.8) { p in
                    p.move(to: pt(x, end + 2)); p.addLine(to: pt(x, end + 18))
                }
            }
        }
    }

    // MARK: - Tủ (chân chạm y ≈ 99, ngay đường tường–sàn)

    private static func closetDresser(_ ctx: GraphicsContext) {
        let body = rgb(0xEBC9A8)
        let top = rgb(0xD6AB84)
        let drawer = rgb(0xF6DEC4)
        let knob = rgb(0xB98A62)
        shadow(ctx, 6, 95, 88, 7)
        ctx.rect(14, 92, 6, 7, top, radius: 1.5)
        ctx.rect(80, 92, 6, 7, top, radius: 1.5)
        ctx.rect(10, 40, 80, 54, body, radius: 5)
        ctx.rect(6, 36, 88, 7, top, radius: 3)
        ctx.rect(9, 37, 40, 1.6, Color.white.opacity(0.35), radius: 0.8)
        for i in 0..<3 {
            let y = 47 + CGFloat(i) * 15
            ctx.rect(16, y, 68, 12, drawer, radius: 3)
            ctx.circle(36, y + 6, 2.6, knob)
            ctx.circle(64, y + 6, 2.6, knob)
            ctx.circle(35.2, y + 5.2, 0.9, shine)
            ctx.circle(63.2, y + 5.2, 0.9, shine)
        }
        // Chậu cây nhỏ
        ctx.rect(18, 26, 14, 10, rgb(0xF4B0C0), radius: 3)
        ctx.ellipse(14, 14, 12, 14, rgb(0x8FC79C))
        ctx.ellipse(23, 10, 12, 17, rgb(0xA9DDB8))
        // Khung ảnh có trái tim
        ctx.rect(58, 18, 20, 18, rgb(0xFFFBF5), radius: 2.5)
        ctx.rect(61, 21, 14, 12, rgb(0xD9E8F6), radius: 1.5)
        ctx.heart(center: pt(68, 27), size: 7, rgb(0xF4A9C0))
    }

    private static func closetMirror(_ ctx: GraphicsContext) {
        let frame = rgb(0xF2C6D6)
        let frameDark = rgb(0xE3A9BF)
        shadow(ctx, 18, 94, 64, 7)
        // Chân đế
        ctx.polygon([pt(44, 78), pt(56, 78), pt(70, 97), pt(62, 97)], frameDark)
        ctx.polygon([pt(44, 78), pt(56, 78), pt(38, 97), pt(30, 97)], frameDark)
        ctx.rect(46, 74, 8, 22, frame, radius: 3)
        // Khung + gương
        ctx.ellipse(24, 6, 52, 76, frame)
        ctx.ellipse(29, 11, 42, 66, rgb(0xDDEEF8))
        var g = ctx
        g.clip(to: Path(ellipseIn: CGRect(x: 29, y: 11, width: 42, height: 66)))
        g.ellipse(26, 52, 50, 34, rgb(0xC9E2F3))
        g.polygon([pt(34, 40), pt(54, 14), pt(60, 14), pt(36, 48)], Color.white.opacity(0.65))
        g.polygon([pt(40, 54), pt(62, 26), pt(65, 30), pt(42, 58)], Color.white.opacity(0.45))
        ctx.heart(center: pt(50, 6), size: 12, rgb(0xF4A9C0))
        ctx.circle(28, 44, 2, Color.white.opacity(0.6))
        ctx.circle(72, 44, 2, Color.white.opacity(0.6))
        ctx.circle(50, 81.5, 2, Color.white.opacity(0.6))
    }

    private static func closetWardrobe(_ ctx: GraphicsContext) {
        let body = rgb(0xD5C4EF)
        let door = rgb(0xE8DFF8)
        let top = rgb(0xBEA9E6)
        shadow(ctx, 4, 95, 92, 7)
        ctx.rect(14, 92, 7, 7, top, radius: 1.5)
        ctx.rect(79, 92, 7, 7, top, radius: 1.5)
        ctx.rect(8, 10, 84, 84, body, radius: 5)
        ctx.rect(4, 4, 92, 9, top, radius: 4)
        ctx.rect(7, 5, 40, 2, Color.white.opacity(0.35), radius: 1)
        ctx.rect(13, 17, 36, 72, door, radius: 4)
        ctx.rect(51, 17, 36, 72, door, radius: 4)
        ctx.rect(18, 23, 26, 26, body.opacity(0.55), radius: 3)
        ctx.rect(18, 55, 26, 28, body.opacity(0.55), radius: 3)
        ctx.rect(56, 55, 26, 28, body.opacity(0.55), radius: 3)
        ctx.circle(45, 52, 2.6, rgb(0xF7D27A))
        ctx.circle(55, 52, 2.6, rgb(0xF7D27A))
        ctx.circle(44.3, 51.3, 0.9, shine)
        ctx.circle(54.3, 51.3, 0.9, shine)
        // Móc treo khăn
        ctx.rect(64, 24, 12, 3, rgb(0xCFA175), radius: 1.5)
        ctx.rect(63, 25, 14, 26, rgb(0xF4B0B0), radius: 3)
        ctx.rect(63, 25, 14, 5, rgb(0xF8C8C8), radius: 3)
        ctx.rect(63, 41, 14, 2.4, Color.white.opacity(0.8))
        ctx.rect(63, 45, 14, 1.4, Color.white.opacity(0.8))
        ctx.heart(center: pt(50, 8.5), size: 6, rgb(0xF4A9C0))
    }

    private static func closetVanity(_ ctx: GraphicsContext) {
        let wood = rgb(0xF6D2DD)
        let woodDark = rgb(0xE9B3C5)
        shadow(ctx, 6, 95, 88, 7)
        // Chân bàn
        ctx.rect(14, 66, 6, 32, woodDark, radius: 3)
        ctx.rect(80, 66, 6, 32, woodDark, radius: 3)
        ctx.rect(16, 86, 68, 3, woodDark, radius: 1.5)
        // Mặt bàn + ngăn kéo
        ctx.rect(10, 60, 80, 16, wood, radius: 4)
        ctx.rect(6, 55, 88, 7, woodDark, radius: 3)
        ctx.rect(9, 56, 40, 1.5, Color.white.opacity(0.4), radius: 0.8)
        ctx.rect(32, 64, 36, 9, rgb(0xFCE8EE), radius: 2.5)
        ctx.circle(50, 68.5, 1.8, rgb(0xF7D27A))
        // Gương tròn viền đèn
        ctx.rect(45, 46, 10, 10, woodDark, radius: 2)
        ctx.circle(50, 29, 24, rgb(0xFFF6FA))
        ctx.circle(50, 29, 18, rgb(0xDDEEF8))
        var g = ctx
        g.clip(to: Path(ellipseIn: CGRect(x: 32, y: 11, width: 36, height: 36)))
        g.polygon([pt(36, 30), pt(52, 12), pt(58, 12), pt(38, 36)], Color.white.opacity(0.65))
        for i in 0..<12 {
            let a = Double(i) / 12 * 2 * Double.pi
            let x = 50 + 21 * CGFloat(cos(a)), y = 29 + 21 * CGFloat(sin(a))
            ctx.circle(x, y, 3.6, rgb(0xFFE08A).opacity(0.3))
            ctx.circle(x, y, 2.2, rgb(0xFFF1C2))
        }
        // Lọ nước hoa & son
        ctx.rect(15, 44, 10, 11, rgb(0xB9A6EA), radius: 3)
        ctx.rect(18, 40, 4, 4, rgb(0xF7D27A), radius: 1)
        ctx.rect(17, 46, 2, 6, Color.white.opacity(0.6), radius: 1)
        ctx.rect(78, 45, 5, 10, rgb(0xF4A9C0), radius: 1.5)
        ctx.rect(78.5, 41, 4, 4, rgb(0xE0625A), radius: 1.8)
        ctx.ellipse(64, 51, 10, 4.5, rgb(0xA9DDB8))
    }

    // MARK: - Thảm (vẽ trong x 18…88, y 58…96 rồi phóng to quanh đáy để nằm dưới chân thú cưng)

    private static func rugSpace(_ ctx: GraphicsContext) -> GraphicsContext {
        var c = ctx
        c.translateBy(x: 52, y: 95)
        c.scaleBy(x: 1.12, y: 1.25)
        c.translateBy(x: -53, y: -96)
        return c
    }

    private static func rugRound(_ ctx: GraphicsContext) {
        ctx.ellipse(18, 61, 70, 35, rgb(0xE8D3B8))
        ctx.ellipse(18, 58, 70, 35, rgb(0xF8ECDB))
        ctx.ellipse(24, 61, 58, 29, rgb(0xD9CCF2))
        ctx.ellipse(29, 63.5, 48, 24, rgb(0xF8ECDB))
        ctx.ellipse(39, 68.5, 28, 14, rgb(0xF6C3C3))
        ctx.ellipse(45, 71.5, 16, 8, rgb(0xFBDDDA))
        // Hạt len
        for i in 0..<10 {
            let a = Double(i) / 10 * 2 * Double.pi
            ctx.circle(53 + 26.5 * CGFloat(cos(a)), 75.5 + 13 * CGFloat(sin(a)), 1.2, Color.white.opacity(0.75))
        }
    }

    private static func rugHeart(_ ctx: GraphicsContext) {
        var c = ctx
        c.translateBy(x: 53, y: 78)
        c.scaleBy(x: 1, y: 0.58)
        c.heart(center: pt(0, 6), size: 70, rgb(0xEC97AF))
        c.heart(center: .zero, size: 70, rgb(0xF6B3C6))
        c.heart(center: pt(0, 1), size: 52, rgb(0xFAC9D6))
        c.heart(center: pt(0, 2), size: 30, rgb(0xFDE0E8))
        for (x, y) in [(CGFloat(-22), CGFloat(-12)), (18, -14), (-8, 8), (10, 4), (0, -6), (-26, -2), (26, -4)] {
            c.circle(x, y, 1.6, Color.white.opacity(0.7))
        }
    }

    private static func rugCloud(_ ctx: GraphicsContext) {
        let shade = rgb(0xCFE0F3)
        let white = rgb(0xFBFDFF)
        for (dy, color) in [(CGFloat(3), shade), (0, white)] {
            ctx.ellipse(22, 74 + dy, 62, 18, color)
            ctx.ellipse(18, 70 + dy, 26, 18, color)
            ctx.ellipse(32, 61 + dy, 30, 22, color)
            ctx.ellipse(52, 60 + dy, 28, 22, color)
            ctx.ellipse(66, 68 + dy, 22, 20, color)
        }
        ctx.ellipse(38, 65, 14, 5, Color.white)
        ctx.ellipse(36, 64, 9, 3, rgb(0xE6F0FA))
        for (x, y) in [(CGFloat(30), CGFloat(80)), (52, 84), (72, 78)] {
            ctx.circle(x, y, 1.4, shade)
        }
    }

    private static func rugRainbow(_ ctx: GraphicsContext) {
        let colors = [rgb(0xF4A3A8), rgb(0xF7C59F), rgb(0xF9E3A0), rgb(0xBFE3B4), rgb(0xAFD3F2), rgb(0xB9B4EE), rgb(0xD8B9EE)]
        var c = ctx
        c.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 90)))
        let cx: CGFloat = 53, cy: CGFloat = 90
        for (i, color) in colors.enumerated() {
            let rx = 34 - CGFloat(i) * 3.6
            let ry = rx * 0.82
            c.ellipse(cx - rx, cy - ry, rx * 2, ry * 2, color)
        }
        let rx: CGFloat = 34 - 7 * 3.6
        c.ellipse(cx - rx, cy - rx * 0.82, rx * 2, rx * 1.64, rgb(0xFFF6EC))
        ctx.rect(19, 89, 68, 3, Color.black.opacity(0.07), radius: 1.5)
        // Mây hai chân cầu vồng
        for x in [CGFloat(17), 68] {
            ctx.ellipse(x, 84, 22, 10, rgb(0xDDE8F5))
            ctx.ellipse(x, 82, 22, 9, Color.white)
            ctx.circle(x + 7, 82, 5, Color.white)
            ctx.circle(x + 14, 81, 6, Color.white)
        }
    }

    // MARK: - Đồ chơi (góc trái phía trước, chân chạm y ≈ 94)

    private static func plushYarn(_ ctx: GraphicsContext) {
        let yarn = rgb(0xF4A9C0)
        let line = rgb(0xDE86A4)
        shadow(ctx, 14, 86, 72, 10)
        // Sợi len lòng thòng
        ctx.strokePath(yarn, width: 3) { p in
            p.move(to: pt(68, 80))
            p.addQuadCurve(to: pt(84, 88), control: pt(76, 92))
            p.addQuadCurve(to: pt(92, 78), control: pt(96, 86))
            p.addQuadCurve(to: pt(86, 90), control: pt(84, 80))
        }
        ctx.circle(46, 62, 28, yarn)
        var c = ctx
        c.clip(to: Path(ellipseIn: CGRect(x: 18, y: 34, width: 56, height: 56)))
        c.strokePath(line, width: 2.2) { p in
            for i in 0..<5 {
                let o = CGFloat(i) * 9
                p.move(to: pt(14, 46 + o)); p.addQuadCurve(to: pt(78, 30 + o), control: pt(40, 26 + o))
            }
            for i in 0..<3 {
                let o = CGFloat(i) * 10
                p.move(to: pt(30 + o, 92)); p.addQuadCurve(to: pt(58 + o, 34), control: pt(30 + o, 54))
            }
        }
        ctx.ellipse(28, 44, 12, 8, Color.white.opacity(0.45))
        // Que đan
        ctx.rect(56, 22, 3.5, 44, rgb(0xCFA175), radius: 1.75)
        ctx.circle(57.7, 22, 3.4, rgb(0xB9A6EA))
    }

    private static func plushBall(_ ctx: GraphicsContext) {
        shadow(ctx, 16, 86, 68, 10)
        ctx.circle(50, 62, 28, rgb(0xFFF6EC))
        var c = ctx
        c.clip(to: Path(ellipseIn: CGRect(x: 22, y: 34, width: 56, height: 56)))
        c.rotated(-24, around: pt(50, 62)) { r in
            r.rect(10, 38, 80, 10, rgb(0xF4A3A8))
            r.rect(10, 57, 80, 10, rgb(0xAFD3F2))
            r.rect(10, 76, 80, 10, rgb(0xF9D98A))
        }
        c.ellipse(22, 74, 56, 22, Color.black.opacity(0.05))
        ctx.ellipse(32, 42, 14, 9, Color.white.opacity(0.6))
        ctx.circle(47, 40, 2, Color.white.opacity(0.6))
    }

    private static func plushTeddy(_ ctx: GraphicsContext) {
        let fur = rgb(0xCFA27A)
        let furDark = rgb(0xB8875F)
        let light = rgb(0xF1D8BE)
        shadow(ctx, 14, 86, 72, 10)
        // Chân
        ctx.ellipse(20, 72, 26, 20, fur)
        ctx.ellipse(54, 72, 26, 20, fur)
        ctx.ellipse(24, 76, 14, 12, light)
        ctx.ellipse(62, 76, 14, 12, light)
        // Thân + tay
        ctx.ellipse(28, 48, 44, 40, fur)
        ctx.ellipse(37, 58, 26, 26, light)
        ctx.ellipse(16, 52, 18, 24, furDark)
        ctx.ellipse(66, 52, 18, 24, furDark)
        // Đầu
        ctx.circle(31, 18, 9, fur)
        ctx.circle(69, 18, 9, fur)
        ctx.circle(31, 18, 4.5, light)
        ctx.circle(69, 18, 4.5, light)
        ctx.circle(50, 34, 23, fur)
        ctx.ellipse(40, 36, 20, 15, light)
        ctx.ellipse(46.5, 37.5, 7, 5, ink)
        ctx.strokePath(ink, width: 1.3) { p in
            p.move(to: pt(50, 42)); p.addLine(to: pt(50, 45))
            p.move(to: pt(46.5, 46)); p.addQuadCurve(to: pt(53.5, 46), control: pt(50, 48.5))
        }
        ctx.circle(41, 30, 2.8, ink)
        ctx.circle(59, 30, 2.8, ink)
        ctx.circle(40.2, 29.2, 0.9, Color.white.opacity(0.8))
        ctx.circle(58.2, 29.2, 0.9, Color.white.opacity(0.8))
        ctx.ellipse(32, 38, 7, 4, Palette.blush.opacity(0.85))
        ctx.ellipse(61, 38, 7, 4, Palette.blush.opacity(0.85))
        ctx.ellipse(40, 16, 10, 6, Color.white.opacity(0.3))
        // Nơ cổ
        ctx.polygon([pt(50, 56), pt(38, 50), pt(38, 62)], rgb(0xF4A9C0))
        ctx.polygon([pt(50, 56), pt(62, 50), pt(62, 62)], rgb(0xF4A9C0))
        ctx.circle(50, 56, 3, rgb(0xEC8FAE))
    }

    private static func plushDino(_ ctx: GraphicsContext) {
        let green = rgb(0xA9DDB8)
        let shade = rgb(0x86C79A)
        let belly = rgb(0xE2F4E6)
        let spike = rgb(0xF7C59F)
        shadow(ctx, 6, 86, 84, 10)
        // Đuôi
        var tail = Path()
        tail.move(to: pt(30, 64))
        tail.addQuadCurve(to: pt(4, 86), control: pt(10, 68))
        tail.addQuadCurve(to: pt(34, 88), control: pt(18, 92))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(green))
        // Gai lưng
        for (x, y) in [(CGFloat(24), CGFloat(56)), (32, 46), (44, 40), (14, 70)] {
            ctx.polygon([pt(x - 6, y + 4), pt(x, y - 7), pt(x + 6, y + 4)], spike)
        }
        // Chân sau
        ctx.ellipse(26, 76, 18, 16, shade)
        ctx.ellipse(54, 76, 18, 16, shade)
        // Thân
        ctx.ellipse(22, 44, 52, 46, green)
        ctx.ellipse(42, 56, 26, 30, belly)
        // Đầu
        ctx.polygon([pt(56, 14), pt(62, 4), pt(67, 13)], spike)
        ctx.polygon([pt(68, 14), pt(76, 6), pt(78, 16)], spike)
        ctx.ellipse(50, 12, 42, 34, green)
        ctx.ellipse(70, 24, 24, 20, green)
        ctx.circle(84, 30, 1.2, shade)
        ctx.circle(88, 28, 1.2, shade)
        // Mặt
        ctx.circle(68, 24, 3.4, ink)
        ctx.circle(67, 23, 1.1, Color.white.opacity(0.85))
        ctx.ellipse(70, 31, 8, 4.5, Palette.blush.opacity(0.85))
        ctx.strokePath(ink, width: 1.4) { p in
            p.move(to: pt(78, 36)); p.addQuadCurve(to: pt(90, 34), control: pt(84, 39))
        }
        ctx.polygon([pt(81, 36.5), pt(84.5, 36.8), pt(82.6, 40.5)], Color.white)
        // Tay nhỏ
        ctx.ellipse(64, 52, 12, 8, shade)
        ctx.ellipse(56, 18, 12, 7, Color.white.opacity(0.35))
    }
}

// MARK: - Đồ thêm (bộ 2)

extension BedroomArt {
    fileprivate static func drawMore(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        case "bedroomTheme.attic": themeAttic(ctx)
        case "bed.bunk": bedBunk(ctx)
        case "bed.cat": bedCat(ctx)
        case "bed.hammock": bedHammock(ctx)
        case "nightstand.books": standBooks(ctx)
        case "nightstand.lantern": standLantern(ctx)
        case "nightstand.clock": standClock(ctx)
        case "bedroomWall.mobile": wallMobile(ctx)
        case "bedroomWall.photos": wallPhotos(ctx)
        case "bedroomWall.hoops": wallHoops(ctx)
        case "closet.bunny": closetBunny(ctx)
        case "closet.bookcase": closetBookcase(ctx)
        case "closet.rack": closetRack(ctx)
        case "bedroomRug.star": rugStar(rugSpace(ctx))
        case "bedroomRug.fluffy": rugFluffy(rugSpace(ctx))
        case "bedroomRug.cat": rugCatFace(rugSpace(ctx))
        case "plush.whale": plushWhale(ctx)
        case "plush.octopus": plushOctopus(ctx)
        case "plush.egg": plushEgg(ctx)
        default: return false
        }
        return true
    }

    // MARK: Tiện ích thêm

    /// Ngôi sao năm cánh bo tròn.
    private static func star(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        var pts: [CGPoint] = []
        for i in 0..<10 {
            let a = Double(i) * Double.pi / 5 - Double.pi / 2
            let rr = i % 2 == 0 ? r : r * 0.5
            pts.append(pt(cx + rr * CGFloat(cos(a)), cy + rr * CGFloat(sin(a))))
        }
        ctx.polygon(pts, color)
        ctx.strokePath(color, width: r * 0.22) { p in
            p.addLines(pts); p.closeSubpath()
        }
    }

    /// Trăng khuyết quay lưng sang trái.
    private static func crescent(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        var p = Path()
        p.move(to: pt(cx + r * 0.35, cy - r))
        p.addQuadCurve(to: pt(cx + r * 0.35, cy + r), control: pt(cx - r * 1.55, cy))
        p.addQuadCurve(to: pt(cx + r * 0.35, cy - r), control: pt(cx - r * 0.35, cy))
        ctx.fill(p, with: .color(color))
    }

    /// Bông hoa năm cánh.
    private static func flower(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ petal: Color, _ middle: Color) {
        for i in 0..<5 {
            let a = Double(i) / 5 * 2 * Double.pi - Double.pi / 2
            ctx.circle(cx + r * 0.62 * CGFloat(cos(a)), cy + r * 0.62 * CGFloat(sin(a)), r * 0.48, petal)
        }
        ctx.circle(cx, cy, r * 0.36, middle)
    }

    /// Mắt nhắm cong (ngủ/cười).
    private static func sleepyEye(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, width: CGFloat = 1.3) {
        ctx.strokePath(ink, width: width) { p in
            p.move(to: pt(x - w / 2, y)); p.addQuadCurve(to: pt(x + w / 2, y), control: pt(x, y + w * 0.55))
        }
    }

    // MARK: Tường & sàn: gác mái gỗ

    private static func themeAttic(_ ctx: GraphicsContext) {
        let wall = rgb(0xF5E4CE)
        let seam = rgb(0xE6CCAB)
        let roof = rgb(0xE6C7A2)
        let beam = rgb(0xC99A6E)
        let beamDark = rgb(0xAE8259)
        ctx.rect(0, 0, 125, 62, wall)
        // Ván dọc và mắt gỗ
        ctx.strokePath(seam, width: 0.7) { p in
            var x: CGFloat = 8
            while x < 125 {
                p.move(to: pt(x, 0)); p.addLine(to: pt(x, 58))
                x += 9
            }
        }
        for (x, y) in [(CGFloat(12.5), CGFloat(40)), (39.5, 46), (84.5, 48), (111.5, 36), (66.5, 54), (21.5, 54)] {
            ctx.ellipse(x - 1.6, y - 0.9, 3.2, 1.8, seam)
        }
        // Mái dốc hai bên
        for flip in [false, true] {
            let fx: (CGFloat) -> CGFloat = { x in flip ? 125 - x : x }
            ctx.polygon([pt(fx(0), 0), pt(fx(40), 0), pt(fx(0), 34)], roof)
            ctx.strokePath(beamDark.opacity(0.3), width: 0.6) { p in
                for k in [CGFloat(0.3), 0.55, 0.8] {
                    p.move(to: pt(fx(0), 34 * k)); p.addLine(to: pt(fx(40 * k), 0))
                }
            }
            ctx.strokePath(beam, width: 4) { p in
                p.move(to: pt(fx(-1), 35)); p.addLine(to: pt(fx(41), -1))
            }
            ctx.strokePath(Color.white.opacity(0.3), width: 0.8) { p in
                p.move(to: pt(fx(0), 32.6)); p.addLine(to: pt(fx(38), 0.2))
            }
        }
        ctx.rect(0, 0, 125, 3.2, beamDark)
        // Đèn treo bóng tròn
        ctx.strokePath(rgb(0x8F7A66), width: 0.7) { p in
            p.move(to: pt(91, 3)); p.addLine(to: pt(91, 15))
        }
        ctx.circle(91, 18.5, 6, rgb(0xFFE7A0).opacity(0.35))
        ctx.rect(89.4, 14, 3.2, 2.6, rgb(0x8F7A66), radius: 0.8)
        ctx.circle(91, 18.8, 2.8, rgb(0xFFF1C2))
        ctx.circle(90.2, 18, 0.8, Color.white)
        // Cửa sổ tròn
        let c = pt(56, 20)
        ctx.circle(c.x, c.y, 12.5, rgb(0xFFFAF2))
        ctx.circle(c.x, c.y, 10, rgb(0xC9E2F6))
        var w = ctx
        w.clip(to: Path(ellipseIn: CGRect(x: c.x - 10, y: c.y - 10, width: 20, height: 20)))
        puff(w, 46.5, 14, 0.5, Color.white)
        w.ellipse(44, 24, 30, 14, rgb(0xB9DDB0))
        w.circle(61, 15, 2.2, rgb(0xFFE7A0))
        ctx.rect(c.x - 0.7, c.y - 10, 1.4, 20, rgb(0xFFFAF2))
        ctx.rect(c.x - 10, c.y - 0.7, 20, 1.4, rgb(0xFFFAF2))
        ctx.strokePath(beam.opacity(0.5), width: 0.8) { p in
            p.addEllipse(in: CGRect(x: c.x - 12.5, y: c.y - 12.5, width: 25, height: 25))
        }
        ctx.strokePath(Color.white.opacity(0.7), width: 0.8) { p in
            p.addArc(center: c, radius: 7.5, startAngle: .degrees(195), endAngle: .degrees(245), clockwise: false)
        }
        ctx.rect(43.5, 33.5, 25, 3, beam, radius: 1.5)
        // Len chân tường
        ctx.rect(0, 57.5, 125, 4.5, beam)
        ctx.rect(0, 57.5, 125, 0.8, Color.white.opacity(0.35))
        // Sàn gỗ ấm
        ctx.rect(0, 62, 125, 38, rgb(0xE8CFAE))
        ctx.rect(0, 62, 125, 1.6, Color.black.opacity(0.07))
        let plank = rgb(0xD3B48E)
        let rows: [CGFloat] = [62, 70.5, 80, 90.5]
        for (i, y) in rows.enumerated() {
            if i > 0 { ctx.rect(0, y, 125, 0.7, plank) }
            let next = i + 1 < rows.count ? rows[i + 1] : 100
            var x: CGFloat = (i % 2 == 0 ? 0 : 16) + 8
            while x < 125 {
                ctx.rect(x, y, 0.7, next - y, plank)
                x += 32
            }
        }
    }

    // MARK: Giường

    private static func bedBunk(_ ctx: GraphicsContext) {
        let wood = rgb(0xE3BD92)
        let woodDark = rgb(0xC69A6C)
        shadow(ctx, 2, 89, 98, 9)
        ctx.rect(10, 44, 80, 30, Color.black.opacity(0.06))
        // Tầng dưới
        ctx.rect(8, 82, 84, 7, woodDark, radius: 3)
        ctx.rect(10, 70, 80, 14, rgb(0xFFFBF5), radius: 5)
        ctx.ellipse(12, 59, 24, 14, rgb(0xFFFDFB))
        ctx.ellipse(15, 68, 18, 4, rgb(0xEEE6F2))
        ctx.ellipse(16, 62, 7, 3, shine)
        ctx.rect(36, 67, 54, 18, rgb(0xF6B3C6), radius: 5)
        ctx.rect(36, 67, 54, 5, rgb(0xFBD0DC), radius: 4)
        for x in stride(from: CGFloat(44), to: 90, by: 9) {
            ctx.rect(x, 72, 2, 13, Color.white.opacity(0.45))
        }
        ctx.rect(32, 66, 7, 19, rgb(0xFFF4F7), radius: 3.5)
        // Tầng trên
        ctx.rect(8, 40, 84, 6, woodDark, radius: 3)
        ctx.rect(10, 30, 80, 11, rgb(0xFFFBF5), radius: 4)
        ctx.ellipse(12, 20, 22, 12, rgb(0xFFFDFB))
        ctx.rect(34, 27, 56, 14, rgb(0xAFCFF2), radius: 5)
        ctx.rect(34, 27, 56, 4.5, rgb(0xCDE2F8), radius: 4)
        for (x, y) in [(CGFloat(44), CGFloat(36)), (57, 34.5), (88, 36)] {
            star(ctx, x, y, 2.6, rgb(0xFFF1C2))
        }
        // Lan can tầng trên
        ctx.rect(8, 16, 54, 3.6, wood, radius: 1.8)
        for x in [CGFloat(20), 32, 44, 56] {
            ctx.rect(x, 17, 3, 13, wood, radius: 1.5)
        }
        // Cột
        ctx.rect(3, 6, 8, 88, wood, radius: 3.5)
        ctx.rect(89, 6, 8, 88, wood, radius: 3.5)
        ctx.rect(5, 10, 2, 76, Color.white.opacity(0.3), radius: 1)
        ctx.circle(7, 6, 4.5, wood)
        ctx.circle(93, 6, 4.5, wood)
        ctx.circle(5.8, 4.8, 1.4, Color.white.opacity(0.35))
        // Thang
        for x in [CGFloat(67), 81] {
            ctx.rect(x, 17, 3.2, 71, woodDark, radius: 1.6)
        }
        for y in stride(from: CGFloat(26), to: 88, by: 13) {
            ctx.rect(67, y, 17, 3, wood, radius: 1.5)
        }
    }

    private static func bedCat(_ ctx: GraphicsContext) {
        let fur = rgb(0xF6C9A0)
        let furDark = rgb(0xE5A475)
        let cream = rgb(0xFFF1E0)
        let pink = rgb(0xF6B3C6)
        shadow(ctx, 2, 89, 98, 9)
        // Đầu giường: đầu mèo trên cột tròn
        ctx.rect(3, 30, 22, 64, fur, radius: 9)
        ctx.rect(6, 50, 3, 36, Color.white.opacity(0.3), radius: 1.5)
        ctx.polygon([pt(1, 24), pt(3, 3), pt(16, 13)], fur)
        ctx.polygon([pt(27, 24), pt(25, 3), pt(12, 13)], fur)
        ctx.polygon([pt(4, 18), pt(5, 8), pt(12, 13.5)], pink)
        ctx.polygon([pt(24, 18), pt(23, 8), pt(16, 13.5)], pink)
        ctx.circle(14, 26, 14, fur)
        for dx in [CGFloat(-4.5), 0, 4.5] {
            ctx.rect(14 + dx - 0.9, 13, 1.8, 5.5, furDark, radius: 0.9)
        }
        ctx.ellipse(7, 26, 14, 11, cream)
        sleepyEye(ctx, 8.5, 25, 5)
        sleepyEye(ctx, 19.5, 25, 5)
        ctx.polygon([pt(12.6, 28.4), pt(15.4, 28.4), pt(14, 30)], pink)
        ctx.strokePath(ink, width: 1) { p in
            p.move(to: pt(14, 30)); p.addQuadCurve(to: pt(11.5, 31.5), control: pt(13.4, 32))
            p.move(to: pt(14, 30)); p.addQuadCurve(to: pt(16.5, 31.5), control: pt(14.6, 32))
        }
        ctx.ellipse(3.5, 28.5, 5, 3, Palette.blush.opacity(0.9))
        ctx.ellipse(19.5, 28.5, 5, 3, Palette.blush.opacity(0.9))
        ctx.strokePath(furDark, width: 0.8) { p in
            p.move(to: pt(4, 30)); p.addLine(to: pt(-2, 29))
            p.move(to: pt(24, 30)); p.addLine(to: pt(30, 29))
        }
        ctx.rect(10, 74, 82, 8, furDark, radius: 3)
        mattress(ctx, blanket: rgb(0xC9B8EE), blanketTop: rgb(0xDCD0F5), cuff: rgb(0xFFFFFF)) { b in
            for (x, y) in [(CGFloat(50), CGFloat(66)), (64, 60), (78, 70), (60, 76), (84, 56)] {
                b.circle(x, y, 2.6, Color.white.opacity(0.75))
                for (dx, dy) in [(CGFloat(-3), CGFloat(-3.2)), (0, -4.4), (3, -3.2)] {
                    b.circle(x + dx, y + dy, 1.1, Color.white.opacity(0.75))
                }
            }
        }
        // Chân giường cuối: chiếc đuôi cong
        ctx.strokePath(fur, width: 9) { p in
            p.move(to: pt(90, 92))
            p.addQuadCurve(to: pt(93, 50), control: pt(99, 72))
            p.addQuadCurve(to: pt(82, 41), control: pt(91, 38))
        }
        ctx.circle(82, 41.5, 4.8, cream)
        ctx.strokePath(furDark, width: 2) { p in
            p.move(to: pt(91, 80)); p.addLine(to: pt(98, 79))
            p.move(to: pt(92, 66)); p.addLine(to: pt(99, 64))
            p.move(to: pt(91, 53)); p.addLine(to: pt(97, 49))
        }
    }

    private static func bedHammock(_ ctx: GraphicsContext) {
        let wood = rgb(0xCFA175)
        let woodDark = rgb(0xB3845A)
        let rope = rgb(0xF2E6D2)
        shadow(ctx, 2, 89, 98, 9)
        // Khung gỗ
        ctx.rect(6, 85, 88, 5, woodDark, radius: 2.5)
        ctx.polygon([pt(7, 90), pt(10, 20), pt(15, 20), pt(15, 90)], wood)
        ctx.polygon([pt(93, 90), pt(90, 20), pt(85, 20), pt(85, 90)], wood)
        ctx.circle(12.5, 20, 4.2, wood)
        ctx.circle(87.5, 20, 4.2, wood)
        ctx.circle(11.3, 18.8, 1.3, Color.white.opacity(0.35))
        ctx.circle(86.3, 18.8, 1.3, Color.white.opacity(0.35))
        ctx.rect(1, 88, 20, 6, wood, radius: 3)
        ctx.rect(79, 88, 20, 6, wood, radius: 3)
        // Dây buộc
        ctx.strokePath(rope, width: 1.2) { p in
            for (from, tos) in [(pt(12.5, 22), [pt(17, 39), pt(22, 37.5), pt(19, 42)]),
                                (pt(87.5, 22), [pt(83, 39), pt(78, 37.5), pt(81, 42)])] {
                for to in tos {
                    p.move(to: from); p.addLine(to: to)
                }
            }
        }
        // Lưới võng
        let a = pt(16, 38), b = pt(84, 38)
        var h = Path()
        h.move(to: a)
        h.addQuadCurve(to: b, control: pt(50, 96))
        h.addQuadCurve(to: a, control: pt(50, 64))
        ctx.fill(h, with: .color(rgb(0xF7C59F)))
        var g = ctx
        g.clip(to: h)
        for (k, color) in [(CGFloat(0.28), rgb(0xFFF3E4)), (0.6, rgb(0xA9DDB8)), (0.86, rgb(0xFFF3E4))] {
            g.strokePath(color, width: 4) { p in
                p.move(to: a); p.addQuadCurve(to: b, control: pt(50, 64 + 32 * k))
            }
        }
        // Gối + chăn vắt qua
        ctx.ellipse(18, 38, 24, 13, rgb(0xFFFDFB))
        ctx.ellipse(22, 41, 8, 3.4, shine)
        ctx.rect(46, 52, 24, 27, rgb(0xC9B8EE), radius: 3)
        ctx.rect(46, 52, 24, 6, rgb(0xDCD0F5), radius: 3)
        for x in stride(from: CGFloat(48), to: 70, by: 3.5) {
            ctx.rect(x, 79, 1.4, 4, rgb(0xC9B8EE), radius: 0.7)
        }
        ctx.heart(center: pt(58, 68), size: 7, Color.white.opacity(0.75))
        // Tua rua mép võng
        ctx.strokePath(rope, width: 1.2) { p in
            for i in 1..<10 {
                let t = CGFloat(i) / 10
                if t > 0.4 && t < 0.72 { continue }
                let m = quad(a, pt(50, 96), b, t)
                p.move(to: m); p.addLine(to: pt(m.x, m.y + 4.5))
            }
        }
    }

    // MARK: Đầu giường

    private static func standBooks(_ ctx: GraphicsContext) {
        shadow(ctx, 12, 90, 76, 8)
        let books: [(CGFloat, CGFloat, CGFloat, CGFloat, UInt32)] = [
            (16, 84, 68, 11, 0xB9A6EA), (21, 74, 60, 10, 0xA9D8BA), (14, 64, 66, 10, 0xF4A9A0),
            (22, 55, 57, 9, 0xF7D27A), (18, 46, 62, 9, 0xAFCFF2)
        ]
        for (x, y, w, h, c) in books {
            ctx.rect(x, y, w, h, rgb(c), radius: 2)
            ctx.rect(x + w - 7, y + 1.4, 6, h - 2.8, rgb(0xFFFBF5), radius: 1)
            ctx.strokePath(Color.black.opacity(0.08), width: 0.5) { p in
                p.move(to: pt(x + w - 6.5, y + h / 2)); p.addLine(to: pt(x + w - 1.5, y + h / 2))
            }
            ctx.rect(x + 5, y + 1.8, 3, h - 3.6, Color.white.opacity(0.55), radius: 1)
            ctx.rect(x + 10, y + 1.8, 1.4, h - 3.6, Color.white.opacity(0.4))
        }
        // Cốc ca cao
        ctx.strokePath(rgb(0xF6B3C6), width: 2.8) { p in
            p.addEllipse(in: CGRect(x: 40, y: 32, width: 10, height: 10))
        }
        ctx.rect(25, 29, 19, 17, rgb(0xF6B3C6), radius: 4)
        ctx.ellipse(25, 27, 19, 5, rgb(0xFFF4E8))
        ctx.ellipse(27, 28, 15, 3.4, rgb(0xB98A62))
        ctx.heart(center: pt(34.5, 38), size: 6, Color.white.opacity(0.8))
        ctx.strokePath(Color.white.opacity(0.85), width: 1.6) { p in
            for x in [CGFloat(30), 38] {
                p.move(to: pt(x, 25)); p.addQuadCurve(to: pt(x, 13), control: pt(x - 4, 19))
            }
        }
        // Kính đọc sách
        ctx.strokePath(ink, width: 1.4) { p in
            p.addEllipse(in: CGRect(x: 55, y: 38, width: 10, height: 8))
            p.addEllipse(in: CGRect(x: 68, y: 38, width: 10, height: 8))
            p.move(to: pt(65, 41)); p.addQuadCurve(to: pt(68, 41), control: pt(66.5, 39.2))
        }
        ctx.ellipse(56, 39, 8, 6, Color.white.opacity(0.35))
        ctx.ellipse(69, 39, 8, 6, Color.white.opacity(0.35))
    }

    private static func standLantern(_ ctx: GraphicsContext) {
        let wood = rgb(0xD9B087)
        let dark = rgb(0xBE915F)
        let paper = rgb(0xF7B89A)
        let rib = rgb(0xE8957A)
        shadow(ctx, 14, 90, 72, 8)
        // Ghế đẩu tròn
        ctx.polygon([pt(25, 52), pt(32, 52), pt(25, 95), pt(18, 95)], dark)
        ctx.polygon([pt(75, 52), pt(68, 52), pt(75, 95), pt(82, 95)], dark)
        ctx.rect(46.5, 54, 7, 40, dark, radius: 2)
        ctx.rect(24, 76, 52, 3, dark, radius: 1.5)
        ctx.ellipse(16, 46, 68, 13, dark)
        ctx.ellipse(16, 43, 68, 12, wood)
        ctx.ellipse(26, 45, 22, 3.6, Color.white.opacity(0.3))
        // Quầng sáng
        ctx.circle(50, 25, 27, rgb(0xFFD9A0).opacity(0.22))
        ctx.circle(50, 25, 20, rgb(0xFFD9A0).opacity(0.25))
        // Đèn lồng giấy
        let body = CGRect(x: 29, y: 8, width: 42, height: 37)
        ctx.ellipse(body.minX, body.minY, body.width, body.height, paper)
        var g = ctx
        g.clip(to: Path(ellipseIn: body))
        g.ellipse(37, 13, 26, 26, rgb(0xFFDDB8).opacity(0.7))
        g.strokePath(rib, width: 0.9) { p in
            for y in stride(from: CGFloat(14), to: 44, by: 6) {
                p.move(to: pt(28, y)); p.addQuadCurve(to: pt(72, y), control: pt(50, y + 2.4))
            }
        }
        ctx.heart(center: pt(50, 27), size: 9, Color.white.opacity(0.7))
        ctx.ellipse(33, 15, 5, 12, Color.white.opacity(0.4))
        ctx.rect(39, 4.5, 22, 6, rgb(0x9C7458), radius: 2)
        ctx.rect(39, 41.5, 22, 5, rgb(0x9C7458), radius: 2)
        ctx.strokePath(rgb(0x9C7458), width: 1.2) { p in
            p.move(to: pt(44, 5)); p.addQuadCurve(to: pt(56, 5), control: pt(50, -2))
        }
    }

    private static func standClock(_ ctx: GraphicsContext) {
        cabinet(ctx, body: rgb(0xBFE3CF), top: rgb(0x9DCDB3), front: rgb(0xDDF1E5), knob: rgb(0xF4A9A0))
        let red = rgb(0xF4A9A0)
        let bell = rgb(0xF7D27A)
        let metal = rgb(0x9A93A8)
        // Chân
        ctx.polygon([pt(35, 36), pt(39, 38), pt(34, 47), pt(30, 47)], metal)
        ctx.polygon([pt(61, 36), pt(57, 38), pt(62, 47), pt(66, 47)], metal)
        // Chuông + búa
        ctx.rect(46.5, 4, 3, 7, metal, radius: 1.5)
        ctx.circle(48, 4, 2.4, metal)
        for x in [CGFloat(34), 62] {
            ctx.circle(x, 13, 7, bell)
            ctx.rect(x - 1.2, 4.5, 2.4, 3, metal, radius: 1)
            ctx.circle(x - 2.4, 10.5, 1.6, shine)
        }
        // Thân
        ctx.circle(48, 27, 16, red)
        ctx.circle(48, 27, 12.5, rgb(0xFFFBF5))
        for i in 0..<12 {
            let a = Double(i) / 12 * 2 * Double.pi
            ctx.circle(48 + 10 * CGFloat(cos(a)), 27 + 10 * CGFloat(sin(a)), i % 3 == 0 ? 1 : 0.6, rgb(0xC9BEDA))
        }
        ctx.strokePath(ink, width: 1.6) { p in
            p.move(to: pt(48, 27)); p.addLine(to: pt(48, 19.5))
            p.move(to: pt(48, 27)); p.addLine(to: pt(53.5, 29.5))
        }
        ctx.circle(48, 27, 1.5, red)
        ctx.strokePath(Color.white.opacity(0.6), width: 1.4) { p in
            p.addArc(center: pt(48, 27), radius: 14.2, startAngle: .degrees(200), endAngle: .degrees(245), clockwise: false)
        }
        // Cốc sữa
        ctx.rect(70, 30, 12, 16, rgb(0xEAF4FB), radius: 3)
        ctx.rect(71.5, 35, 9, 9.5, Color.white, radius: 2.2)
        ctx.rect(72.5, 32, 1.8, 11, Color.white.opacity(0.8), radius: 0.9)
        sparkle(ctx, 20, 18, 6, rgb(0xF7D27A))
    }

    // MARK: Trang trí tường

    private static func wallMobile(_ ctx: GraphicsContext) {
        let wood = rgb(0xCFA175)
        let thread = rgb(0xA593B8)
        func barY(_ x: CGFloat) -> CGFloat {
            let t = (x - 14) / 72
            return 24 - 16 * t * (1 - t) * 2
        }
        ctx.strokePath(thread, width: 1.1) { p in
            p.move(to: pt(50, 3)); p.addLine(to: pt(50, 12))
            p.move(to: pt(50, 12)); p.addLine(to: pt(24, barY(24)))
            p.move(to: pt(50, 12)); p.addLine(to: pt(76, barY(76)))
        }
        ctx.circle(50, 3, 2.2, wood)
        let hangs: [(CGFloat, CGFloat)] = [(20, 43), (38, 62), (60, 52), (80, 38)]
        ctx.strokePath(thread, width: 0.8) { p in
            for (x, y) in hangs {
                p.move(to: pt(x, barY(x))); p.addLine(to: pt(x, y))
            }
        }
        ctx.strokePath(wood, width: 3.2) { p in
            p.move(to: pt(14, 24)); p.addQuadCurve(to: pt(86, 24), control: pt(50, 8))
        }
        for (x, y) in hangs {
            ctx.circle(x, (barY(x) + y) / 2, 1.5, rgb(0xF6AFC4))
        }
        // Trăng ngủ
        crescent(ctx, 22, 53, 10, rgb(0xFFE7A0))
        sleepyEye(ctx, 15.5, 53, 3.4, width: 1)
        ctx.ellipse(13, 55.5, 4, 2.2, Palette.blush.opacity(0.85))
        // Sao
        star(ctx, 38, 69, 7, rgb(0xF7D27A))
        ctx.circle(36, 67, 1.2, shine)
        star(ctx, 80, 45, 6, rgb(0xF6AFC4))
        // Mây
        ctx.ellipse(48, 56, 25, 10, rgb(0xD7E6F6))
        ctx.ellipse(48, 54, 25, 10, Color.white)
        ctx.circle(55, 54, 6, Color.white)
        ctx.circle(63, 53, 7, Color.white)
        ctx.circle(56, 52, 1.6, shine)
        for x in [CGFloat(53), 60, 67] {
            ctx.ellipse(x - 1, 68, 2, 3.4, rgb(0xAFCFF2))
        }
    }

    private static func wallPhotos(_ ctx: GraphicsContext) {
        let a = pt(4, 14), c = pt(50, 40), b = pt(96, 14)
        ctx.strokePath(rgb(0xA593B8), width: 1.1) { p in
            p.move(to: a); p.addQuadCurve(to: b, control: c)
        }
        let photos: [(CGFloat, Double)] = [(0.13, -8), (0.38, 5), (0.63, -4), (0.88, 8)]
        for (i, (t, tilt)) in photos.enumerated() {
            let m = quad(a, c, b, t)
            ctx.rotated(tilt, around: m) { r in
                r.rect(m.x - 9, m.y + 3, 19, 23, Color.black.opacity(0.08), radius: 1)
                r.rect(m.x - 9.5, m.y + 2, 19, 23, rgb(0xFFFDF8), radius: 1)
                let pic = CGRect(x: m.x - 7.5, y: m.y + 4, width: 15, height: 14)
                var g = r
                g.clip(to: Path(pic))
                switch i {
                case 0:
                    g.rect(pic.minX, pic.minY, pic.width, pic.height, rgb(0xCFE7F8))
                    g.circle(pic.maxX - 4, pic.minY + 4, 2.4, rgb(0xFFD98A))
                    g.ellipse(pic.minX - 4, pic.minY + 8, 14, 10, rgb(0xA9DDB8))
                    g.ellipse(pic.minX + 5, pic.minY + 9, 16, 10, rgb(0x8FCB9E))
                case 1:
                    g.rect(pic.minX, pic.minY, pic.width, pic.height, rgb(0xFBD3DE))
                    g.heart(center: pt(pic.midX, pic.midY), size: 9, rgb(0xEC8FAE))
                case 2:
                    g.rect(pic.minX, pic.minY, pic.width, pic.height, rgb(0xE4DBF6))
                    g.polygon([pt(pic.midX - 5, pic.midY - 1), pt(pic.midX - 4, pic.midY - 7), pt(pic.midX - 1, pic.midY - 3)], Palette.catCream)
                    g.polygon([pt(pic.midX + 5, pic.midY - 1), pt(pic.midX + 4, pic.midY - 7), pt(pic.midX + 1, pic.midY - 3)], Palette.catCream)
                    g.circle(pic.midX, pic.midY + 1.5, 5, Palette.catCream)
                    g.circle(pic.midX - 2, pic.midY + 1, 0.7, ink)
                    g.circle(pic.midX + 2, pic.midY + 1, 0.7, ink)
                default:
                    g.rect(pic.minX, pic.minY, pic.width, pic.height, rgb(0xDDF1E5))
                    flower(g, pic.midX, pic.midY, 4, rgb(0xFFFFFF), rgb(0xF7D27A))
                }
                r.rect(m.x - 1.6, m.y - 3, 3.2, 8, rgb(0xCFA175), radius: 1)
            }
        }
        ctx.circle(a.x, a.y, 2.4, rgb(0xCFA175))
        ctx.circle(b.x, b.y, 2.4, rgb(0xCFA175))
    }

    private static func hoop(_ ctx: GraphicsContext, _ c: CGPoint, _ r: CGFloat, fabric: Color,
                             _ content: (GraphicsContext) -> Void) {
        let wood = rgb(0xD9B087)
        ctx.strokePath(rgb(0xA593B8), width: 0.9) { p in
            p.move(to: pt(c.x, c.y - r - 7)); p.addLine(to: pt(c.x, c.y - r))
        }
        ctx.circle(c.x, c.y - r - 7, 1.8, rgb(0xCFA175))
        ctx.circle(c.x, c.y, r, fabric)
        var g = ctx
        g.clip(to: Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)))
        content(g)
        ctx.strokePath(wood, width: 3) { p in
            p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        }
        ctx.rect(c.x - 2.6, c.y - r - 3.4, 5.2, 4.6, rgb(0xC6D2DA), radius: 1)
        ctx.strokePath(Color.white.opacity(0.45), width: 0.9) { p in
            p.addArc(center: c, radius: r, startAngle: .degrees(150), endAngle: .degrees(200), clockwise: false)
        }
    }

    private static func wallHoops(_ ctx: GraphicsContext) {
        hoop(ctx, pt(36, 42), 22, fabric: rgb(0xFFF8EE)) { g in
            g.strokePath(rgb(0x8FC79C), width: 1.3) { p in
                p.move(to: pt(36, 60)); p.addQuadCurve(to: pt(26, 38), control: pt(28, 50))
                p.move(to: pt(36, 60)); p.addLine(to: pt(37, 33))
                p.move(to: pt(36, 60)); p.addQuadCurve(to: pt(47, 41), control: pt(44, 52))
            }
            g.ellipse(27, 47, 6, 3.4, rgb(0xA9DDB8))
            g.ellipse(39, 50, 6, 3.4, rgb(0xA9DDB8))
            flower(g, 26, 37, 5.5, rgb(0xF6AFC4), rgb(0xF7D27A))
            flower(g, 37, 31, 6, rgb(0xB9A6EA), rgb(0xFFF1C2))
            flower(g, 47, 40, 5, rgb(0xF7D27A), rgb(0xF4A9A0))
            g.rect(31, 57, 10, 3, rgb(0xF4A9C0), radius: 1.5)
        }
        hoop(ctx, pt(77, 27), 14, fabric: rgb(0xE4F0FA)) { g in
            g.heart(center: pt(77, 28), size: 15, rgb(0xF4A9C0))
            g.strokePath(Color.white.opacity(0.8), width: 0.7) { p in
                p.move(to: pt(72, 25)); p.addLine(to: pt(74, 23))
            }
        }
        hoop(ctx, pt(75, 67), 13, fabric: rgb(0xF6EEDF)) { g in
            g.rect(72.5, 66, 5, 9, rgb(0xFFF6EC), radius: 2)
            var cap = Path()
            cap.move(to: pt(66, 68))
            cap.addQuadCurve(to: pt(84, 68), control: pt(75, 54))
            cap.closeSubpath()
            g.fill(cap, with: .color(rgb(0xF4A3A8)))
            g.circle(71, 63.5, 1.5, Color.white)
            g.circle(77.5, 61.5, 1.8, Color.white)
            g.circle(80.5, 66, 1.2, Color.white)
            g.ellipse(64, 75, 22, 5, rgb(0xA9DDB8))
        }
    }

    // MARK: Tủ

    private static func closetBunny(_ ctx: GraphicsContext) {
        let body = rgb(0xFBE4EC)
        let door = rgb(0xFFF5F8)
        let trim = rgb(0xF0BCCD)
        let inner = rgb(0xF6AFC4)
        shadow(ctx, 4, 95, 92, 7)
        ctx.rect(16, 90, 9, 9, trim, radius: 3)
        ctx.rect(75, 90, 9, 9, trim, radius: 3)
        // Tai thỏ
        ctx.rotated(-12, around: pt(32, 30)) { c in
            c.ellipse(23, -2, 18, 40, body)
            c.ellipse(28, 4, 8, 26, inner)
        }
        ctx.rotated(12, around: pt(68, 30)) { c in
            c.ellipse(59, -2, 18, 40, body)
            c.ellipse(64, 4, 8, 26, inner)
        }
        // Thân tủ
        ctx.rect(8, 22, 84, 72, body, radius: 20)
        ctx.rect(12, 34, 3, 50, Color.white.opacity(0.45), radius: 1.5)
        // Mặt thỏ
        ctx.circle(37, 33, 3, ink)
        ctx.circle(63, 33, 3, ink)
        ctx.circle(36, 32, 1, Color.white.opacity(0.9))
        ctx.circle(62, 32, 1, Color.white.opacity(0.9))
        ctx.ellipse(47.5, 35.5, 5, 3.4, inner)
        ctx.strokePath(ink, width: 1.2) { p in
            p.move(to: pt(50, 39)); p.addQuadCurve(to: pt(46, 41), control: pt(49, 42))
            p.move(to: pt(50, 39)); p.addQuadCurve(to: pt(54, 41), control: pt(51, 42))
        }
        ctx.ellipse(25, 37, 8, 4.5, Palette.blush.opacity(0.85))
        ctx.ellipse(67, 37, 8, 4.5, Palette.blush.opacity(0.85))
        // Hai cánh tủ
        ctx.rect(14, 47, 35, 42, door, radius: 6)
        ctx.rect(51, 47, 35, 42, door, radius: 6)
        ctx.circle(45, 68, 2.6, rgb(0xF7D27A))
        ctx.circle(55, 68, 2.6, rgb(0xF7D27A))
        ctx.circle(44.3, 67.3, 0.9, shine)
        ctx.circle(54.3, 67.3, 0.9, shine)
        // Cà rốt và trái tim dán cửa
        ctx.polygon([pt(25, 58), pt(35, 58), pt(30, 78)], rgb(0xF7B27A))
        ctx.strokePath(rgb(0xE5935A), width: 0.9) { p in
            p.move(to: pt(27.5, 63)); p.addLine(to: pt(30.5, 63))
            p.move(to: pt(29, 69)); p.addLine(to: pt(31.5, 69))
        }
        ctx.ellipse(25.5, 52, 4, 7, rgb(0x8FC79C))
        ctx.ellipse(30.5, 51, 4, 7, rgb(0xA9DDB8))
        ctx.heart(center: pt(69, 66), size: 13, inner)
        ctx.heart(center: pt(67.5, 64.5), size: 4, Color.white.opacity(0.6))
    }

    private static func closetBookcase(_ ctx: GraphicsContext) {
        let wood = rgb(0xD9B087)
        let dark = rgb(0xB98A62)
        let back = rgb(0xF4E5D1)
        shadow(ctx, 4, 95, 92, 7)
        ctx.rect(12, 90, 8, 9, dark, radius: 2)
        ctx.rect(80, 90, 8, 9, dark, radius: 2)
        ctx.rect(8, 6, 84, 88, wood, radius: 4)
        ctx.rect(13, 11, 74, 78, back, radius: 2)
        ctx.rect(5, 3, 90, 6, dark, radius: 3)
        ctx.rect(8, 4, 40, 1.4, Color.white.opacity(0.3), radius: 0.7)
        func book(_ x: CGFloat, _ bottom: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: UInt32) {
            ctx.rect(x, bottom - h, w, h, rgb(c), radius: 1.2)
            ctx.rect(x + 1, bottom - h + 3, w - 2, 1.4, Color.white.opacity(0.6))
        }
        // Tầng 1: sách đứng + chậu cây
        for (x, w, h, c) in [(CGFloat(15), CGFloat(6), CGFloat(16), UInt32(0xB9A6EA)), (21.5, 5, 14, 0xF4A9A0),
                             (27, 7, 17, 0xA9D8BA), (34.5, 5, 13, 0xF7D27A), (40, 6, 15, 0xAFCFF2)] {
            book(x, 31, w, h, c)
        }
        ctx.polygon([pt(47, 30), pt(53, 13), pt(56, 14), pt(51, 31)], rgb(0xF6B3C6))
        ctx.rect(68, 22, 13, 9, rgb(0xF4B0A0), radius: 2.5)
        ctx.ellipse(63, 11, 11, 12, rgb(0x8FC79C))
        ctx.ellipse(72, 8, 10, 15, rgb(0xA9DDB8))
        ctx.ellipse(77, 13, 10, 10, rgb(0x8FC79C))
        ctx.rect(13, 31, 74, 3.6, wood)
        // Tầng 2: quả địa cầu + sách
        ctx.rect(26, 50, 12, 2.6, dark, radius: 1.3)
        ctx.rect(31, 46, 2, 5, dark)
        ctx.circle(32, 41, 7, rgb(0xAFD3F2))
        ctx.ellipse(27, 37, 6, 4, rgb(0xA9DDB8))
        ctx.ellipse(32, 42, 5, 5, rgb(0xA9DDB8))
        ctx.circle(29.5, 38.5, 1.4, shine)
        for (x, w, h, c) in [(CGFloat(48), CGFloat(6), CGFloat(15), UInt32(0xF7C59F)), (54.5, 5, 13, 0xC9B8EE),
                             (60, 7, 16, 0xF4A9C0), (67.5, 5, 14, 0xA9D8BA)] {
            book(x, 52.5, w, h, c)
        }
        ctx.polygon([pt(73, 52.5), pt(80, 38), pt(83.5, 39.5), pt(77.5, 52.5)], rgb(0xAFCFF2))
        ctx.rect(13, 52.5, 74, 3.6, wood)
        // Tầng 3: chồng sách nằm + khung ảnh
        for (i, c) in [UInt32(0xB9A6EA), 0xF7D27A, 0xA9D8BA].enumerated() {
            ctx.rect(17 + CGFloat(i % 2) * 2, 69 - CGFloat(i) * 4.5, 26, 4.5, rgb(c), radius: 1)
        }
        ctx.rect(53, 57, 18, 16, rgb(0xFFFBF5), radius: 1.5)
        ctx.rect(56, 60, 12, 10, rgb(0xFBD3DE), radius: 1)
        ctx.heart(center: pt(62, 65), size: 6, rgb(0xEC8FAE))
        ctx.rect(13, 73.5, 74, 3.6, wood)
        // Tầng 4: hai giỏ mây
        for x in [CGFloat(17), 51] {
            ctx.rect(x, 78, 32, 11, rgb(0xE9C79C), radius: 2.5)
            ctx.strokePath(rgb(0xCFA175), width: 0.8) { p in
                for k in 0..<5 {
                    let xx = x + 4 + CGFloat(k) * 6
                    p.move(to: pt(xx, 79)); p.addLine(to: pt(xx, 88))
                }
                p.move(to: pt(x, 83.5)); p.addLine(to: pt(x + 32, 83.5))
            }
        }
    }

    private static func closetRack(_ ctx: GraphicsContext) {
        let wood = rgb(0xD9B087)
        let dark = rgb(0xB98A62)
        shadow(ctx, 4, 95, 92, 7)
        // Khung
        ctx.rect(10, 13, 4, 80, wood, radius: 2)
        ctx.rect(86, 13, 4, 80, wood, radius: 2)
        ctx.rect(6, 13, 88, 4, dark, radius: 2)
        ctx.circle(12, 12, 3.4, dark)
        ctx.circle(88, 12, 3.4, dark)
        ctx.rect(12, 80, 76, 3.4, dark, radius: 1.5)
        ctx.rect(4, 91, 20, 5, dark, radius: 2.5)
        ctx.rect(76, 91, 20, 5, dark, radius: 2.5)
        func hanger(_ x: CGFloat) {
            ctx.strokePath(rgb(0x9A93A8), width: 1.2) { p in
                p.move(to: pt(x, 22)); p.addQuadCurve(to: pt(x + 2.5, 15), control: pt(x - 1, 15))
                p.move(to: pt(x, 22)); p.addLine(to: pt(x - 9, 27))
                p.move(to: pt(x, 22)); p.addLine(to: pt(x + 9, 27))
            }
        }
        // Váy chấm bi
        hanger(26)
        ctx.rect(19, 25, 14, 14, rgb(0xF6B3C6), radius: 3)
        ctx.polygon([pt(19, 37), pt(33, 37), pt(39, 66), pt(13, 66)], rgb(0xF6B3C6))
        ctx.rect(19, 36, 14, 3, rgb(0xFFFFFF), radius: 1.5)
        for (x, y) in [(CGFloat(19), CGFloat(46)), (27, 44), (33, 52), (22, 57), (30, 60), (17, 63)] {
            ctx.circle(x, y, 1.3, Color.white.opacity(0.85))
        }
        // Áo len sọc
        hanger(50)
        ctx.rect(38, 25, 24, 34, rgb(0xA9D8BA), radius: 5)
        ctx.rect(35, 26, 7, 28, rgb(0x93CCA6), radius: 3.5)
        ctx.rect(58, 26, 7, 28, rgb(0x93CCA6), radius: 3.5)
        for y in [CGFloat(34), 42, 50] {
            ctx.rect(38, y, 24, 3, Color.white.opacity(0.75))
        }
        ctx.ellipse(45, 24, 10, 5, rgb(0x93CCA6))
        // Áo mưa vàng
        hanger(74)
        ctx.polygon([pt(65, 25), pt(83, 25), pt(86, 70), pt(62, 70)], rgb(0xF7D27A))
        ctx.rect(65, 25, 18, 5, rgb(0xF0C255), radius: 2)
        ctx.rect(73.3, 30, 1.4, 40, rgb(0xE5B347))
        for y in [CGFloat(38), 48, 58] {
            ctx.circle(76.8, y, 1.4, rgb(0xFFFBF5))
        }
        ctx.rect(66, 52, 6, 5, rgb(0xF0C255), radius: 1.5)
        // Mũ cói trên thanh
        ctx.ellipse(56, 9, 30, 7, rgb(0xF2D49A))
        ctx.ellipse(63, 2, 16, 11, rgb(0xF2D49A))
        ctx.rect(63, 8, 16, 2.6, rgb(0xF4A9A0), radius: 1.2)
        // Đôi ủng
        for x in [CGFloat(24), 36] {
            ctx.rect(x, 69, 7, 11, rgb(0xF4A3A8), radius: 2)
            ctx.rect(x, 76, 11, 4, rgb(0xF4A3A8), radius: 2)
            ctx.rect(x + 1, 70.5, 1.6, 6, Color.white.opacity(0.5), radius: 0.8)
        }
    }

    // MARK: Thảm

    private static func rugStar(_ ctx: GraphicsContext) {
        var c = ctx
        c.translateBy(x: 53, y: 77)
        c.scaleBy(x: 1, y: 0.56)
        star(c, 0, 6, 34, rgb(0xE9C46F))
        star(c, 0, 0, 34, rgb(0xF9DD8F))
        star(c, 0, 2, 22, rgb(0xFFEDBB))
        for (x, y) in [(CGFloat(-22), CGFloat(-6)), (22, -7), (0, -24), (-12, 18), (13, 18)] {
            c.circle(x, y, 1.8, Color.white.opacity(0.75))
        }
        sleepyEye(c, -6, 0, 5)
        sleepyEye(c, 6, 0, 5)
        c.ellipse(-13, 4, 6, 4, Palette.blush.opacity(0.85))
        c.ellipse(7, 4, 6, 4, Palette.blush.opacity(0.85))
    }

    private static func rugFluffy(_ ctx: GraphicsContext) {
        let fur = rgb(0xD9EED3)
        let shade = rgb(0xB3D7AE)
        let n = 30
        for (dy, color, grow) in [(CGFloat(2.5), shade, CGFloat(1)), (0, fur, 0)] {
            for i in 0..<n {
                let a = Double(i) / Double(n) * 2 * Double.pi
                ctx.circle(53 + (34 + grow) * CGFloat(cos(a)), 77 + dy + (17 + grow) * CGFloat(sin(a)), 4.4, color)
            }
            ctx.ellipse(19, 60 + dy, 68, 34, color)
        }
        ctx.ellipse(27, 64, 52, 26, rgb(0xEAF6E6))
        ctx.strokePath(Color.white, width: 1.2) { p in
            for i in 0..<14 {
                let a = Double(i) / 14 * 2 * Double.pi
                let x = 53 + 24 * CGFloat(cos(a)), y = 77 + 12 * CGFloat(sin(a))
                p.move(to: pt(x - 1.6, y + 1)); p.addQuadCurve(to: pt(x + 1.6, y + 1), control: pt(x, y - 2))
            }
            for (x, y) in [(CGFloat(44), CGFloat(74)), (60, 72), (52, 82), (38, 82), (68, 81)] {
                p.move(to: pt(x - 1.6, y + 1)); p.addQuadCurve(to: pt(x + 1.6, y + 1), control: pt(x, y - 2))
            }
        }
        ctx.strokePath(shade, width: 1) { p in
            for (x, y) in [(CGFloat(48), CGFloat(68)), (64, 77), (44, 87), (58, 88), (34, 74), (72, 70)] {
                p.move(to: pt(x - 1.4, y + 1)); p.addQuadCurve(to: pt(x + 1.4, y + 1), control: pt(x, y - 1.6))
            }
        }
    }

    private static func rugCatFace(_ ctx: GraphicsContext) {
        let fur = rgb(0xF7C59F)
        let dark = rgb(0xE6A579)
        let light = rgb(0xFFF1E0)
        let pink = rgb(0xF6B3C6)
        // Tai
        ctx.polygon([pt(22, 72), pt(25, 52), pt(42, 63)], dark)
        ctx.polygon([pt(84, 72), pt(81, 52), pt(64, 63)], dark)
        ctx.polygon([pt(23, 70), pt(26, 51), pt(42, 61)], fur)
        ctx.polygon([pt(83, 70), pt(80, 51), pt(64, 61)], fur)
        ctx.polygon([pt(27, 64), pt(28, 56), pt(36, 61)], pink)
        ctx.polygon([pt(79, 64), pt(78, 56), pt(70, 61)], pink)
        // Mặt
        ctx.ellipse(18, 62, 70, 35, dark)
        ctx.ellipse(18, 59, 70, 35, fur)
        for dx in [CGFloat(-6), 0, 6] {
            ctx.ellipse(53 + dx - 1.4, 61, 2.8, 7, dark)
        }
        ctx.ellipse(39, 76, 28, 15, light)
        sleepyEye(ctx, 39, 74, 7, width: 1.6)
        sleepyEye(ctx, 67, 74, 7, width: 1.6)
        ctx.polygon([pt(50.5, 78.5), pt(55.5, 78.5), pt(53, 81)], pink)
        ctx.strokePath(ink, width: 1.3) { p in
            p.move(to: pt(53, 81)); p.addQuadCurve(to: pt(48.5, 83.5), control: pt(52, 84.5))
            p.move(to: pt(53, 81)); p.addQuadCurve(to: pt(57.5, 83.5), control: pt(54, 84.5))
        }
        ctx.ellipse(28, 78, 9, 5, Palette.blush.opacity(0.9))
        ctx.ellipse(69, 78, 9, 5, Palette.blush.opacity(0.9))
        ctx.strokePath(dark, width: 1) { p in
            p.move(to: pt(30, 84)); p.addLine(to: pt(14, 82))
            p.move(to: pt(30, 87)); p.addLine(to: pt(16, 89))
            p.move(to: pt(76, 84)); p.addLine(to: pt(92, 82))
            p.move(to: pt(76, 87)); p.addLine(to: pt(90, 89))
        }
    }

    // MARK: Đồ chơi

    private static func plushWhale(_ ctx: GraphicsContext) {
        let blue = rgb(0x9CC8EE)
        let shade = rgb(0x7FB2E0)
        let belly = rgb(0xEAF4FC)
        shadow(ctx, 8, 86, 82, 10)
        // Đuôi vểnh
        ctx.strokePath(blue, width: 11) { p in
            p.move(to: pt(70, 70)); p.addQuadCurve(to: pt(86, 44), control: pt(84, 64))
        }
        ctx.rotated(-35, around: pt(84, 42)) { c in c.ellipse(72, 36, 16, 10, blue) }
        ctx.rotated(35, around: pt(88, 42)) { c in c.ellipse(84, 36, 16, 10, blue) }
        // Thân
        let body = CGRect(x: 6, y: 36, width: 76, height: 56)
        ctx.ellipse(body.minX, body.minY, body.width, body.height, blue)
        var g = ctx
        g.clip(to: Path(ellipseIn: body))
        g.ellipse(0, 68, 80, 34, belly)
        g.strokePath(rgb(0xCFE2F4), width: 1.2) { p in
            for y in [CGFloat(76), 82, 88] {
                p.move(to: pt(14, y)); p.addLine(to: pt(70, y))
            }
        }
        star(ctx, 58, 50, 5, rgb(0xFFF1C2))
        star(ctx, 70, 60, 3, rgb(0xFFF1C2))
        ctx.ellipse(18, 42, 16, 8, Color.white.opacity(0.35))
        // Mặt
        sleepyEye(ctx, 26, 60, 7, width: 1.6)
        ctx.ellipse(18, 64, 9, 5, Palette.blush.opacity(0.9))
        ctx.strokePath(ink, width: 1.3) { p in
            p.move(to: pt(12, 70)); p.addQuadCurve(to: pt(20, 70), control: pt(16, 73.5))
        }
        ctx.rotated(25, around: pt(46, 76)) { c in c.ellipse(38, 72, 18, 9, shade) }
        // Vòi nước hình tim
        ctx.strokePath(rgb(0xAFD8F2), width: 2.2) { p in
            p.move(to: pt(34, 36)); p.addLine(to: pt(34, 26))
        }
        ctx.heart(center: pt(34, 20), size: 14, rgb(0xAFD8F2))
        ctx.circle(22, 26, 2, rgb(0xAFD8F2))
        ctx.circle(46, 26, 2, rgb(0xAFD8F2))
    }

    private static func plushOctopus(_ ctx: GraphicsContext) {
        let pink = rgb(0xF6B3C6)
        let shade = rgb(0xE897B1)
        let spot = rgb(0xFCD9E3)
        shadow(ctx, 6, 86, 88, 10)
        let arms: [(CGFloat, CGPoint, CGPoint)] = [
            (30, pt(10, 82), pt(14, 64)), (40, pt(28, 92), pt(28, 80)), (50, pt(52, 94), pt(48, 84)),
            (60, pt(74, 92), pt(70, 80)), (70, pt(91, 80), pt(88, 64))
        ]
        for (sx, end, c) in arms {
            ctx.strokePath(pink, width: 10) { p in
                p.move(to: pt(sx, 60)); p.addQuadCurve(to: end, control: c)
            }
            ctx.circle(end.x, end.y - 3.5, 4.2, shade)
            for t in [CGFloat(0.55), 0.8] {
                let m = quad(pt(sx, 60), c, end, t)
                ctx.circle(m.x, m.y + 2, 1.3, spot)
            }
        }
        // Đầu tròn
        ctx.ellipse(20, 10, 60, 60, pink)
        ctx.circle(34, 24, 3.6, spot)
        ctx.circle(62, 20, 2.6, spot)
        ctx.circle(68, 32, 2, spot)
        ctx.ellipse(30, 14, 12, 7, Color.white.opacity(0.4))
        // Mặt
        ctx.circle(40, 46, 3.4, ink)
        ctx.circle(60, 46, 3.4, ink)
        ctx.circle(39, 45, 1.1, Color.white.opacity(0.9))
        ctx.circle(59, 45, 1.1, Color.white.opacity(0.9))
        ctx.ellipse(29, 50, 8, 4.5, Palette.blush.opacity(0.95))
        ctx.ellipse(63, 50, 8, 4.5, Palette.blush.opacity(0.95))
        ctx.ellipse(47.5, 51, 5, 5, shade)
        ctx.ellipse(48.5, 52, 3, 3, ink.opacity(0.75))
        // Nơ
        ctx.polygon([pt(70, 16), pt(60, 9), pt(62, 22)], rgb(0xB9A6EA))
        ctx.polygon([pt(70, 16), pt(80, 9), pt(79, 23)], rgb(0xB9A6EA))
        ctx.circle(70, 16, 3, rgb(0x9F8BDB))
    }

    private static func plushEgg(_ ctx: GraphicsContext) {
        let shell = rgb(0xFFF6E6)
        let shellShade = rgb(0xF1E2C8)
        let spot = rgb(0xA9DDB8)
        let green = rgb(0xA9DDB8)
        let greenShade = rgb(0x86C79A)
        shadow(ctx, 16, 86, 68, 10)
        // Bé khủng long ló đầu
        for (x, y) in [(CGFloat(40), CGFloat(22)), (50, 19), (60, 22)] {
            ctx.polygon([pt(x - 4, y + 4), pt(x, y - 4), pt(x + 4, y + 4)], rgb(0xF7C59F))
        }
        ctx.ellipse(28, 20, 44, 40, green)
        ctx.circle(41, 38, 3.2, ink)
        ctx.circle(59, 38, 3.2, ink)
        ctx.circle(40, 37, 1.1, Color.white.opacity(0.9))
        ctx.circle(58, 37, 1.1, Color.white.opacity(0.9))
        ctx.ellipse(31, 42, 7, 4, Palette.blush.opacity(0.9))
        ctx.ellipse(62, 42, 7, 4, Palette.blush.opacity(0.9))
        ctx.strokePath(ink, width: 1.3) { p in
            p.move(to: pt(45, 45)); p.addQuadCurve(to: pt(55, 45), control: pt(50, 49))
        }
        ctx.polygon([pt(48, 46.5), pt(51, 46.8), pt(49.5, 49.5)], Color.white)
        // Nửa vỏ dưới, mép răng cưa
        var low = Path()
        low.move(to: pt(18, 54))
        var x: CGFloat = 18
        var up = true
        while x < 82 {
            x += 8
            low.addLine(to: pt(min(x, 82), up ? 47 : 54))
            up.toggle()
        }
        low.addCurve(to: pt(50, 95), control1: pt(84, 78), control2: pt(70, 95))
        low.addCurve(to: pt(18, 54), control1: pt(30, 95), control2: pt(16, 78))
        low.closeSubpath()
        ctx.fill(low, with: .color(shell))
        var g = ctx
        g.clip(to: low)
        g.ellipse(18, 78, 70, 30, shellShade)
        g.ellipse(26, 60, 10, 7, spot)
        g.ellipse(58, 66, 13, 9, spot)
        g.ellipse(40, 80, 9, 6, spot)
        g.ellipse(70, 52, 8, 6, spot)
        ctx.ellipse(22, 60, 5, 12, Color.white.opacity(0.6))
        // Tay bám mép vỏ
        ctx.ellipse(28, 48, 10, 7, greenShade)
        ctx.ellipse(62, 48, 10, 7, greenShade)
        // Nửa vỏ trên làm mũ
        ctx.rotated(-14, around: pt(50, 22)) { c in
            var cap = Path()
            cap.move(to: pt(30, 22))
            var xx: CGFloat = 30
            var dn = true
            while xx < 69 {
                xx += 6.66
                cap.addLine(to: pt(min(xx, 70), dn ? 27 : 22))
                dn.toggle()
            }
            cap.addCurve(to: pt(30, 22), control1: pt(68, 0), control2: pt(32, 0))
            cap.closeSubpath()
            c.fill(cap, with: .color(shell))
            c.ellipse(44, 10, 9, 6, spot)
            c.ellipse(36, 8, 5, 4, Color.white.opacity(0.7))
        }
    }
}
