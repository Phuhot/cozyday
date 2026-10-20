import SwiftUI

/// Hình vẽ đồ trong Kitchen. Trả về false nếu không phải ID của phòng này.
enum KitchenArt {
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        // MARK: Tường & sàn (125×100)
        case "kitchenTheme.mint": themeMint(clipRoom(ctx))
        case "kitchenTheme.gingham": themeGingham(clipRoom(ctx))
        case "kitchenTheme.lemon": themeLemon(clipRoom(ctx))
        case "kitchenTheme.wood": themeWood(clipRoom(ctx))
        case "kitchenTheme.bakery": themeBakery(clipRoom(ctx))
        case "kitchenTheme.night": themeNight(clipRoom(ctx))
        // MARK: Bếp
        case "stove.basic": stoveBasic(ctx)
        case "stove.retro": stoveRetro(ctx)
        case "stove.oven": stoveOven(ctx)
        case "stove.hearth": stoveHearth(ctx)
        case "stove.induction": stoveInduction(ctx)
        case "stove.pizza": stovePizza(ctx)
        case "stove.waffle": stoveWaffle(ctx)
        case "stove.cat": stoveCat(ctx)
        // MARK: Tủ lạnh
        case "fridge.mini": fridgeMini(ctx)
        case "fridge.retro": fridgeRetro(ctx)
        case "fridge.pink": fridgePink(ctx)
        case "fridge.magnets": fridgeMagnets(ctx)
        case "fridge.double": fridgeDouble(ctx)
        case "fridge.icebox": fridgeIcebox(ctx)
        case "fridge.glass": fridgeGlass(ctx)
        case "fridge.cat": fridgeCat(ctx)
        // MARK: Bàn ăn
        case "dining.stool": diningStool(ctx)
        case "dining.round": diningRound(ctx)
        case "dining.picnic": diningPicnic(ctx)
        case "dining.long": diningLong(ctx)
        case "dining.kotatsu": diningKotatsu(ctx)
        case "dining.bar": diningBar(ctx)
        case "dining.stump": diningStump(ctx)
        case "dining.booth": diningBooth(ctx)
        // MARK: Đồ treo tường
        case "kitchenWall.clock": wallClock(ctx)
        case "kitchenWall.pans": wallPans(ctx)
        case "kitchenWall.fruit": wallFruit(ctx)
        case "kitchenWall.jars": wallJars(ctx)
        case "kitchenWall.spice": wallSpice(ctx)
        case "kitchenWall.herbs": wallHerbs(ctx)
        case "kitchenWall.plates": wallPlates(ctx)
        case "kitchenWall.menu": wallMenu(ctx)
        case "kitchenWall.cherry": wallCherry(ctx)
        // MARK: Món ăn trên bàn
        case "treat.tea": treatTea(ctx)
        case "treat.bread": treatBread(ctx)
        case "treat.ramen": treatRamen(ctx)
        case "treat.pizza": treatPizza(ctx)
        case "treat.cake": treatCake(ctx)
        case "treat.dumpling": treatDumpling(ctx)
        case "treat.pho": treatPho(ctx)
        case "treat.banhmi": treatBanhMi(ctx)
        case "treat.mooncake": treatMooncake(ctx)
        case "treat.boba": treatBoba(ctx)
        default: return false
        }
        return true
    }

    // MARK: - Màu chung

    private static let ink = rgb(0x5A4E66)
    private static let cream = rgb(0xFFF8EC)
    private static let steel = rgb(0xD9DCE3)
    private static let steelDark = rgb(0xB9BCC8)
    private static let shadow = Color.black.opacity(0.1)

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func sparkle(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 6, _ color: Color = Color.white.opacity(0.8)) {
        ctx.draw(Text("✦").font(.system(size: size)).foregroundColor(color), at: pt(x, y))
    }

    private static func steam(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ h: CGFloat, _ color: Color = Color.white.opacity(0.75), width: CGFloat = 2.5) {
        ctx.strokePath(color, width: width) { p in
            p.move(to: pt(x, y))
            p.addCurve(to: pt(x, y - h), control1: pt(x - h * 0.35, y - h * 0.33), control2: pt(x + h * 0.35, y - h * 0.66))
        }
    }

    // MARK: - Tường & sàn

    private static func clipRoom(_ ctx: GraphicsContext) -> GraphicsContext {
        var c = ctx
        c.clip(to: Path(CGRect(x: 0, y: 0, width: 125, height: 100)))
        return c
    }

    /// Cửa sổ ở x 46…72, y 8…30, có rèm ngắn màu `curtain`.
    private static func window(_ ctx: GraphicsContext, frame: Color, curtain: Color, night: Bool = false) {
        ctx.rect(45, 7, 28, 24, frame, radius: 2.5)
        if night {
            ctx.rect(47.5, 9.5, 23, 19, rgb(0x34386B), radius: 1.5)
            ctx.circle(65, 15, 3.4, rgb(0xFFF1B8))
            ctx.circle(66.6, 13.8, 3, rgb(0x34386B))
            for (sx, sy) in [(51.0, 14.0), (55.5, 23.0), (62.0, 24.5), (52.5, 21.0)] as [(CGFloat, CGFloat)] {
                ctx.circle(sx, sy, 0.7, rgb(0xFFF1B8))
            }
        } else {
            ctx.rect(47.5, 9.5, 23, 19, rgb(0xCFE9F4), radius: 1.5)
            ctx.ellipse(50, 20, 9, 4, Color.white.opacity(0.85))
            ctx.ellipse(54, 18, 7, 4, Color.white.opacity(0.85))
            ctx.circle(66, 14, 2.6, rgb(0xFBE7A6))
        }
        ctx.rect(58.2, 9.5, 1.6, 19, frame)
        ctx.rect(47.5, 18.4, 23, 1.6, frame)
        // rèm ngắn có viền lượn sóng
        ctx.rect(46, 7.5, 26, 4, curtain, radius: 1.5)
        for i in 0..<6 {
            ctx.circle(48.2 + CGFloat(i) * 4.3, 11.4, 2.2, curtain)
        }
        ctx.rect(44, 29, 30, 3, frame, radius: 1.2)
        // chậu rau thơm nhỏ trên bậu
        ctx.rect(64, 25, 5, 4, rgb(0xE9A27F), radius: 1)
        ctx.ellipse(63.2, 21.5, 3.6, 4.2, rgb(0x8CC08F))
        ctx.ellipse(65.8, 20.6, 3.6, 4.6, rgb(0x7DB582))
        ctx.ellipse(66.8, 22, 3, 3.6, rgb(0x8CC08F))
    }

    /// Dải gạch men ốp phía sau bếp và tủ lạnh.
    private static func backsplash(_ ctx: GraphicsContext, _ base: Color, _ grout: Color) {
        ctx.rect(48, 39, 77, 22, base)
        var row = 0
        var y: CGFloat = 40
        while y < 61 {
            ctx.rect(48, y, 77, 0.6, grout)
            var x: CGFloat = row % 2 == 0 ? 48 : 52
            while x < 125 {
                ctx.rect(x, y, 0.6, 3.5, grout)
                x += 8
            }
            y += 3.5
            row += 1
        }
        ctx.rect(47, 38, 78, 2, grout, radius: 1)
        ctx.rect(47, 38, 78, 0.7, Color.white.opacity(0.6))
    }

    private static func floorChecker(_ ctx: GraphicsContext, _ a: Color, _ b: Color) {
        ctx.rect(0, 62, 125, 38, a)
        let rows: [CGFloat] = [62, 69, 77, 87.5]
        let heights: [CGFloat] = [7, 8, 10.5, 12.5]
        for r in 0..<rows.count {
            let w: CGFloat = 12.5 + CGFloat(r) * 1.5
            var x: CGFloat = r % 2 == 0 ? 0 : -w / 2
            var k = 0
            while x < 125 {
                if k % 2 == 0 { ctx.rect(x, rows[r], w, heights[r], b) }
                x += w
                k += 1
            }
        }
    }

    private static func baseboard(_ ctx: GraphicsContext, _ color: Color) {
        ctx.rect(0, 59.5, 125, 3.5, color)
        ctx.rect(0, 59.5, 125, 0.8, Color.white.opacity(0.5))
        ctx.rect(0, 63, 125, 1.2, Color.black.opacity(0.06))
    }

    private static func themeMint(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xDDF1E5))
        // gạch men vuông
        let grout = Color.white.opacity(0.55)
        var y: CGFloat = 0
        while y < 60 { ctx.rect(0, y, 125, 0.6, grout); y += 10 }
        var x: CGFloat = 0
        while x < 125 { ctx.rect(x, 0, 0.6, 60, grout); x += 10 }
        for (cx, cy) in [(5.0, 5.0), (35.0, 25.0), (95.0, 15.0), (115.0, 35.0), (25.0, 45.0), (85.0, 5.0)] {
            sparkle(ctx, cx, cy, 4, Color.white.opacity(0.7))
        }
        backsplash(ctx, rgb(0xF6FBF7), rgb(0xD6ECDF))
        window(ctx, frame: rgb(0xFFFDF8), curtain: rgb(0xF3B7B3))
        baseboard(ctx, rgb(0xA9D6BC))
        floorChecker(ctx, rgb(0xFAF4E6), rgb(0xCBE7D6))
    }

    private static func themeGingham(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xFFF5EC))
        let red = rgb(0xEE9E9A).opacity(0.22)
        var x: CGFloat = 0
        while x < 125 { ctx.rect(x, 0, 4, 60, red); x += 8 }
        var y: CGFloat = 0
        while y < 60 { ctx.rect(0, y, 125, 4, red); y += 8 }
        backsplash(ctx, rgb(0xFFFBF6), rgb(0xF5DDD6))
        window(ctx, frame: rgb(0xFFFDF8), curtain: rgb(0xE88F8C))
        baseboard(ctx, rgb(0xE7A7A2))
        floorChecker(ctx, rgb(0xFCF1E7), rgb(0xF0C3BC))
    }

    private static func themeLemon(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xFFF3C4))
        // họa tiết trái chanh nhỏ
        var row = 0
        var y: CGFloat = 6
        while y < 58 {
            var x: CGFloat = row % 2 == 0 ? 6 : 16
            while x < 125 {
                ctx.ellipse(x - 2.6, y - 1.8, 5.2, 3.6, rgb(0xF6D867).opacity(0.75))
                ctx.ellipse(x + 0.6, y - 3.4, 2.6, 1.4, rgb(0xA8D08D).opacity(0.75))
                x += 20
            }
            y += 11
            row += 1
        }
        backsplash(ctx, rgb(0xFFFDF2), rgb(0xF4E7B8))
        window(ctx, frame: rgb(0xFFFDF8), curtain: rgb(0xA8D3A6))
        baseboard(ctx, rgb(0xEDCB6A))
        floorChecker(ctx, rgb(0xFFFCEF), rgb(0xF7E6A6))
    }

    private static func themeWood(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xE6C39C))
        var x: CGFloat = 0
        var i = 0
        while x < 125 {
            if i % 3 == 1 { ctx.rect(x, 0, 9, 60, rgb(0xDDB78E)) }
            ctx.rect(x, 0, 0.7, 60, rgb(0xC99D70))
            ctx.circle(x + 4.5, CGFloat((i * 17) % 50) + 6, 0.9, rgb(0xC99D70).opacity(0.7))
            x += 9
            i += 1
        }
        backsplash(ctx, rgb(0xF7EBDD), rgb(0xE3CDB5))
        window(ctx, frame: rgb(0xB98559), curtain: rgb(0xE7A39A))
        baseboard(ctx, rgb(0xA87A50))
        // sàn ván gỗ
        ctx.rect(0, 62, 125, 38, rgb(0xC9976A))
        let rows: [CGFloat] = [62, 70, 79, 89]
        for (r, ry) in rows.enumerated() {
            ctx.rect(0, ry, 125, 0.8, rgb(0xAD7D52))
            var sx: CGFloat = CGFloat((r * 23) % 40) + 8
            while sx < 125 {
                ctx.rect(sx, ry, 0.8, r == 3 ? 11 : rows[r + 1] - ry, rgb(0xAD7D52))
                sx += 38
            }
            if r % 2 == 0 { ctx.rect(0, ry + 2, 125, 1, Color.white.opacity(0.12)) }
        }
    }

    // MARK: - Bếp (ô 100×100, thân bếp x 6…70, đáy ≈ 94)

    private static func knob(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        ctx.circle(cx, cy, r, color)
        ctx.rect(cx - 0.8, cy - r + 0.8, 1.6, r * 0.9, Color.white.opacity(0.8), radius: 0.8)
    }

    private static func stoveBasic(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 89, 70, 8, shadow)
        // tủ bếp
        ctx.rect(9, 46, 58, 46, rgb(0xF5EFE4), radius: 4)
        ctx.rect(13, 54, 24, 34, rgb(0xFBF7F0), radius: 3)
        ctx.rect(39, 54, 24, 34, rgb(0xFBF7F0), radius: 3)
        ctx.rect(32, 66, 2.5, 8, steelDark, radius: 1.2)
        ctx.rect(41.5, 66, 2.5, 8, steelDark, radius: 1.2)
        ctx.rect(12, 91, 6, 3, rgb(0xB5AFA8), radius: 1)
        ctx.rect(58, 91, 6, 3, rgb(0xB5AFA8), radius: 1)
        // mặt bếp
        ctx.rect(6, 38, 64, 10, steel, radius: 3)
        ctx.rect(6, 38, 64, 2.5, Color.white.opacity(0.6), radius: 1.2)
        knob(ctx, 16, 44, 2.6, rgb(0xE59A7A))
        knob(ctx, 24, 44, 2.6, rgb(0xE59A7A))
        ctx.rect(52, 42.5, 12, 3, rgb(0x8E8899), radius: 1.5)
        // hai bếp
        ctx.ellipse(12, 35.5, 22, 5, rgb(0x6A6274))
        ctx.ellipse(16, 36.3, 14, 3, rgb(0xF3A07A))
        ctx.ellipse(42, 35.5, 22, 5, rgb(0x6A6274))
        // nồi
        ctx.rect(38, 33, 4, 3, rgb(0xD47F64), radius: 1)
        ctx.rect(62, 33, 4, 3, rgb(0xD47F64), radius: 1)
        ctx.rect(41, 18, 22, 20, rgb(0xF0A387), radius: 5)
        ctx.rect(41, 26, 22, 3, rgb(0xFBD3C2))
        ctx.ellipse(39, 14, 26, 7, rgb(0xE08E70))
        ctx.circle(52, 13, 2.5, rgb(0x8E6B5A))
        ctx.rect(44, 20, 3, 12, Color.white.opacity(0.45), radius: 1.5)
        steam(ctx, 46, 9, 9)
        steam(ctx, 56, 8, 8)
    }

    private static func stoveRetro(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 89, 70, 8, shadow)
        let body = rgb(0xFBF0D9)
        // tấm chắn phía sau có đồng hồ nhỏ
        ctx.rect(10, 20, 56, 16, body, radius: 7)
        ctx.circle(38, 27.5, 4.5, rgb(0xEFE3C8))
        ctx.circle(38, 27.5, 3.3, Color.white)
        ctx.strokePath(ink, width: 0.9) { p in
            p.move(to: pt(38, 27.5)); p.addLine(to: pt(38, 25.2))
            p.move(to: pt(38, 27.5)); p.addLine(to: pt(39.8, 28.4))
        }
        ctx.rect(14, 33, 48, 2, rgb(0x9FD3C1), radius: 1)
        // thân
        ctx.rect(6, 34, 64, 58, body, radius: 9)
        ctx.rect(6, 34, 64, 4, rgb(0x6A6274).opacity(0.85), radius: 2)
        ctx.ellipse(10, 33, 14, 3, rgb(0x6A6274))
        ctx.ellipse(52, 33, 14, 3, rgb(0x6A6274))
        // núm xoay
        for (i, cx) in [18.0, 30.0, 46.0, 58.0].enumerated() {
            knob(ctx, cx, 45, 3.6, i % 2 == 0 ? rgb(0xEE8F8F) : rgb(0x8FCDB9))
        }
        // cửa lò
        ctx.rect(12, 53, 52, 33, rgb(0xF3E2C2), radius: 6)
        ctx.rect(17, 54.5, 42, 3, steelDark, radius: 1.5)
        ctx.rect(19, 61, 38, 19, rgb(0x6F6680), radius: 5)
        ctx.rect(22, 63, 10, 3, Color.white.opacity(0.35), radius: 1.5)
        ctx.ellipse(28, 74, 20, 4, rgb(0xF1B36B).opacity(0.6))
        // điểm sáng & chân
        ctx.rect(9, 40, 3, 40, Color.white.opacity(0.55), radius: 1.5)
        ctx.rect(11, 90, 7, 4, steelDark, radius: 1.5)
        ctx.rect(58, 90, 7, 4, steelDark, radius: 1.5)
    }

    private static func stoveOven(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 89, 70, 8, shadow)
        let body = rgb(0xF4C9AE)
        // thân lò mái vòm
        ctx.rect(6, 40, 64, 52, body, radius: 6)
        ctx.ellipse(6, 26, 64, 34, body)
        ctx.rect(6, 52, 64, 4, rgb(0xE9B293))
        // ô cửa sổ lò đang sáng
        ctx.rect(14, 58, 48, 28, rgb(0xE6A58A), radius: 7)
        ctx.rect(17, 61, 42, 22, rgb(0xFBD98C), radius: 5)
        ctx.ellipse(20, 63, 36, 12, rgb(0xFFF0C2).opacity(0.8))
        ctx.rect(19, 75, 38, 1.4, rgb(0xC98E5E))
        for cx in [26.0, 38.0, 50.0] {
            ctx.ellipse(cx - 5, 70.5, 10, 5, rgb(0xD9A061))
            ctx.circle(cx - 1.5, 72, 0.9, rgb(0x6B4A3A))
            ctx.circle(cx + 2, 71.6, 0.9, rgb(0x6B4A3A))
        }
        ctx.rect(26, 54.5, 24, 2.6, cream, radius: 1.3)
        // núm & đồng hồ hẹn giờ
        knob(ctx, 22, 43, 3.6, rgb(0xFFF4E6))
        knob(ctx, 54, 43, 3.6, rgb(0xFFF4E6))
        ctx.circle(38, 39, 6, cream)
        ctx.heart(center: pt(38, 39.5), size: 6, rgb(0xEE8F8F))
        // ống khói nhỏ + mùi bánh
        ctx.rect(52, 18, 9, 14, rgb(0xE3AD90), radius: 2)
        ctx.rect(50.5, 16, 12, 4, rgb(0xD99C7E), radius: 2)
        steam(ctx, 54, 13, 9, Color.white.opacity(0.85))
        ctx.heart(center: pt(46, 9), size: 5, rgb(0xF4B0B0))
        ctx.heart(center: pt(62, 5), size: 4, rgb(0xF4B0B0))
        ctx.rect(10, 44, 3, 36, Color.white.opacity(0.45), radius: 1.5)
        ctx.ellipse(16, 32, 10, 5, Color.white.opacity(0.5))
        ctx.rect(10, 90, 8, 4, rgb(0xC88E70), radius: 1.5)
        ctx.rect(58, 90, 8, 4, rgb(0xC88E70), radius: 1.5)
    }

    private static func stoveHearth(_ ctx: GraphicsContext) {
        ctx.ellipse(2, 88, 74, 9, shadow)
        let iron = rgb(0x6E6278)
        let ironDark = rgb(0x584D62)
        // ống khói
        ctx.rect(51, 0, 9, 40, iron)
        ctx.rect(49.5, 10, 12, 3, ironDark, radius: 1.5)
        ctx.rect(49.5, 26, 12, 3, ironDark, radius: 1.5)
        ctx.rect(53, 0, 2, 38, Color.white.opacity(0.2))
        // thân bếp gang
        ctx.rect(8, 38, 60, 6, ironDark, radius: 3)
        ctx.rect(11, 43, 54, 44, iron, radius: 6)
        ctx.rect(14, 86, 6, 8, ironDark, radius: 2)
        ctx.rect(56, 86, 6, 8, ironDark, radius: 2)
        // cửa lửa
        var arch = Path()
        arch.move(to: pt(20, 80))
        arch.addLine(to: pt(20, 62))
        arch.addQuadCurve(to: pt(56, 62), control: pt(38, 44))
        arch.addLine(to: pt(56, 80))
        arch.closeSubpath()
        ctx.fill(arch, with: .color(rgb(0x3F3548)))
        // củi + lửa
        ctx.rect(24, 74, 28, 5, rgb(0xB0805F), radius: 2.5)
        ctx.rect(28, 70, 22, 5, rgb(0x9A6C4F), radius: 2.5)
        ctx.polygon([pt(26, 72), pt(30, 60), pt(34, 66), pt(38, 54), pt(43, 65), pt(47, 59), pt(50, 72)], rgb(0xF4A25E))
        ctx.polygon([pt(31, 72), pt(35, 64), pt(38, 61), pt(42, 67), pt(45, 72)], rgb(0xF8D772))
        ctx.circle(38, 69, 2.5, rgb(0xFFF2C8))
        ctx.rect(18, 81, 40, 2.4, ironDark, radius: 1.2)
        // tia lửa tí tách
        sparkle(ctx, 32, 52, 5, rgb(0xF8D772))
        sparkle(ctx, 46, 50, 4, rgb(0xF4A25E))
        // ấm nước trên bếp
        ctx.ellipse(16, 25, 26, 15, rgb(0x8FCDB9))
        ctx.rect(16, 31, 26, 8, rgb(0x8FCDB9), radius: 3)
        ctx.strokePath(rgb(0x6FB09B), width: 2) { p in
            p.move(to: pt(20, 26)); p.addQuadCurve(to: pt(38, 26), control: pt(29, 14))
        }
        ctx.polygon([pt(17, 30), pt(10, 24), pt(12, 22.5), pt(19, 27)], rgb(0x8FCDB9))
        ctx.circle(29, 24.5, 2, rgb(0x6FB09B))
        ctx.rect(20, 28, 3, 8, Color.white.opacity(0.5), radius: 1.5)
        steam(ctx, 10, 20, 8)
        ctx.rect(14, 46, 3, 30, Color.white.opacity(0.18), radius: 1.5)
    }

    // MARK: - Tủ lạnh (ô 100×100, chỉ dùng x 4…78 vì ô tràn mép phải phòng)

    private static func fridgeBody(_ ctx: GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color, radius: CGFloat) {
        ctx.ellipse(x - 4, y + h - 4, w + 8, 8, shadow)
        ctx.rect(x + 5, y + h - 3, 6, 4, steelDark, radius: 1.5)
        ctx.rect(x + w - 11, y + h - 3, 6, 4, steelDark, radius: 1.5)
        ctx.rect(x, y, w, h - 1, color, radius: radius)
    }

    private static func fridgeMini(_ ctx: GraphicsContext) {
        fridgeBody(ctx, x: 14, y: 50, w: 50, h: 45, color: rgb(0xF4F6F8), radius: 7)
        ctx.strokePath(rgb(0xD8DCE4), width: 1.4) { p in
            p.move(to: pt(16, 62)); p.addLine(to: pt(62, 62))
        }
        ctx.rect(54, 66, 3.5, 16, steelDark, radius: 1.7)
        ctx.rect(54, 53, 3.5, 6, steelDark, radius: 1.7)
        ctx.rect(18, 54, 3, 30, Color.white.opacity(0.9), radius: 1.5)
        ctx.heart(center: pt(30, 72), size: 6, rgb(0xF4B0B0))
        // sữa
        ctx.rect(20, 32, 13, 18, Color.white, radius: 2)
        ctx.polygon([pt(20, 32), pt(26.5, 26), pt(33, 32)], rgb(0x9FC7EC))
        ctx.rect(25, 24, 3, 3, rgb(0x9FC7EC), radius: 1)
        ctx.rect(20, 38, 13, 6, rgb(0x9FC7EC))
        ctx.circle(26.5, 41, 1.6, Color.white)
        // bát trái cây
        ctx.circle(44, 40, 5, rgb(0xEE8B8B))
        ctx.rect(43.6, 33, 1.2, 3.5, rgb(0x8E6B5A))
        ctx.ellipse(50, 33, 9, 12, rgb(0xF6D867))
        ctx.circle(56, 41, 4.5, rgb(0xF4B36E))
        ctx.circle(42.5, 38.5, 1.2, Color.white.opacity(0.7))
        var bowl = Path()
        bowl.move(to: pt(38, 42))
        bowl.addQuadCurve(to: pt(62, 42), control: pt(50, 58))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(rgb(0x9FD3C1)))
        ctx.rect(46, 48, 8, 2, rgb(0x8BC5B1), radius: 1)
    }

    private static func fridgeRetro(_ ctx: GraphicsContext) {
        let body = rgb(0x9FDACB)
        fridgeBody(ctx, x: 8, y: 8, w: 66, h: 87, color: body, radius: 18)
        ctx.strokePath(rgb(0x7EC3B2), width: 1.6) { p in
            p.move(to: pt(9, 36)); p.addLine(to: pt(73, 36))
        }
        ctx.rect(62, 18, 4.5, 12, rgb(0xEDEBF1), radius: 2.2)
        ctx.rect(62, 42, 4.5, 24, rgb(0xEDEBF1), radius: 2.2)
        ctx.rect(30, 82, 22, 4, rgb(0xEDEBF1), radius: 2)
        ctx.ellipse(33, 46, 16, 6, rgb(0xEDEBF1))
        ctx.ellipse(35, 47.2, 12, 3.6, rgb(0xEE8F8F))
        ctx.rect(14, 16, 4, 16, Color.white.opacity(0.55), radius: 2)
        ctx.rect(14, 42, 4, 32, Color.white.opacity(0.55), radius: 2)
        sparkle(ctx, 24, 22, 7)
    }

    private static func fridgePink(_ ctx: GraphicsContext) {
        let body = rgb(0xF7C6D0)
        fridgeBody(ctx, x: 8, y: 6, w: 66, h: 89, color: body, radius: 11)
        ctx.strokePath(rgb(0xE9A6B5), width: 1.6) { p in
            p.move(to: pt(9, 34)); p.addLine(to: pt(73, 34))
        }
        ctx.rect(13, 12, 56, 4, Color.white.opacity(0.5), radius: 2)
        ctx.rect(14, 22, 3.5, 7, Color.white, radius: 1.7)
        ctx.rect(14, 40, 3.5, 22, Color.white, radius: 1.7)
        // nam châm dâu tây + tim
        ctx.heart(center: pt(52, 23), size: 9, rgb(0xEE7F95))
        ctx.ellipse(46, 50, 11, 12, rgb(0xEF7B7B))
        ctx.polygon([pt(46.5, 51), pt(51.5, 47), pt(56.5, 51), pt(51.5, 53)], rgb(0x8CC08F))
        for (sx, sy) in [(49.0, 55.0), (53.0, 54.0), (51.0, 58.0)] {
            ctx.circle(sx, sy, 0.8, rgb(0xFFF1B8))
        }
        // nhãn sữa dâu
        ctx.rect(26, 66, 30, 14, Color.white.opacity(0.85), radius: 4)
        ctx.circle(34, 73, 3.5, rgb(0xF7A7B8))
        ctx.rect(40, 70, 12, 2, rgb(0xE9A6B5), radius: 1)
        ctx.rect(40, 74, 9, 2, rgb(0xE9A6B5), radius: 1)
        ctx.rect(64, 12, 3, 74, Color.white.opacity(0.35), radius: 1.5)
        sparkle(ctx, 24, 20, 7)
    }

    private static func fridgeMagnets(_ ctx: GraphicsContext) {
        let body = rgb(0xF7F4EE)
        fridgeBody(ctx, x: 8, y: 6, w: 66, h: 89, color: body, radius: 11)
        ctx.strokePath(rgb(0xDEDAD3), width: 1.6) { p in
            p.move(to: pt(9, 32)); p.addLine(to: pt(73, 32))
        }
        ctx.rect(64, 14, 4, 12, steelDark, radius: 2)
        ctx.rect(64, 38, 4, 24, steelDark, radius: 2)
        // tranh vẽ: mặt trời
        ctx.rotated(-6, around: pt(26, 46)) { c in
            c.rect(14, 37, 24, 20, Color.white, radius: 1)
            c.circle(22, 45, 4, rgb(0xF6D867))
            c.strokePath(rgb(0xF6D867), width: 1) { p in
                p.move(to: pt(22, 38.5)); p.addLine(to: pt(22, 39.5))
                p.move(to: pt(15.8, 45)); p.addLine(to: pt(16.8, 45))
                p.move(to: pt(28.2, 45)); p.addLine(to: pt(27.2, 45))
            }
            c.rect(14, 52, 24, 5, rgb(0xA8D3A6))
            c.circle(32, 50, 2.5, rgb(0xEE8F8F))
        }
        ctx.circle(26, 37, 2.3, rgb(0x8D78CF))
        // tranh vẽ: con mèo
        ctx.rotated(5, around: pt(48, 70)) { c in
            c.rect(36, 60, 26, 21, rgb(0xFFF8E6), radius: 1)
            c.ellipse(42, 66, 14, 11, rgb(0xF2B27A))
            c.polygon([pt(43, 68), pt(44, 63), pt(47, 66.5)], rgb(0xF2B27A))
            c.polygon([pt(55, 68), pt(54, 63), pt(51, 66.5)], rgb(0xF2B27A))
            c.circle(46.5, 71, 0.9, ink)
            c.circle(51.5, 71, 0.9, ink)
        }
        ctx.circle(49, 60, 2.3, rgb(0x8FCDB9))
        // nam châm nhiều màu
        ctx.heart(center: pt(52, 15), size: 8, rgb(0xEE8F8F))
        ctx.circle(22, 16, 3.5, rgb(0xF6D867))
        ctx.circle(40, 22, 3, rgb(0x9FC7EC))
        ctx.draw(Text("★").font(.system(size: 10)).foregroundColor(rgb(0xF4B36E)), at: pt(30, 24))
        ctx.circle(56, 46, 3.2, rgb(0xC9B6F0))
        ctx.circle(22, 82, 3, rgb(0xF7A7B8))
        ctx.draw(Text("♪").font(.system(size: 9)).foregroundColor(rgb(0x8FCDB9)), at: pt(34, 86))
        ctx.rect(18, 66, 10, 7, rgb(0xF6D867), radius: 2)
        ctx.rect(13, 12, 3, 14, Color.white.opacity(0.9), radius: 1.5)
    }

    // MARK: - Bàn ăn (ô 100×100, mặt bàn ở y ≈ 41, giữa x = 50)
    // Món ăn được vẽ TRƯỚC bàn, nên khoảng x 24…76 phía trên y 41 phải để trống.

    private static func diningStool(_ ctx: GraphicsContext) {
        let top = rgb(0xFBEEDC)
        let leg = rgb(0x9DC3E6)
        ctx.ellipse(10, 89, 84, 8, shadow)
        ctx.rect(22, 47, 6, 46, leg, radius: 2)
        ctx.rect(72, 47, 6, 46, leg, radius: 2)
        ctx.rect(22, 58, 56, 3, leg, radius: 1.5)
        ctx.rect(14, 41, 72, 8, rgb(0xE9CFAE), radius: 3)
        ctx.rect(14, 41, 72, 4, top, radius: 2)
        ctx.rect(20, 42, 10, 1.2, Color.white.opacity(0.8), radius: 0.6)
        ctx.rect(18, 48.5, 64, 1.2, Color.black.opacity(0.06))
        // đẩu tròn phía trước
        ctx.ellipse(56, 90, 36, 6, shadow)
        ctx.rect(62, 74, 4.5, 19, rgb(0x86B2DA), radius: 2)
        ctx.rect(81, 74, 4.5, 19, rgb(0x86B2DA), radius: 2)
        ctx.rect(64, 84, 20, 2.5, rgb(0x86B2DA), radius: 1.2)
        ctx.ellipse(57, 69, 34, 10, rgb(0xE59A7A))
        ctx.ellipse(59, 68, 30, 7, rgb(0xF3B79C))
        ctx.ellipse(66, 69, 8, 2.4, Color.white.opacity(0.5))
    }

    private static func chair(_ ctx: GraphicsContext, x: CGFloat, color: Color, cushion: Color) {
        ctx.rect(x + 1, 22, 4, 70, color, radius: 2)
        ctx.rect(x + 15, 22, 4, 70, color, radius: 2)
        ctx.rect(x, 19, 20, 8, color, radius: 4)
        ctx.rect(x + 2, 32, 16, 3, color, radius: 1.5)
        ctx.rect(x + 2, 40, 16, 3, color, radius: 1.5)
        ctx.ellipse(x - 2, 56, 24, 8, cushion)
        ctx.ellipse(x + 2, 56.5, 10, 2.5, Color.white.opacity(0.5))
    }

    private static func diningRound(_ ctx: GraphicsContext) {
        let wood = rgb(0xC99060)
        let woodDark = rgb(0xA4724A)
        ctx.ellipse(2, 88, 96, 8, shadow)
        chair(ctx, x: 2, color: rgb(0x9CCDB6), cushion: rgb(0xF3B7B3))
        chair(ctx, x: 78, color: rgb(0x9CCDB6), cushion: rgb(0xF3B7B3))
        // bàn tròn một chân
        ctx.rect(46, 48, 8, 38, woodDark, radius: 2)
        ctx.ellipse(32, 84, 36, 8, woodDark)
        ctx.ellipse(16, 43, 68, 9, woodDark)
        ctx.ellipse(16, 40.5, 68, 8, wood)
        ctx.ellipse(28, 41.5, 18, 2.4, Color.white.opacity(0.45))
    }

    private static func diningPicnic(_ ctx: GraphicsContext) {
        let woodDark = rgb(0xB58357)
        ctx.ellipse(6, 88, 88, 8, shadow)
        ctx.rect(16, 60, 6, 33, woodDark, radius: 2)
        ctx.rect(78, 60, 6, 33, woodDark, radius: 2)
        // khăn trải bàn ca rô
        var cloth = Path()
        cloth.move(to: pt(10, 41))
        cloth.addLine(to: pt(90, 41))
        cloth.addLine(to: pt(93, 64))
        cloth.addLine(to: pt(7, 64))
        cloth.closeSubpath()
        for i in 0..<9 { cloth.addEllipse(in: CGRect(x: 7 + CGFloat(i) * 9.55, y: 60, width: 9.6, height: 8)) }
        ctx.fill(cloth, with: .color(Color.white))
        var c = ctx
        c.clip(to: cloth)
        let red = rgb(0xE9817F).opacity(0.5)
        var x: CGFloat = 7
        while x < 94 { c.rect(x, 41, 4.5, 28, red); x += 9 }
        var y: CGFloat = 45.5
        while y < 70 { c.rect(0, y, 100, 4.5, red); y += 9 }
        c.rect(0, 41, 100, 4.5, rgb(0xFFFFFF).opacity(0.0))
        // mặt bàn nhìn từ trên
        ctx.rect(10, 41, 80, 4, rgb(0xF6D6D3), radius: 1.5)
        ctx.rect(10, 41, 80, 1.2, Color.white.opacity(0.8), radius: 0.6)
        // lọ hoa cúc nhỏ ở góc
        ctx.rect(81, 33, 6, 8, rgb(0x9FC7EC), radius: 2)
        ctx.rect(83.6, 26, 1, 8, rgb(0x7DB582))
        for a in 0..<6 {
            let ang = Double(a) * Double.pi / 3
            ctx.circle(84.1 + CGFloat(cos(ang)) * 2.4, 25 + CGFloat(sin(ang)) * 2.4, 1.6, Color.white)
        }
        ctx.circle(84.1, 25, 1.4, rgb(0xF6D867))
    }

    private static func diningLong(_ ctx: GraphicsContext) {
        let wood = rgb(0xC9976A)
        let woodDark = rgb(0xA87A50)
        ctx.ellipse(0, 88, 100, 8, shadow)
        for lx in [6.0, 88.0] {
            ctx.rect(lx, 48, 6, 45, woodDark, radius: 2)
        }
        ctx.rect(10, 52, 80, 3, woodDark, radius: 1.5)
        // khăn ren trắng
        ctx.rect(2, 41, 96, 7, wood, radius: 3)
        ctx.rect(2, 41, 96, 2.4, rgb(0xDDB088), radius: 1.2)
        ctx.rect(14, 41, 72, 11, rgb(0xFFFBF4), radius: 1.5)
        for i in 0..<9 { ctx.circle(18 + CGFloat(i) * 8, 52, 2.4, rgb(0xFFFBF4)) }
        ctx.rect(42, 41, 16, 15, rgb(0xC9B6F0), radius: 1.5)
        ctx.polygon([pt(42, 56), pt(50, 60), pt(58, 56)], rgb(0xC9B6F0))
        // hai cây nến
        for cx in [12.0, 88.0] {
            ctx.ellipse(cx - 6, 39, 12, 3.6, rgb(0xE9C46A))
            ctx.rect(cx - 1.5, 30, 3, 10, rgb(0xE9C46A), radius: 1)
            ctx.ellipse(cx - 4, 28, 8, 3, rgb(0xE9C46A))
            ctx.rect(cx - 2.5, 13, 5, 16, cream, radius: 1.5)
            ctx.circle(cx, 8, 6, rgb(0xF6D867).opacity(0.25))
            ctx.ellipse(cx - 2.2, 4.5, 4.4, 7, rgb(0xF4B36E))
            ctx.ellipse(cx - 1.2, 7, 2.4, 4, rgb(0xFFF2C8))
            ctx.rect(cx - 1.6, 15, 1.4, 10, Color.white.opacity(0.7), radius: 0.7)
        }
    }

    // MARK: - Đồ treo tường (ô 100×100)

    private static func wallClock(_ ctx: GraphicsContext) {
        let lemon = rgb(0xF7D865)
        ctx.ellipse(10, 24, 80, 64, lemon)
        ctx.ellipse(4, 50, 12, 12, lemon)
        ctx.ellipse(84, 50, 12, 12, lemon)
        ctx.ellipse(20, 32, 60, 48, rgb(0xFFF6D2))
        // múi chanh mờ
        ctx.strokePath(rgb(0xF7E59A), width: 1.4) { p in
            for a in 0..<8 {
                let ang = Double(a) * Double.pi / 4
                p.move(to: pt(50, 56))
                p.addLine(to: pt(50 + CGFloat(cos(ang)) * 27, 56 + CGFloat(sin(ang)) * 21))
            }
        }
        for (dx, dy) in [(50.0, 37.0), (73.0, 56.0), (50.0, 75.0), (27.0, 56.0)] {
            ctx.circle(dx, dy, 2, rgb(0xE5B843))
        }
        ctx.strokePath(ink, width: 3.2) { p in
            p.move(to: pt(50, 56)); p.addLine(to: pt(50, 42))
        }
        ctx.strokePath(ink, width: 2.4) { p in
            p.move(to: pt(50, 56)); p.addLine(to: pt(63, 62))
        }
        ctx.circle(50, 56, 3, rgb(0xEE8F8F))
        // má hồng
        ctx.ellipse(29, 66, 8, 4, rgb(0xF4B0B0).opacity(0.7))
        ctx.ellipse(63, 66, 8, 4, rgb(0xF4B0B0).opacity(0.7))
        // cuống & lá
        ctx.rect(48, 16, 4, 10, rgb(0x8E6B5A), radius: 2)
        ctx.rotated(-25, around: pt(60, 18)) { c in
            c.ellipse(52, 13, 22, 10, rgb(0x8CC08F))
            c.rect(54, 17.4, 16, 1.2, rgb(0x6FA373))
        }
        ctx.ellipse(22, 30, 14, 8, Color.white.opacity(0.55))
    }

    private static func wallPans(_ ctx: GraphicsContext) {
        // thanh treo
        ctx.rect(4, 16, 92, 5, rgb(0xB58357), radius: 2.5)
        ctx.circle(8, 18.5, 3.5, rgb(0xA07448))
        ctx.circle(92, 18.5, 3.5, rgb(0xA07448))
        ctx.strokePath(steelDark, width: 1.6) { p in
            for hx in [26.0, 50.0, 68.0, 84.0] {
                p.move(to: pt(hx, 20)); p.addLine(to: pt(hx, 25))
            }
        }
        // chảo
        ctx.rect(23.5, 24, 5, 26, rgb(0xB58357), radius: 2.5)
        ctx.circle(26, 66, 18, rgb(0x6E6278))
        ctx.circle(26, 66, 13.5, rgb(0x857A90))
        ctx.ellipse(16, 56, 9, 6, Color.white.opacity(0.35))
        // muôi
        ctx.strokePath(rgb(0xC9B6F0), width: 3.4) { p in
            p.move(to: pt(50, 26)); p.addLine(to: pt(50, 64))
        }
        var ladle = Path()
        ladle.move(to: pt(41, 63))
        ladle.addQuadCurve(to: pt(59, 63), control: pt(50, 80))
        ladle.closeSubpath()
        ctx.fill(ladle, with: .color(rgb(0xB7A3E6)))
        ctx.circle(50, 26, 2.6, rgb(0xC9B6F0))
        // xẻng
        ctx.strokePath(rgb(0x9CCDB6), width: 3.4) { p in
            p.move(to: pt(68, 26)); p.addLine(to: pt(68, 56))
        }
        ctx.rect(61, 54, 14, 18, rgb(0x9CCDB6), radius: 4)
        ctx.strokePath(rgb(0xDDF1E5), width: 1.4) { p in
            for sx in [65.0, 68.0, 71.0] { p.move(to: pt(sx, 58)); p.addLine(to: pt(sx, 68)) }
        }
        // nồi nhỏ bằng đồng
        ctx.strokePath(rgb(0xD48B66), width: 2) { p in
            p.move(to: pt(84, 25)); p.addLine(to: pt(84, 38))
        }
        ctx.rect(76, 38, 16, 4, rgb(0xD48B66), radius: 2)
        ctx.rect(76, 41, 16, 15, rgb(0xEAA584), radius: 4)
        ctx.rect(79, 44, 3, 8, Color.white.opacity(0.45), radius: 1.5)
    }

    private static func wallFruit(_ ctx: GraphicsContext) {
        ctx.rect(12, 12, 76, 76, rgb(0xC9976A), radius: 6)
        ctx.rect(17, 17, 66, 66, rgb(0xFFF8EC), radius: 3)
        ctx.ellipse(22, 70, 56, 10, rgb(0xF3E2C6))
        // chùm nho
        for (gx, gy) in [(44.0, 32.0), (52.0, 32.0), (60.0, 32.0), (48.0, 39.0), (56.0, 39.0), (52.0, 46.0)] {
            ctx.circle(gx, gy, 4.6, rgb(0xB7A3E6))
            ctx.circle(gx - 1.4, gy - 1.6, 1.2, Color.white.opacity(0.7))
        }
        ctx.rect(51, 22, 2, 6, rgb(0x8E6B5A), radius: 1)
        ctx.ellipse(54, 22, 9, 5, rgb(0x8CC08F))
        // quả lê
        ctx.circle(34, 64, 10, rgb(0xD7E28A))
        ctx.circle(34, 51, 6.5, rgb(0xD7E28A))
        ctx.rect(33, 41, 2, 6, rgb(0x8E6B5A), radius: 1)
        ctx.ellipse(28, 60, 4, 6, Color.white.opacity(0.5))
        // quả táo
        ctx.circle(62, 64, 11, rgb(0xEE8686))
        ctx.circle(67, 62, 9, rgb(0xEE8686))
        ctx.rect(63.5, 49, 2, 7, rgb(0x8E6B5A), radius: 1)
        ctx.ellipse(66, 48, 8, 4.5, rgb(0x8CC08F))
        ctx.ellipse(57, 58, 4, 6, Color.white.opacity(0.5))
        sparkle(ctx, 76, 26, 6, rgb(0xF6D867))
    }

    private static func jar(_ ctx: GraphicsContext, x: CGFloat, w: CGFloat, h: CGFloat, glass: Color, lid: Color, label: Color) {
        let top = 72 - h
        ctx.rect(x, top + 5, w, h - 5, glass, radius: 5)
        ctx.rect(x + 2, top, w - 4, 6, lid, radius: 2.5)
        ctx.rect(x + w * 0.2, top + h * 0.5, w * 0.6, h * 0.24, label, radius: 2)
        ctx.rect(x + 3, top + 9, 2.5, h - 16, Color.white.opacity(0.6), radius: 1.2)
    }

    private static func wallJars(_ ctx: GraphicsContext) {
        // hũ kẹo
        jar(ctx, x: 8, w: 24, h: 34, glass: rgb(0xE3F1F7), lid: rgb(0xEE8F8F), label: Color.white)
        for (cx, cy, col) in [(16.0, 52.0, 0xF7A7B8), (24.0, 50.0, 0xF6D867), (14.0, 63.0, 0x8FCDB9), (25.0, 64.0, 0xC9B6F0), (20.0, 58.0, 0xF4B36E)] as [(Double, Double, UInt32)] {
            ctx.circle(cx, cy, 3, rgb(col))
        }
        ctx.rect(12.8, 54.5, 14.4, 6, Color.white.opacity(0.95), radius: 2)
        ctx.heart(center: pt(20, 57.5), size: 4, rgb(0xEE8F8F))
        // hũ bánh quy
        jar(ctx, x: 37, w: 28, h: 42, glass: rgb(0xF6E6D2), lid: rgb(0xC9976A), label: rgb(0xFFF8EC))
        ctx.circle(51, 28, 3, rgb(0xB58357))
        ctx.circle(48, 56, 5, rgb(0xD9A061))
        ctx.circle(46.5, 55, 0.9, rgb(0x6B4A3A))
        ctx.circle(49.5, 57.5, 0.9, rgb(0x6B4A3A))
        ctx.circle(56, 58, 3.4, rgb(0xD9A061))
        // hộp trà
        jar(ctx, x: 70, w: 22, h: 30, glass: rgb(0xA8D3B3), lid: rgb(0x8BC5A0), label: rgb(0xFFF8EC))
        ctx.ellipse(77.5, 55, 7, 4, rgb(0x8CC08F))
        ctx.rect(80, 56.5, 1, 3, rgb(0x8E6B5A))
        // kệ gỗ
        ctx.rect(4, 72, 92, 6, rgb(0xC9976A), radius: 2)
        ctx.rect(4, 72, 92, 1.6, rgb(0xDDB088), radius: 0.8)
        ctx.polygon([pt(12, 78), pt(20, 78), pt(12, 88)], rgb(0xA87A50))
        ctx.polygon([pt(88, 78), pt(80, 78), pt(88, 88)], rgb(0xA87A50))
    }

    // MARK: - Món ăn (ô 100×100, đáy ở y ≈ 94, giữa x = 50 — ngồi trên mặt bàn ăn)

    private static func treatTea(_ ctx: GraphicsContext) {
        let pot = rgb(0xA9D8C4)
        let potDark = rgb(0x86C2AA)
        // vòi & quai
        ctx.polygon([pt(24, 74), pt(9, 56), pt(13, 53), pt(30, 66)], pot)
        ctx.strokePath(potDark, width: 5) { p in
            p.move(to: pt(62, 62)); p.addQuadCurve(to: pt(62, 84), control: pt(76, 72))
        }
        // thân ấm
        ctx.rect(30, 88, 28, 6, potDark, radius: 2.5)
        ctx.ellipse(20, 52, 48, 40, pot)
        ctx.ellipse(30, 46, 28, 10, potDark)
        ctx.circle(44, 45, 4, rgb(0xF3B7B3))
        for (dx, dy) in [(32.0, 68.0), (44.0, 76.0), (54.0, 66.0), (38.0, 82.0)] {
            ctx.circle(dx, dy, 2.2, Color.white.opacity(0.75))
        }
        ctx.ellipse(26, 58, 8, 12, Color.white.opacity(0.45))
        // tách trà
        ctx.ellipse(64, 89, 32, 6, rgb(0xF7E8E4))
        ctx.strokePath(rgb(0xF3B7B3), width: 2.6) { p in
            p.addEllipse(in: CGRect(x: 85, y: 79, width: 7, height: 7))
        }
        ctx.rect(68, 76, 20, 15, rgb(0xFFFBF6), radius: 6)
        ctx.ellipse(68, 74, 20, 5, rgb(0xF3B7B3))
        ctx.ellipse(70, 75, 16, 3.2, rgb(0xE2AC79))
        ctx.heart(center: pt(78, 84), size: 5, rgb(0xF3B7B3))
        steam(ctx, 74, 70, 12)
        steam(ctx, 82, 70, 10)
    }

    private static func treatBread(_ ctx: GraphicsContext) {
        // bánh mì que & bánh tròn
        ctx.rotated(-28, around: pt(54, 54)) { c in
            c.ellipse(26, 46, 60, 16, rgb(0xE2A86A))
            c.strokePath(rgb(0xF6D3A2), width: 2) { p in
                for sx in [36.0, 48.0, 60.0, 72.0] {
                    p.move(to: pt(sx, 50)); p.addLine(to: pt(sx + 5, 58))
                }
            }
        }
        ctx.ellipse(22, 58, 30, 22, rgb(0xEDB97C))
        ctx.strokePath(rgb(0xF8DDB5), width: 2) { p in
            p.move(to: pt(30, 64)); p.addQuadCurve(to: pt(44, 64), control: pt(37, 60))
        }
        ctx.ellipse(48, 60, 32, 22, rgb(0xE8AE70))
        ctx.strokePath(rgb(0xF8DDB5), width: 2) { p in
            p.move(to: pt(56, 66)); p.addQuadCurve(to: pt(72, 66), control: pt(64, 61))
        }
        // khăn ca rô ló ra
        ctx.polygon([pt(16, 72), pt(30, 66), pt(34, 74)], rgb(0xF3B7B3))
        ctx.polygon([pt(84, 72), pt(70, 66), pt(66, 74)], rgb(0xF3B7B3))
        // giỏ mây
        ctx.rect(14, 70, 72, 24, rgb(0xDAA96E), radius: 9)
        ctx.rect(12, 68, 76, 7, rgb(0xC8915A), radius: 3.5)
        ctx.strokePath(rgb(0xC8915A), width: 1.4) { p in
            p.move(to: pt(18, 81)); p.addLine(to: pt(82, 81))
            p.move(to: pt(20, 87.5)); p.addLine(to: pt(80, 87.5))
            for sx in stride(from: 24.0, through: 76.0, by: 8.0) {
                p.move(to: pt(sx, 75)); p.addLine(to: pt(sx, 92))
            }
        }
        ctx.ellipse(28, 60, 8, 5, Color.white.opacity(0.45))
        sparkle(ctx, 76, 46, 7)
    }

    private static func treatRamen(_ ctx: GraphicsContext) {
        // đũa
        ctx.strokePath(rgb(0xC9976A), width: 2.6) { p in
            p.move(to: pt(58, 62)); p.addLine(to: pt(92, 32))
            p.move(to: pt(62, 63)); p.addLine(to: pt(96, 38))
        }
        // nước dùng
        ctx.ellipse(12, 54, 76, 16, rgb(0xF7D9A3))
        ctx.strokePath(rgb(0xFCEBC2), width: 2) { p in
            p.move(to: pt(22, 63)); p.addCurve(to: pt(44, 62), control1: pt(28, 57), control2: pt(38, 67))
            p.move(to: pt(40, 60)); p.addCurve(to: pt(62, 60), control1: pt(46, 55), control2: pt(56, 65))
        }
        // trứng, chả cá, rong biển, hành
        ctx.ellipse(24, 55, 18, 11, Color.white)
        ctx.ellipse(28.5, 57.5, 9, 6, rgb(0xF6B04F))
        ctx.circle(62, 60, 6, Color.white)
        ctx.strokePath(rgb(0xF29BA8), width: 1.4) { p in
            p.addArc(center: pt(62, 60), radius: 3.2, startAngle: .degrees(0), endAngle: .degrees(300), clockwise: false)
        }
        ctx.rect(72, 50, 8, 12, rgb(0x5C7A62), radius: 1.5)
        for (gx, gy) in [(46.0, 58.0), (50.0, 62.0), (54.0, 57.0), (42.0, 63.0), (68.0, 64.0)] {
            ctx.circle(gx, gy, 1.8, rgb(0x8CC08F))
            ctx.circle(gx, gy, 0.7, rgb(0xDDF1E5))
        }
        // bát
        var bowl = Path()
        bowl.move(to: pt(10, 62))
        bowl.addLine(to: pt(90, 62))
        bowl.addCurve(to: pt(50, 90), control1: pt(88, 82), control2: pt(70, 90))
        bowl.addCurve(to: pt(10, 62), control1: pt(30, 90), control2: pt(12, 82))
        bowl.closeSubpath()
        ctx.rect(36, 86, 28, 8, rgb(0xE07F78), radius: 3)
        ctx.fill(bowl, with: .color(rgb(0xF29E96)))
        ctx.strokePath(Color.white.opacity(0.85), width: 2) { p in
            p.move(to: pt(16, 70)); p.addLine(to: pt(84, 70))
        }
        for wx in [28.0, 50.0, 72.0] {
            ctx.circle(wx, 78, 2.6, Color.white.opacity(0.8))
        }
        ctx.ellipse(10, 60, 80, 4, rgb(0xF6B7AF))
        steam(ctx, 34, 48, 14)
        steam(ctx, 50, 46, 16)
    }

    private static func treatPizza(_ ctx: GraphicsContext) {
        // thớt gỗ
        ctx.rect(84, 76, 14, 7, rgb(0xB58357), radius: 3.5)
        ctx.ellipse(6, 66, 84, 28, rgb(0xC9976A))
        ctx.ellipse(6, 63, 84, 27, rgb(0xDDB088))
        let pizzaRect = CGRect(x: 12, y: 62, width: 72, height: 24)
        let c = ctx
        c.fill(Path(ellipseIn: pizzaRect), with: .color(rgb(0xE6B26C)))
        c.ellipse(16, 64, 64, 20, rgb(0xF7D67C))
        for (px, py) in [(30.0, 68.0), (44.0, 66.0), (24.0, 75.0), (40.0, 79.0), (58.0, 66.0), (54.0, 81.0)] {
            c.ellipse(px - 4, py - 2.4, 8, 4.8, rgb(0xE97A6E))
            c.ellipse(px - 2.5, py - 1.8, 2.5, 1.4, Color.white.opacity(0.5))
        }
        for (bx, by) in [(36.0, 73.0), (50.0, 72.0), (30.0, 81.0)] {
            c.ellipse(bx - 2.5, by - 1.2, 5, 2.6, rgb(0x7DB582))
        }
        // một lát đã bị ăn mất: tô lại màu thớt trong hình quạt
        var wedge = Path()
        wedge.move(to: pt(48, 74))
        wedge.addLine(to: pt(92, 70))
        wedge.addLine(to: pt(88, 100))
        wedge.closeSubpath()
        var cut = ctx
        cut.clip(to: Path(ellipseIn: pizzaRect))
        cut.fill(wedge, with: .color(rgb(0xDDB088)))
        // vụn bánh
        ctx.circle(74, 82, 1.3, rgb(0xE6B26C))
        ctx.circle(80, 78, 1, rgb(0xE6B26C))
        ctx.circle(70, 87, 1, rgb(0xE6B26C))
        sparkle(ctx, 20, 58, 7)
    }

    private static func treatCake(_ ctx: GraphicsContext) {
        // đĩa có chân
        ctx.ellipse(34, 89, 32, 6, rgb(0xD7CBEF))
        ctx.rect(45, 84, 10, 7, rgb(0xD7CBEF), radius: 2)
        ctx.ellipse(12, 80, 76, 8, rgb(0xECE6FA))
        ctx.ellipse(16, 79, 68, 5, Color.white)
        // thân bánh
        ctx.rect(22, 50, 56, 32, rgb(0xFFF4E8), radius: 6)
        ctx.rect(22, 64, 56, 5, rgb(0xF29BA8))
        ctx.rect(22, 69, 56, 2, rgb(0xFBD3DA))
        // kem phủ chảy
        ctx.rect(20, 46, 60, 10, rgb(0xF7C1CC), radius: 5)
        for (dx, dh) in [(26.0, 6.0), (36.0, 9.0), (47.0, 5.0), (57.0, 8.0), (68.0, 6.0), (75.0, 4.0)] {
            ctx.rect(dx - 2.6, 52, 5.2, dh + 2, rgb(0xF7C1CC), radius: 2.6)
        }
        // dâu tây
        for sx in [32.0, 68.0] {
            ctx.ellipse(sx - 5, 38, 10, 11, rgb(0xEE6F7C))
            ctx.polygon([pt(sx - 4.5, 39), pt(sx, 35.5), pt(sx + 4.5, 39), pt(sx, 41)], rgb(0x8CC08F))
            ctx.circle(sx - 1.6, 44, 0.7, rgb(0xFFF1B8))
            ctx.circle(sx + 1.8, 45.5, 0.7, rgb(0xFFF1B8))
        }
        ctx.circle(42, 44, 4, Color.white)
        ctx.circle(58, 44, 4, Color.white)
        // nến
        ctx.rect(48, 30, 4, 15, rgb(0xC9B6F0), radius: 1.2)
        ctx.rect(48, 34, 4, 2, Color.white.opacity(0.8))
        ctx.rect(48, 39, 4, 2, Color.white.opacity(0.8))
        ctx.circle(50, 24, 5.5, rgb(0xF6D867).opacity(0.3))
        ctx.ellipse(47.6, 20, 4.8, 8, rgb(0xF4B36E))
        ctx.ellipse(48.8, 23, 2.4, 4, rgb(0xFFF2C8))
        ctx.rect(26, 56, 3, 22, Color.white.opacity(0.6), radius: 1.5)
        sparkle(ctx, 82, 34, 7)
        sparkle(ctx, 18, 40, 5, rgb(0xF6D867))
    }

    // MARK: - Tường & sàn mới

    private static func starPoints(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ inner: CGFloat) -> [CGPoint] {
        (0..<10).map { i in
            let ang = Double(i) * Double.pi / 5 - Double.pi / 2
            let rr = i % 2 == 0 ? r : inner
            return pt(cx + CGFloat(cos(ang)) * rr, cy + CGFloat(sin(ang)) * rr)
        }
    }

    /// Tiệm bánh: tường sọc hồng, mái hiên vỏ sò, sàn đá mài lấm tấm.
    private static func themeBakery(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xFCE6E4))
        var x: CGFloat = 0
        while x < 125 { ctx.rect(x, 0, 6, 60, rgb(0xF8D4D6)); x += 12 }
        for (hx, hy) in [(9.0, 44.0), (33.0, 52.0), (21.0, 34.0)] as [(CGFloat, CGFloat)] {
            ctx.heart(center: pt(hx, hy), size: 4, Color.white.opacity(0.75))
        }
        backsplash(ctx, rgb(0xFFF8F5), rgb(0xF3D3D2))
        window(ctx, frame: rgb(0xFFFDF8), curtain: rgb(0xF6C59B))
        // mái hiên sọc có viền vỏ sò
        var i = 0
        var ax: CGFloat = 0
        while ax < 125 {
            ctx.rect(ax, 0, 8.4, 5, i % 2 == 0 ? rgb(0xEE9EA6) : rgb(0xFFF8F2))
            ctx.circle(ax + 4.2, 5, 4.2, i % 2 == 0 ? rgb(0xEE9EA6) : rgb(0xFFF8F2))
            ax += 8.4
            i += 1
        }
        ctx.rect(0, 0, 125, 1.4, rgb(0xE48C96))
        baseboard(ctx, rgb(0xEDB0B6))
        // sàn đá mài
        ctx.rect(0, 62, 125, 38, rgb(0xFBF2EC))
        let chips: [UInt32] = [0xF2B8BC, 0xA9D8C4, 0xF6D88A, 0xC9B6F0, 0xF4C29E]
        for k in 0..<70 {
            let cx = CGFloat((k * 37) % 125) + CGFloat(k % 3)
            let cy = 64 + CGFloat((k * 53) % 35)
            let s: CGFloat = 0.8 + CGFloat(k % 4) * 0.35
            ctx.ellipse(cx, cy, s * 1.6, s, rgb(chips[k % chips.count]))
        }
    }

    /// Bếp đêm: tường xanh tím điểm sao, dây đèn ấm, cửa sổ có trăng.
    private static func themeNight(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0x5D6194))
        for k in 0..<26 {
            let sx = CGFloat((k * 47) % 123) + 1
            let sy = CGFloat((k * 29) % 36) + 3
            ctx.circle(sx, sy, k % 3 == 0 ? 0.9 : 0.55, rgb(0xFFF1B8).opacity(k % 2 == 0 ? 0.9 : 0.55))
        }
        backsplash(ctx, rgb(0x777AAA), rgb(0x666999))
        window(ctx, frame: rgb(0xE9E3F5), curtain: rgb(0xB7A3E6), night: true)
        // dây đèn ấm
        ctx.strokePath(rgb(0x3F4270), width: 0.6) { p in
            p.move(to: pt(0, 2))
            p.addQuadCurve(to: pt(44, 2), control: pt(22, 14))
            p.move(to: pt(74, 2))
            p.addQuadCurve(to: pt(125, 2), control: pt(100, 14))
        }
        for t in stride(from: 0.08, through: 0.93, by: 0.14) {
            for (x0, x1) in [(0.0, 44.0), (74.0, 125.0)] as [(CGFloat, CGFloat)] {
                let u = CGFloat(t)
                let bx = x0 + (x1 - x0) * u
                let by = 2 + 12 * 2 * u * (1 - u) * 0.5 + 1.2
                ctx.circle(bx, by, 2.6, rgb(0xFFE6A0).opacity(0.25))
                ctx.circle(bx, by, 1.2, rgb(0xFFE6A0))
            }
        }
        baseboard(ctx, rgb(0x4A4D7C))
        floorChecker(ctx, rgb(0x8C8DBA), rgb(0x7A7BAA))
        ctx.ellipse(30, 70, 70, 14, rgb(0xFFE6A0).opacity(0.08))
    }

    // MARK: - Bếp mới

    private static func stoveInduction(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 89, 70, 8, shadow)
        let cab = rgb(0xD7EEE4)
        ctx.rect(9, 47, 58, 45, cab, radius: 4)
        ctx.rect(13, 53, 50, 15, rgb(0xE8F6F0), radius: 3)
        ctx.rect(13, 71, 50, 17, rgb(0xE8F6F0), radius: 3)
        ctx.rect(28, 58.5, 20, 2.6, steelDark, radius: 1.3)
        ctx.rect(28, 77.5, 20, 2.6, steelDark, radius: 1.3)
        ctx.rect(12, 91, 6, 3, rgb(0xA9C9BC), radius: 1)
        ctx.rect(58, 91, 6, 3, rgb(0xA9C9BC), radius: 1)
        // mặt kính đen
        ctx.rect(6, 40, 64, 9, rgb(0x4E4760), radius: 3)
        ctx.rect(8, 41, 26, 1.4, Color.white.opacity(0.25), radius: 0.7)
        ctx.strokePath(rgb(0x8E879C), width: 1) { p in
            p.addEllipse(in: CGRect(x: 48, y: 42.4, width: 16, height: 4))
        }
        for k in 0..<3 { ctx.circle(41 + CGFloat(k) * 2.6, 46.5, 0.8, k == 0 ? rgb(0x8FE3B9) : rgb(0x8E879C)) }
        // vòng nóng dưới nồi
        ctx.ellipse(10, 41.6, 30, 6, rgb(0xF29E8E).opacity(0.55))
        // nồi canh
        ctx.rect(11, 29, 4, 3, rgb(0xD4806A), radius: 1)
        ctx.rect(35, 29, 4, 3, rgb(0xD4806A), radius: 1)
        ctx.rect(13, 22, 24, 21, rgb(0xF3A58E), radius: 6)
        ctx.rect(13, 31, 24, 3, rgb(0xFBD3C2))
        ctx.rect(16, 25, 3, 13, Color.white.opacity(0.45), radius: 1.5)
        ctx.ellipse(12, 19, 26, 7, rgb(0xE48D72))
        ctx.ellipse(14.5, 20.2, 21, 4.4, rgb(0xF6D79A))
        ctx.circle(20, 22, 1.6, rgb(0xF29E8E))
        ctx.circle(28, 21.6, 1.4, rgb(0x8CC08F))
        ctx.circle(31, 22.6, 1.2, rgb(0xF6B04F))
        // muôi gác trên miệng nồi
        ctx.strokePath(rgb(0xC9B6F0), width: 2.4) { p in
            p.move(to: pt(26, 21)); p.addLine(to: pt(38, 6))
        }
        ctx.circle(38.6, 5.4, 2, rgb(0xC9B6F0))
        steam(ctx, 18, 16, 10)
        steam(ctx, 31, 15, 9)
        // thớt có cà rốt
        ctx.rect(45, 35.5, 22, 5, rgb(0xDDB088), radius: 2)
        ctx.rect(45, 35.5, 22, 1.4, rgb(0xEBC9A2), radius: 0.7)
        ctx.circle(65, 38, 1.2, rgb(0xB58357))
        ctx.rotated(-8, around: pt(54, 33)) { c in
            c.ellipse(46, 30.5, 16, 5, rgb(0xF4A25E))
            c.strokePath(rgb(0xE08B48), width: 0.8) { p in
                p.move(to: pt(50, 31.5)); p.addLine(to: pt(50, 33.5))
                p.move(to: pt(54, 31.2)); p.addLine(to: pt(54, 33.8))
            }
            c.ellipse(60, 30, 6, 2.6, rgb(0x7DB582))
            c.ellipse(60.5, 32.4, 5, 2.4, rgb(0x8CC08F))
        }
        ctx.circle(49, 39, 1.8, rgb(0xF4A25E))
        ctx.circle(53, 39.4, 1.8, rgb(0xF4A25E))
        ctx.circle(49, 39, 0.7, rgb(0xFBD3A0))
        ctx.circle(53, 39.4, 0.7, rgb(0xFBD3A0))
    }

    private static func stovePizza(_ ctx: GraphicsContext) {
        ctx.ellipse(2, 88, 74, 9, shadow)
        // bệ đá có ngăn củi
        ctx.rect(8, 64, 60, 29, rgb(0xDCD3CB), radius: 4)
        ctx.rect(8, 64, 60, 3, rgb(0xEAE3DC), radius: 1.5)
        ctx.rect(16, 72, 44, 17, rgb(0x8E7F86), radius: 3)
        for (lx, ly) in [(22.0, 84.0), (30.0, 84.0), (38.0, 84.0), (46.0, 84.0), (54.0, 84.0), (26.0, 77.0), (34.0, 77.0), (42.0, 77.0), (50.0, 77.0)] as [(CGFloat, CGFloat)] {
            ctx.circle(lx, ly, 3.8, rgb(0xC9976A))
            ctx.circle(lx, ly, 2.2, rgb(0xE6C39C))
        }
        // mái vòm gạch
        var dome = Path()
        dome.move(to: pt(8, 66))
        dome.addCurve(to: pt(38, 18), control1: pt(8, 38), control2: pt(20, 18))
        dome.addCurve(to: pt(68, 66), control1: pt(56, 18), control2: pt(68, 38))
        dome.closeSubpath()
        ctx.fill(dome, with: .color(rgb(0xEBA486)))
        var bricks = ctx
        bricks.clip(to: dome)
        var row = 0
        var by: CGFloat = 22
        while by < 66 {
            bricks.rect(0, by, 80, 0.9, rgb(0xD8876A))
            var bx: CGFloat = row % 2 == 0 ? 6 : 12
            while bx < 72 { bricks.rect(bx, by, 0.9, 6, rgb(0xD8876A)); bx += 12 }
            by += 6
            row += 1
        }
        bricks.ellipse(14, 24, 12, 20, Color.white.opacity(0.22))
        // ống khói
        ctx.rect(33, 6, 10, 15, rgb(0xD8876A), radius: 1.5)
        ctx.rect(31.5, 4, 13, 4, rgb(0xC77A60), radius: 1.5)
        steam(ctx, 36, 2, 7, Color.white.opacity(0.7))
        // miệng lò có lửa và pizza
        var mouth = Path()
        mouth.move(to: pt(22, 66))
        mouth.addLine(to: pt(22, 54))
        mouth.addQuadCurve(to: pt(54, 54), control: pt(38, 36))
        mouth.addLine(to: pt(54, 66))
        mouth.closeSubpath()
        ctx.fill(mouth, with: .color(rgb(0x4A3A48)))
        ctx.strokePath(rgb(0xF2C9B5), width: 2.4) { p in
            p.move(to: pt(21, 66)); p.addLine(to: pt(21, 54)); p.addQuadCurve(to: pt(55, 54), control: pt(38, 34.5)); p.addLine(to: pt(55, 66))
        }
        ctx.polygon([pt(40, 64), pt(43, 52), pt(46, 57), pt(49, 49), pt(52, 64)], rgb(0xF4A25E))
        ctx.polygon([pt(43, 64), pt(46, 58), pt(49, 64)], rgb(0xF8D772))
        ctx.ellipse(24, 60, 16, 5, rgb(0xE6B26C))
        ctx.ellipse(25.5, 60.6, 13, 3.6, rgb(0xF7D67C))
        for dx in [28.0, 32.0, 35.5] as [CGFloat] { ctx.circle(dx, 62, 1, rgb(0xE97A6E)) }
        // xẻng gỗ dựa bên phải
        ctx.rotated(10, around: pt(66, 60)) { c in
            c.rect(64.5, 24, 3, 46, rgb(0xC9976A), radius: 1.5)
            c.rect(59, 68, 14, 22, rgb(0xDDB088), radius: 6)
            c.rect(61, 71, 2, 14, Color.white.opacity(0.35), radius: 1)
        }
        ctx.rect(10, 66, 3, 22, Color.white.opacity(0.35), radius: 1.5)
    }

    private static func waffleGrid(_ ctx: GraphicsContext, _ rect: CGRect, _ color: Color) {
        var c = ctx
        c.clip(to: Path(roundedRect: rect, cornerRadius: 2))
        c.strokePath(color, width: 0.9) { p in
            var x = rect.minX + 3
            while x < rect.maxX { p.move(to: pt(x, rect.minY)); p.addLine(to: pt(x, rect.maxY)); x += 3.6 }
            var y = rect.minY + 2.5
            while y < rect.maxY { p.move(to: pt(rect.minX, y)); p.addLine(to: pt(rect.maxX, y)); y += 3 }
        }
    }

    private static func stoveWaffle(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 89, 70, 8, shadow)
        // xe đẩy váy sọc
        let body = CGRect(x: 8, y: 50, width: 60, height: 38)
        ctx.fill(Path(roundedRect: body, cornerRadius: 4), with: .color(rgb(0xFFF6EA)))
        var st = ctx
        st.clip(to: Path(roundedRect: body, cornerRadius: 4))
        var sx: CGFloat = 8
        while sx < 70 { st.rect(sx, 50, 5, 38, rgb(0xF7C1CC)); sx += 10 }
        for k in 0..<8 { ctx.circle(11.5 + CGFloat(k) * 7.6, 52, 3.8, rgb(0xEE9EA6)) }
        ctx.rect(5, 44, 66, 7, rgb(0xC9976A), radius: 2.5)
        ctx.rect(5, 44, 66, 1.8, rgb(0xDDB088), radius: 0.9)
        // bánh xe
        for wx in [18.0, 58.0] as [CGFloat] {
            ctx.circle(wx, 89, 5, rgb(0x8E8899))
            ctx.circle(wx, 89, 2, rgb(0xD9DCE3))
        }
        // khuôn waffle đang mở
        ctx.rect(9, 36, 30, 9, rgb(0x857A90), radius: 4)
        ctx.rect(36, 38, 8, 3, rgb(0x6E6278), radius: 1.5)
        ctx.ellipse(11, 33.5, 26, 6, rgb(0xE8B46A))
        waffleGrid(ctx, CGRect(x: 13, y: 34.5, width: 22, height: 4), rgb(0xD39A50))
        ctx.rotated(-18, around: pt(24, 34)) { c in
            c.rect(9, 18, 30, 12, rgb(0x9E94A9), radius: 5)
            c.rect(12, 20.5, 24, 7, rgb(0x857A90), radius: 3)
            c.heart(center: pt(24, 24), size: 6, rgb(0xB7AEC2))
        }
        // chồng bánh waffle
        for (k, wy) in [37.0, 31.5, 26.0].enumerated() {
            let r = CGRect(x: 46 + CGFloat(k % 2), y: CGFloat(wy), width: 20, height: 6)
            ctx.fill(Path(roundedRect: r, cornerRadius: 2.5), with: .color(rgb(0xEDBB72)))
            waffleGrid(ctx, r, rgb(0xD39A50))
        }
        // si-rô, kem, dâu
        ctx.rect(48, 24.5, 18, 3, rgb(0xC77F4A), radius: 1.5)
        ctx.rect(50, 26, 2.2, 6, rgb(0xC77F4A), radius: 1.1)
        ctx.rect(61, 26, 2.2, 4, rgb(0xC77F4A), radius: 1.1)
        ctx.ellipse(50, 18, 14, 8, Color.white)
        ctx.ellipse(53, 15, 8, 6, Color.white)
        ctx.ellipse(54, 8.5, 7, 8, rgb(0xEE6F7C))
        ctx.polygon([pt(54.5, 9.5), pt(57.5, 7), pt(60.5, 9.5), pt(57.5, 11)], rgb(0x8CC08F))
        ctx.circle(56, 13, 0.6, rgb(0xFFF1B8))
        ctx.circle(59, 12.5, 0.6, rgb(0xFFF1B8))
        sparkle(ctx, 70, 20, 6, rgb(0xF6D867))
    }

    private static func stoveCat(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 89, 70, 8, shadow)
        let fur = rgb(0xFFE2C6)
        let furDark = rgb(0xF2C49E)
        // tai
        ctx.polygon([pt(10, 42), pt(14, 20), pt(30, 36)], fur)
        ctx.polygon([pt(66, 42), pt(62, 20), pt(46, 36)], fur)
        ctx.polygon([pt(14, 38), pt(16, 26), pt(25, 35)], rgb(0xF7B7B8))
        ctx.polygon([pt(62, 38), pt(60, 26), pt(51, 35)], rgb(0xF7B7B8))
        // thân
        ctx.rect(6, 34, 64, 58, fur, radius: 14)
        ctx.ellipse(46, 36, 22, 14, furDark)
        // chảo trứng trên mặt bếp
        ctx.ellipse(20, 31, 26, 6, rgb(0x6A6274))
        ctx.rect(44, 32, 16, 3, rgb(0x6A6274), radius: 1.5)
        ctx.ellipse(24, 30.6, 18, 4, Color.white)
        ctx.circle(32, 32, 2.4, rgb(0xF6B04F))
        // mặt mèo: núm là mắt
        knob(ctx, 25, 47, 4.6, rgb(0x6F6680))
        knob(ctx, 51, 47, 4.6, rgb(0x6F6680))
        ctx.polygon([pt(35.5, 50), pt(40.5, 50), pt(38, 53)], rgb(0xEE8F8F))
        ctx.strokePath(ink, width: 1.1) { p in
            p.move(to: pt(38, 53)); p.addQuadCurve(to: pt(34.5, 54.5), control: pt(36.5, 55.6))
            p.move(to: pt(38, 53)); p.addQuadCurve(to: pt(41.5, 54.5), control: pt(39.5, 55.6))
        }
        ctx.strokePath(rgb(0xC9A486), width: 1) { p in
            p.move(to: pt(8, 50)); p.addLine(to: pt(18, 51.5))
            p.move(to: pt(8, 55)); p.addLine(to: pt(18, 54))
            p.move(to: pt(68, 50)); p.addLine(to: pt(58, 51.5))
            p.move(to: pt(68, 55)); p.addLine(to: pt(58, 54))
        }
        ctx.ellipse(15, 54, 7, 3.6, rgb(0xF7B7B8).opacity(0.8))
        ctx.ellipse(54, 54, 7, 3.6, rgb(0xF7B7B8).opacity(0.8))
        // cửa lò có bánh hình cá
        ctx.rect(14, 60, 48, 26, furDark, radius: 8)
        ctx.rect(18, 63, 40, 19, rgb(0x6F6680), radius: 6)
        ctx.ellipse(21, 66, 34, 13, rgb(0xF1B36B).opacity(0.5))
        ctx.ellipse(28, 70, 16, 7, rgb(0xE6A866))
        ctx.polygon([pt(43, 73.5), pt(49, 69.5), pt(49, 77.5)], rgb(0xE6A866))
        ctx.circle(31.5, 72.5, 0.9, rgb(0x6B4A3A))
        ctx.rect(30, 61, 16, 2.2, cream, radius: 1.1)
        // chân đệm thịt
        ctx.ellipse(10, 88, 16, 7, Color.white)
        ctx.ellipse(50, 88, 16, 7, Color.white)
        ctx.circle(18, 90.5, 1.4, rgb(0xF7B7B8))
        ctx.circle(58, 90.5, 1.4, rgb(0xF7B7B8))
        ctx.rect(9, 40, 3, 30, Color.white.opacity(0.5), radius: 1.5)
    }

    // MARK: - Tủ lạnh mới

    private static func fridgeDouble(_ ctx: GraphicsContext) {
        let body = rgb(0xEEF1F6)
        fridgeBody(ctx, x: 6, y: 4, w: 70, h: 91, color: body, radius: 9)
        let line = rgb(0xD5DAE3)
        ctx.strokePath(line, width: 1.4) { p in
            p.move(to: pt(41, 5)); p.addLine(to: pt(41, 66))
            p.move(to: pt(7, 66)); p.addLine(to: pt(75, 66))
        }
        // tay nắm
        ctx.rect(36, 24, 3, 26, steelDark, radius: 1.5)
        ctx.rect(43, 24, 3, 26, steelDark, radius: 1.5)
        ctx.rect(26, 71, 30, 3, steelDark, radius: 1.5)
        // vòi lấy nước
        ctx.rect(13, 28, 17, 21, rgb(0xC9CFDB), radius: 3)
        ctx.rect(15.5, 31, 12, 3, rgb(0x9FC7EC), radius: 1.5)
        ctx.rect(19.5, 36, 4, 3, steelDark, radius: 1)
        ctx.ellipse(19.6, 42, 3.8, 4.6, rgb(0x9FC7EC))
        // tranh vẽ cầu vồng và ngôi nhà
        ctx.rotated(-5, around: pt(58, 22)) { c in
            c.rect(48, 12, 22, 19, Color.white, radius: 1)
            for (k, col) in [0xEE8F8F, 0xF6D867, 0x8FCDB9, 0x9FC7EC].enumerated() {
                let r = 8 - CGFloat(k) * 1.6
                c.strokePath(rgb(UInt32(col)), width: 1.5) { p in
                    p.addArc(center: pt(59, 27), radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                }
            }
        }
        ctx.circle(59, 13, 2.2, rgb(0xEE8F8F))
        ctx.rotated(6, around: pt(60, 46)) { c in
            c.rect(49, 37, 21, 19, rgb(0xFFF8E6), radius: 1)
            c.rect(53, 46, 12, 8, rgb(0xF2B27A))
            c.polygon([pt(51.5, 46.5), pt(59, 40), pt(66.5, 46.5)], rgb(0xEE8F8F))
            c.rect(57.5, 49.5, 3, 4.5, rgb(0x8E6B5A))
            c.circle(66, 40.5, 1.8, rgb(0xF6D867))
        }
        ctx.heart(center: pt(52, 38), size: 5, rgb(0xC9B6F0))
        // giấy nhớ & nam châm ngăn đá
        ctx.rotated(-4, around: pt(18, 80)) { c in
            c.rect(12, 74, 13, 12, rgb(0xFFF1A8), radius: 1)
            c.rect(14, 78, 9, 1, rgb(0xE5C85E))
            c.rect(14, 81, 6, 1, rgb(0xE5C85E))
        }
        ctx.circle(66, 82, 3, rgb(0x8FCDB9))
        ctx.rect(10, 10, 3, 50, Color.white.opacity(0.9), radius: 1.5)
    }

    private static func fridgeIcebox(_ ctx: GraphicsContext) {
        let wood = rgb(0xCF9B6C)
        let woodDark = rgb(0xAE7A4F)
        let panel = rgb(0xE0B387)
        let brass = rgb(0xEAC66A)
        ctx.ellipse(6, 89, 72, 8, shadow)
        // chân tiện cong
        ctx.rect(14, 86, 7, 8, woodDark, radius: 3)
        ctx.rect(61, 86, 7, 8, woodDark, radius: 3)
        // thân tủ gỗ
        ctx.rect(10, 30, 62, 58, wood, radius: 5)
        ctx.rect(8, 27, 66, 6, woodDark, radius: 2.5)
        ctx.rect(8, 27, 66, 1.6, rgb(0xDDB088), radius: 0.8)
        // hai cửa
        for (dy, dh) in [(37.0, 18.0), (59.0, 25.0)] as [(CGFloat, CGFloat)] {
            ctx.rect(15, dy, 52, dh, woodDark, radius: 3)
            ctx.rect(17, dy + 2, 48, dh - 4, panel, radius: 2.5)
            ctx.rect(21, dy + 4, 40, dh - 8, rgb(0xE8C29C), radius: 2)
            ctx.rect(14, dy + 3, 4, 4, brass, radius: 1)
            ctx.rect(14, dy + dh - 7, 4, 4, brass, radius: 1)
            ctx.rect(60, dy + dh / 2 - 3, 9, 6, brass, radius: 2)
            ctx.circle(64.5, dy + dh / 2, 1.2, rgb(0xC9A04C))
        }
        // biển đồng nhỏ
        ctx.ellipse(34, 39.5, 14, 6, brass)
        ctx.ellipse(36, 40.8, 10, 3.4, rgb(0xF6DE95))
        // khối đá lạnh và kẹp trên nóc
        ctx.rect(22, 11, 20, 16, rgb(0xCDEBF7), radius: 2.5)
        ctx.polygon([pt(22, 13.5), pt(27, 8), pt(47, 8), pt(42, 13.5)], rgb(0xE6F6FC))
        ctx.polygon([pt(42, 13.5), pt(47, 8), pt(47, 22), pt(42, 27)], rgb(0xB4DDEE))
        ctx.rect(25, 15, 2.5, 9, Color.white.opacity(0.8), radius: 1.2)
        sparkle(ctx, 30, 7, 7, Color.white)
        ctx.strokePath(rgb(0x8E8899), width: 1.8) { p in
            p.move(to: pt(51, 26)); p.addQuadCurve(to: pt(60, 8), control: pt(50, 14))
            p.move(to: pt(65, 26)); p.addQuadCurve(to: pt(60, 8), control: pt(66, 14))
        }
        ctx.circle(60, 8, 2, rgb(0x8E8899))
        ctx.rect(13, 34, 2.5, 48, Color.white.opacity(0.25), radius: 1.2)
    }

    private static func fridgeGlass(_ ctx: GraphicsContext) {
        let frame = rgb(0xB9D7F0)
        fridgeBody(ctx, x: 8, y: 6, w: 66, h: 89, color: frame, radius: 10)
        // biển trên đầu có đèn
        ctx.rect(14, 10, 54, 7, rgb(0xFFFDF8), radius: 3.5)
        ctx.heart(center: pt(41, 13.6), size: 5, rgb(0xEE8F8F))
        ctx.circle(20, 13.5, 1.4, rgb(0x8FE3B9))
        // cửa kính
        let glass = CGRect(x: 14, y: 21, width: 50, height: 66)
        ctx.fill(Path(roundedRect: glass, cornerRadius: 5), with: .color(rgb(0xEAF6FB)))
        var g = ctx
        g.clip(to: Path(roundedRect: glass, cornerRadius: 5))
        for sy in [42.0, 63.0] as [CGFloat] { g.rect(14, sy, 50, 2, rgb(0xCFE3F1)) }
        // tầng trên: chai sữa và nước cam
        for (bx, col) in [(18.0, 0xFFFFFF), (26.0, 0xFFFFFF), (34.0, 0xF6C46B)] as [(CGFloat, UInt32)] {
            g.rect(bx, 29, 6.5, 13, rgb(col), radius: 2)
            g.rect(bx + 1.5, 25.5, 3.5, 4.5, rgb(col), radius: 1)
            g.rect(bx + 1.2, 25, 4.1, 1.8, col == 0xFFFFFF ? rgb(0x9FC7EC) : rgb(0xF29E8E), radius: 0.8)
        }
        g.rect(44, 32, 16, 10, rgb(0xFFF4E8), radius: 2)
        g.rect(44, 35, 16, 2.5, rgb(0xF29BA8))
        g.ellipse(48, 28.5, 7, 6, rgb(0xEE6F7C))
        // tầng giữa: dưa hấu, nho, táo
        var melon = Path()
        melon.move(to: pt(17, 51))
        melon.addQuadCurve(to: pt(37, 51), control: pt(27, 70))
        melon.closeSubpath()
        g.fill(melon, with: .color(rgb(0x8CC08F)))
        var flesh = Path()
        flesh.move(to: pt(18.5, 51))
        flesh.addQuadCurve(to: pt(35.5, 51), control: pt(27, 66))
        flesh.closeSubpath()
        g.fill(flesh, with: .color(rgb(0xF48C8C)))
        for (sx, sy) in [(23.0, 54.0), (27.0, 56.5), (31.0, 54.0)] as [(CGFloat, CGFloat)] { g.circle(sx, sy, 0.8, ink) }
        for (gx, gy) in [(44.0, 52.0), (49.0, 52.0), (46.5, 56.5), (41.5, 56.5), (44.0, 60.5)] as [(CGFloat, CGFloat)] {
            g.circle(gx, gy, 3, rgb(0xB7A3E6))
        }
        g.circle(57, 57, 5, rgb(0xEE8686))
        g.rect(56.4, 49.5, 1.4, 3.5, rgb(0x8E6B5A))
        // tầng dưới: cà rốt và bông cải
        for (cx, rot) in [(22.0, -10.0), (30.0, 8.0)] as [(CGFloat, Double)] {
            g.rotated(rot, around: pt(cx, 76)) { c in
                c.polygon([pt(cx - 3, 69), pt(cx + 3, 69), pt(cx, 84)], rgb(0xF4A25E))
                c.ellipse(cx - 3, 65, 6, 5, rgb(0x7DB582))
            }
        }
        g.rect(44.5, 76, 4, 8, rgb(0xB7DDA8), radius: 1.5)
        for (bx, by) in [(43.0, 74.0), (47.0, 72.0), (51.0, 74.5)] as [(CGFloat, CGFloat)] { g.circle(bx, by, 3.6, rgb(0x8CC08F)) }
        g.ellipse(53, 74, 9, 11, rgb(0xC9B6F0))
        // phản chiếu kính
        g.polygon([pt(14, 54), pt(36, 21), pt(43, 21), pt(14, 64)], Color.white.opacity(0.35))
        g.polygon([pt(30, 87), pt(64, 40), pt(64, 46), pt(35, 87)], Color.white.opacity(0.3))
        ctx.strokePath(Color.white.opacity(0.9), width: 1.2) { p in
            p.addRoundedRect(in: glass, cornerSize: CGSize(width: 5, height: 5))
        }
        ctx.rect(66, 36, 4, 28, rgb(0xEDEBF1), radius: 2)
    }

    private static func fridgeCat(_ ctx: GraphicsContext) {
        let body = rgb(0xFFF5E6)
        let patch = rgb(0xF4B67E)
        // đuôi cong bên trái
        ctx.strokePath(patch, width: 5) { p in
            p.move(to: pt(14, 80)); p.addCurve(to: pt(6, 50), control1: pt(0, 76), control2: pt(0, 58))
        }
        ctx.circle(6.5, 49, 3, rgb(0x6E6278).opacity(0.0))
        // tai
        ctx.polygon([pt(14, 34), pt(16, 6), pt(36, 22)], body)
        ctx.polygon([pt(70, 34), pt(68, 6), pt(48, 22)], patch)
        ctx.polygon([pt(18, 26), pt(19, 13), pt(29, 21)], rgb(0xF7B7B8))
        ctx.polygon([pt(66, 26), pt(65, 13), pt(55, 21)], rgb(0xF7B7B8))
        fridgeBody(ctx, x: 10, y: 16, w: 64, h: 79, color: body, radius: 20)
        // mảng lông màu cam
        var c = ctx
        c.clip(to: Path(roundedRect: CGRect(x: 10, y: 16, width: 64, height: 78), cornerRadius: 20))
        c.ellipse(46, 8, 40, 30, patch)
        c.ellipse(4, 70, 20, 30, patch)
        ctx.strokePath(rgb(0xE8D9C4), width: 1.6) { p in
            p.move(to: pt(11, 50)); p.addLine(to: pt(73, 50))
        }
        // mặt đang ngủ
        ctx.strokePath(ink, width: 1.6) { p in
            p.move(to: pt(26, 34)); p.addQuadCurve(to: pt(34, 34), control: pt(30, 38))
            p.move(to: pt(50, 34)); p.addQuadCurve(to: pt(58, 34), control: pt(54, 38))
            p.move(to: pt(42, 40)); p.addQuadCurve(to: pt(38.5, 42), control: pt(40.5, 43))
            p.move(to: pt(42, 40)); p.addQuadCurve(to: pt(45.5, 42), control: pt(43.5, 43))
        }
        ctx.polygon([pt(40, 37.5), pt(44, 37.5), pt(42, 40)], rgb(0xEE8F8F))
        ctx.ellipse(20, 38, 8, 4, rgb(0xF7B7B8).opacity(0.8))
        ctx.ellipse(56, 38, 8, 4, rgb(0xF7B7B8).opacity(0.8))
        ctx.strokePath(rgb(0xC9B8A6), width: 0.9) { p in
            p.move(to: pt(11, 39)); p.addLine(to: pt(19, 40))
            p.move(to: pt(11, 43)); p.addLine(to: pt(19, 42))
            p.move(to: pt(73, 39)); p.addLine(to: pt(65, 40))
            p.move(to: pt(73, 43)); p.addLine(to: pt(65, 42))
        }
        // tay nắm hình đệm thịt
        ctx.ellipse(57, 62, 9, 8, rgb(0xF7B7B8))
        for (tx, ty) in [(56.5, 59.0), (60.0, 57.0), (64.0, 57.5), (66.5, 60.5)] as [(CGFloat, CGFloat)] {
            ctx.circle(tx, ty, 1.7, rgb(0xF7B7B8))
        }
        // vòng cổ chuông
        ctx.rect(30, 48.5, 24, 3.2, rgb(0xEE8F8F), radius: 1.6)
        ctx.circle(42, 53.5, 3, rgb(0xF6D867))
        ctx.rect(41.4, 54, 1.2, 2, rgb(0xC9A04C))
        ctx.ellipse(60, 74, 3, 0, Color.clear)
        ctx.rect(15, 56, 3, 30, Color.white.opacity(0.9), radius: 1.5)
        sparkle(ctx, 22, 24, 6)
    }

    // MARK: - Bàn ăn mới

    private static func diningKotatsu(_ ctx: GraphicsContext) {
        ctx.ellipse(2, 86, 96, 10, shadow)
        // chăn bông phủ bàn
        var quilt = Path()
        quilt.move(to: pt(12, 44))
        quilt.addLine(to: pt(88, 44))
        quilt.addCurve(to: pt(96, 86), control1: pt(92, 56), control2: pt(97, 72))
        quilt.addLine(to: pt(4, 86))
        quilt.addCurve(to: pt(12, 44), control1: pt(3, 72), control2: pt(8, 56))
        quilt.closeSubpath()
        for k in 0..<8 { quilt.addEllipse(in: CGRect(x: 4 + CGFloat(k) * 11.5, y: 82, width: 12, height: 8)) }
        ctx.fill(quilt, with: .color(rgb(0xF6B9B4)))
        var q = ctx
        q.clip(to: quilt)
        q.strokePath(rgb(0xEC9F9A), width: 1.2) { p in
            for k in 0..<7 {
                let x = 10 + CGFloat(k) * 13.5
                p.move(to: pt(x, 44)); p.addLine(to: pt(x + (x - 50) * 0.18, 92))
            }
            p.move(to: pt(0, 66)); p.addLine(to: pt(100, 66))
        }
        for (fx, fy) in [(23.0, 56.0), (50.0, 74.0), (77.0, 57.0), (36.0, 80.0), (64.0, 80.0)] as [(CGFloat, CGFloat)] {
            q.circle(fx, fy, 2.2, Color.white.opacity(0.9))
            q.circle(fx, fy, 0.9, rgb(0xF6D867))
        }
        // mặt bàn gỗ
        ctx.rect(8, 38.5, 84, 7, rgb(0xB98559), radius: 2.5)
        ctx.rect(8, 38.5, 84, 3, rgb(0xD9A877), radius: 1.5)
        ctx.rect(14, 39.2, 12, 1, Color.white.opacity(0.6), radius: 0.5)
        // quýt ở góc bàn
        ctx.circle(84, 35, 4, rgb(0xF4A25E))
        ctx.circle(89, 36, 3.2, rgb(0xF6B04F))
        ctx.ellipse(83, 30, 3.4, 1.8, rgb(0x7DB582))
        ctx.circle(82.6, 33.8, 1, Color.white.opacity(0.6))
        // đệm ngồi
        for cx in [14.0, 86.0] as [CGFloat] {
            ctx.rect(cx - 13, 84, 26, 9, rgb(0xA9D8C4), radius: 4)
            ctx.rect(cx - 13, 84, 26, 3, rgb(0xC3E6D6), radius: 2)
            ctx.circle(cx, 88.5, 1.2, rgb(0x86C2AA))
        }
    }

    private static func diningBar(_ ctx: GraphicsContext) {
        ctx.ellipse(2, 88, 96, 8, shadow)
        // đèn thả hai bên
        for lx in [12.0, 88.0] as [CGFloat] {
            ctx.rect(lx - 0.5, 0, 1, 16, rgb(0x6E6278))
            ctx.circle(lx, 25, 6, rgb(0xFFE6A0).opacity(0.3))
            var shade = Path()
            shade.move(to: pt(lx - 7, 24))
            shade.addQuadCurve(to: pt(lx + 7, 24), control: pt(lx, 9))
            shade.closeSubpath()
            ctx.fill(shade, with: .color(rgb(0x8FCDB9)))
            ctx.ellipse(lx - 2.5, 22.5, 5, 3.6, rgb(0xFFF2C8))
        }
        // quầy ốp ván
        let front = CGRect(x: 10, y: 45, width: 80, height: 46)
        ctx.fill(Path(roundedRect: front, cornerRadius: 3), with: .color(rgb(0xFFF4E4)))
        ctx.strokePath(rgb(0xEDDCC4), width: 1) { p in
            var x: CGFloat = 16
            while x < 90 { p.move(to: pt(x, 47)); p.addLine(to: pt(x, 89)); x += 6 }
        }
        ctx.rect(10, 86, 80, 5, rgb(0xC9976A), radius: 2)
        // mặt quầy đá
        ctx.rect(6, 39.5, 88, 7, rgb(0xEDE8F3), radius: 2.5)
        ctx.rect(6, 39.5, 88, 2.2, Color.white, radius: 1.1)
        ctx.strokePath(rgb(0xD7CFE3), width: 0.7) { p in
            p.move(to: pt(20, 43)); p.addQuadCurve(to: pt(34, 45), control: pt(28, 42))
            p.move(to: pt(64, 44)); p.addQuadCurve(to: pt(80, 43), control: pt(72, 46))
        }
        // hai ghế cao
        for sx in [24.0, 76.0] as [CGFloat] {
            ctx.rect(sx - 8, 64, 2.6, 30, rgb(0x8E8899), radius: 1.3)
            ctx.rect(sx + 5.4, 64, 2.6, 30, rgb(0x8E8899), radius: 1.3)
            ctx.rect(sx - 9, 80, 18, 2.2, rgb(0x8E8899), radius: 1.1)
            ctx.ellipse(sx - 12, 58, 24, 9, rgb(0xE48D72))
            ctx.ellipse(sx - 11, 57, 22, 6.5, rgb(0xF3A58E))
            ctx.ellipse(sx - 6, 58, 7, 2, Color.white.opacity(0.5))
        }
    }

    private static func diningStump(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 87, 92, 9, shadow)
        let bark = rgb(0xB58357)
        // gốc cây có rễ
        ctx.polygon([pt(14, 90), pt(20, 74), pt(26, 86)], bark)
        ctx.polygon([pt(86, 90), pt(80, 74), pt(74, 86)], bark)
        ctx.rect(18, 42, 64, 48, bark, radius: 6)
        ctx.strokePath(rgb(0x9E6E46), width: 1.5) { p in
            for x in [28.0, 40.0, 52.0, 64.0, 74.0] as [CGFloat] {
                p.move(to: pt(x, 48)); p.addQuadCurve(to: pt(x + 1, 86), control: pt(x - 3, 66))
            }
        }
        ctx.ellipse(22, 60, 10, 6, rgb(0x8CC08F))
        ctx.ellipse(66, 78, 12, 6, rgb(0x8CC08F))
        // mặt cắt có vòng tuổi
        ctx.ellipse(12, 37, 76, 12, rgb(0xA87A50))
        ctx.ellipse(13, 36, 74, 10, rgb(0xEBC79C))
        ctx.strokePath(rgb(0xD6AC7D), width: 0.9) { p in
            p.addEllipse(in: CGRect(x: 22, y: 37.5, width: 56, height: 7))
            p.addEllipse(in: CGRect(x: 32, y: 39, width: 36, height: 4))
        }
        // mầm non
        ctx.strokePath(rgb(0x7DB582), width: 1.4) { p in
            p.move(to: pt(84, 40)); p.addQuadCurve(to: pt(86, 26), control: pt(87, 33))
        }
        ctx.ellipse(78, 22, 8, 5, rgb(0x8CC08F))
        ctx.ellipse(86, 21, 8, 5, rgb(0xA8D3A6))
        // ghế nấm
        for (mx, cap) in [(10.0, 0xEE8B8B), (90.0, 0xF6B04F)] as [(CGFloat, UInt32)] {
            ctx.rect(mx - 5, 80, 10, 13, rgb(0xFFF4E2), radius: 3)
            ctx.ellipse(mx - 10, 72, 20, 12, rgb(cap))
            ctx.circle(mx - 4, 76, 1.6, Color.white)
            ctx.circle(mx + 3, 75, 2, Color.white)
            ctx.circle(mx, 79, 1.2, Color.white)
        }
    }

    private static func diningBooth(_ ctx: GraphicsContext) {
        ctx.ellipse(0, 88, 100, 8, shadow)
        let vinyl = rgb(0xF2A39C)
        let vinylDark = rgb(0xE38A84)
        // ghế băng hai bên
        for (bx, flip) in [(0.0, false), (82.0, true)] as [(CGFloat, Bool)] {
            ctx.rect(bx, 20, 18, 72, vinyl, radius: 7)
            ctx.strokePath(vinylDark, width: 1) { p in
                for k in 0..<3 {
                    let x = bx + 4.5 + CGFloat(k) * 4.5
                    p.move(to: pt(x, 25)); p.addLine(to: pt(x, 62))
                }
            }
            ctx.rect(bx - (flip ? 4 : 0), 62, 22, 9, vinylDark, radius: 4)
            ctx.rect(bx - (flip ? 4 : 0), 61, 22, 4, vinyl, radius: 2)
            ctx.rect(bx + 1, 70, 16, 22, rgb(0xD97D78), radius: 2)
            ctx.rect(bx + 2, 23, 3, 30, Color.white.opacity(0.35), radius: 1.5)
        }
        // bàn chân trụ
        ctx.rect(46, 46, 8, 40, steelDark, radius: 2)
        ctx.ellipse(34, 85, 32, 7, rgb(0xB9BCC8))
        ctx.rect(48, 48, 2, 34, Color.white.opacity(0.5), radius: 1)
        ctx.rect(16, 39.5, 68, 7, rgb(0xC9CCD6), radius: 3)
        ctx.rect(16, 39.5, 68, 5, rgb(0xA9D8C4), radius: 2.5)
        ctx.rect(16, 39.5, 68, 1.4, Color.white.opacity(0.7), radius: 0.7)
        // tương cà, mù tạt
        ctx.rect(17.5, 30, 4, 10, rgb(0xEE6F6F), radius: 1.5)
        ctx.rect(18.8, 27, 1.4, 3.5, rgb(0xEE6F6F))
        ctx.rect(21.5, 31.5, 4, 8.5, rgb(0xF6D05A), radius: 1.5)
        ctx.rect(22.8, 28.5, 1.4, 3.5, rgb(0xF6D05A))
    }

    // MARK: - Đồ treo tường mới

    private static func wallShelf(_ ctx: GraphicsContext, y: CGFloat) {
        ctx.rect(6, y, 88, 6, rgb(0xC9976A), radius: 2)
        ctx.rect(6, y, 88, 1.6, rgb(0xDDB088), radius: 0.8)
        ctx.polygon([pt(14, y + 6), pt(21, y + 6), pt(14, y + 14)], rgb(0xA87A50))
        ctx.polygon([pt(86, y + 6), pt(79, y + 6), pt(86, y + 14)], rgb(0xA87A50))
    }

    private static func spiceBottle(_ ctx: GraphicsContext, x: CGFloat, bottom: CGFloat, w: CGFloat, h: CGFloat, fill: Color, lid: Color, round: Bool = false) {
        let top = bottom - h
        ctx.rect(x, top + 4, w, h - 4, rgb(0xF1F7FA), radius: round ? w / 2 : 2.5)
        ctx.rect(x + 1, top + h * 0.42, w - 2, h * 0.58 - 1, fill, radius: 2)
        ctx.rect(x + 1.5, top, w - 3, 5, lid, radius: 1.5)
        ctx.rect(x + 1.5, top + 6, 1.8, h - 10, Color.white.opacity(0.7), radius: 0.9)
    }

    private static func wallSpice(_ ctx: GraphicsContext) {
        // tầng trên
        spiceBottle(ctx, x: 12, bottom: 40, w: 12, h: 24, fill: rgb(0xEE7F6E), lid: rgb(0x6E6278))
        spiceBottle(ctx, x: 27, bottom: 40, w: 12, h: 20, fill: rgb(0x8CC08F), lid: rgb(0xC9976A))
        spiceBottle(ctx, x: 42, bottom: 40, w: 14, h: 26, fill: rgb(0xF6C94F), lid: rgb(0xEE8F8F))
        // cối giã nhỏ
        ctx.rect(62, 30, 22, 10, rgb(0xB9BCC8), radius: 4)
        ctx.ellipse(61, 27, 24, 6, rgb(0xD9DCE3))
        ctx.ellipse(64, 28, 18, 3, rgb(0x9E98A9))
        ctx.rotated(28, around: pt(74, 24)) { c in c.rect(72, 10, 5, 20, rgb(0xC9976A), radius: 2.5) }
        wallShelf(ctx, y: 40)
        // tầng dưới
        spiceBottle(ctx, x: 12, bottom: 76, w: 11, h: 22, fill: rgb(0xB58357), lid: rgb(0x8FCDB9))
        spiceBottle(ctx, x: 26, bottom: 76, w: 13, h: 18, fill: rgb(0xF4A25E), lid: rgb(0x6E6278), round: true)
        spiceBottle(ctx, x: 42, bottom: 76, w: 11, h: 24, fill: rgb(0xC9B6F0), lid: rgb(0xF6D867))
        spiceBottle(ctx, x: 56, bottom: 76, w: 12, h: 20, fill: rgb(0xEFE3C8), lid: rgb(0xEE8F8F))
        // tỏi và ớt
        ctx.ellipse(72, 66, 10, 10, rgb(0xFFF8EC))
        ctx.strokePath(rgb(0xE6DCCB), width: 0.8) { p in
            p.move(to: pt(77, 67)); p.addLine(to: pt(77, 75))
        }
        ctx.polygon([pt(75.5, 67), pt(77, 62), pt(78.5, 67)], rgb(0xFFF8EC))
        ctx.rotated(-30, around: pt(86, 70)) { c in
            c.ellipse(82, 66, 12, 5, rgb(0xEE6F6F))
            c.rect(92, 67, 3, 2.4, rgb(0x7DB582), radius: 1)
        }
        wallShelf(ctx, y: 76)
    }

    private static func herbBunch(_ ctx: GraphicsContext, x: CGFloat, top: CGFloat, leaf: Color, leafDark: Color, flower: Color?) {
        ctx.strokePath(rgb(0xC9A486), width: 1) { p in
            p.move(to: pt(x, 16)); p.addLine(to: pt(x, top))
        }
        ctx.strokePath(rgb(0x7DA06F), width: 1.2) { p in
            for dx in [-4.0, 0.0, 4.0] as [CGFloat] {
                p.move(to: pt(x, top)); p.addLine(to: pt(x + dx * 1.6, top + 34))
            }
        }
        for k in 0..<5 {
            let yy = top + 8 + CGFloat(k) * 6
            let spread = 3 + CGFloat(k) * 1.4
            ctx.ellipse(x - spread - 4, yy, 7, 4.4, k % 2 == 0 ? leaf : leafDark)
            ctx.ellipse(x + spread - 3, yy + 1.5, 7, 4.4, k % 2 == 0 ? leafDark : leaf)
            if let f = flower {
                ctx.circle(x - spread * 1.3, yy + 6, 1.6, f)
                ctx.circle(x + spread * 1.3, yy + 7, 1.6, f)
            }
        }
        ctx.rect(x - 4, top - 1, 8, 4, rgb(0xEE8F8F), radius: 1.5)
    }

    private static func wallHerbs(_ ctx: GraphicsContext) {
        // cành gỗ treo bằng dây
        ctx.strokePath(rgb(0xC9A486), width: 1) { p in
            p.move(to: pt(10, 14)); p.addLine(to: pt(50, 2)); p.addLine(to: pt(90, 14))
        }
        ctx.circle(50, 2.5, 2, rgb(0xA87A50))
        ctx.rect(4, 12, 92, 5, rgb(0xA87A50), radius: 2.5)
        ctx.ellipse(86, 9, 8, 4, rgb(0x8CC08F))
        // húng quế, oải hương, hương thảo
        herbBunch(ctx, x: 18, top: 24, leaf: rgb(0x8CC08F), leafDark: rgb(0x6FA373), flower: nil)
        herbBunch(ctx, x: 42, top: 22, leaf: rgb(0xA8C7A0), leafDark: rgb(0x8DB487), flower: rgb(0xB7A3E6))
        // dây tỏi
        ctx.strokePath(rgb(0xD9C9A6), width: 2) { p in
            p.move(to: pt(64, 16)); p.addLine(to: pt(64, 82))
        }
        for k in 0..<5 {
            let gy = 30 + CGFloat(k) * 11
            let gx: CGFloat = k % 2 == 0 ? 61 : 67
            ctx.ellipse(gx - 6, gy - 5, 12, 11, rgb(0xFFF8EC))
            ctx.polygon([pt(gx - 1.5, gy - 4), pt(gx, gy - 9), pt(gx + 1.5, gy - 4)], rgb(0xFFF8EC))
            ctx.strokePath(rgb(0xE8DCC8), width: 0.8) { p in
                p.move(to: pt(gx, gy - 4)); p.addLine(to: pt(gx, gy + 5))
            }
        }
        // chuỗi ớt đỏ
        ctx.strokePath(rgb(0xC9A486), width: 1) { p in
            p.move(to: pt(84, 16)); p.addLine(to: pt(84, 74))
        }
        for k in 0..<6 {
            let cy = 24 + CGFloat(k) * 9
            let dir: Double = k % 2 == 0 ? 25 : -25
            ctx.rotated(dir, around: pt(84, cy)) { c in
                c.ellipse(81, cy, 6, 12, rgb(k % 3 == 1 ? 0xF29E5E : 0xEE6F6F))
                c.rect(82.6, cy - 1.5, 2.8, 3, rgb(0x7DB582), radius: 1)
            }
        }
    }

    private static func plate(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, rim: Color, inner: Color) {
        ctx.circle(cx + 1, cy + 1.5, r, Color.black.opacity(0.08))
        ctx.circle(cx, cy, r, rim)
        ctx.circle(cx, cy, r * 0.78, Color.white)
        ctx.circle(cx, cy, r * 0.66, inner)
    }

    private static func wallPlates(_ ctx: GraphicsContext) {
        // đĩa lớn hoa xanh ở giữa
        plate(ctx, 50, 50, 22, rim: rgb(0x9FC7EC), inner: rgb(0xFFFDF8))
        for a in 0..<6 {
            let ang = Double(a) * Double.pi / 3
            ctx.ellipse(50 + CGFloat(cos(ang)) * 6 - 3.5, 50 + CGFloat(sin(ang)) * 6 - 3.5, 7, 7, rgb(0x9FC7EC))
        }
        ctx.circle(50, 50, 3, rgb(0xF6D867))
        ctx.strokePath(rgb(0x9FC7EC), width: 1) { p in
            p.addEllipse(in: CGRect(x: 36, y: 36, width: 28, height: 28))
        }
        // đĩa nhỏ xung quanh
        plate(ctx, 18, 22, 13, rim: rgb(0xF7B7C2), inner: rgb(0xFFF4F6))
        ctx.heart(center: pt(18, 22), size: 9, rgb(0xEE8F9E))
        plate(ctx, 82, 22, 13, rim: rgb(0xF6D867), inner: rgb(0xFFFBEA))
        ctx.circle(82, 22, 5.5, rgb(0xF6D867))
        ctx.circle(82, 22, 4.3, rgb(0xFFF6D2))
        ctx.strokePath(rgb(0xF6D867), width: 0.8) { p in
            for a in 0..<6 {
                let ang = Double(a) * Double.pi / 3
                p.move(to: pt(82, 22)); p.addLine(to: pt(82 + CGFloat(cos(ang)) * 4.3, 22 + CGFloat(sin(ang)) * 4.3))
            }
        }
        plate(ctx, 18, 80, 12, rim: rgb(0x8FCDB9), inner: rgb(0xF2FAF6))
        ctx.strokePath(rgb(0x8FCDB9), width: 1.4) { p in
            for dx in [-4.0, 0.0, 4.0] as [CGFloat] { p.move(to: pt(18 + dx, 74.5)); p.addLine(to: pt(18 + dx, 85.5)) }
        }
        plate(ctx, 82, 80, 12, rim: rgb(0xC9B6F0), inner: rgb(0xF7F3FD))
        ctx.draw(Text("★").font(.system(size: 10)).foregroundColor(rgb(0xB7A3E6)), at: pt(82, 80))
        // móc treo
        for (hx, hy) in [(50.0, 27.0), (18.0, 8.0), (82.0, 8.0), (18.0, 67.0), (82.0, 67.0)] as [(CGFloat, CGFloat)] {
            ctx.rect(hx - 1, hy - 1, 2, 3, steelDark, radius: 1)
        }
    }

    private static func wallMenu(_ ctx: GraphicsContext) {
        // dây treo
        ctx.strokePath(rgb(0xA87A50), width: 1.2) { p in
            p.move(to: pt(22, 16)); p.addLine(to: pt(50, 4)); p.addLine(to: pt(78, 16))
        }
        ctx.circle(50, 4, 2.2, rgb(0x8E8899))
        // bảng phấn khung gỗ
        ctx.rect(8, 14, 84, 70, rgb(0xC9976A), radius: 5)
        ctx.rect(13, 19, 74, 60, rgb(0x56706A), radius: 2.5)
        let chalk = Color.white.opacity(0.85)
        ctx.draw(Text("Menu").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(chalk), at: pt(50, 27))
        ctx.strokePath(chalk, width: 0.8) { p in
            p.move(to: pt(33, 33)); p.addQuadCurve(to: pt(67, 33), control: pt(50, 36))
        }
        // tách cà phê
        ctx.strokePath(chalk, width: 1.2) { p in
            p.move(to: pt(20, 44)); p.addLine(to: pt(22, 54)); p.addLine(to: pt(30, 54)); p.addLine(to: pt(32, 44)); p.closeSubpath()
            p.addEllipse(in: CGRect(x: 31, y: 46, width: 4, height: 4))
            p.move(to: pt(24, 41)); p.addQuadCurve(to: pt(25, 36), control: pt(22, 38))
            p.move(to: pt(28, 41)); p.addQuadCurve(to: pt(29, 36), control: pt(26, 38))
        }
        // dòng chữ phấn
        ctx.strokePath(rgb(0xF6D867).opacity(0.9), width: 1.2) { p in
            p.move(to: pt(40, 45)); p.addLine(to: pt(66, 45))
            p.move(to: pt(40, 50)); p.addLine(to: pt(58, 50))
        }
        ctx.strokePath(chalk, width: 1) { p in
            p.move(to: pt(72, 47)); p.addLine(to: pt(80, 47))
        }
        // lát bánh
        ctx.strokePath(chalk, width: 1.2) { p in
            p.move(to: pt(20, 72)); p.addLine(to: pt(32, 72)); p.addLine(to: pt(32, 64)); p.addLine(to: pt(20, 68)); p.closeSubpath()
        }
        ctx.circle(28, 62, 1.8, rgb(0xF7A7B8))
        ctx.strokePath(rgb(0xF7A7B8).opacity(0.9), width: 1.2) { p in
            p.move(to: pt(40, 63)); p.addLine(to: pt(62, 63))
            p.move(to: pt(40, 68)); p.addLine(to: pt(54, 68))
        }
        ctx.strokePath(chalk, width: 1) { p in
            p.move(to: pt(72, 65)); p.addLine(to: pt(80, 65))
        }
        ctx.heart(center: pt(78, 74), size: 5, rgb(0xF7A7B8).opacity(0.9))
        // máng phấn
        ctx.rect(10, 83, 80, 4, rgb(0xA87A50), radius: 2)
        ctx.rect(24, 80.5, 9, 3, Color.white, radius: 1.5)
        ctx.rect(36, 81, 7, 2.6, rgb(0xF7A7B8), radius: 1.3)
        ctx.rect(46, 81, 6, 2.6, rgb(0xF6D867), radius: 1.3)
    }

    private static func wallCherry(_ ctx: GraphicsContext) {
        // cuống và lá
        ctx.strokePath(rgb(0x7DA06F), width: 3) { p in
            p.move(to: pt(36, 44)); p.addQuadCurve(to: pt(56, 10), control: pt(38, 20))
            p.move(to: pt(72, 54)); p.addQuadCurve(to: pt(56, 10), control: pt(70, 26))
        }
        ctx.rotated(-20, around: pt(64, 12)) { c in
            c.ellipse(56, 6, 24, 11, rgb(0x8CC08F))
            c.rect(58, 11, 18, 1.2, rgb(0x6FA373))
        }
        ctx.circle(56, 10, 2.6, rgb(0x6FA373))
        // quả nhỏ
        ctx.circle(72, 70, 17, rgb(0xE8606E))
        ctx.circle(67, 63, 4, Color.white.opacity(0.55))
        // quả lớn là mặt đồng hồ
        ctx.circle(36, 62, 25, rgb(0xEE6F7C))
        ctx.circle(36, 63, 19, rgb(0xFFF6F2))
        for (dx, dy) in [(36.0, 47.5), (51.5, 63.0), (36.0, 78.5), (20.5, 63.0)] as [(CGFloat, CGFloat)] {
            ctx.circle(dx, dy, 1.8, rgb(0xEE8F9E))
        }
        ctx.strokePath(ink, width: 2.8) { p in
            p.move(to: pt(36, 63)); p.addLine(to: pt(36, 51))
        }
        ctx.strokePath(ink, width: 2.2) { p in
            p.move(to: pt(36, 63)); p.addLine(to: pt(45, 68))
        }
        ctx.circle(36, 63, 2.6, rgb(0xEE6F7C))
        ctx.ellipse(18, 42, 12, 7, Color.white.opacity(0.5))
        sparkle(ctx, 88, 46, 7, rgb(0xF6D867))
    }

    // MARK: - Món ăn mới

    private static func treatDumpling(_ ctx: GraphicsContext) {
        // nắp xửng dựa phía sau
        ctx.ellipse(52, 36, 42, 40, rgb(0xD9B57F))
        ctx.ellipse(56, 40, 34, 32, rgb(0xE8CA96))
        ctx.strokePath(rgb(0xD9B57F), width: 1) { p in
            for k in 0..<4 { let y = 46 + CGFloat(k) * 6; p.move(to: pt(58, y)); p.addLine(to: pt(88, y)) }
        }
        // chén nước tương & đũa
        ctx.strokePath(rgb(0xC9976A), width: 2.4) { p in
            p.move(to: pt(4, 80)); p.addLine(to: pt(30, 92))
            p.move(to: pt(4, 85)); p.addLine(to: pt(28, 94))
        }
        // xửng hấp
        ctx.rect(12, 66, 62, 26, rgb(0xE2C08A), radius: 6)
        ctx.strokePath(rgb(0xCBA46D), width: 1.2) { p in
            p.move(to: pt(14, 74)); p.addLine(to: pt(72, 74))
            p.move(to: pt(14, 84)); p.addLine(to: pt(72, 84))
        }
        ctx.ellipse(10, 60, 66, 12, rgb(0xCBA46D))
        ctx.ellipse(13, 61, 60, 9, rgb(0xF1E3C2))
        // ba chiếc há cảo
        for (dx, dy) in [(22.0, 58.0), (43.0, 56.0), (33.0, 61.0)] as [(CGFloat, CGFloat)] {
            ctx.ellipse(dx - 9, dy - 6, 18, 13, rgb(0xFFF9F2))
            ctx.ellipse(dx - 6, dy - 4, 10, 6, rgb(0xFBE3D8).opacity(0.7))
            ctx.strokePath(rgb(0xEAD9CC), width: 0.9) { p in
                for k in 0..<3 {
                    let x = dx - 4 + CGFloat(k) * 4
                    p.move(to: pt(x, dy - 5)); p.addLine(to: pt(x + 1, dy - 1))
                }
            }
        }
        ctx.circle(33, 54.6, 1, rgb(0x8CC08F))
        steam(ctx, 24, 46, 12)
        steam(ctx, 40, 44, 14)
        // chén nước chấm
        ctx.ellipse(74, 84, 22, 9, rgb(0xF7F1EA))
        ctx.ellipse(76, 84.6, 18, 5.5, rgb(0x8E6450))
        ctx.circle(84, 86, 1, rgb(0xEE6F6F))
    }

    private static func treatPho(_ ctx: GraphicsContext) {
        // đũa và thìa sứ
        ctx.strokePath(rgb(0xC9976A), width: 2.6) { p in
            p.move(to: pt(62, 60)); p.addLine(to: pt(94, 28))
            p.move(to: pt(66, 61)); p.addLine(to: pt(98, 34))
        }
        ctx.rotated(32, around: pt(16, 50)) { c in
            c.rect(14, 30, 4, 20, Color.white, radius: 2)
            c.ellipse(10, 46, 12, 14, Color.white)
            c.ellipse(12, 48, 8, 9, rgb(0xF6E7C1))
        }
        // nước dùng trong
        ctx.ellipse(12, 54, 76, 16, rgb(0xF4DFB4))
        ctx.strokePath(Color.white.opacity(0.95), width: 1.6) { p in
            p.move(to: pt(20, 62)); p.addCurve(to: pt(46, 61), control1: pt(28, 56), control2: pt(38, 66))
            p.move(to: pt(30, 64)); p.addCurve(to: pt(60, 63), control1: pt(40, 58), control2: pt(50, 68))
            p.move(to: pt(50, 60)); p.addCurve(to: pt(78, 61), control1: pt(58, 56), control2: pt(68, 66))
        }
        // thịt bò tái
        for (bx, by, rot) in [(36.0, 57.0, -10.0), (50.0, 56.0, 12.0), (44.0, 61.5, 4.0)] as [(CGFloat, CGFloat, Double)] {
            ctx.rotated(rot, around: pt(bx, by)) { c in
                c.ellipse(bx - 7, by - 3, 14, 6, rgb(0xC98B7E))
                c.ellipse(bx - 5, by - 2.2, 8, 2.4, rgb(0xE2AFA3))
            }
        }
        // rau, hành, chanh, ớt
        for (gx, gy) in [(24.0, 58.0), (58.0, 62.0), (30.0, 63.0), (64.0, 57.0)] as [(CGFloat, CGFloat)] {
            ctx.ellipse(gx - 3.5, gy - 2, 7, 4, rgb(0x7DB582))
        }
        for (gx, gy) in [(40.0, 54.5), (54.0, 63.0), (27.0, 55.0)] as [(CGFloat, CGFloat)] {
            ctx.circle(gx, gy, 1.5, rgb(0x8CC08F))
            ctx.circle(gx, gy, 0.6, rgb(0xDDF1E5))
        }
        ctx.circle(70, 61, 1.5, rgb(0xEE6F6F))
        ctx.circle(73, 58.5, 1.3, rgb(0xEE6F6F))
        var lime = Path()
        lime.move(to: pt(70, 52)); lime.addArc(center: pt(76, 52), radius: 6, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        lime.closeSubpath()
        ctx.fill(lime, with: .color(rgb(0x9CCB6E)))
        ctx.ellipse(71.5, 50.5, 9, 3, rgb(0xDDEFB8))
        // tô sứ viền xanh
        var bowl = Path()
        bowl.move(to: pt(10, 62))
        bowl.addLine(to: pt(90, 62))
        bowl.addCurve(to: pt(50, 90), control1: pt(88, 82), control2: pt(70, 90))
        bowl.addCurve(to: pt(10, 62), control1: pt(30, 90), control2: pt(12, 82))
        bowl.closeSubpath()
        ctx.rect(36, 86, 28, 8, rgb(0xD9E3EE), radius: 3)
        ctx.fill(bowl, with: .color(rgb(0xFBFCFE)))
        ctx.strokePath(rgb(0x8EB4DE), width: 2.2) { p in
            p.move(to: pt(13, 67)); p.addLine(to: pt(87, 67))
        }
        ctx.strokePath(rgb(0x8EB4DE), width: 1.2) { p in
            var x: CGFloat = 20
            while x < 80 {
                p.move(to: pt(x, 76)); p.addQuadCurve(to: pt(x + 8, 76), control: pt(x + 4, 71))
                x += 10
            }
        }
        ctx.ellipse(10, 60, 80, 4, rgb(0xE9EEF5))
        steam(ctx, 34, 48, 14)
        steam(ctx, 52, 46, 16)
    }

    private static func treatBanhMi(_ ctx: GraphicsContext) {
        // giấy gói
        ctx.rotated(-6, around: pt(50, 78)) { c in
            c.rect(12, 70, 76, 20, Color.white, radius: 2)
            c.strokePath(rgb(0xF29E96).opacity(0.7), width: 1.6) { p in
                var x: CGFloat = 16
                while x < 88 { p.move(to: pt(x, 70)); p.addLine(to: pt(x, 90)); x += 6 }
            }
        }
        ctx.rotated(-12, around: pt(50, 66)) { c in
            // nửa dưới ổ bánh
            c.ellipse(8, 64, 84, 20, rgb(0xDE9F5C))
            // nhân: thịt, đồ chua, dưa leo, ngò, ớt
            c.ellipse(14, 60, 72, 10, rgb(0xE6A79A))
            c.rect(18, 58.5, 64, 4, rgb(0xC98B7E), radius: 2)
            for k in 0..<7 {
                let x = 18 + CGFloat(k) * 9.5
                c.rect(x, 55, 8, 2.4, rgb(0xF4A25E), radius: 1.2)
                c.ellipse(x + 2, 57, 7, 3.6, rgb(0xA8D08D))
            }
            for (gx, gy) in [(22.0, 53.0), (40.0, 52.0), (58.0, 53.0), (74.0, 52.5)] as [(CGFloat, CGFloat)] {
                c.ellipse(gx - 4, gy - 2, 8, 5, rgb(0x6FA373))
                c.ellipse(gx, gy - 3, 5, 4, rgb(0x8CC08F))
            }
            c.circle(32, 54, 1.4, rgb(0xEE6F6F))
            c.circle(64, 54, 1.4, rgb(0xEE6F6F))
            // nửa trên ổ bánh, giòn vàng
            var crust = Path()
            crust.move(to: pt(8, 54))
            crust.addCurve(to: pt(92, 54), control1: pt(16, 30), control2: pt(84, 30))
            crust.addQuadCurve(to: pt(8, 54), control: pt(50, 48))
            c.fill(crust, with: .color(rgb(0xE8AE6A)))
            c.strokePath(rgb(0xF8D9A6), width: 2) { p in
                for sx in [26.0, 42.0, 58.0, 74.0] as [CGFloat] {
                    p.move(to: pt(sx - 4, 44)); p.addQuadCurve(to: pt(sx + 5, 42), control: pt(sx, 40))
                }
            }
            c.ellipse(20, 41, 14, 4, Color.white.opacity(0.35))
        }
        sparkle(ctx, 84, 30, 7, rgb(0xF6D867))
    }

    private static func treatMooncake(_ ctx: GraphicsContext) {
        // đèn ông sao
        ctx.strokePath(rgb(0xC9976A), width: 1.6) { p in
            p.move(to: pt(16, 92)); p.addLine(to: pt(16, 52))
        }
        ctx.circle(16, 40, 12, rgb(0xF6D867).opacity(0.25))
        ctx.polygon(starPoints(16, 40, 11, 5), rgb(0xEE6F6F))
        ctx.polygon(starPoints(16, 40, 6, 2.8), rgb(0xF6D867))
        ctx.strokePath(rgb(0xF6D867), width: 0.8) { p in
            p.move(to: pt(10, 50)); p.addLine(to: pt(8, 58))
            p.move(to: pt(22, 50)); p.addLine(to: pt(24, 58))
        }
        // đĩa
        ctx.ellipse(22, 80, 74, 14, rgb(0xE9E3F5))
        ctx.ellipse(26, 80, 66, 10, Color.white)
        // bánh nguyên
        ctx.rect(48, 56, 36, 30, rgb(0xC98A4E), radius: 10)
        ctx.ellipse(48, 50, 36, 14, rgb(0xE0A764))
        ctx.strokePath(rgb(0xC98A4E), width: 1.2) { p in
            p.addEllipse(in: CGRect(x: 52, y: 52, width: 28, height: 10))
            for a in 0..<4 {
                let ang = Double(a) * Double.pi / 2
                p.move(to: pt(66, 57)); p.addLine(to: pt(66 + CGFloat(cos(ang)) * 9, 57 + CGFloat(sin(ang)) * 3.4))
            }
        }
        ctx.circle(66, 57, 2, rgb(0xC98A4E))
        ctx.rect(51, 60, 3, 20, Color.white.opacity(0.3), radius: 1.5)
        // miếng cắt có trứng muối
        ctx.ellipse(26, 61, 26, 9, rgb(0xE0A764))
        ctx.rect(26, 65, 26, 23, rgb(0xC98A4E), radius: 7)
        ctx.rect(28.5, 66, 21, 19.5, rgb(0xE9C9A0), radius: 5)
        ctx.circle(39, 75.5, 5.5, rgb(0xF4A63C))
        ctx.circle(37.8, 74.2, 1.8, rgb(0xFBD07A))
        // tách trà nhỏ
        ctx.rect(84, 76, 12, 10, rgb(0xA9D8C4), radius: 4)
        ctx.ellipse(84, 74, 12, 4, rgb(0xC8B27A))
        steam(ctx, 90, 70, 9)
    }

    private static func treatBoba(_ ctx: GraphicsContext) {
        // bánh quy bên cạnh
        ctx.circle(22, 84, 10, rgb(0xDDA35F))
        for (dx, dy) in [(18.0, 80.0), (25.0, 83.0), (20.0, 88.0), (27.0, 89.0)] as [(CGFloat, CGFloat)] {
            ctx.circle(dx, dy, 1.4, rgb(0x6B4A3A))
        }
        // cốc
        var cup = Path()
        cup.move(to: pt(36, 34))
        cup.addLine(to: pt(70, 34))
        cup.addLine(to: pt(66, 90))
        cup.addQuadCurve(to: pt(40, 90), control: pt(53, 95))
        cup.closeSubpath()
        ctx.fill(cup, with: .color(rgb(0xF4ECF6)))
        var tea = ctx
        tea.clip(to: cup)
        tea.rect(30, 44, 50, 52, rgb(0xE9C9A2))
        tea.rect(30, 44, 50, 3, rgb(0xF4DEC2))
        for (px, py) in [(42.0, 87.0), (48.0, 89.0), (54.0, 88.0), (60.0, 87.0), (45.0, 82.0), (51.0, 83.0), (57.0, 82.0), (63.0, 83.0), (48.0, 77.5), (55.0, 77.0)] as [(CGFloat, CGFloat)] {
            tea.circle(px, py, 2.6, rgb(0x5E4A52))
            tea.circle(px - 0.8, py - 0.9, 0.7, Color.white.opacity(0.5))
        }
        tea.rect(38, 36, 3.5, 50, Color.white.opacity(0.45), radius: 1.7)
        // nắp có mặt mèo
        ctx.rect(34, 31, 38, 5, rgb(0xF7C1CC), radius: 2.5)
        ctx.circle(53, 60, 7, Color.white.opacity(0.85))
        ctx.polygon([pt(47, 57), pt(47.5, 51), pt(51, 55)], Color.white.opacity(0.85))
        ctx.polygon([pt(59, 57), pt(58.5, 51), pt(55, 55)], Color.white.opacity(0.85))
        ctx.circle(50.5, 60, 0.9, ink)
        ctx.circle(55.5, 60, 0.9, ink)
        ctx.polygon([pt(52.2, 61.6), pt(53.8, 61.6), pt(53, 62.6)], rgb(0xEE8F8F))
        // ống hút to
        ctx.rotated(14, around: pt(56, 30)) { c in
            c.rect(53, 6, 7, 32, rgb(0xEE8F9E), radius: 2)
            c.rect(54.5, 8, 2, 26, Color.white.opacity(0.5), radius: 1)
        }
        sparkle(ctx, 78, 44, 7)
    }
}
