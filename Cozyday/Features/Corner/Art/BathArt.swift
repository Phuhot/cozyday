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
        default: return false
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
