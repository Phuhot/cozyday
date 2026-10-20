import SwiftUI

/// Hình vẽ đồ trong phòng tắm. Trả về false nếu không phải ID của phòng này.
enum BathArt {
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        // MARK: Tường & sàn (125×100)
        case "bathTheme.aqua": drawAqua(ctx)
        case "bathTheme.pink": drawPink(ctx)
        case "bathTheme.ocean": drawOcean(ctx)
        case "bathTheme.marble": drawMarble(ctx)
        // MARK: Bồn tắm
        case "tub.basin": drawTubBasin(ctx)
        case "tub.shower": drawShower(ctx)
        case "tub.claw": drawClawTub(ctx)
        case "tub.bubble": drawBubbleTub(ctx)
        // MARK: Bồn rửa
        case "sink.basic": drawSink(ctx, basin: rgb(0xFFFFFF), shade: rgb(0xDDE7EC))
        case "sink.mirror":
            drawRoundMirror(ctx)
            drawSink(ctx, basin: rgb(0xFFFFFF), shade: rgb(0xDDE7EC))
        case "sink.shell":
            drawShellMirror(ctx)
            drawShellSink(ctx)
        // MARK: Kệ
        case "bathShelf.towels": drawTowelShelf(ctx)
        case "bathShelf.bottles": drawBottleShelf(ctx)
        case "bathShelf.fern": drawFernShelf(ctx)
        // MARK: Thảm
        case "bathMat.basic": drawMatBasic(ctx)
        case "bathMat.duck": drawMatDuck(ctx)
        case "bathMat.wave": drawMatWave(ctx)
        // MARK: Đồ chơi
        case "bathToy.duck": drawRubberDuck(ctx)
        case "bathToy.boat": drawBoat(ctx)
        case "bathToy.bubbles": drawBubbles(ctx)
        case "bathToy.whale": drawWhale(ctx)
        default: return drawMore(id, in: ctx)
        }
        return true
    }

    // MARK: - Màu dùng chung

    private static let porcelain = rgb(0xFFFFFF)
    private static let porcelainShade = rgb(0xDCE6EC)
    private static let chrome = rgb(0xC6D2DA)
    private static let chromeDark = rgb(0xA3B3BF)
    private static let duckYellow = rgb(0xF8D35E)
    private static let duckShade = rgb(0xEDB840)
    private static let beak = rgb(0xF29A5B)

    // MARK: - Khung phòng dùng chung

    /// Cửa sổ nhỏ chung vị trí: x 54…76, y 8…28.
    private static let win = CGRect(x: 54, y: 8, width: 22, height: 20)

    private static func wallTiles(_ ctx: GraphicsContext, base: Color, grout: Color, w: CGFloat, h: CGFloat,
                                  from top: CGFloat = 0, to bottom: CGFloat = 62) {
        ctx.rect(0, top, 125, bottom - top, base)
        ctx.strokePath(grout, width: 0.6) { p in
            var y = top + h
            while y < bottom {
                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: 125, y: y))
                y += h
            }
            var x = w
            while x < 125 {
                p.move(to: CGPoint(x: x, y: top)); p.addLine(to: CGPoint(x: x, y: bottom))
                x += w
            }
        }
    }

    /// Điểm sáng nhỏ ở góc vài viên gạch.
    private static func tileShine(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, from top: CGFloat, to bottom: CGFloat) {
        var row = 0
        var y = top
        while y + h <= bottom + 0.1 {
            var col = 0
            var x: CGFloat = 0
            while x + w <= 125.1 {
                if (row * 3 + col * 2) % 5 == 0 {
                    ctx.rect(x + 1.2, y + 1.2, w * 0.28, 0.8, Color.white.opacity(0.55), radius: 0.4)
                }
                x += w
                col += 1
            }
            y += h
            row += 1
        }
    }

    private static func floorChecker(_ ctx: GraphicsContext, a: Color, b: Color, grout: Color) {
        ctx.rect(0, 62, 125, 38, a)
        let tw: CGFloat = 12.5
        let rows: [(CGFloat, CGFloat)] = [(62, 8), (70, 9), (79, 10), (89, 11)]
        for (i, r) in rows.enumerated() {
            for col in 0..<10 where (col + i) % 2 == 0 {
                ctx.rect(CGFloat(col) * tw, r.0, tw, r.1, b)
            }
        }
        ctx.strokePath(grout, width: 0.5) { p in
            for r in rows {
                p.move(to: CGPoint(x: 0, y: r.0)); p.addLine(to: CGPoint(x: 125, y: r.0))
            }
        }
    }

    private static func baseboard(_ ctx: GraphicsContext, _ color: Color) {
        ctx.rect(0, 59.5, 125, 3, color)
        ctx.rect(0, 59.5, 125, 0.7, Color.white.opacity(0.5))
    }

    private static func band(_ ctx: GraphicsContext, y: CGFloat, _ color: Color, dot: Color) {
        ctx.rect(0, y, 125, 3.2, color)
        var x: CGFloat = 3
        while x < 125 {
            ctx.circle(x, y + 1.6, 0.7, dot)
            x += 6
        }
    }

    /// Cửa sổ vuông: khung, kính trời, nửa dưới kính mờ, song dọc.
    private static func squareWindow(_ ctx: GraphicsContext, frame: Color, sky: Color, sill: Color) {
        let r = win
        ctx.rect(r.minX, r.minY, r.width, r.height, frame, radius: 4)
        ctx.rect(r.minX + 2.2, r.minY + 2.2, r.width - 4.4, r.height - 4.4, sky, radius: 2.2)
        ctx.ellipse(r.minX + 4, r.minY + 5, 8, 3.4, Color.white.opacity(0.85))
        ctx.ellipse(r.minX + 6, r.minY + 3.8, 5, 3, Color.white.opacity(0.85))
        // kính mờ nửa dưới
        ctx.rect(r.minX + 2.2, r.midY, r.width - 4.4, r.height / 2 - 2.2, Color.white.opacity(0.55), radius: 1.5)
        for i in 0..<4 {
            ctx.circle(r.minX + 5 + CGFloat(i) * 4, r.midY + 4, 0.6, Color.white.opacity(0.9))
        }
        ctx.rect(r.midX - 0.7, r.minY + 2, 1.4, r.height - 4, frame)
        ctx.rect(r.minX + 2, r.midY - 0.7, r.width - 4, 1.4, frame)
        ctx.rect(r.minX - 2.5, r.maxY - 1, r.width + 5, 2.6, sill, radius: 1.3)
        // chậu cây nhỏ trên bậu cửa
        ctx.rect(r.maxX - 7, r.maxY - 5, 4.4, 4, rgb(0xE59A7A), radius: 1)
        ctx.ellipse(r.maxX - 8, r.maxY - 8.5, 3.6, 4.4, Palette.sage)
        ctx.ellipse(r.maxX - 5.4, r.maxY - 9.5, 3.6, 5, Palette.sage)
    }

    // MARK: - Theme: Gạch xanh nước (mặc định)

    private static func drawAqua(_ ctx: GraphicsContext) {
        wallTiles(ctx, base: rgb(0xDFF2F2), grout: rgb(0xC3E2E4).opacity(0.75), w: 10.42, h: 10, from: 0, to: 62)
        tileShine(ctx, w: 10.42, h: 10, from: 0, to: 60)
        band(ctx, y: 38.4, rgb(0x9FD3D6), dot: Color.white.opacity(0.8))
        floorChecker(ctx, a: rgb(0xE8F3F2), b: rgb(0xCDE6E6), grout: rgb(0xB7D8D9).opacity(0.6))
        baseboard(ctx, rgb(0xA9D7DA))
        squareWindow(ctx, frame: rgb(0xFFFFFF), sky: rgb(0xCBE9F5), sill: rgb(0xF4FAFA))
    }

    // MARK: - Theme: Gạch hồng

    private static func drawPink(_ ctx: GraphicsContext) {
        wallTiles(ctx, base: rgb(0xFCE8ED), grout: rgb(0xF2D0DA).opacity(0.8), w: 10.42, h: 10, from: 0, to: 62)
        tileShine(ctx, w: 10.42, h: 10, from: 0, to: 60)
        band(ctx, y: 38.4, rgb(0xF4B8C8), dot: Color.white.opacity(0.85))
        // tim nhỏ lác đác
        let hearts: [(CGFloat, CGFloat)] = [(15.6, 15), (36.5, 25), (98.9, 15), (109.4, 45), (26, 55), (88.5, 55), (46.9, 5)]
        for h in hearts {
            ctx.heart(center: CGPoint(x: h.0, y: h.1), size: 3, rgb(0xF4B8C8).opacity(0.7))
        }
        floorChecker(ctx, a: rgb(0xFFF6F7), b: rgb(0xF6D9E0), grout: rgb(0xEBC3CD).opacity(0.6))
        baseboard(ctx, rgb(0xEFB3C3))
        squareWindow(ctx, frame: rgb(0xFFFFFF), sky: rgb(0xD6EBF7), sill: rgb(0xFFF7F9))
    }

    // MARK: - Theme: Đại dương

    private static func drawOcean(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xE2F3FA))
        // hai lớp sóng
        func wave(_ y: CGFloat, _ color: Color) {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: 62))
            p.addLine(to: CGPoint(x: 0, y: y))
            var x: CGFloat = 0
            while x < 125 {
                p.addQuadCurve(to: CGPoint(x: x + 8, y: y), control: CGPoint(x: x + 4, y: y - 4))
                p.addQuadCurve(to: CGPoint(x: x + 16, y: y), control: CGPoint(x: x + 12, y: y + 3))
                x += 16
            }
            p.addLine(to: CGPoint(x: 125, y: 62))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
        wave(34, rgb(0xB5DEEE))
        wave(44, rgb(0x93CDE5))
        ctx.strokePath(Color.white.opacity(0.6), width: 0.8) { p in
            var x: CGFloat = 0
            while x < 125 {
                p.move(to: CGPoint(x: x + 1.5, y: 33)); p.addQuadCurve(to: CGPoint(x: x + 6.5, y: 32.5), control: CGPoint(x: x + 4, y: 30.6))
                x += 16
            }
        }
        // bong bóng
        let bubbles: [(CGFloat, CGFloat, CGFloat)] = [
            (10, 12, 2.4), (16, 22, 1.4), (30, 8, 1.8), (40, 18, 2.6), (92, 10, 2.2), (104, 20, 1.6),
            (116, 8, 2.8), (112, 30, 1.4), (22, 40, 1.8), (50, 50, 2.2), (86, 46, 1.6), (106, 54, 2.4), (8, 54, 1.4)
        ]
        for b in bubbles {
            ctx.circle(b.0, b.1, b.2, Color.white.opacity(0.35))
            ctx.strokePath(Color.white.opacity(0.9), width: 0.5) { p in
                p.addEllipse(in: CGRect(x: b.0 - b.2, y: b.1 - b.2, width: b.2 * 2, height: b.2 * 2))
            }
            ctx.circle(b.0 - b.2 * 0.35, b.1 - b.2 * 0.35, b.2 * 0.28, Color.white.opacity(0.9))
        }
        floorChecker(ctx, a: rgb(0xD8ECF3), b: rgb(0xBFDFEC), grout: rgb(0xA7CFE0).opacity(0.6))
        baseboard(ctx, rgb(0x7DBBD6))
        // cửa sổ tròn kiểu tàu thủy
        let c = CGPoint(x: win.midX, y: win.midY)
        ctx.circle(c.x, c.y, 10.5, rgb(0xE0B866))
        ctx.circle(c.x, c.y, 8.2, rgb(0xBFE5F5))
        var g = ctx
        g.clip(to: Path(ellipseIn: CGRect(x: c.x - 8.2, y: c.y - 8.2, width: 16.4, height: 16.4)))
        g.rect(c.x - 9, c.y + 2, 18, 8, rgb(0x6FB5D6))
        g.strokePath(Color.white.opacity(0.8), width: 0.7) { p in
            p.move(to: CGPoint(x: c.x - 7, y: c.y + 4)); p.addQuadCurve(to: CGPoint(x: c.x - 2, y: c.y + 4), control: CGPoint(x: c.x - 4.5, y: c.y + 2.6))
            p.move(to: CGPoint(x: c.x + 1, y: c.y + 6)); p.addQuadCurve(to: CGPoint(x: c.x + 6, y: c.y + 6), control: CGPoint(x: c.x + 3.5, y: c.y + 4.6))
        }
        g.ellipse(c.x - 5, c.y - 5, 7, 3, Color.white.opacity(0.9))
        ctx.strokePath(Color.white.opacity(0.7), width: 1) { p in
            p.addArc(center: c, radius: 6.5, startAngle: .degrees(200), endAngle: .degrees(250), clockwise: false)
        }
        for i in 0..<8 {
            let a = Double(i) * 45.0 * Double.pi / 180
            ctx.circle(c.x + CGFloat(cos(a)) * 9.4, c.y + CGFloat(sin(a)) * 9.4, 0.55, rgb(0xB48A3E))
        }
    }

    // MARK: - Theme: Đá cẩm thạch

    private static func drawMarble(_ ctx: GraphicsContext) {
        wallTiles(ctx, base: rgb(0xF7F4F1), grout: rgb(0xE4DDD6), w: 25, h: 20.67, from: 0, to: 62)
        let vein = rgb(0xC9C0BA).opacity(0.55)
        ctx.strokePath(vein, width: 0.5) { p in
            p.move(to: CGPoint(x: 2, y: 4)); p.addCurve(to: CGPoint(x: 22, y: 18), control1: CGPoint(x: 10, y: 6), control2: CGPoint(x: 12, y: 16))
            p.move(to: CGPoint(x: 28, y: 30)); p.addCurve(to: CGPoint(x: 48, y: 38), control1: CGPoint(x: 36, y: 26), control2: CGPoint(x: 40, y: 40))
            p.move(to: CGPoint(x: 80, y: 2)); p.addCurve(to: CGPoint(x: 98, y: 16), control1: CGPoint(x: 86, y: 10), control2: CGPoint(x: 92, y: 8))
            p.move(to: CGPoint(x: 102, y: 26)); p.addCurve(to: CGPoint(x: 122, y: 38), control1: CGPoint(x: 110, y: 32), control2: CGPoint(x: 116, y: 28))
            p.move(to: CGPoint(x: 4, y: 46)); p.addCurve(to: CGPoint(x: 22, y: 58), control1: CGPoint(x: 12, y: 44), control2: CGPoint(x: 14, y: 56))
            p.move(to: CGPoint(x: 78, y: 44)); p.addCurve(to: CGPoint(x: 96, y: 56), control1: CGPoint(x: 84, y: 52), control2: CGPoint(x: 90, y: 46))
            p.move(to: CGPoint(x: 54, y: 46)); p.addQuadCurve(to: CGPoint(x: 70, y: 58), control: CGPoint(x: 66, y: 48))
        }
        ctx.strokePath(vein.opacity(0.6), width: 0.3) { p in
            p.move(to: CGPoint(x: 12, y: 8)); p.addLine(to: CGPoint(x: 8, y: 14))
            p.move(to: CGPoint(x: 38, y: 32)); p.addLine(to: CGPoint(x: 36, y: 38))
            p.move(to: CGPoint(x: 110, y: 31)); p.addLine(to: CGPoint(x: 114, y: 36))
        }
        // viền vàng
        ctx.rect(0, 41, 125, 1.6, rgb(0xE2C27A))
        // sàn đá
        ctx.rect(0, 62, 125, 38, rgb(0xEAE5DF))
        ctx.strokePath(rgb(0xD6CEC6), width: 0.6) { p in
            p.move(to: CGPoint(x: 0, y: 76)); p.addLine(to: CGPoint(x: 125, y: 76))
            p.move(to: CGPoint(x: 0, y: 91)); p.addLine(to: CGPoint(x: 125, y: 91))
            for x in [31.0, 62.5, 94.0] as [CGFloat] {
                p.move(to: CGPoint(x: x, y: 62)); p.addLine(to: CGPoint(x: x, y: 76))
            }
            for x in [15.0, 47.0, 78.0, 110.0] as [CGFloat] {
                p.move(to: CGPoint(x: x, y: 76)); p.addLine(to: CGPoint(x: x, y: 91))
            }
            for x in [31.0, 62.5, 94.0] as [CGFloat] {
                p.move(to: CGPoint(x: x, y: 91)); p.addLine(to: CGPoint(x: x, y: 100))
            }
        }
        ctx.strokePath(vein, width: 0.5) { p in
            p.move(to: CGPoint(x: 4, y: 66)); p.addCurve(to: CGPoint(x: 26, y: 72), control1: CGPoint(x: 12, y: 64), control2: CGPoint(x: 16, y: 74))
            p.move(to: CGPoint(x: 52, y: 80)); p.addCurve(to: CGPoint(x: 74, y: 88), control1: CGPoint(x: 60, y: 78), control2: CGPoint(x: 64, y: 90))
            p.move(to: CGPoint(x: 98, y: 64)); p.addQuadCurve(to: CGPoint(x: 120, y: 72), control: CGPoint(x: 110, y: 64))
        }
        baseboard(ctx, rgb(0xDCCFBF))
        ctx.rect(0, 59.5, 125, 0.8, rgb(0xE2C27A))
        // cửa sổ vòm viền vàng
        let r = win
        var arch = Path()
        arch.move(to: CGPoint(x: r.minX, y: r.maxY))
        arch.addLine(to: CGPoint(x: r.minX, y: r.minY + r.width / 2))
        arch.addArc(center: CGPoint(x: r.midX, y: r.minY + r.width / 2), radius: r.width / 2,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        arch.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        arch.closeSubpath()
        ctx.fill(arch, with: .color(rgb(0xE2C27A)))
        let inR = r.width / 2 - 2
        var glassP = Path()
        glassP.move(to: CGPoint(x: r.minX + 2, y: r.maxY - 1))
        glassP.addLine(to: CGPoint(x: r.minX + 2, y: r.minY + r.width / 2))
        glassP.addArc(center: CGPoint(x: r.midX, y: r.minY + r.width / 2), radius: inR,
                      startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        glassP.addLine(to: CGPoint(x: r.maxX - 2, y: r.maxY - 1))
        glassP.closeSubpath()
        ctx.fill(glassP, with: .color(rgb(0xDCEEF6)))
        ctx.ellipse(r.minX + 4, r.minY + 9, 8, 3.2, Color.white.opacity(0.9))
        ctx.rect(r.midX - 0.6, r.minY + 2, 1.2, r.height - 3, rgb(0xE2C27A))
        ctx.rect(r.minX + 2, r.minY + 13, r.width - 4, 1.2, rgb(0xE2C27A))
        ctx.rect(r.minX - 2.5, r.maxY - 1, r.width + 5, 2.6, rgb(0xF4EFEA), radius: 1.3)
        // nến thơm trên bậu
        ctx.rect(r.minX + 1, r.maxY - 5, 4, 4, rgb(0xFFF8EC), radius: 0.8)
        ctx.ellipse(r.minX + 2.3, r.maxY - 8, 1.6, 2.6, Palette.honey)
    }

    // MARK: - Bồn tắm (ô 60, đáy ~94)

    private static func steam(_ ctx: GraphicsContext, _ xs: [CGFloat], top: CGFloat, bottom: CGFloat) {
        ctx.strokePath(Color.white.opacity(0.85), width: 2.4) { p in
            for x in xs {
                p.move(to: CGPoint(x: x, y: bottom))
                p.addCurve(to: CGPoint(x: x, y: top), control1: CGPoint(x: x - 6, y: bottom - (bottom - top) * 0.35),
                           control2: CGPoint(x: x + 6, y: bottom - (bottom - top) * 0.65))
            }
        }
    }

    private static func drawTubBasin(_ ctx: GraphicsContext) {
        let wood = rgb(0xDDB485)
        let woodLine = rgb(0xB98A5C)
        ctx.ellipse(8, 86, 84, 10, Color.black.opacity(0.1))
        steam(ctx, [34, 50, 66], top: 20, bottom: 42)
        // thân chậu tròn
        var body = Path()
        body.move(to: CGPoint(x: 12, y: 52))
        body.addLine(to: CGPoint(x: 16, y: 84))
        body.addQuadCurve(to: CGPoint(x: 84, y: 84), control: CGPoint(x: 50, y: 96))
        body.addLine(to: CGPoint(x: 88, y: 52))
        body.closeSubpath()
        ctx.fill(body, with: .color(wood))
        var g = ctx
        g.clip(to: body)
        g.strokePath(woodLine.opacity(0.5), width: 0.8) { p in
            for x in stride(from: 21.0, to: 85.0, by: 9.0) {
                p.move(to: CGPoint(x: CGFloat(x), y: 50)); p.addLine(to: CGPoint(x: CGFloat(x) + (CGFloat(x) - 50) * 0.06, y: 96))
            }
        }
        // đai
        g.strokePath(rgb(0x8C6B4E), width: 3) { p in
            p.move(to: CGPoint(x: 10, y: 62)); p.addQuadCurve(to: CGPoint(x: 90, y: 62), control: CGPoint(x: 50, y: 70))
            p.move(to: CGPoint(x: 10, y: 80)); p.addQuadCurve(to: CGPoint(x: 90, y: 80), control: CGPoint(x: 50, y: 89))
        }
        g.rect(16, 54, 3, 30, Color.white.opacity(0.25), radius: 1.5)
        // miệng chậu + nước
        ctx.ellipse(10, 44, 80, 16, rgb(0xE9C79C))
        ctx.ellipse(15, 47, 70, 11, rgb(0x9ED8E2))
        ctx.ellipse(26, 48.5, 18, 3.4, Color.white.opacity(0.6))
        ctx.circle(68, 51, 1.5, Color.white.opacity(0.7))
        // khăn nhỏ vắt miệng chậu
        ctx.rect(62, 44, 12, 12, Palette.blush, radius: 2)
        ctx.rect(62, 49, 12, 1.4, Color.white.opacity(0.7))
        // gáo/xô gỗ nhỏ
        ctx.ellipse(76, 89, 20, 5, Color.black.opacity(0.08))
        ctx.rect(78, 74, 16, 17, wood, radius: 3)
        ctx.rect(77, 72, 18, 4, rgb(0xE9C79C), radius: 2)
        ctx.rect(78, 82, 16, 2, rgb(0x8C6B4E))
        ctx.strokePath(rgb(0x8C6B4E), width: 1.6) { p in
            p.move(to: CGPoint(x: 80, y: 73)); p.addQuadCurve(to: CGPoint(x: 92, y: 73), control: CGPoint(x: 86, y: 62))
        }
    }

    private static func drawShower(_ ctx: GraphicsContext) {
        // ống & vòi sen
        ctx.rect(84, 12, 3.4, 60, chrome, radius: 1.7)
        ctx.strokePath(chrome, width: 3.4) { p in
            p.move(to: CGPoint(x: 85.7, y: 13)); p.addQuadCurve(to: CGPoint(x: 72, y: 14), control: CGPoint(x: 84, y: 6))
        }
        ctx.polygon([CGPoint(x: 64, y: 16), CGPoint(x: 78, y: 16), CGPoint(x: 75, y: 13), CGPoint(x: 67, y: 13)], chromeDark)
        ctx.ellipse(63, 15, 16, 4, chrome)
        // giọt nước
        for (i, x) in [65.0, 69.0, 73.0, 77.0].enumerated() {
            let y = 23.0 + Double(i % 2) * 6
            ctx.ellipse(CGFloat(x) - 0.8, CGFloat(y), 1.6, 3, rgb(0x8FCDE6))
            ctx.ellipse(CGFloat(x) - 0.4 + 1.5, CGFloat(y) + 10, 1.6, 3, rgb(0x8FCDE6))
        }
        // bồn đứng (khay)
        ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
        // thanh rèm
        ctx.rect(8, 6, 84, 2.6, chromeDark, radius: 1.3)
        // rèm chấm bi (kéo sang trái)
        var cur = Path()
        cur.move(to: CGPoint(x: 10, y: 8))
        cur.addLine(to: CGPoint(x: 52, y: 8))
        cur.addQuadCurve(to: CGPoint(x: 46, y: 72), control: CGPoint(x: 44, y: 40))
        var x: CGFloat = 46
        while x > 12 {
            cur.addQuadCurve(to: CGPoint(x: x - 7, y: 72), control: CGPoint(x: x - 3.5, y: 76))
            x -= 7
        }
        cur.addLine(to: CGPoint(x: 10, y: 72))
        cur.closeSubpath()
        ctx.fill(cur, with: .color(rgb(0xFFFDF8)))
        var g = ctx
        g.clip(to: cur)
        g.strokePath(rgb(0xE6E0EA), width: 1) { p in
            for fx in [18.0, 27.0, 36.0] as [CGFloat] {
                p.move(to: CGPoint(x: fx, y: 10)); p.addQuadCurve(to: CGPoint(x: fx - 2, y: 72), control: CGPoint(x: fx + 2, y: 40))
            }
        }
        let dots: [Color] = [Palette.blush, rgb(0x8FCDE6), Palette.honey]
        var k = 0
        for row in 0..<7 {
            for col in 0..<5 {
                let dx: CGFloat = row % 2 == 0 ? 0 : 4.5
                g.circle(15 + CGFloat(col) * 9 + dx, 15 + CGFloat(row) * 9, 2, dots[k % 3])
                k += 1
            }
        }
        // khoen treo
        for rx in [12.0, 22.0, 32.0, 42.0, 50.0] as [CGFloat] {
            ctx.strokePath(chromeDark, width: 0.9) { p in p.addEllipse(in: CGRect(x: rx - 1.6, y: 5, width: 3.2, height: 4.4)) }
        }
        // bồn tắm phía dưới
        ctx.rect(6, 66, 88, 6, porcelain, radius: 3)
        ctx.rect(9, 70, 82, 20, porcelain, radius: 8)
        ctx.rect(9, 82, 82, 8, porcelainShade, radius: 6)
        ctx.rect(14, 73, 30, 2, rgb(0x8FCDE6).opacity(0.6), radius: 1)
        ctx.rect(14, 89, 8, 5, chromeDark, radius: 1.5)
        ctx.rect(78, 89, 8, 5, chromeDark, radius: 1.5)
        ctx.rect(12, 67, 30, 1.4, Color.white.opacity(0.9), radius: 0.7)
    }

    private static func clawTubBody(_ ctx: GraphicsContext, color: Color, shade: Color, feet: Bool) {
        ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
        var body = Path()
        body.move(to: CGPoint(x: 8, y: 50))
        body.addCurve(to: CGPoint(x: 30, y: 86), control1: CGPoint(x: 8, y: 74), control2: CGPoint(x: 16, y: 86))
        body.addLine(to: CGPoint(x: 70, y: 86))
        body.addCurve(to: CGPoint(x: 92, y: 50), control1: CGPoint(x: 84, y: 86), control2: CGPoint(x: 92, y: 74))
        body.closeSubpath()
        if feet {
            for fx in [22.0, 70.0] as [CGFloat] {
                ctx.rect(fx, 82, 8, 9, rgb(0xE2C27A), radius: 3)
                ctx.ellipse(fx - 1.5, 89, 11, 5, rgb(0xD4AE5E))
            }
        }
        ctx.fill(body, with: .color(color))
        var g = ctx
        g.clip(to: body)
        g.ellipse(4, 72, 92, 24, shade)
        g.strokePath(Color.white.opacity(0.8), width: 2.4) { p in
            p.move(to: CGPoint(x: 16, y: 56)); p.addQuadCurve(to: CGPoint(x: 24, y: 76), control: CGPoint(x: 16, y: 70))
        }
        ctx.rect(4, 46, 92, 7, color, radius: 3.5)
        ctx.rect(8, 47, 84, 2, shade.opacity(0.8), radius: 1)
    }

    private static func drawClawTub(_ ctx: GraphicsContext) {
        // vòi
        ctx.rect(83, 30, 3.4, 18, chrome, radius: 1.7)
        ctx.strokePath(chrome, width: 3.4) { p in
            p.move(to: CGPoint(x: 84.7, y: 31)); p.addQuadCurve(to: CGPoint(x: 74, y: 36), control: CGPoint(x: 82, y: 24))
        }
        ctx.circle(80, 40, 2.4, chromeDark)
        ctx.circle(90, 40, 2.4, chromeDark)
        clawTubBody(ctx, color: porcelain, shade: porcelainShade, feet: true)
        // vài bong bóng nhỏ
        ctx.circle(30, 43, 4, Color.white)
        ctx.circle(37, 41, 5, Color.white)
        ctx.circle(44, 44, 3.4, Color.white)
        ctx.strokePath(rgb(0xBFE3EF), width: 0.8) { p in
            p.addEllipse(in: CGRect(x: 26, y: 39, width: 8, height: 8))
            p.addEllipse(in: CGRect(x: 32, y: 36, width: 10, height: 10))
        }
        ctx.strokePath(rgb(0xA9D7E6), width: 0.8) { p in
            p.addEllipse(in: CGRect(x: 48, y: 28, width: 5, height: 5))
        }
    }

    private static func drawBubbleTub(_ ctx: GraphicsContext) {
        let pink = rgb(0xF7C6D3)
        let pinkShade = rgb(0xEBA9BC)
        clawTubBody(ctx, color: pink, shade: pinkShade, feet: true)
        // bọt tràn
        let foam: [(CGFloat, CGFloat, CGFloat)] = [
            (10, 46, 7), (20, 40, 9), (32, 36, 10), (46, 34, 11), (60, 36, 10), (72, 39, 9), (84, 44, 8), (92, 48, 5),
            (26, 46, 7), (40, 44, 8), (54, 44, 8), (68, 46, 7), (40, 28, 6), (56, 26, 7)
        ]
        for f in foam {
            ctx.circle(f.0, f.1, f.2, rgb(0xFFFFFF))
        }
        // bọt chảy xuống thành bồn
        ctx.rect(6, 48, 8, 16, Color.white, radius: 4)
        ctx.circle(10, 66, 4, Color.white)
        ctx.rect(84, 48, 7, 10, Color.white, radius: 3.5)
        ctx.circle(87.5, 59, 3.5, Color.white)
        ctx.rect(56, 50, 6, 8, Color.white, radius: 3)
        // bóng nhẹ trên bọt
        for f in [(32.0, 36.0, 10.0), (60.0, 36.0, 10.0), (20.0, 40.0, 9.0)] as [(CGFloat, CGFloat, CGFloat)] {
            ctx.circle(f.0 + f.2 * 0.25, f.1 + f.2 * 0.3, f.2 * 0.45, rgb(0xEAF4F8))
        }
        // bong bóng bay
        let bubbles: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (18, 18, 5, rgb(0xBFE3EF)), (32, 8, 3.4, rgb(0xF4B8C8)), (74, 16, 6, rgb(0xCDBDF0)),
            (88, 28, 3.6, rgb(0xBFE3EF)), (60, 10, 2.6, rgb(0xF6D58A))
        ]
        for b in bubbles {
            ctx.circle(b.0, b.1, b.2, b.3.opacity(0.3))
            ctx.strokePath(b.3, width: 1) { p in
                p.addEllipse(in: CGRect(x: b.0 - b.2, y: b.1 - b.2, width: b.2 * 2, height: b.2 * 2))
            }
            ctx.circle(b.0 - b.2 * 0.35, b.1 - b.2 * 0.35, b.2 * 0.3, Color.white.opacity(0.9))
        }
        // vịt nhỏ trên bọt
        ctx.ellipse(66, 25, 14, 10, duckYellow)
        ctx.circle(70, 23, 5, duckYellow)
        ctx.ellipse(64.5, 22.6, 4, 2.4, beak)
        ctx.circle(69, 21.8, 0.9, Palette.catInk)
    }

    // MARK: - Bồn rửa (ô 44, đáy ~94)

    private static func drawSink(_ ctx: GraphicsContext, basin: Color, shade: Color) {
        ctx.ellipse(24, 89, 52, 8, Color.black.opacity(0.1))
        // chân bồn
        ctx.polygon([CGPoint(x: 41, y: 58), CGPoint(x: 59, y: 58), CGPoint(x: 63, y: 92), CGPoint(x: 37, y: 92)], basin)
        ctx.polygon([CGPoint(x: 52, y: 58), CGPoint(x: 59, y: 58), CGPoint(x: 63, y: 92), CGPoint(x: 55, y: 92)], shade.opacity(0.7))
        ctx.rect(35, 89, 30, 4, shade, radius: 2)
        // vòi
        ctx.rect(46.5, 33, 7, 12, chrome, radius: 2)
        ctx.rect(42, 31, 16, 3.4, chromeDark, radius: 1.7)
        ctx.rect(49, 37, 2, 5, Color.white.opacity(0.6), radius: 1)
        // chậu
        ctx.rect(14, 44, 72, 6, basin, radius: 3)
        var bowl = Path()
        bowl.move(to: CGPoint(x: 17, y: 49))
        bowl.addQuadCurve(to: CGPoint(x: 83, y: 49), control: CGPoint(x: 50, y: 76))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(basin))
        var g = ctx
        g.clip(to: bowl)
        g.ellipse(20, 54, 60, 16, shade)
        ctx.rect(18, 45, 22, 1.6, Color.white.opacity(0.9), radius: 0.8)
        // xà phòng
        ctx.ellipse(20, 40, 12, 5.4, Palette.blush)
        ctx.ellipse(22, 40.6, 5, 1.6, Color.white.opacity(0.7))
        // cốc & bàn chải
        ctx.rect(72, 27, 2.4, 14, Palette.blush, radius: 1.2)
        ctx.rect(76.5, 25, 2.4, 16, rgb(0x8FCDE6), radius: 1.2)
        ctx.rect(71.6, 25.5, 3.2, 4, Color.white, radius: 1)
        ctx.rect(76.1, 23.5, 3.2, 4, Color.white, radius: 1)
        ctx.rect(68, 33, 16, 11.5, rgb(0xA9D7DA), radius: 2.5)
        ctx.rect(70, 35, 2, 7, Color.white.opacity(0.6), radius: 1)
    }

    private static func drawRoundMirror(_ ctx: GraphicsContext) {
        ctx.circle(50, 16, 15.5, Palette.wood)
        ctx.circle(50, 16, 12, rgb(0xDDEFF5))
        ctx.strokePath(Color.white.opacity(0.85), width: 2) { p in
            p.move(to: CGPoint(x: 42, y: 18)); p.addLine(to: CGPoint(x: 49, y: 8))
            p.move(to: CGPoint(x: 46, y: 21)); p.addLine(to: CGPoint(x: 48, y: 18.4))
        }
        ctx.strokePath(Palette.woodDark.opacity(0.4), width: 0.8) { p in
            p.addEllipse(in: CGRect(x: 36, y: 2, width: 28, height: 28))
        }
        ctx.circle(50, 0.8, 1.4, Palette.woodDark)
    }

    private static func drawShellMirror(_ ctx: GraphicsContext) {
        // vỏ sò hình quạt
        let c = CGPoint(x: 50, y: 32)
        var shell = Path()
        shell.move(to: c)
        let n = 7
        for i in 0...n {
            let a = Double.pi + Double(i) / Double(n) * Double.pi
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * 28, y: c.y + CGFloat(sin(a)) * 28)
            if i == 0 {
                shell.addLine(to: pt)
            } else {
                let mid = Double.pi + (Double(i) - 0.5) / Double(n) * Double.pi
                let ctrl = CGPoint(x: c.x + CGFloat(cos(mid)) * 33, y: c.y + CGFloat(sin(mid)) * 33)
                shell.addQuadCurve(to: pt, control: ctrl)
            }
        }
        shell.closeSubpath()
        ctx.fill(shell, with: .color(rgb(0xF7C3C3)))
        ctx.strokePath(rgb(0xEC9FA6), width: 1) { p in
            for i in 1..<n {
                let a = Double.pi + Double(i) / Double(n) * Double.pi
                p.move(to: c)
                p.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * 27, y: c.y + CGFloat(sin(a)) * 27))
            }
        }
        // gương bên trong
        var mirror = Path()
        mirror.move(to: CGPoint(x: c.x - 19, y: c.y - 0.5))
        mirror.addArc(center: c, radius: 19, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        mirror.closeSubpath()
        ctx.fill(mirror, with: .color(rgb(0xE2F1F7)))
        ctx.strokePath(Color.white.opacity(0.85), width: 1.8) { p in
            p.move(to: CGPoint(x: 38, y: 28)); p.addLine(to: CGPoint(x: 45, y: 18))
            p.move(to: CGPoint(x: 43, y: 29)); p.addLine(to: CGPoint(x: 45, y: 26.4))
        }
        // ngọc trai
        ctx.circle(50, 33.5, 3.4, rgb(0xFFF8F2))
        ctx.circle(49, 32.5, 1.1, Color.white)
        ctx.draw(Text("✦").font(.system(size: 6)).foregroundColor(rgb(0xF2A7BC)), at: CGPoint(x: 82, y: 8))
    }

    private static func drawShellSink(_ ctx: GraphicsContext) {
        let basin = rgb(0xFFF4EE)
        let shade = rgb(0xF6D3CF)
        ctx.ellipse(24, 89, 52, 8, Color.black.opacity(0.1))
        ctx.polygon([CGPoint(x: 41, y: 58), CGPoint(x: 59, y: 58), CGPoint(x: 63, y: 92), CGPoint(x: 37, y: 92)], basin)
        ctx.polygon([CGPoint(x: 52, y: 58), CGPoint(x: 59, y: 58), CGPoint(x: 63, y: 92), CGPoint(x: 55, y: 92)], shade.opacity(0.7))
        ctx.rect(35, 89, 30, 4, shade, radius: 2)
        // vòi vàng
        ctx.rect(46.5, 36, 7, 9, rgb(0xE2C27A), radius: 2)
        ctx.rect(43, 35, 14, 3, rgb(0xD4AE5E), radius: 1.5)
        // chậu vỏ sò mép lượn
        var bowl = Path()
        bowl.move(to: CGPoint(x: 14, y: 46))
        var x: CGFloat = 14
        while x < 86 {
            bowl.addQuadCurve(to: CGPoint(x: x + 9, y: 46), control: CGPoint(x: x + 4.5, y: 41))
            x += 9
        }
        bowl.addQuadCurve(to: CGPoint(x: 14, y: 46), control: CGPoint(x: 50, y: 82))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(rgb(0xF9D2D0)))
        var g = ctx
        g.clip(to: bowl)
        g.strokePath(rgb(0xEFAFB2), width: 0.9) { p in
            for i in 0..<7 {
                let tx = 20 + CGFloat(i) * 10
                p.move(to: CGPoint(x: tx, y: 46)); p.addLine(to: CGPoint(x: 50 + (tx - 50) * 0.3, y: 68))
            }
        }
        ctx.rect(18, 45.2, 20, 1.4, Color.white.opacity(0.8), radius: 0.7)
        // sao biển nhỏ
        ctx.draw(Text("★").font(.system(size: 9)).foregroundColor(rgb(0xF2A57E)), at: CGPoint(x: 78, y: 38))
        ctx.circle(22, 41, 2.2, rgb(0xFFF8F2))
        ctx.circle(26.5, 42, 1.6, rgb(0xFFF8F2))
    }

    // MARK: - Kệ treo tường (ô 30)

    private static func shelfBoard(_ ctx: GraphicsContext) {
        ctx.polygon([CGPoint(x: 18, y: 82), CGPoint(x: 26, y: 82), CGPoint(x: 18, y: 92)], Palette.woodDark)
        ctx.polygon([CGPoint(x: 82, y: 82), CGPoint(x: 74, y: 82), CGPoint(x: 82, y: 92)], Palette.woodDark)
        ctx.rect(8, 76, 84, 6, Palette.wood, radius: 2)
        ctx.rect(9, 76.5, 82, 1.4, Color.white.opacity(0.35), radius: 0.7)
    }

    private static func towel(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color, _ stripe: Color) {
        ctx.rect(x, y, w, h, c, radius: h * 0.4)
        ctx.rect(x + 4, y + h * 0.55, w - 8, 2, stripe, radius: 1)
        ctx.rect(x + w - 10, y + 1.5, 7, h - 3, Color.white.opacity(0.18), radius: 3)
        ctx.ellipse(x - 1, y + 1, h * 0.7, h - 2, c)
    }

    private static func drawTowelShelf(_ ctx: GraphicsContext) {
        shelfBoard(ctx)
        towel(ctx, 18, 62, 64, 14, rgb(0x9FD3D6), Color.white.opacity(0.75))
        towel(ctx, 21, 48, 58, 14, Palette.blush, Color.white.opacity(0.75))
        towel(ctx, 24, 34, 52, 14, rgb(0xF6D58A), Color.white.opacity(0.75))
        ctx.heart(center: CGPoint(x: 68, y: 40.5), size: 5, Color.white.opacity(0.85))
        ctx.draw(Text("✦").font(.system(size: 7)).foregroundColor(Palette.honey), at: CGPoint(x: 84, y: 30))
    }

    private static func drawBottleShelf(_ ctx: GraphicsContext) {
        shelfBoard(ctx)
        // chai dầu gội có vòi bơm
        ctx.rect(14, 46, 20, 30, rgb(0x9FD3D6), radius: 6)
        ctx.rect(20.5, 38, 7, 9, rgb(0xFFFFFF), radius: 1.5)
        ctx.rect(20.5, 36, 13, 3, rgb(0xFFFFFF), radius: 1.5)
        ctx.rect(17, 55, 14, 12, Color.white.opacity(0.8), radius: 2)
        ctx.circle(24, 61, 2.4, rgb(0x6FB5D6))
        ctx.rect(16, 49, 2.4, 22, Color.white.opacity(0.4), radius: 1.2)
        // chai sữa tắm
        ctx.rect(38, 52, 18, 24, Palette.blush, radius: 5)
        ctx.rect(42, 45, 10, 8, rgb(0xE88AA5), radius: 2)
        ctx.heart(center: CGPoint(x: 47, y: 64), size: 7, Color.white.opacity(0.85))
        ctx.rect(40, 55, 2.2, 16, Color.white.opacity(0.4), radius: 1.1)
        // nến thơm
        ctx.circle(71, 54, 10, rgb(0xFFD98A).opacity(0.25))
        ctx.rect(61, 60, 20, 16, rgb(0xFFF6E6), radius: 3)
        ctx.rect(61, 66, 20, 4, Palette.lavender.opacity(0.5))
        ctx.rect(70.4, 55, 1.4, 5, Palette.catInk)
        ctx.ellipse(68, 46, 6, 10, Palette.honey)
        ctx.ellipse(69.5, 50, 3, 5, Color.white.opacity(0.8))
    }

    private static func drawFernShelf(_ ctx: GraphicsContext) {
        shelfBoard(ctx)
        // chậu
        ctx.rect(32, 56, 36, 20, rgb(0xFFFFFF), radius: 5)
        ctx.rect(30, 54, 40, 6, rgb(0xF2F6F7), radius: 3)
        ctx.rect(36, 66, 28, 2, rgb(0x9FD3D6), radius: 1)
        // lá dương xỉ rủ
        func frond(_ from: CGPoint, _ to: CGPoint, _ ctrl: CGPoint) {
            ctx.strokePath(rgb(0x5E8C61), width: 1.2) { p in
                p.move(to: from); p.addQuadCurve(to: to, control: ctrl)
            }
            for i in 1...6 {
                let t = CGFloat(i) / 7
                let x = (1 - t) * (1 - t) * from.x + 2 * (1 - t) * t * ctrl.x + t * t * to.x
                let y = (1 - t) * (1 - t) * from.y + 2 * (1 - t) * t * ctrl.y + t * t * to.y
                let s = 5.5 * (1 - t * 0.6)
                ctx.ellipse(x - s, y - s * 0.4, s * 0.9, s * 0.8, Palette.sage)
                ctx.ellipse(x + s * 0.1, y - s * 0.4, s * 0.9, s * 0.8, rgb(0x8DB88F))
            }
        }
        frond(CGPoint(x: 42, y: 54), CGPoint(x: 12, y: 86), CGPoint(x: 18, y: 50))
        frond(CGPoint(x: 58, y: 54), CGPoint(x: 90, y: 88), CGPoint(x: 84, y: 50))
        frond(CGPoint(x: 46, y: 54), CGPoint(x: 30, y: 18), CGPoint(x: 34, y: 40))
        frond(CGPoint(x: 54, y: 54), CGPoint(x: 72, y: 20), CGPoint(x: 68, y: 40))
        frond(CGPoint(x: 50, y: 54), CGPoint(x: 52, y: 12), CGPoint(x: 48, y: 30))
        // giọt nước
        ctx.ellipse(84, 36, 3, 4.4, rgb(0x8FCDE6))
        ctx.ellipse(16, 30, 2.4, 3.6, rgb(0x8FCDE6))
    }

    // MARK: - Thảm (ô 40)

    private static func drawMatBasic(_ ctx: GraphicsContext) {
        let main = rgb(0xBFE3E6)
        ctx.ellipse(6, 72, 88, 24, Color.black.opacity(0.06))
        // viền bông
        var x: CGFloat = 12
        while x <= 84 {
            ctx.circle(x, 70, 3, main)
            ctx.circle(x, 92, 3, main)
            x += 6
        }
        ctx.rect(8, 68, 84, 26, main, radius: 10)
        ctx.rect(14, 72, 72, 18, rgb(0xDDF1F1), radius: 7)
        ctx.rect(14, 79.5, 72, 3, rgb(0x9FD3D6), radius: 1.5)
        ctx.heart(center: CGPoint(x: 50, y: 80.5), size: 7, Color.white)
    }

    private static func drawMatDuck(_ ctx: GraphicsContext) {
        ctx.ellipse(8, 76, 84, 20, Color.black.opacity(0.06))
        // thân
        var body = Path()
        body.move(to: CGPoint(x: 10, y: 76))
        body.addQuadCurve(to: CGPoint(x: 20, y: 70), control: CGPoint(x: 10, y: 66))
        body.addQuadCurve(to: CGPoint(x: 66, y: 72), control: CGPoint(x: 44, y: 74))
        body.addQuadCurve(to: CGPoint(x: 84, y: 84), control: CGPoint(x: 86, y: 70))
        body.addQuadCurve(to: CGPoint(x: 20, y: 93), control: CGPoint(x: 70, y: 96))
        body.addQuadCurve(to: CGPoint(x: 10, y: 76), control: CGPoint(x: 8, y: 90))
        body.closeSubpath()
        ctx.fill(body, with: .color(duckYellow))
        // đầu
        ctx.ellipse(56, 58, 30, 24, duckYellow)
        ctx.polygon([CGPoint(x: 84, y: 66), CGPoint(x: 96, y: 70), CGPoint(x: 84, y: 74)], beak)
        ctx.circle(76, 66, 2, Palette.catInk)
        ctx.circle(75.4, 65.3, 0.7, Color.white)
        ctx.ellipse(66, 70, 7, 3.6, Palette.blush.opacity(0.8))
        // cánh
        ctx.strokePath(duckShade, width: 2) { p in
            p.move(to: CGPoint(x: 30, y: 80)); p.addQuadCurve(to: CGPoint(x: 54, y: 82), control: CGPoint(x: 42, y: 90))
        }
        ctx.strokePath(Color.white.opacity(0.6), width: 2) { p in
            p.move(to: CGPoint(x: 16, y: 76)); p.addQuadCurve(to: CGPoint(x: 26, y: 72), control: CGPoint(x: 18, y: 72))
        }
    }

    private static func drawMatWave(_ ctx: GraphicsContext) {
        ctx.ellipse(6, 72, 88, 24, Color.black.opacity(0.06))
        let mat = Path(roundedRect: CGRect(x: 8, y: 68, width: 84, height: 26), cornerRadius: 12)
        ctx.fill(mat, with: .color(rgb(0x8CC8E0)))
        var g = ctx
        g.clip(to: mat)
        func waveLine(_ y: CGFloat, _ color: Color, _ w: CGFloat) {
            g.strokePath(color, width: w) { p in
                p.move(to: CGPoint(x: 4, y: y))
                var x: CGFloat = 4
                while x < 96 {
                    p.addQuadCurve(to: CGPoint(x: x + 6, y: y), control: CGPoint(x: x + 3, y: y - 3.4))
                    p.addQuadCurve(to: CGPoint(x: x + 12, y: y), control: CGPoint(x: x + 9, y: y + 3.4))
                    x += 12
                }
            }
        }
        g.rect(8, 84, 84, 12, rgb(0x6FB5D6))
        waveLine(75, Color.white.opacity(0.85), 1.8)
        waveLine(84, rgb(0xDDF1F8), 1.8)
        g.circle(80, 74, 1.6, Color.white.opacity(0.85))
        g.circle(22, 89, 1.4, Color.white.opacity(0.85))
    }

    // MARK: - Đồ chơi (ô 20)

    private static func drawRubberDuck(_ ctx: GraphicsContext) {
        ctx.ellipse(14, 86, 72, 10, Color.black.opacity(0.1))
        // thân
        var body = Path()
        body.move(to: CGPoint(x: 10, y: 60))
        body.addQuadCurve(to: CGPoint(x: 30, y: 54), control: CGPoint(x: 14, y: 50))
        body.addLine(to: CGPoint(x: 70, y: 56))
        body.addQuadCurve(to: CGPoint(x: 82, y: 76), control: CGPoint(x: 86, y: 60))
        body.addQuadCurve(to: CGPoint(x: 22, y: 90), control: CGPoint(x: 70, y: 94))
        body.addQuadCurve(to: CGPoint(x: 10, y: 60), control: CGPoint(x: 8, y: 84))
        body.closeSubpath()
        ctx.fill(body, with: .color(duckYellow))
        // đầu
        ctx.circle(56, 38, 20, duckYellow)
        ctx.ellipse(70, 40, 22, 10, beak)
        ctx.ellipse(72, 44, 16, 4, rgb(0xE07F45))
        ctx.circle(62, 32, 3.2, Palette.catInk)
        ctx.circle(61, 31, 1.1, Color.white)
        ctx.ellipse(52, 42, 8, 4.4, Palette.blush.opacity(0.85))
        // cánh
        ctx.strokePath(duckShade, width: 3) { p in
            p.move(to: CGPoint(x: 28, y: 66)); p.addQuadCurve(to: CGPoint(x: 56, y: 72), control: CGPoint(x: 40, y: 82))
        }
        ctx.strokePath(Color.white.opacity(0.65), width: 3) { p in
            p.move(to: CGPoint(x: 44, y: 28)); p.addQuadCurve(to: CGPoint(x: 52, y: 22), control: CGPoint(x: 46, y: 23))
        }
        ctx.draw(Text("♪").font(.system(size: 14)).foregroundColor(Palette.lavender), at: CGPoint(x: 26, y: 26))
    }

    private static func drawBoat(_ ctx: GraphicsContext) {
        ctx.ellipse(6, 80, 88, 14, rgb(0x8FCDE6).opacity(0.5))
        ctx.strokePath(Color.white.opacity(0.85), width: 1.6) { p in
            p.move(to: CGPoint(x: 14, y: 87)); p.addQuadCurve(to: CGPoint(x: 26, y: 87), control: CGPoint(x: 20, y: 84))
            p.move(to: CGPoint(x: 72, y: 88)); p.addQuadCurve(to: CGPoint(x: 86, y: 88), control: CGPoint(x: 79, y: 85))
        }
        // buồm (mũ giấy)
        ctx.polygon([CGPoint(x: 50, y: 14), CGPoint(x: 26, y: 60), CGPoint(x: 74, y: 60)], rgb(0xFFFDF8))
        ctx.polygon([CGPoint(x: 50, y: 14), CGPoint(x: 50, y: 60), CGPoint(x: 74, y: 60)], rgb(0xE9EEF2))
        // thân thuyền
        ctx.polygon([CGPoint(x: 8, y: 58), CGPoint(x: 92, y: 58), CGPoint(x: 76, y: 84), CGPoint(x: 24, y: 84)], rgb(0xFFFFFF))
        ctx.polygon([CGPoint(x: 8, y: 58), CGPoint(x: 30, y: 58), CGPoint(x: 38, y: 84), CGPoint(x: 24, y: 84)], rgb(0xEEF2F5))
        ctx.polygon([CGPoint(x: 92, y: 58), CGPoint(x: 70, y: 58), CGPoint(x: 62, y: 84), CGPoint(x: 76, y: 84)], rgb(0xEEF2F5))
        ctx.strokePath(rgb(0xD5DDE3), width: 0.9) { p in
            p.move(to: CGPoint(x: 50, y: 16)); p.addLine(to: CGPoint(x: 50, y: 58))
        }
        ctx.heart(center: CGPoint(x: 50, y: 70), size: 8, Palette.blush)
        // cờ nhỏ
        ctx.strokePath(Palette.woodDark, width: 1.2) { p in
            p.move(to: CGPoint(x: 50, y: 14)); p.addLine(to: CGPoint(x: 50, y: 4))
        }
        ctx.polygon([CGPoint(x: 50, y: 4), CGPoint(x: 62, y: 7), CGPoint(x: 50, y: 10)], Palette.peach)
    }

    private static func drawBubbles(_ ctx: GraphicsContext) {
        // lọ nước xà phòng + que thổi
        ctx.ellipse(10, 88, 34, 6, Color.black.opacity(0.1))
        ctx.rect(14, 62, 24, 28, rgb(0xCDBDF0), radius: 5)
        ctx.rect(18, 56, 16, 7, rgb(0x8D78CF), radius: 2)
        ctx.rect(17, 66, 3, 18, Color.white.opacity(0.5), radius: 1.5)
        ctx.heart(center: CGPoint(x: 26, y: 76), size: 7, Color.white.opacity(0.85))
        ctx.strokePath(rgb(0xF29A5B), width: 2) { p in
            p.move(to: CGPoint(x: 36, y: 58)); p.addLine(to: CGPoint(x: 52, y: 44))
            p.addEllipse(in: CGRect(x: 50, y: 34, width: 11, height: 11))
        }
        let bubbles: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (70, 30, 14, rgb(0xBFE3EF)), (44, 16, 9, rgb(0xF4B8C8)), (84, 62, 9, rgb(0xCDBDF0)),
            (24, 34, 6, rgb(0xF6D58A)), (66, 80, 6, rgb(0xBFE3EF)), (88, 10, 5, rgb(0xF4B8C8))
        ]
        for b in bubbles {
            ctx.circle(b.0, b.1, b.2, b.3.opacity(0.3))
            ctx.strokePath(b.3, width: 1.6) { p in
                p.addEllipse(in: CGRect(x: b.0 - b.2, y: b.1 - b.2, width: b.2 * 2, height: b.2 * 2))
            }
            ctx.circle(b.0 - b.2 * 0.38, b.1 - b.2 * 0.38, b.2 * 0.26, Color.white.opacity(0.9))
        }
    }

    private static func drawWhale(_ ctx: GraphicsContext) {
        let blue = rgb(0x84B8E6)
        let belly = rgb(0xDDEEFA)
        ctx.ellipse(10, 86, 80, 10, Color.black.opacity(0.1))
        // tia nước
        ctx.strokePath(rgb(0x8FCDE6), width: 2.6) { p in
            p.move(to: CGPoint(x: 40, y: 40)); p.addLine(to: CGPoint(x: 40, y: 24))
            p.move(to: CGPoint(x: 40, y: 26)); p.addQuadCurve(to: CGPoint(x: 28, y: 22), control: CGPoint(x: 32, y: 14))
            p.move(to: CGPoint(x: 40, y: 26)); p.addQuadCurve(to: CGPoint(x: 52, y: 22), control: CGPoint(x: 48, y: 14))
        }
        ctx.circle(26, 26, 2.2, rgb(0x8FCDE6))
        ctx.circle(54, 26, 2.2, rgb(0x8FCDE6))
        ctx.circle(40, 12, 2.6, rgb(0x8FCDE6))
        // đuôi
        ctx.polygon([CGPoint(x: 72, y: 70), CGPoint(x: 86, y: 48), CGPoint(x: 80, y: 66), CGPoint(x: 96, y: 54), CGPoint(x: 84, y: 76)], blue)
        // thân
        var body = Path()
        body.move(to: CGPoint(x: 10, y: 70))
        body.addCurve(to: CGPoint(x: 78, y: 70), control1: CGPoint(x: 8, y: 36), control2: CGPoint(x: 70, y: 36))
        body.addQuadCurve(to: CGPoint(x: 10, y: 70), control: CGPoint(x: 50, y: 98))
        body.closeSubpath()
        ctx.fill(body, with: .color(blue))
        var g = ctx
        g.clip(to: body)
        g.ellipse(4, 70, 70, 30, belly)
        g.strokePath(rgb(0xB9D8F1), width: 1) { p in
            p.move(to: CGPoint(x: 20, y: 78)); p.addLine(to: CGPoint(x: 60, y: 78))
            p.move(to: CGPoint(x: 24, y: 84)); p.addLine(to: CGPoint(x: 56, y: 84))
        }
        ctx.circle(26, 62, 2.6, Palette.catInk)
        ctx.circle(25.2, 61.2, 0.9, Color.white)
        ctx.ellipse(28, 67, 8, 4, Palette.blush.opacity(0.85))
        ctx.strokePath(Palette.catInk, width: 1.2) { p in
            p.move(to: CGPoint(x: 16, y: 70)); p.addQuadCurve(to: CGPoint(x: 22, y: 70), control: CGPoint(x: 19, y: 73))
        }
        ctx.strokePath(Color.white.opacity(0.6), width: 2.4) { p in
            p.move(to: CGPoint(x: 40, y: 48)); p.addQuadCurve(to: CGPoint(x: 56, y: 48), control: CGPoint(x: 48, y: 45))
        }
        // vây
        ctx.ellipse(44, 74, 12, 7, rgb(0x6FA2D2))
    }
}

