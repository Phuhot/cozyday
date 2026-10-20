import SwiftUI

/// Hình vẽ đồ trong phòng học (tường & sàn + đồ mới). Đồ cũ của phòng học nằm trong ItemPainter.
/// Trả về false nếu không phải ID của phòng này.
enum StudyArt {
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        switch id {
        // MARK: Tường & sàn (125×100)
        case "studyTheme.cream": drawCream(ctx)
        case "studyTheme.mint": drawMint(ctx)
        case "studyTheme.night": drawNight(ctx)
        case "studyTheme.sakura": drawSakura(ctx)
        // MARK: Đồ mới
        case "wall.corkboard": drawCorkboard(ctx)
        case "lamp.mushroom": drawMushroomLamp(ctx)
        case "desk.computer": drawComputerDesk(ctx)
        case "plant.bonsai": drawBonsai(ctx)
        case "seat.beanbag": drawBeanbag(ctx)
        default: return false
        }
        return true
    }

    // MARK: - Khung phòng dùng chung

    /// Cửa sổ chung vị trí: x 57.5…87.5, y 8…34.
    private static let win = CGRect(x: 57.5, y: 8, width: 30, height: 26)

    private static func floorPlanks(_ ctx: GraphicsContext, base: Color, line: Color, top: CGFloat = 62) {
        ctx.rect(0, top, 125, 100 - top, base)
        let rows: [CGFloat] = [70.5, 80, 90.5]
        ctx.strokePath(line, width: 0.6) { p in
            for y in rows {
                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: 125, y: y))
            }
            // mối nối ván so le
            let seams: [(CGFloat, CGFloat, CGFloat)] = [
                (34, top + 0.5, 70.5), (96, top + 0.5, 70.5),
                (12, 70.5, 80), (66, 70.5, 80), (116, 70.5, 80),
                (42, 80, 90.5), (98, 80, 90.5),
                (20, 90.5, 100), (74, 90.5, 100)
            ]
            for s in seams {
                p.move(to: CGPoint(x: s.0, y: s.1)); p.addLine(to: CGPoint(x: s.0, y: s.2))
            }
        }
    }

    private static func baseboard(_ ctx: GraphicsContext, _ color: Color, highlight: Color) {
        ctx.rect(0, 59, 125, 3.5, color)
        ctx.rect(0, 59, 125, 0.7, highlight)
    }

    /// Viền gỗ ngoài cửa sổ (vẽ trước kính).
    private static func windowBase(_ ctx: GraphicsContext, frame: Color) {
        ctx.rect(win.minX, win.minY, win.width, win.height, frame, radius: 5)
    }

    /// Song cửa + bậu cửa (vẽ sau nội dung kính).
    private static func windowBars(_ ctx: GraphicsContext, sill: Color, bar: Color) {
        let r = win
        ctx.rect(r.midX - 0.7, r.minY + 2, 1.4, r.height - 4, bar)
        ctx.rect(r.minX + 2, r.midY - 0.7, r.width - 4, 1.4, bar)
        ctx.rect(r.minX - 3, r.maxY - 1, r.width + 6, 3, sill, radius: 1.5)
    }

    private static func glass(_ ctx: GraphicsContext, _ color: Color) {
        ctx.rect(win.minX + 2.5, win.minY + 2.5, win.width - 5, win.height - 5, color, radius: 2.5)
    }

    /// Vùng kính để clip nội dung bên ngoài cửa sổ.
    private static var glassPath: Path {
        Path(roundedRect: win.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 2.5)
    }

    private static func glassShine(_ ctx: GraphicsContext) {
        ctx.strokePath(Color.white.opacity(0.6), width: 1.2) { p in
            p.move(to: CGPoint(x: 61.5, y: 17)); p.addLine(to: CGPoint(x: 66, y: 12))
            p.move(to: CGPoint(x: 62, y: 21)); p.addLine(to: CGPoint(x: 64, y: 19))
        }
    }

    /// Rèm hai bên + diềm lượn sóng phía trên.
    private static func curtains(_ ctx: GraphicsContext, _ color: Color, shade: Color, valance: Color) {
        let r = win
        for left in [true, false] {
            let x0: CGFloat = left ? r.minX - 3.5 : r.maxX + 3.5
            let dir: CGFloat = left ? 1 : -1
            var p = Path()
            p.move(to: CGPoint(x: x0, y: r.minY - 1))
            p.addLine(to: CGPoint(x: x0 + dir * 10, y: r.minY - 1))
            p.addQuadCurve(to: CGPoint(x: x0 + dir * 4.2, y: r.minY + 15), control: CGPoint(x: x0 + dir * 9.5, y: r.minY + 10))
            p.addQuadCurve(to: CGPoint(x: x0 + dir * 7, y: r.maxY + 1), control: CGPoint(x: x0 + dir * 3, y: r.minY + 21))
            p.addLine(to: CGPoint(x: x0, y: r.maxY + 1))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
            // dây buộc rèm
            ctx.rect(left ? x0 - 0.5 : x0 - 5.5, r.minY + 14, 6, 2, shade, radius: 1)
            ctx.strokePath(shade, width: 0.6) { q in
                q.move(to: CGPoint(x: x0 + dir * 2.4, y: r.minY + 1)); q.addLine(to: CGPoint(x: x0 + dir * 2, y: r.minY + 13))
                q.move(to: CGPoint(x: x0 + dir * 2.2, y: r.minY + 17)); q.addLine(to: CGPoint(x: x0 + dir * 2.8, y: r.maxY))
            }
        }
        // diềm
        ctx.rect(r.minX - 4.5, r.minY - 3, r.width + 9, 3.6, valance, radius: 1.5)
        var x = r.minX - 4.5
        while x < r.maxX + 4 {
            ctx.ellipse(x, r.minY - 0.6, 4.3, 3, valance)
            x += 4.3
        }
    }

    // MARK: - Theme: Kem ấm (mặc định)

    private static func drawCream(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, Palette.roomWall)
        // chấm nhỏ trên tường
        for row in 0..<5 {
            for col in 0..<11 {
                let x = CGFloat(col) * 12 + (row % 2 == 0 ? 4 : 10)
                let y = CGFloat(row) * 11 + 5
                if x > 52 && x < 93 && y < 40 { continue }
                ctx.circle(x, y, 0.55, Palette.lavender.opacity(0.13))
            }
        }
        floorPlanks(ctx, base: Palette.roomFloor, line: Palette.woodDark.opacity(0.11))
        baseboard(ctx, Palette.wood.opacity(0.45), highlight: Color.white.opacity(0.35))
        windowBase(ctx, frame: Palette.wood)
        glass(ctx, Palette.lavenderSoft)
        ctx.ellipse(73, 13, 9, 4, Color.white.opacity(0.7))
        ctx.ellipse(76, 11, 6, 4, Color.white.opacity(0.7))
        glassShine(ctx)
        windowBars(ctx, sill: Palette.woodDark.opacity(0.85), bar: Palette.wood)
        curtains(ctx, Palette.blush.opacity(0.55), shade: Palette.peach.opacity(0.7), valance: Palette.blush.opacity(0.75))
    }

    // MARK: - Theme: Sọc bạc hà

    private static func drawMint(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xE6F4EC))
        var x: CGFloat = 0
        while x < 125 {
            ctx.rect(x, 0, 6, 62, rgb(0xD3EBDD))
            x += 12
        }
        ctx.strokePath(Color.white.opacity(0.55), width: 0.5) { p in
            var sx: CGFloat = 9
            while sx < 125 {
                p.move(to: CGPoint(x: sx, y: 0)); p.addLine(to: CGPoint(x: sx, y: 59))
                sx += 12
            }
        }
        floorPlanks(ctx, base: rgb(0xEBD5B7), line: rgb(0xB88D62).opacity(0.25))
        baseboard(ctx, rgb(0xFFFFFF).opacity(0.85), highlight: rgb(0xBFDCCB))
        windowBase(ctx, frame: rgb(0xFFFFFF))
        glass(ctx, rgb(0xDDF0F7))
        ctx.ellipse(62, 23, 10, 5, Color.white.opacity(0.85))
        ctx.ellipse(65, 21, 6, 4, Color.white.opacity(0.85))
        ctx.circle(81, 13.5, 3, rgb(0xF6D58A))
        glassShine(ctx)
        windowBars(ctx, sill: rgb(0xF4F8F5), bar: rgb(0xFFFFFF))
        curtains(ctx, rgb(0xA9D5BC).opacity(0.85), shade: rgb(0x7FB898), valance: rgb(0x8EC7A8))
    }

    // MARK: - Theme: Đêm sao

    private static func drawNight(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0x34406A))
        // sao trên tường
        let stars: [(CGFloat, CGFloat, CGFloat)] = [
            (8, 8, 1.0), (22, 18, 0.7), (40, 6, 0.9), (48, 26, 0.6), (14, 34, 0.8), (34, 44, 0.6),
            (100, 10, 0.9), (112, 24, 0.7), (96, 36, 0.6), (118, 46, 0.8), (6, 50, 0.6), (50, 52, 0.7),
            (104, 52, 0.6), (30, 30, 0.5), (118, 6, 0.6)
        ]
        for s in stars {
            ctx.circle(s.0, s.1, s.2, rgb(0xFFF1C2).opacity(0.75))
        }
        let big: [(CGFloat, CGFloat)] = [(28, 12), (108, 18), (20, 42), (52, 40)]
        for s in big {
            ctx.draw(Text("✦").font(.system(size: 5)).foregroundColor(rgb(0xF6D58A).opacity(0.85)), at: CGPoint(x: s.0, y: s.1))
        }
        floorPlanks(ctx, base: rgb(0x5B4E6E), line: rgb(0x2E2640).opacity(0.35))
        // vệt sáng trăng trên sàn
        ctx.polygon([CGPoint(x: 60, y: 62), CGPoint(x: 86, y: 62), CGPoint(x: 96, y: 76), CGPoint(x: 66, y: 76)],
                    rgb(0xC9D3FF).opacity(0.10))
        baseboard(ctx, rgb(0x262F52), highlight: rgb(0x5A6698).opacity(0.6))
        windowBase(ctx, frame: rgb(0x8E6E57))
        glass(ctx, rgb(0x1F2650))
        // trăng khuyết
        ctx.circle(79, 16, 4.6, rgb(0xFBE7A6))
        ctx.circle(81.6, 14.4, 4.0, rgb(0x1F2650))
        ctx.circle(63, 13, 0.6, Color.white.opacity(0.85))
        ctx.circle(68, 27, 0.5, Color.white.opacity(0.8))
        ctx.circle(83, 28, 0.6, Color.white.opacity(0.8))
        ctx.draw(Text("✦").font(.system(size: 3.6)).foregroundColor(Color.white.opacity(0.9)), at: CGPoint(x: 66, y: 19))
        windowBars(ctx, sill: rgb(0x6E523F), bar: rgb(0x8E6E57))
        curtains(ctx, rgb(0x7B6FB8).opacity(0.9), shade: rgb(0xF0C26A), valance: rgb(0x6A5EA8))
    }

    // MARK: - Theme: Hoa anh đào

    private static func petal(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ angle: Double, _ color: Color) {
        ctx.rotated(angle, around: CGPoint(x: x, y: y)) { c in
            c.ellipse(x - s, y - s * 0.55, s * 2, s * 1.1, color)
        }
    }

    private static func blossom(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        for i in 0..<5 {
            let a = Double(i) * 72.0 * Double.pi / 180
            ctx.circle(cx + CGFloat(cos(a)) * r * 0.8, cy + CGFloat(sin(a)) * r * 0.8, r * 0.62, rgb(0xF7B9CB))
        }
        ctx.circle(cx, cy, r * 0.45, rgb(0xFCE1E8))
        ctx.circle(cx, cy, r * 0.2, rgb(0xE88AA5))
    }

    private static func drawSakura(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xFCEBEF))
        // họa tiết hoa nhỏ mờ
        for row in 0..<4 {
            for col in 0..<7 {
                let x = CGFloat(col) * 19 + (row % 2 == 0 ? 6 : 15)
                let y = CGFloat(row) * 14 + 7
                if x > 50 && x < 95 && y < 40 { continue }
                for i in 0..<5 {
                    let a = Double(i) * 72.0 * Double.pi / 180
                    ctx.circle(x + CGFloat(cos(a)) * 0.9, y + CGFloat(sin(a)) * 0.9, 0.6, rgb(0xF4C3D0).opacity(0.4))
                }
            }
        }
        floorPlanks(ctx, base: rgb(0xF0DCC6), line: rgb(0xC39C78).opacity(0.25))
        baseboard(ctx, rgb(0xEFC6D2), highlight: Color.white.opacity(0.5))
        windowBase(ctx, frame: Palette.wood)
        glass(ctx, rgb(0xE4F0FA))
        var g = ctx
        g.clip(to: glassPath)
        g.strokePath(rgb(0x8B6A5A), width: 1.4) { p in
            p.move(to: CGPoint(x: 88, y: 12)); p.addQuadCurve(to: CGPoint(x: 66, y: 16), control: CGPoint(x: 76, y: 10))
            p.move(to: CGPoint(x: 76, y: 12)); p.addQuadCurve(to: CGPoint(x: 70, y: 24), control: CGPoint(x: 72, y: 17))
        }
        blossom(g, 67, 16, 2.4)
        blossom(g, 74, 11, 2.2)
        blossom(g, 70, 23.5, 2.2)
        blossom(g, 82, 14, 2.0)
        petal(g, 64, 28, 1.0, 30, rgb(0xF7B9CB))
        petal(g, 80, 26, 0.9, -20, rgb(0xF7B9CB))
        glassShine(ctx)
        windowBars(ctx, sill: Palette.woodDark.opacity(0.85), bar: Palette.wood)
        curtains(ctx, Color.white.opacity(0.85), shade: rgb(0xF2A7BC), valance: rgb(0xF6C2D0))
        // cánh hoa bay vào phòng
        let petals: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (98, 14, 1.3, 20), (104, 24, 1.1, -30), (112, 12, 1.0, 50), (96, 34, 1.2, 70),
            (50, 18, 1.1, -40), (44, 30, 1.0, 10), (118, 32, 1.1, -10), (108, 42, 0.9, 40)
        ]
        for p in petals {
            petal(ctx, p.0, p.1, p.2, p.3, rgb(0xF4A9BE).opacity(0.85))
        }
        petal(ctx, 74, 70, 1.2, 15, rgb(0xF4A9BE).opacity(0.6))
        petal(ctx, 100, 82, 1.1, -25, rgb(0xF4A9BE).opacity(0.6))
    }

    // MARK: - Đồ mới

    private static func drawCorkboard(_ ctx: GraphicsContext) {
        ctx.rect(10, 20, 80, 60, Palette.woodDark, radius: 5)
        ctx.rect(14, 24, 72, 52, rgb(0xDDB585), radius: 3)
        // lỗ chấm vân bần
        let dots: [(CGFloat, CGFloat)] = [(20, 30), (34, 70), (48, 28), (62, 72), (80, 44), (22, 56), (56, 50), (78, 68), (40, 46)]
        for d in dots { ctx.circle(d.0, d.1, 0.9, rgb(0xC09668)) }
        // ảnh polaroid 1 (đồi xanh)
        ctx.rotated(-8, around: CGPoint(x: 32, y: 44)) { c in
            c.rect(21, 31, 22, 26, Color.white, radius: 1.5)
            c.rect(23.5, 33.5, 17, 15, rgb(0xCFE6F4))
            var cc = c
            cc.clip(to: Path(CGRect(x: 23.5, y: 33.5, width: 17, height: 15)))
            cc.ellipse(19, 42, 18, 12, Palette.sage)
            cc.ellipse(29, 44, 16, 10, rgb(0x8DB88F))
            c.circle(36.5, 37, 2.2, Palette.honey)
        }
        // ảnh polaroid 2 (trái tim)
        ctx.rotated(7, around: CGPoint(x: 60, y: 40)) { c in
            c.rect(49, 28, 22, 25, Color.white, radius: 1.5)
            c.rect(51.5, 30.5, 17, 14, rgb(0xFBE3EA))
            c.heart(center: CGPoint(x: 60, y: 37.5), size: 9, Palette.blush)
        }
        // giấy nhớ
        ctx.rotated(-5, around: CGPoint(x: 31, y: 66)) { c in
            c.rect(23, 59, 16, 14, rgb(0xF8DC86), radius: 1)
            c.rect(26, 63, 10, 1.2, Palette.catInk.opacity(0.35), radius: 0.6)
            c.rect(26, 66.5, 7, 1.2, Palette.catInk.opacity(0.35), radius: 0.6)
        }
        ctx.rotated(6, around: CGPoint(x: 76, y: 61)) { c in
            c.rect(68, 54, 16, 14, rgb(0xBFE3CF), radius: 1)
            c.strokePath(Palette.sage, width: 1.4) { p in
                p.move(to: CGPoint(x: 72, y: 61)); p.addLine(to: CGPoint(x: 75, y: 64)); p.addLine(to: CGPoint(x: 80, y: 58))
            }
        }
        ctx.rect(47, 58, 14, 12, rgb(0xF7C6D3), radius: 1)
        ctx.draw(Text("♪").font(.system(size: 7)).foregroundColor(Palette.catInk.opacity(0.45)), at: CGPoint(x: 54, y: 64))
        // đinh ghim
        let pins: [(CGFloat, CGFloat, Color)] = [
            (31, 31, Palette.peach), (60, 29.5, Palette.lavender), (31, 58.5, Palette.sage),
            (76, 54, Palette.blush), (54, 57.5, Palette.honey)
        ]
        for p in pins {
            ctx.circle(p.0, p.1, 2, p.2)
            ctx.circle(p.0 - 0.6, p.1 - 0.6, 0.6, Color.white.opacity(0.7))
        }
        ctx.rect(15, 24.8, 70, 1, Color.white.opacity(0.25), radius: 0.5)
    }

    private static func drawMushroomLamp(_ ctx: GraphicsContext) {
        // quầng sáng
        ctx.circle(50, 44, 40, rgb(0xFFD98A).opacity(0.14))
        ctx.circle(50, 44, 31, rgb(0xFFD98A).opacity(0.16))
        // bóng đổ
        ctx.ellipse(26, 88, 48, 8, Color.black.opacity(0.1))
        // chân nấm
        var stem = Path()
        stem.move(to: CGPoint(x: 40, y: 56))
        stem.addQuadCurve(to: CGPoint(x: 34, y: 90), control: CGPoint(x: 34, y: 76))
        stem.addQuadCurve(to: CGPoint(x: 66, y: 90), control: CGPoint(x: 50, y: 94))
        stem.addQuadCurve(to: CGPoint(x: 60, y: 56), control: CGPoint(x: 66, y: 76))
        stem.closeSubpath()
        ctx.fill(stem, with: .color(rgb(0xFBEFD9)))
        ctx.ellipse(40, 54, 20, 10, rgb(0xFFF6D6))
        ctx.rect(53, 64, 3, 20, Color.white.opacity(0.6), radius: 1.5)
        // mũ nấm
        var cap = Path()
        cap.move(to: CGPoint(x: 12, y: 58))
        cap.addCurve(to: CGPoint(x: 88, y: 58), control1: CGPoint(x: 10, y: 14), control2: CGPoint(x: 90, y: 14))
        cap.addQuadCurve(to: CGPoint(x: 12, y: 58), control: CGPoint(x: 50, y: 66))
        cap.closeSubpath()
        ctx.fill(cap, with: .color(rgb(0xE8736F)))
        // vành sáng dưới mũ
        var rim = Path()
        rim.move(to: CGPoint(x: 14, y: 57))
        rim.addQuadCurve(to: CGPoint(x: 86, y: 57), control: CGPoint(x: 50, y: 66))
        rim.addQuadCurve(to: CGPoint(x: 14, y: 57), control: CGPoint(x: 50, y: 60))
        ctx.fill(rim, with: .color(rgb(0xFFE2A8)))
        // chấm bi
        ctx.ellipse(24, 40, 12, 9, rgb(0xFFF6EE))
        ctx.ellipse(44, 26, 13, 9, rgb(0xFFF6EE))
        ctx.ellipse(64, 38, 14, 10, rgb(0xFFF6EE))
        ctx.ellipse(76, 50, 7, 5, rgb(0xFFF6EE))
        ctx.ellipse(36, 50, 7, 5, rgb(0xFFF6EE))
        ctx.strokePath(Color.white.opacity(0.55), width: 2.4) { p in
            p.move(to: CGPoint(x: 22, y: 32)); p.addQuadCurve(to: CGPoint(x: 32, y: 24), control: CGPoint(x: 24, y: 26))
        }
        // tia sáng nhỏ
        ctx.draw(Text("✦").font(.system(size: 8)).foregroundColor(Palette.honey), at: CGPoint(x: 86, y: 22))
        ctx.draw(Text("✦").font(.system(size: 5)).foregroundColor(Palette.honey.opacity(0.8)), at: CGPoint(x: 12, y: 30))
    }

    private static func drawComputerDesk(_ ctx: GraphicsContext) {
        let top = rgb(0xF4EEE6)
        let side = rgb(0xE2D6C8)
        // màn hình
        ctx.rect(46, 30, 8, 7, Palette.catShade, radius: 1)
        ctx.ellipse(37, 35, 26, 6, Palette.catShade)
        ctx.rect(20, 2, 60, 30, rgb(0xFBF4E8), radius: 6)
        ctx.rect(25, 6, 50, 22, rgb(0x6F86C7), radius: 3)
        // nội dung màn hình: cửa sổ nhỏ + tim
        ctx.rect(28, 9, 26, 15, rgb(0xEAF0FF), radius: 1.5)
        ctx.rect(28, 9, 26, 3, rgb(0xB7C6F0), radius: 1.5)
        ctx.rect(30, 14.5, 14, 1.4, rgb(0x6F86C7).opacity(0.6), radius: 0.7)
        ctx.rect(30, 17.5, 18, 1.4, rgb(0x6F86C7).opacity(0.6), radius: 0.7)
        ctx.rect(30, 20.5, 10, 1.4, rgb(0x6F86C7).opacity(0.6), radius: 0.7)
        ctx.heart(center: CGPoint(x: 64, y: 16), size: 9, Palette.blush)
        ctx.strokePath(Color.white.opacity(0.35), width: 1.6) { p in
            p.move(to: CGPoint(x: 66, y: 25)); p.addLine(to: CGPoint(x: 72, y: 19))
        }
        // sticker trên viền màn hình
        ctx.rotated(-15, around: CGPoint(x: 23, y: 6)) { c in
            c.draw(Text("★").font(.system(size: 9)).foregroundColor(Palette.honey), at: CGPoint(x: 23, y: 6))
        }
        ctx.circle(76.5, 29, 3.2, Palette.sage)
        ctx.circle(76.5, 29, 1.3, Color.white.opacity(0.8))
        ctx.heart(center: CGPoint(x: 24, y: 28.5), size: 6, Palette.peach)
        ctx.rect(71, 2.5, 8, 4, Palette.lavender, radius: 2)
        ctx.circle(49.5, 30.2, 0.8, Palette.sage)
        // cốc
        ctx.rect(78, 30, 9, 10, Palette.lavender, radius: 2)
        ctx.strokePath(Palette.lavender, width: 1.6) { p in
            p.addEllipse(in: CGRect(x: 85, y: 32.5, width: 5, height: 5))
        }
        ctx.strokePath(Color.white.opacity(0.7), width: 1) { p in
            p.move(to: CGPoint(x: 81, y: 27)); p.addQuadCurve(to: CGPoint(x: 82, y: 22), control: CGPoint(x: 79, y: 25))
        }
        // bàn phím + chuột
        ctx.rect(26, 37, 34, 3.4, rgb(0xFFFFFF), radius: 1.5)
        ctx.rect(28, 37.8, 30, 0.8, Palette.catShade, radius: 0.4)
        ctx.ellipse(64, 36.6, 6, 3.6, rgb(0xFFFFFF))
        // mặt bàn + chân (giống bàn cũ: mặt 40…49, chân tới 91)
        ctx.rect(8, 40, 84, 9, top, radius: 3)
        ctx.rect(8, 40, 84, 2, Color.white.opacity(0.6), radius: 1)
        ctx.rect(14, 49, 6, 42, side, radius: 2)
        ctx.rect(56, 49, 30, 42, side, radius: 2)
        ctx.rect(59, 53, 24, 16, top, radius: 2)
        ctx.rect(59, 72, 24, 16, top, radius: 2)
        ctx.rect(67, 59.5, 8, 2.4, Palette.lavender, radius: 1.2)
        ctx.rect(67, 78.5, 8, 2.4, Palette.lavender, radius: 1.2)
    }

    private static func drawBonsai(_ ctx: GraphicsContext) {
        ctx.ellipse(18, 89, 64, 8, Color.black.opacity(0.1))
        // chậu thấp
        ctx.polygon([CGPoint(x: 18, y: 76), CGPoint(x: 82, y: 76), CGPoint(x: 76, y: 92), CGPoint(x: 24, y: 92)], rgb(0x7E9CC4))
        ctx.rect(14, 73, 72, 6, rgb(0x93B0D4), radius: 3)
        ctx.rect(28, 92, 8, 3, rgb(0x5F7EA6), radius: 1)
        ctx.rect(64, 92, 8, 3, rgb(0x5F7EA6), radius: 1)
        ctx.rect(24, 82, 14, 1.6, Color.white.opacity(0.45), radius: 0.8)
        // đất rêu
        ctx.ellipse(20, 70, 60, 7, rgb(0x8DB88F))
        // thân cây uốn
        ctx.strokePath(rgb(0x8A6448), width: 7) { p in
            p.move(to: CGPoint(x: 52, y: 74))
            p.addCurve(to: CGPoint(x: 46, y: 40), control1: CGPoint(x: 40, y: 62), control2: CGPoint(x: 62, y: 52))
        }
        ctx.strokePath(rgb(0x8A6448), width: 3.5) { p in
            p.move(to: CGPoint(x: 49, y: 54)); p.addQuadCurve(to: CGPoint(x: 26, y: 48), control: CGPoint(x: 36, y: 56))
            p.move(to: CGPoint(x: 52, y: 46)); p.addQuadCurve(to: CGPoint(x: 72, y: 38), control: CGPoint(x: 64, y: 46))
        }
        // tán lá dạng mây
        func pad(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
            ctx.ellipse(x, y, w, h, Palette.sage)
            ctx.ellipse(x + w * 0.15, y - h * 0.25, w * 0.45, h * 0.8, Palette.sage)
            ctx.ellipse(x + w * 0.45, y - h * 0.3, w * 0.42, h * 0.85, Palette.sage)
            ctx.ellipse(x + w * 0.22, y - h * 0.1, w * 0.4, h * 0.42, rgb(0x9CC39E))
        }
        pad(10, 42, 28, 11)
        pad(60, 32, 30, 11)
        pad(30, 26, 36, 13)
        // điểm sáng
        ctx.circle(40, 23, 1.6, Color.white.opacity(0.55))
        ctx.circle(68, 29, 1.3, Color.white.opacity(0.55))
        // viên đá nhỏ
        ctx.ellipse(62, 69, 9, 5, rgb(0xD8D2CC))
    }

    private static func drawBeanbag(_ ctx: GraphicsContext) {
        let main = rgb(0xF4C978)
        let shade = rgb(0xE5B25E)
        ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
        // thân ghế lười
        var body = Path()
        body.move(to: CGPoint(x: 12, y: 90))
        body.addCurve(to: CGPoint(x: 34, y: 42), control1: CGPoint(x: 2, y: 72), control2: CGPoint(x: 12, y: 46))
        body.addCurve(to: CGPoint(x: 72, y: 40), control1: CGPoint(x: 46, y: 30), control2: CGPoint(x: 62, y: 30))
        body.addCurve(to: CGPoint(x: 88, y: 90), control1: CGPoint(x: 90, y: 50), control2: CGPoint(x: 98, y: 74))
        body.addQuadCurve(to: CGPoint(x: 12, y: 90), control: CGPoint(x: 50, y: 96))
        body.closeSubpath()
        ctx.fill(body, with: .color(main))
        // lõm chỗ ngồi
        ctx.ellipse(22, 58, 56, 22, shade.opacity(0.6))
        ctx.ellipse(26, 56, 48, 18, main)
        // đường may
        ctx.strokePath(shade, width: 1.4) { p in
            p.move(to: CGPoint(x: 50, y: 36)); p.addQuadCurve(to: CGPoint(x: 44, y: 54), control: CGPoint(x: 44, y: 44))
            p.move(to: CGPoint(x: 18, y: 78)); p.addQuadCurve(to: CGPoint(x: 30, y: 92), control: CGPoint(x: 20, y: 88))
            p.move(to: CGPoint(x: 82, y: 78)); p.addQuadCurve(to: CGPoint(x: 72, y: 92), control: CGPoint(x: 80, y: 88))
        }
        // nhãn nhỏ
        ctx.rect(70, 70, 9, 6, Palette.peach, radius: 1.5)
        ctx.heart(center: CGPoint(x: 74.5, y: 73), size: 3.5, Color.white.opacity(0.85))
        // điểm sáng
        ctx.strokePath(Color.white.opacity(0.55), width: 3) { p in
            p.move(to: CGPoint(x: 20, y: 66)); p.addQuadCurve(to: CGPoint(x: 30, y: 48), control: CGPoint(x: 20, y: 54))
        }
        ctx.circle(62, 40, 1.8, Color.white.opacity(0.6))
    }
}
