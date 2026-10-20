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
        // MARK: Bếp
        case "stove.basic": stoveBasic(ctx)
        case "stove.retro": stoveRetro(ctx)
        case "stove.oven": stoveOven(ctx)
        case "stove.hearth": stoveHearth(ctx)
        // MARK: Tủ lạnh
        case "fridge.mini": fridgeMini(ctx)
        case "fridge.retro": fridgeRetro(ctx)
        case "fridge.pink": fridgePink(ctx)
        case "fridge.magnets": fridgeMagnets(ctx)
        // MARK: Bàn ăn
        case "dining.stool": diningStool(ctx)
        case "dining.round": diningRound(ctx)
        case "dining.picnic": diningPicnic(ctx)
        case "dining.long": diningLong(ctx)
        // MARK: Đồ treo tường
        case "kitchenWall.clock": wallClock(ctx)
        case "kitchenWall.pans": wallPans(ctx)
        case "kitchenWall.fruit": wallFruit(ctx)
        case "kitchenWall.jars": wallJars(ctx)
        // MARK: Món ăn trên bàn
        case "treat.tea": treatTea(ctx)
        case "treat.bread": treatBread(ctx)
        case "treat.ramen": treatRamen(ctx)
        case "treat.pizza": treatPizza(ctx)
        case "treat.cake": treatCake(ctx)
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
    private static func window(_ ctx: GraphicsContext, frame: Color, curtain: Color) {
        ctx.rect(45, 7, 28, 24, frame, radius: 2.5)
        ctx.rect(47.5, 9.5, 23, 19, rgb(0xCFE9F4), radius: 1.5)
        ctx.ellipse(50, 20, 9, 4, Color.white.opacity(0.85))
        ctx.ellipse(54, 18, 7, 4, Color.white.opacity(0.85))
        ctx.circle(66, 14, 2.6, rgb(0xFBE7A6))
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
}