// MARK: - Đồ thêm (bộ 2)

extension BathArt {
    fileprivate static func drawMore(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        case "bathTheme.hex": drawHoneycomb(ctx)
        case "bathTheme.onsen": drawOnsen(ctx)
        case "tub.shell": drawShellTub(ctx)
        case "tub.duck": drawDuckTub(ctx)
        case "tub.pool": drawPool(ctx)
        case "sink.vanity": drawVanitySink(ctx)
        case "sink.duck": drawDuckSink(ctx)
        case "sink.cloud": drawCloudSink(ctx)
        case "bathShelf.candles": drawCandleShelf(ctx)
        case "bathShelf.duckies": drawDuckShelf(ctx)
        case "bathShelf.macrame": drawMacrame(ctx)
        case "bathMat.whale": drawMatWhale(ctx)
        case "bathMat.cloud": drawMatCloud(ctx)
        case "bathMat.pebbles": drawMatPebbles(ctx)
        case "bathToy.ducklings": drawDucklings(ctx)
        case "bathToy.tugboat": drawTugboat(ctx)
        case "bathToy.sub": drawSubmarine(ctx)
        default: return false
        }
        return true
    }

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    private static let ink = Palette.catInk
    private static let water = rgb(0x9ED8E2)

    /// Vịt cao su nhỏ: cx là giữa thân, base là đáy, s là tỉ lệ (s = 1 rộng khoảng 38).
    private static func duck(_ ctx: GraphicsContext, _ cx: CGFloat, _ base: CGFloat, _ s: CGFloat,
                             body: Color = duckYellow, shade: Color = duckShade) {
        ctx.polygon([pt(cx - 14 * s, base - 11 * s), pt(cx - 19 * s, base - 19 * s), pt(cx - 9 * s, base - 14 * s)], body)
        ctx.ellipse(cx - 15 * s, base - 16 * s, 30 * s, 16 * s, body)
        ctx.circle(cx + 6 * s, base - 20 * s, 8 * s, body)
        ctx.ellipse(cx + 11 * s, base - 21 * s, 8 * s, 4.4 * s, beak)
        ctx.circle(cx + 8 * s, base - 22.5 * s, 1.4 * s, ink)
        ctx.circle(cx + 7.6 * s, base - 23 * s, 0.5 * s, Color.white)
        ctx.ellipse(cx + 1.5 * s, base - 19.5 * s, 4 * s, 2.2 * s, Palette.blush.opacity(0.9))
        ctx.strokePath(shade, width: 1.8 * s) { p in
            p.move(to: pt(cx - 8 * s, base - 10 * s)); p.addQuadCurve(to: pt(cx + 3 * s, base - 9 * s), control: pt(cx - 3 * s, base - 4 * s))
        }
        ctx.ellipse(cx + 1 * s, base - 26 * s, 4 * s, 2.4 * s, Color.white.opacity(0.55))
    }

    /// Ngôi sao năm cánh nhỏ.
    private static func star(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        var pts: [CGPoint] = []
        for i in 0..<10 {
            let a = Double(i) * Double.pi / 5 - Double.pi / 2
            let rr = i % 2 == 0 ? r : r * 0.5
            pts.append(pt(cx + rr * CGFloat(cos(a)), cy + rr * CGFloat(sin(a))))
        }
        ctx.polygon(pts, color)
    }

    // MARK: Theme: tổ ong

    private static func drawHoneycomb(_ scene: GraphicsContext) {
        var ctx = scene
        ctx.clip(to: Path(CGRect(x: 0, y: 0, width: 125, height: 100)))
        ctx.rect(0, 0, 125, 62, rgb(0xFFF5DC))
        let r: CGFloat = 5
        let w = r * 1.732
        for row in 0..<9 {
            for col in 0..<16 {
                let cx = CGFloat(col) * w + (row % 2 == 0 ? 0 : w / 2)
                let cy = CGFloat(row) * r * 1.5 + 2
                var pts: [CGPoint] = []
                for k in 0..<6 {
                    let a = Double(k) * Double.pi / 3 + Double.pi / 6
                    pts.append(pt(cx + (r - 0.4) * CGFloat(cos(a)), cy + (r - 0.4) * CGFloat(sin(a))))
                }
                if (row * 5 + col * 3) % 11 == 0 {
                    ctx.polygon(pts, rgb(0xFBE3A2))
                } else if (row * 7 + col) % 13 == 0 {
                    ctx.polygon(pts, rgb(0xFFFBEF))
                }
                ctx.strokePath(rgb(0xF0DAA0), width: 0.7) { p in
                    p.addLines(pts); p.closeSubpath()
                }
            }
        }
        band(ctx, y: 38.4, rgb(0xF6D58A), dot: Color.white.opacity(0.85))
        floorChecker(ctx, a: rgb(0xFFFBF0), b: rgb(0xF7E8C3), grout: rgb(0xEBD6A6).opacity(0.6))
        baseboard(ctx, rgb(0xEFC977))
        squareWindow(ctx, frame: rgb(0xFFFFFF), sky: rgb(0xCDE9F5), sill: rgb(0xFFFBF0))
        // Ong nhỏ và đường bay
        ctx.strokePath(rgb(0xD9B66A).opacity(0.7), width: 0.6) { p in
            for (a, b, c) in [(pt(80, 14), pt(96, 4), pt(104, 18)), (pt(100, 34), pt(112, 44), pt(118, 28))] {
                var t: CGFloat = 0
                while t < 1 {
                    let u = 1 - t, v = min(1, t + 0.06), uv = 1 - v
                    p.move(to: pt(u * u * a.x + 2 * u * t * b.x + t * t * c.x, u * u * a.y + 2 * u * t * b.y + t * t * c.y))
                    p.addLine(to: pt(uv * uv * a.x + 2 * uv * v * b.x + v * v * c.x, uv * uv * a.y + 2 * uv * v * b.y + v * v * c.y))
                    t += 0.14
                }
            }
        }
        for (x, y) in [(CGFloat(106), CGFloat(18)), (CGFloat(119), CGFloat(27))] {
            ctx.ellipse(x - 2.2, y - 4, 2.6, 3, Color.white.opacity(0.9))
            ctx.ellipse(x - 0.2, y - 4.2, 2.6, 3, Color.white.opacity(0.9))
            ctx.ellipse(x - 3, y - 1.8, 6, 3.8, rgb(0xF8D35E))
            ctx.rect(x - 1.2, y - 1.8, 0.9, 3.8, ink)
            ctx.rect(x + 0.6, y - 1.8, 0.9, 3.8, ink)
            ctx.circle(x + 2.4, y - 0.4, 0.4, ink)
        }
    }

    // MARK: Theme: suối nước nóng

    private static func drawOnsen(_ scene: GraphicsContext) {
        var ctx = scene
        ctx.clip(to: Path(CGRect(x: 0, y: 0, width: 125, height: 100)))
        ctx.rect(0, 0, 125, 62, rgb(0xEFD6B3))
        ctx.strokePath(rgb(0xDDBC92), width: 0.7) { p in
            var y: CGFloat = 6
            while y < 58 {
                p.move(to: pt(0, y)); p.addLine(to: pt(125, y))
                y += 6.4
            }
        }
        for (x, y) in [(CGFloat(18), CGFloat(9.2)), (46, 22), (88, 15.6), (30, 47.6), (70, 41.2), (110, 53.6)] {
            ctx.ellipse(x - 2, y - 0.8, 4, 1.6, rgb(0xDDBC92))
        }
        // Hơi nước
        ctx.strokePath(Color.white.opacity(0.55), width: 1.4) { p in
            for (x, y) in [(CGFloat(36), CGFloat(52)), (88, 46), (52, 40)] {
                p.move(to: pt(x, y)); p.addCurve(to: pt(x, y - 12), control1: pt(x - 4, y - 4), control2: pt(x + 4, y - 8))
            }
        }
        // Tre bên phải
        for (x, top) in [(CGFloat(104), CGFloat(-2)), (113, 4), (121, -2)] {
            ctx.rect(x, top, 3.4, 60 - top, rgb(0x9CC79A), radius: 1.2)
            var y = top + 9
            while y < 58 {
                ctx.rect(x - 0.4, y, 4.2, 1.2, rgb(0x7FB27F), radius: 0.6)
                y += 11
            }
        }
        for (x, y, a) in [(CGFloat(102), CGFloat(14), -30.0), (CGFloat(110), CGFloat(24), 30.0), (CGFloat(118), CGFloat(12), -25.0),
                          (CGFloat(100), CGFloat(36), 25.0), (CGFloat(124), CGFloat(30), -30.0)] {
            ctx.rotated(a, around: pt(x, y)) { c in
                c.ellipse(x - 7, y - 1.6, 9, 3.4, rgb(0x8DBF88))
            }
        }
        // Sàn đá cuội
        ctx.rect(0, 62, 125, 38, rgb(0xC5CFD2))
        let rows: [(CGFloat, CGFloat)] = [(63, 7.5), (71.5, 8.5), (81, 9), (91, 9)]
        for (i, r) in rows.enumerated() {
            var x: CGFloat = i % 2 == 0 ? -4 : 3
            var k = i
            while x < 125 {
                let w: CGFloat = [14, 11, 16, 12][k % 4]
                let c: UInt32 = [0xE0E7E9, 0xD3DDE0, 0xE8EDEA, 0xD9E2DC][(k + i) % 4]
                ctx.rect(x, r.0, w - 1.2, r.1 - 1.2, rgb(c), radius: 3)
                ctx.rect(x + 1.5, r.0 + 1, w * 0.3, 0.9, Color.white.opacity(0.6), radius: 0.45)
                x += w
                k += 1
            }
        }
        baseboard(ctx, rgb(0xC99A6E))
        // Cửa sổ tròn giấy dán
        let c = pt(win.midX, win.midY)
        ctx.circle(c.x, c.y, 11, rgb(0xA77B54))
        ctx.circle(c.x, c.y, 9, rgb(0xFFF6E4))
        var g = ctx
        g.clip(to: Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18)))
        g.ellipse(c.x - 9, c.y + 1, 12, 9, rgb(0xE9DCC2).opacity(0.7))
        g.strokePath(rgb(0xC69C70), width: 0.8) { p in
            for d in [CGFloat(-4.5), 0, 4.5] {
                p.move(to: pt(c.x + d, c.y - 10)); p.addLine(to: pt(c.x + d, c.y + 10))
                p.move(to: pt(c.x - 10, c.y + d)); p.addLine(to: pt(c.x + 10, c.y + d))
            }
        }
        g.circle(c.x + 4, c.y - 4, 2.4, rgb(0xF4B0A0).opacity(0.5))
    }

    // MARK: Bồn tắm

    private static func drawShellTub(_ ctx: GraphicsContext) {
        let shell = rgb(0xF9CFCF)
        let rib = rgb(0xEFAAB0)
        let front = rgb(0xFBDCD6)
        ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
        // Vỏ sau hình quạt
        let c = pt(50, 62)
        var fan = Path()
        fan.move(to: c)
        let n = 9
        for i in 0...n {
            let a = Double.pi + Double(i) / Double(n) * Double.pi
            let p = pt(c.x + CGFloat(cos(a)) * 44, c.y + CGFloat(sin(a)) * 40)
            if i == 0 {
                fan.addLine(to: p)
            } else {
                let mid = Double.pi + (Double(i) - 0.5) / Double(n) * Double.pi
                fan.addQuadCurve(to: p, control: pt(c.x + CGFloat(cos(mid)) * 50, c.y + CGFloat(sin(mid)) * 46))
            }
        }
        fan.closeSubpath()
        ctx.fill(fan, with: .color(shell))
        ctx.strokePath(rib, width: 1.2) { p in
            for i in 1..<n {
                let a = Double.pi + Double(i) / Double(n) * Double.pi
                p.move(to: pt(c.x, c.y - 4)); p.addLine(to: pt(c.x + CGFloat(cos(a)) * 42, c.y + CGFloat(sin(a)) * 38))
            }
        }
        ctx.strokePath(Color.white.opacity(0.6), width: 2) { p in
            p.addArc(center: c, radius: 34, startAngle: .degrees(205), endAngle: .degrees(240), clockwise: false)
        }
        // Nước + bọt
        ctx.ellipse(10, 52, 80, 14, water)
        ctx.ellipse(22, 54, 20, 3.6, Color.white.opacity(0.6))
        for (x, y, r) in [(CGFloat(20), CGFloat(54), CGFloat(5)), (28, 51, 6), (36, 54, 4), (66, 52, 5.5), (74, 54, 4.5)] {
            ctx.circle(x, y, r, Color.white)
        }
        // Vỏ trước
        var bowl = Path()
        bowl.move(to: pt(6, 60))
        bowl.addQuadCurve(to: pt(94, 60), control: pt(50, 112))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(front))
        var g = ctx
        g.clip(to: bowl)
        g.strokePath(rib, width: 1) { p in
            for i in 0..<9 {
                let x = 12 + CGFloat(i) * 9.5
                p.move(to: pt(x, 60)); p.addLine(to: pt(50 + (x - 50) * 0.25, 92))
            }
        }
        g.ellipse(0, 76, 100, 20, rib.opacity(0.35))
        ctx.rect(4, 57, 92, 6, rgb(0xFFEAE6), radius: 3)
        ctx.rect(10, 58, 30, 1.6, Color.white.opacity(0.9), radius: 0.8)
        // Ngọc trai + sao biển
        ctx.circle(84, 52, 5, rgb(0xFFF8F2))
        ctx.circle(82.6, 50.6, 1.6, Color.white)
        star(ctx, 16, 80, 6, rgb(0xF2A57E))
        ctx.circle(16, 80, 1.2, rgb(0xFFD2B8))
    }

    private static func drawDuckTub(_ ctx: GraphicsContext) {
        // Đuôi
        ctx.polygon([pt(88, 52), pt(100, 32), pt(98, 56)], duckYellow)
        // Chân vịt
        for x in [CGFloat(18), 66] {
            ctx.ellipse(x, 86, 18, 7, beak)
        }
        clawTubBody(ctx, color: duckYellow, shade: duckShade, feet: false)
        // Nước, bọt
        ctx.rect(9, 47.5, 82, 3, water, radius: 1.5)
        for (x, y, r) in [(CGFloat(30), CGFloat(44), CGFloat(5)), (38, 41, 6), (46, 44, 4), (70, 43, 5), (78, 45, 3.5)] {
            ctx.circle(x, y, r, Color.white)
        }
        // Cánh
        ctx.strokePath(duckShade, width: 3) { p in
            p.move(to: pt(44, 62)); p.addQuadCurve(to: pt(76, 64), control: pt(60, 80))
        }
        ctx.strokePath(duckShade, width: 2) { p in
            p.move(to: pt(52, 64)); p.addQuadCurve(to: pt(70, 65), control: pt(62, 74))
        }
        // Cổ + đầu
        ctx.rect(4, 26, 16, 30, duckYellow, radius: 8)
        ctx.circle(14, 22, 14, duckYellow)
        ctx.ellipse(-4, 20, 14, 8, beak)
        ctx.ellipse(-2, 25, 10, 3.4, rgb(0xE07F45))
        ctx.circle(10, 17, 2.6, ink)
        ctx.circle(9.2, 16.2, 0.9, Color.white)
        ctx.ellipse(12, 24, 8, 4, Palette.blush.opacity(0.9))
        ctx.ellipse(14, 10, 8, 4, Color.white.opacity(0.5))
        // Lông tơ trên đỉnh
        ctx.strokePath(duckYellow, width: 2) { p in
            p.move(to: pt(16, 9)); p.addQuadCurve(to: pt(20, 2), control: pt(14, 3))
        }
    }

    private static func drawPool(_ ctx: GraphicsContext) {
        ctx.ellipse(2, 82, 96, 12, Color.black.opacity(0.1))
        let rings: [(CGFloat, UInt32, UInt32)] = [(64, 0x8FCDE6, 0x73B8D8), (53, 0xF6B3C6, 0xE993AE), (42, 0xF7D27A, 0xE9BA55)]
        for (y, c, d) in rings {
            ctx.ellipse(4, y + 2, 92, 24, rgb(d))
            ctx.ellipse(4, y, 92, 23, rgb(c))
            ctx.strokePath(Color.white.opacity(0.55), width: 1.6) { p in
                p.move(to: pt(12, y + 8)); p.addQuadCurve(to: pt(30, y + 3), control: pt(18, y + 3))
            }
        }
        // Chấm bi trên vòng giữa
        for x in stride(from: CGFloat(14), to: 92, by: 11) {
            ctx.circle(x, 70 + abs(x - 50) * -0.08, 1.8, Color.white.opacity(0.85))
        }
        // Mặt nước
        ctx.ellipse(13, 46, 74, 15, rgb(0x7FC3DD))
        ctx.ellipse(14, 47, 72, 13, water)
        ctx.strokePath(Color.white.opacity(0.8), width: 1) { p in
            p.move(to: pt(24, 53)); p.addQuadCurve(to: pt(34, 53), control: pt(29, 51))
            p.move(to: pt(58, 56)); p.addQuadCurve(to: pt(68, 56), control: pt(63, 54))
        }
        // Bóng bãi biển
        let b = pt(66, 44)
        ctx.circle(b.x, b.y, 8, Color.white)
        var g = ctx
        g.clip(to: Path(ellipseIn: CGRect(x: b.x - 8, y: b.y - 8, width: 16, height: 16)))
        g.polygon([b, pt(b.x - 10, b.y - 8), pt(b.x - 2, b.y - 10)], rgb(0xF4A3A8))
        g.polygon([b, pt(b.x + 10, b.y - 6), pt(b.x + 9, b.y + 4)], rgb(0x8FCDE6))
        g.polygon([b, pt(b.x - 4, b.y + 10), pt(b.x + 5, b.y + 10)], rgb(0xF7D27A))
        ctx.circle(b.x - 3, b.y - 4, 1.6, Color.white.opacity(0.9))
        // Vịt nhỏ
        duck(ctx, 32, 54, 0.5)
        // Giọt nước bắn
        for (x, y) in [(CGFloat(8), CGFloat(36)), (90, 34), (84, 26)] {
            ctx.ellipse(x - 1, y, 2.2, 3.6, rgb(0x8FCDE6))
        }
    }

    // MARK: Bồn rửa

    private static func drawVanitySink(_ ctx: GraphicsContext) {
        let wood = rgb(0xD9B087)
        let door = rgb(0xE9C79C)
        ctx.ellipse(12, 89, 76, 8, Color.black.opacity(0.1))
        // Gương vòm
        ctx.rect(33, 0, 34, 24, wood, radius: 12)
        ctx.rect(36, 3, 28, 19, rgb(0xDDEEF8), radius: 9.5)
        ctx.strokePath(Color.white.opacity(0.85), width: 1.8) { p in
            p.move(to: pt(41, 15)); p.addLine(to: pt(47, 6))
            p.move(to: pt(45, 17)); p.addLine(to: pt(47, 14.5))
        }
        // Tủ
        ctx.rect(16, 51, 68, 40, wood, radius: 3)
        ctx.rect(20, 56, 29, 31, door, radius: 2.5)
        ctx.rect(51, 56, 29, 31, door, radius: 2.5)
        ctx.rect(44, 69, 2.2, 8, rgb(0x9C7458), radius: 1.1)
        ctx.rect(53.8, 69, 2.2, 8, rgb(0x9C7458), radius: 1.1)
        ctx.rect(22, 89, 6, 4, rgb(0x9C7458), radius: 1)
        ctx.rect(72, 89, 6, 4, rgb(0x9C7458), radius: 1)
        // Mặt đá + chậu đặt nổi
        ctx.rect(12, 46, 76, 6, rgb(0xF4EFEA), radius: 2)
        ctx.rect(14, 47, 30, 1.4, Color.white, radius: 0.7)
        var bowl = Path()
        bowl.move(to: pt(32, 38))
        bowl.addQuadCurve(to: pt(68, 38), control: pt(50, 60))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(porcelain))
        ctx.ellipse(31, 35, 38, 7, porcelain)
        ctx.ellipse(34, 36, 32, 4.4, porcelainShade)
        // Vòi cổ ngỗng
        ctx.rect(56, 26, 3, 12, chrome, radius: 1.5)
        ctx.strokePath(chrome, width: 3) { p in
            p.move(to: pt(57.5, 27)); p.addQuadCurve(to: pt(50, 30), control: pt(57, 20))
        }
        // Cây nhỏ & bình xà phòng
        ctx.rect(15, 38, 10, 8, rgb(0xFFFFFF), radius: 2)
        ctx.ellipse(12, 28, 8, 11, Palette.sage)
        ctx.ellipse(18, 25, 8, 13, rgb(0x8DB88F))
        ctx.rect(75, 36, 8, 10, rgb(0xF4B8C8), radius: 2.4)
        ctx.rect(77.5, 31, 3, 5, chromeDark, radius: 1)
        ctx.rect(78, 30, 6, 2, chromeDark, radius: 1)
    }

    private static func drawDuckSink(_ ctx: GraphicsContext) {
        let basin = rgb(0xFFFFFF)
        let shade = rgb(0xDDE7EC)
        ctx.ellipse(18, 89, 64, 8, Color.black.opacity(0.1))
        // Chân bồn
        ctx.polygon([pt(41, 58), pt(59, 58), pt(63, 92), pt(37, 92)], basin)
        ctx.polygon([pt(52, 58), pt(59, 58), pt(63, 92), pt(55, 92)], shade.opacity(0.7))
        ctx.rect(35, 89, 30, 4, shade, radius: 2)
        // Ghế bậc cho bé
        ctx.rect(24, 78, 52, 6, rgb(0xF6B3C6), radius: 3)
        ctx.rect(28, 84, 6, 10, rgb(0xE993AE), radius: 2)
        ctx.rect(66, 84, 6, 10, rgb(0xE993AE), radius: 2)
        ctx.heart(center: pt(50, 81), size: 5, Color.white.opacity(0.85))
        // Chậu
        ctx.rect(14, 44, 72, 6, basin, radius: 3)
        var bowl = Path()
        bowl.move(to: pt(17, 49))
        bowl.addQuadCurve(to: pt(83, 49), control: pt(50, 76))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(basin))
        var g = ctx
        g.clip(to: bowl)
        g.ellipse(20, 54, 60, 16, shade)
        ctx.rect(14, 44, 72, 2.4, duckYellow, radius: 1.2)
        // Vòi hình vịt, nước chảy từ mỏ
        ctx.strokePath(rgb(0x9FD3E6), width: 2.4) { p in
            p.move(to: pt(60, 36)); p.addQuadCurve(to: pt(58, 52), control: pt(62, 44))
        }
        ctx.ellipse(43, 30, 16, 14, duckYellow)
        ctx.circle(50, 26, 7, duckYellow)
        ctx.ellipse(54, 27, 8, 4.2, beak)
        ctx.circle(51.5, 24, 1.3, ink)
        ctx.ellipse(46, 27.5, 4, 2.2, Palette.blush.opacity(0.9))
        ctx.ellipse(48, 21, 3.6, 2, Color.white.opacity(0.6))
        // Bong bóng
        for (x, y, r) in [(CGFloat(24), CGFloat(30), CGFloat(4)), (32, 20, 2.6), (78, 28, 3.4), (70, 16, 2.2)] {
            ctx.circle(x, y, r, Color.white.opacity(0.4))
            ctx.strokePath(rgb(0xA9D7E6), width: 0.8) { p in
                p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
        }
        // Xà phòng hình vịt con
        ctx.ellipse(18, 40, 12, 5, rgb(0xFBE7A2))
        ctx.circle(26, 39.5, 2.6, rgb(0xFBE7A2))
    }

    private static func drawCloudSink(_ ctx: GraphicsContext) {
        let basin = rgb(0xDCEEF8)
        let shade = rgb(0xBCDCEE)
        // Gương mây
        for (dy, c) in [(CGFloat(1.5), rgb(0xD7E6F6)), (0, rgb(0xFFFFFF))] {
            ctx.ellipse(16, 10 + dy, 68, 18, c)
            ctx.circle(32, 13 + dy, 10, c)
            ctx.circle(50, 9 + dy, 12, c)
            ctx.circle(68, 13 + dy, 10, c)
        }
        var m = Path(ellipseIn: CGRect(x: 21, y: 12, width: 58, height: 14))
        m.addEllipse(in: CGRect(x: 25, y: 6, width: 14, height: 14))
        m.addEllipse(in: CGRect(x: 40, y: 1, width: 20, height: 18))
        m.addEllipse(in: CGRect(x: 61, y: 6, width: 14, height: 14))
        ctx.fill(m, with: .color(rgb(0xDDEEF8)))
        var mg = ctx
        mg.clip(to: m)
        mg.polygon([pt(34, 26), pt(48, 2), pt(53, 2), pt(39, 26)], Color.white.opacity(0.6))
        for (x, y) in [(CGFloat(16), CGFloat(6)), (86, 10), (82, 26)] {
            ctx.draw(Text("✦").font(.system(size: 6)).foregroundColor(rgb(0xF2C25E)), at: pt(x, y))
        }
        // Vòi gắn tường
        ctx.rect(46, 32, 8, 4, chromeDark, radius: 2)
        ctx.strokePath(chrome, width: 3.4) { p in
            p.move(to: pt(50, 34)); p.addQuadCurve(to: pt(56, 42), control: pt(57, 34))
        }
        // Chậu treo tường
        ctx.rect(14, 44, 72, 6, basin, radius: 3)
        var bowl = Path()
        bowl.move(to: pt(17, 49))
        bowl.addQuadCurve(to: pt(83, 49), control: pt(50, 80))
        bowl.closeSubpath()
        ctx.fill(bowl, with: .color(basin))
        var g = ctx
        g.clip(to: bowl)
        g.ellipse(20, 56, 60, 18, shade)
        ctx.rect(18, 45, 22, 1.6, Color.white.opacity(0.9), radius: 0.8)
        // Ống xi-phông
        ctx.strokePath(chromeDark, width: 3) { p in
            p.move(to: pt(50, 62)); p.addLine(to: pt(50, 74))
            p.addQuadCurve(to: pt(58, 78), control: pt(50, 79))
            p.addLine(to: pt(64, 78))
        }
        // Khăn treo vòng
        ctx.strokePath(chrome, width: 1.6) { p in
            p.addEllipse(in: CGRect(x: 84, y: 52, width: 10, height: 10))
        }
        ctx.rect(83, 60, 12, 24, Palette.blush, radius: 3)
        ctx.rect(83, 74, 12, 2, Color.white.opacity(0.8))
        // Xà phòng mây
        ctx.ellipse(20, 40, 12, 5, rgb(0xFFFFFF))
        ctx.circle(24, 40, 3, rgb(0xFFFFFF))
        ctx.circle(28, 40.5, 2.4, rgb(0xFFFFFF))
    }

    // MARK: Kệ

    private static func drawCandleShelf(_ ctx: GraphicsContext) {
        shelfBoard(ctx)
        let candles: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (14, 24, 12, rgb(0xFFF6E6)), (29, 34, 14, rgb(0xF9DCE4)), (46, 16, 12, rgb(0xE6DDF7))
        ]
        for (x, h, w, c) in candles {
            let top = 76 - h
            ctx.circle(x + w / 2, top - 6, 9, rgb(0xFFD98A).opacity(0.22))
            ctx.rect(x, top, w, h, c, radius: 2.5)
            ctx.ellipse(x, top - 1.5, w, 3.4, c)
            ctx.ellipse(x + 1.5, top - 1, w - 3, 2, Color.black.opacity(0.06))
            ctx.rect(x, top + h * 0.45, w, 2.4, rgb(0xF2C25E).opacity(0.55))
            ctx.rect(x + 1.6, top + 2, 1.8, h - 5, Color.white.opacity(0.6), radius: 0.9)
            ctx.rect(x + w / 2 - 0.5, top - 4, 1, 3, ink)
            ctx.ellipse(x + w / 2 - 2.4, top - 12, 4.8, 8.5, Palette.honey)
            ctx.ellipse(x + w / 2 - 1.2, top - 8.5, 2.4, 4.4, Color.white.opacity(0.85))
        }
        // Đá spa xếp chồng
        ctx.ellipse(64, 66, 24, 10, rgb(0xB9C6CB))
        ctx.ellipse(67, 58, 18, 9, rgb(0xD3DDE0))
        ctx.ellipse(70, 51, 12, 8, rgb(0xC5CFD2))
        ctx.ellipse(68, 67.5, 8, 2, Color.white.opacity(0.5))
        ctx.ellipse(70, 59.5, 6, 1.8, Color.white.opacity(0.5))
        // Nhành lá
        ctx.strokePath(Palette.sage, width: 1) { p in
            p.move(to: pt(84, 74)); p.addQuadCurve(to: pt(92, 52), control: pt(94, 66))
        }
        for (x, y) in [(CGFloat(86), CGFloat(64)), (91, 58), (90, 52)] {
            ctx.ellipse(x - 1, y - 2, 5, 3, rgb(0x8DB88F))
        }
    }

    private static func drawDuckShelf(_ ctx: GraphicsContext) {
        shelfBoard(ctx)
        duck(ctx, 28, 77, 1.05)
        duck(ctx, 60, 77, 0.72, body: rgb(0xBFE0F4), shade: rgb(0x93C6E6))
        duck(ctx, 82, 77, 0.6, body: rgb(0xF9C9D6), shade: rgb(0xEFA3BA))
        // Vương miện nhỏ cho vịt lớn
        ctx.polygon([pt(29, 41), pt(30, 34), pt(33, 38), pt(35, 33), pt(37, 38), pt(40, 34), pt(41, 41)], Palette.honey)
        ctx.circle(35, 37.5, 1, rgb(0xF4A3A8))
        ctx.heart(center: pt(70, 32), size: 7, Palette.blush)
        ctx.draw(Text("♪").font(.system(size: 9)).foregroundColor(Palette.lavender), at: pt(12, 34))
    }

    private static func drawMacrame(_ ctx: GraphicsContext) {
        let rope = rgb(0xF4E8D4)
        let knot = rgb(0xE6D3B3)
        ctx.circle(50, 4, 2.6, Palette.woodDark)
        ctx.rect(46, 6, 8, 5, knot, radius: 2.5)
        // Dây chéo đan
        ctx.strokePath(rope, width: 1.5) { p in
            for dx in [CGFloat(-14), -5, 5, 14] {
                p.move(to: pt(50 + dx * 0.15, 10)); p.addLine(to: pt(50 + dx, 32))
            }
            p.move(to: pt(36, 32)); p.addLine(to: pt(45, 44)); p.addLine(to: pt(36, 56))
            p.move(to: pt(45, 32)); p.addLine(to: pt(36, 44)); p.addLine(to: pt(45, 56))
            p.move(to: pt(55, 32)); p.addLine(to: pt(64, 44)); p.addLine(to: pt(55, 56))
            p.move(to: pt(64, 32)); p.addLine(to: pt(55, 44)); p.addLine(to: pt(64, 56))
        }
        for (x, y) in [(CGFloat(40.5), CGFloat(32)), (59.5, 32), (40.5, 44), (59.5, 44)] {
            ctx.circle(x, y, 2.4, knot)
        }
        // Chậu
        ctx.rect(32, 54, 36, 22, rgb(0xF2B9A6), radius: 7)
        ctx.rect(30, 52, 40, 6, rgb(0xF6CBBB), radius: 3)
        ctx.rect(35, 58, 3, 14, Color.white.opacity(0.35), radius: 1.5)
        // Cây trầu bà rủ
        func vine(_ from: CGPoint, _ to: CGPoint, _ ctrl: CGPoint, _ leaves: Int) {
            ctx.strokePath(Palette.sage, width: 1.1) { p in
                p.move(to: from); p.addQuadCurve(to: to, control: ctrl)
            }
            for i in 1...leaves {
                let t = CGFloat(i) / CGFloat(leaves)
                let u = 1 - t
                let x = u * u * from.x + 2 * u * t * ctrl.x + t * t * to.x
                let y = u * u * from.y + 2 * u * t * ctrl.y + t * t * to.y
                ctx.heart(center: pt(x + (i % 2 == 0 ? 2.5 : -2.5), y), size: 6.5, i % 2 == 0 ? rgb(0x8DBF88) : rgb(0xA9D3A0))
            }
        }
        vine(pt(36, 54), pt(18, 94), pt(14, 62), 5)
        vine(pt(64, 54), pt(84, 90), pt(88, 64), 5)
        vine(pt(44, 54), pt(36, 84), pt(40, 70), 3)
        ctx.heart(center: pt(42, 48), size: 9, rgb(0xA9D3A0))
        ctx.heart(center: pt(52, 46), size: 10, rgb(0x8DBF88))
        ctx.heart(center: pt(60, 49), size: 8, rgb(0xA9D3A0))
        // Tua rua
        ctx.strokePath(rope, width: 1.2) { p in
            for dx in [CGFloat(-3), -1, 1, 3] {
                p.move(to: pt(50, 76)); p.addLine(to: pt(50 + dx, 90))
            }
        }
        ctx.circle(50, 77, 2.6, knot)
    }

    // MARK: Thảm

    private static func drawMatWhale(_ ctx: GraphicsContext) {
        let blue = rgb(0x8FC1E8)
        let belly = rgb(0xDDEEFA)
        ctx.ellipse(6, 76, 90, 20, Color.black.opacity(0.06))
        // Đuôi
        ctx.polygon([pt(72, 80), pt(84, 70), pt(96, 64), pt(90, 78), pt(98, 90), pt(84, 86)], blue)
        // Thân
        let body = CGRect(x: 6, y: 66, width: 76, height: 28)
        ctx.ellipse(body.minX, body.minY, body.width, body.height, blue)
        var g = ctx
        g.clip(to: Path(ellipseIn: body))
        g.ellipse(4, 82, 70, 20, belly)
        g.strokePath(rgb(0xBBD9F0), width: 1) { p in
            p.move(to: pt(16, 88)); p.addLine(to: pt(60, 88))
        }
        ctx.circle(22, 77, 2.2, ink)
        ctx.circle(21.3, 76.3, 0.7, Color.white)
        ctx.ellipse(24, 81, 7, 3.4, Palette.blush.opacity(0.9))
        ctx.strokePath(ink, width: 1.1) { p in
            p.move(to: pt(10, 83)); p.addQuadCurve(to: pt(16, 83), control: pt(13, 85.5))
        }
        ctx.ellipse(44, 84, 12, 5, rgb(0x6FA2D2))
        for (x, y) in [(CGFloat(48), CGFloat(72)), (60, 76), (54, 70)] {
            ctx.circle(x, y, 1.4, Color.white.opacity(0.7))
        }
        // Tia nước nhỏ
        ctx.strokePath(rgb(0x8FCDE6), width: 2) { p in
            p.move(to: pt(30, 66)); p.addQuadCurve(to: pt(24, 60), control: pt(26, 62))
            p.move(to: pt(30, 66)); p.addQuadCurve(to: pt(36, 60), control: pt(34, 62))
        }
    }

    private static func drawMatCloud(_ ctx: GraphicsContext) {
        let shadeC = rgb(0xCFE0F3)
        for (dy, c) in [(CGFloat(2.5), shadeC), (0, rgb(0xFBFDFF))] {
            ctx.ellipse(8, 76 + dy, 84, 18, c)
            ctx.circle(24, 79 + dy, 10, c)
            ctx.circle(42, 74 + dy, 12, c)
            ctx.circle(62, 75 + dy, 11, c)
            ctx.circle(79, 80 + dy, 9, c)
        }
        ctx.ellipse(36, 68, 12, 4, Color.white)
        // Mặt ngủ
        for x in [CGFloat(42), 58] {
            ctx.strokePath(ink, width: 1.3) { p in
                p.move(to: pt(x - 3, 82)); p.addQuadCurve(to: pt(x + 3, 82), control: pt(x, 85))
            }
        }
        ctx.ellipse(33, 85, 6, 3, Palette.blush.opacity(0.85))
        ctx.ellipse(61, 85, 6, 3, Palette.blush.opacity(0.85))
        // Giọt mưa nhỏ
        for (x, y) in [(CGFloat(16), CGFloat(70)), (84, 68), (72, 64)] {
            ctx.ellipse(x - 1.1, y, 2.2, 3.4, rgb(0xAFCFF2))
        }
    }

    private static func drawMatPebbles(_ ctx: GraphicsContext) {
        ctx.ellipse(6, 76, 88, 20, Color.black.opacity(0.06))
        let stones: [(CGFloat, CGFloat, CGFloat, CGFloat, UInt32)] = [
            (8, 74, 24, 13, 0xC9D6CF), (30, 70, 22, 12, 0xE3E8E4), (50, 72, 26, 14, 0xD5DCE6),
            (74, 74, 20, 13, 0xE8DCCB), (16, 84, 22, 11, 0xE6E1D8), (38, 82, 28, 13, 0xBFD3C8), (66, 85, 26, 10, 0xD9D2E6)
        ]
        for (x, y, w, h, c) in stones {
            ctx.ellipse(x, y + 1.6, w, h, Color.black.opacity(0.08))
            ctx.ellipse(x, y, w, h, rgb(c))
            ctx.ellipse(x + w * 0.2, y + h * 0.18, w * 0.35, h * 0.25, Color.white.opacity(0.55))
        }
        // Lá nhỏ
        ctx.ellipse(56, 87, 7, 3.4, Palette.sage)
        ctx.ellipse(60, 85, 7, 3.4, rgb(0x8DB88F))
    }

    // MARK: Đồ chơi

    private static func drawDucklings(_ ctx: GraphicsContext) {
        ctx.ellipse(2, 80, 96, 14, rgb(0x8FCDE6).opacity(0.5))
        ctx.strokePath(Color.white.opacity(0.85), width: 1.6) { p in
            p.move(to: pt(8, 88)); p.addQuadCurve(to: pt(20, 88), control: pt(14, 85))
            p.move(to: pt(78, 90)); p.addQuadCurve(to: pt(90, 90), control: pt(84, 87))
        }
        duck(ctx, 32, 88, 1.45)
        duck(ctx, 66, 88, 0.75)
        duck(ctx, 88, 88, 0.62)
        ctx.heart(center: pt(52, 30), size: 9, Palette.blush)
    }

    private static func drawTugboat(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 80, 92, 14, rgb(0x8FCDE6).opacity(0.5))
        // Khói
        for (x, y, r) in [(CGFloat(74), CGFloat(18), CGFloat(6)), (82, 10, 4.6), (88, 4, 3.4)] {
            ctx.circle(x, y, r, Color.white)
            ctx.strokePath(rgb(0xD5DDE3), width: 0.8) { p in
                p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
        }
        // Ống khói
        ctx.rect(64, 24, 14, 32, rgb(0xF7D27A), radius: 3)
        ctx.rect(64, 30, 14, 4, rgb(0xF4A3A8))
        ctx.rect(62, 22, 18, 4, rgb(0xE9BA55), radius: 2)
        // Ca-bin
        ctx.rect(24, 34, 40, 26, rgb(0xFFFDF8), radius: 4)
        ctx.rect(22, 30, 44, 6, rgb(0x8FCDE6), radius: 3)
        ctx.circle(36, 47, 6, rgb(0x73B8D8))
        ctx.circle(36, 47, 4.4, rgb(0xCDEAF6))
        ctx.circle(34.6, 45.6, 1.4, Color.white)
        ctx.rect(48, 41, 10, 19, rgb(0xF4A3A8), radius: 2)
        ctx.circle(55.5, 51, 1, rgb(0xFFFDF8))
        // Thân tàu
        var hull = Path()
        hull.move(to: pt(4, 58))
        hull.addLine(to: pt(96, 58))
        hull.addQuadCurve(to: pt(84, 86), control: pt(96, 80))
        hull.addLine(to: pt(18, 86))
        hull.addQuadCurve(to: pt(4, 58), control: pt(6, 76))
        hull.closeSubpath()
        ctx.fill(hull, with: .color(rgb(0xF4A3A8)))
        var g = ctx
        g.clip(to: hull)
        g.rect(0, 64, 100, 5, Color.white)
        g.rect(0, 78, 100, 10, rgb(0x6FA2D2))
        // Phao cứu sinh
        ctx.circle(80, 70, 6, Color.white)
        ctx.circle(80, 70, 2.6, rgb(0xF4A3A8))
        ctx.rect(77, 63.6, 6, 2, rgb(0xF4A3A8))
        ctx.rect(77, 74.4, 6, 2, rgb(0xF4A3A8))
        ctx.rect(4, 56, 92, 4, rgb(0xE88A92), radius: 2)
    }

    private static func drawSubmarine(_ ctx: GraphicsContext) {
        ctx.ellipse(4, 82, 92, 12, rgb(0x8FCDE6).opacity(0.5))
        // Kính tiềm vọng
        ctx.strokePath(chromeDark, width: 3) { p in
            p.move(to: pt(52, 34)); p.addLine(to: pt(52, 14)); p.addLine(to: pt(60, 14))
        }
        ctx.rect(58, 11, 6, 6, chromeDark, radius: 1.5)
        // Tháp
        ctx.rect(32, 30, 28, 22, duckYellow, radius: 6)
        ctx.rect(32, 30, 28, 5, duckShade, radius: 3)
        // Thân
        ctx.rect(6, 44, 80, 38, duckYellow, radius: 19)
        ctx.rect(6, 70, 80, 12, duckShade, radius: 6)
        ctx.ellipse(14, 48, 24, 6, Color.white.opacity(0.5))
        // Cửa sổ tròn
        for x in [CGFloat(26), 46, 66] {
            ctx.circle(x, 60, 7, rgb(0xFFFDF8))
            ctx.circle(x, 60, 5, rgb(0x8FCDE6))
            ctx.circle(x - 1.6, 58.4, 1.6, Color.white.opacity(0.9))
        }
        // Chân vịt
        ctx.rect(84, 60, 6, 6, chromeDark, radius: 2)
        ctx.ellipse(88, 50, 6, 13, rgb(0xF4A3A8))
        ctx.ellipse(88, 63, 6, 13, rgb(0xF4A3A8))
        // Bong bóng
        for (x, y, r) in [(CGFloat(14), CGFloat(30), CGFloat(4)), (8, 18, 2.6), (20, 14, 2)] {
            ctx.circle(x, y, r, Color.white.opacity(0.4))
            ctx.strokePath(rgb(0xA9D7E6), width: 1) { p in
                p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
        }
    }
}
