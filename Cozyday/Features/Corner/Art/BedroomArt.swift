import SwiftUI

/// Hình vẽ đồ trong Bedroom. Trả về false nếu không phải ID của phòng này.
enum BedroomArt {
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        case "bedroomTheme.lilac", "bedroomTheme.cloud", "bedroomTheme.candy", "bedroomTheme.galaxy":
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
        default: return false
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
