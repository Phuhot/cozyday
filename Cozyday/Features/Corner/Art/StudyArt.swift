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
        // MARK: Đồ thêm
        case "studyTheme.library": drawLibrary(ctx)
        case "studyTheme.rain": drawRain(ctx)
        case "wall.chalkboard": drawChalkboard(ctx)
        case "wall.photoline": drawPhotoLine(ctx)
        case "wall.macrame": drawMacrame(ctx)
        case "lamp.globe": drawGlobeLamp(ctx)
        case "lamp.star": drawStarProjector(ctx)
        case "lamp.lava": drawLavaLamp(ctx)
        case "desk.fishbowl": drawFishbowlDesk(ctx)
        case "desk.typewriter": drawTypewriterDesk(ctx)
        case "desk.ladder": drawLadderShelf(ctx)
        case "plant.sunflower": drawSunflowerPot(ctx)
        case "plant.terrarium": drawTerrarium(ctx)
        case "plant.teacup": drawTeacupSucculent(ctx)
        case "seat.rocker": drawRocker(ctx)
        case "seat.catbean": drawCatBeanbag(ctx)
        case "seat.pouf": drawPouf(ctx)
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

    // MARK: - Theme: Thư viện gỗ

    private static func drawLibrary(_ ctx: GraphicsContext) {
        // giấy dán tường xanh rêu nhạt họa tiết lá nhỏ
        ctx.rect(0, 0, 125, 62, rgb(0xDCE8D6))
        for row in 0..<4 {
            for col in 0..<9 {
                let x = CGFloat(col) * 14 + (row % 2 == 0 ? 5 : 12)
                let y = CGFloat(row) * 9 + 5
                if x > 50 && x < 95 && y < 38 { continue }
                ctx.rotated(row % 2 == 0 ? 30 : -30, around: CGPoint(x: x, y: y)) { c in
                    c.ellipse(x - 1.6, y - 0.8, 3.2, 1.6, rgb(0xB9D2B0).opacity(0.8))
                }
            }
        }
        // ốp gỗ chân tường
        ctx.rect(0, 38, 125, 22, rgb(0xC9A27A))
        ctx.rect(0, 38, 125, 2, rgb(0xA98260))
        ctx.rect(0, 40, 125, 0.8, Color.white.opacity(0.25))
        var px: CGFloat = 3
        while px < 125 {
            ctx.rect(px, 43, 16, 13, rgb(0xBF966D), radius: 1.5)
            ctx.rect(px, 43, 16, 0.8, rgb(0xA98260).opacity(0.6))
            px += 20
        }
        floorPlanks(ctx, base: rgb(0xB98A62), line: rgb(0x7E5636).opacity(0.3))
        // thảm chạy dài
        ctx.rect(30, 70, 70, 20, rgb(0xB55B55).opacity(0.55), radius: 2)
        ctx.strokePath(rgb(0xF2D9A6).opacity(0.7), width: 0.8) { p in
            p.addRoundedRect(in: CGRect(x: 33, y: 72.5, width: 64, height: 15), cornerSize: CGSize(width: 1.5, height: 1.5))
        }
        baseboard(ctx, rgb(0x8E6748), highlight: rgb(0xC9A27A).opacity(0.6))
        windowBase(ctx, frame: rgb(0x8E6748))
        glass(ctx, rgb(0xFCE6C4))
        ctx.circle(80, 25, 5, rgb(0xF7B970))
        ctx.ellipse(60, 26, 28, 10, rgb(0xC9DDB0))
        ctx.ellipse(70, 28, 24, 8, rgb(0xB0CE98))
        glassShine(ctx)
        windowBars(ctx, sill: rgb(0x6E4F38), bar: rgb(0x8E6748))
        curtains(ctx, rgb(0xE8C07A).opacity(0.9), shade: rgb(0xB57F3E), valance: rgb(0xD9A85E))
        // kệ treo nhỏ bên phải có sách
        ctx.rect(98, 24, 22, 2.4, rgb(0x8E6748), radius: 1)
        let books: [(CGFloat, CGFloat, UInt32)] = [(100, 9, 0xB55B55), (103.5, 11, 0x6F9A72), (107, 8, 0xD9A441), (110.5, 10, 0x7B6FB8)]
        for b in books { ctx.rect(b.0, 24 - b.1, 3.2, b.1, rgb(b.2), radius: 0.6) }
        ctx.rotated(18, around: CGPoint(x: 116, y: 24)) { c in c.rect(114, 15, 3.2, 9, rgb(0xE59A7A), radius: 0.6) }
    }

    // MARK: - Theme: Ngày mưa

    private static func drawRain(_ ctx: GraphicsContext) {
        ctx.rect(0, 0, 125, 62, rgb(0xDDE6F0))
        // sọc mảnh như vệt mưa trên giấy dán tường
        ctx.strokePath(rgb(0xC6D3E3), width: 0.7) { p in
            var x: CGFloat = 4
            while x < 125 {
                if !(x > 52 && x < 93) {
                    p.move(to: CGPoint(x: x, y: 4)); p.addLine(to: CGPoint(x: x, y: 8))
                    p.move(to: CGPoint(x: x + 4, y: 18)); p.addLine(to: CGPoint(x: x + 4, y: 22))
                    p.move(to: CGPoint(x: x, y: 32)); p.addLine(to: CGPoint(x: x, y: 36))
                }
                p.move(to: CGPoint(x: x + 4, y: 46)); p.addLine(to: CGPoint(x: x + 4, y: 50))
                x += 9
            }
        }
        floorPlanks(ctx, base: rgb(0xE9DCC8), line: rgb(0xB59A7A).opacity(0.25))
        baseboard(ctx, rgb(0xFFFFFF).opacity(0.8), highlight: rgb(0xC6D3E3))
        windowBase(ctx, frame: rgb(0xFFFFFF))
        glass(ctx, rgb(0xA9B9CF))
        var g = ctx
        g.clip(to: glassPath)
        g.ellipse(56, 6, 22, 9, rgb(0x93A4BC))
        g.ellipse(70, 4, 22, 10, rgb(0x8C9DB6))
        g.ellipse(58, 26, 34, 12, rgb(0x8FA88E))
        g.strokePath(Color.white.opacity(0.6), width: 0.6) { p in
            let drops: [(CGFloat, CGFloat)] = [(62, 14), (66, 22), (71, 12), (76, 19), (81, 13), (84, 24), (63, 28), (79, 28)]
            for d in drops {
                p.move(to: CGPoint(x: d.0, y: d.1)); p.addLine(to: CGPoint(x: d.0 - 1, y: d.1 + 3))
            }
        }
        // giọt nước đọng trên kính
        let beads: [(CGFloat, CGFloat, CGFloat)] = [(64, 18, 0.9), (74, 25, 1.1), (83, 17, 0.8), (69, 30, 0.7)]
        for b in beads {
            ctx.circle(b.0, b.1, b.2, Color.white.opacity(0.75))
        }
        glassShine(ctx)
        windowBars(ctx, sill: rgb(0xF4F6FA), bar: rgb(0xFFFFFF))
        curtains(ctx, rgb(0xF6D58A).opacity(0.9), shade: rgb(0xE0A94E), valance: rgb(0xF0C46A))
        // ô vàng treo móc sát mép phải tường (tránh chỗ đặt đèn), nhỏ nước
        var u = ctx
        u.translateBy(x: 13, y: 0)
        u.rect(104, 20, 3, 3, rgb(0x8E8EA8), radius: 1)
        var umb = Path()
        umb.move(to: CGPoint(x: 105.5, y: 22))
        umb.addLine(to: CGPoint(x: 100, y: 46))
        umb.addQuadCurve(to: CGPoint(x: 111, y: 46), control: CGPoint(x: 105.5, y: 49))
        umb.closeSubpath()
        u.fill(umb, with: .color(rgb(0xF2B84B)))
        u.strokePath(rgb(0xD99A2E), width: 0.6) { p in
            p.move(to: CGPoint(x: 105.5, y: 23)); p.addLine(to: CGPoint(x: 105.5, y: 47))
        }
        u.strokePath(rgb(0x7E6A5A), width: 1.2) { p in
            p.move(to: CGPoint(x: 105.5, y: 47)); p.addLine(to: CGPoint(x: 105.5, y: 52))
            p.addQuadCurve(to: CGPoint(x: 108.5, y: 52), control: CGPoint(x: 107, y: 55))
        }
        u.circle(104, 57, 0.8, rgb(0x93B4DA))
        u.circle(106, 60, 0.6, rgb(0x93B4DA))
        // vũng nước nhỏ dưới ô
        u.ellipse(99, 63, 14, 2.4, rgb(0xB9CDE6).opacity(0.7))
    }

    // MARK: - Đồ treo tường thêm

    private static func drawChalkboard(_ ctx: GraphicsContext) {
        ctx.rect(10, 18, 80, 60, rgb(0xB88B5E), radius: 5)
        ctx.rect(14, 22, 72, 50, rgb(0x4F6F62), radius: 2)
        ctx.rect(14, 22, 72, 2, Color.white.opacity(0.1))
        let chalk = Color.white.opacity(0.85)
        // A+ và ngôi sao
        ctx.draw(Text("A+").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(chalk), at: CGPoint(x: 31, y: 36))
        ctx.draw(Text("★").font(.system(size: 11)).foregroundColor(rgb(0xF6D58A)), at: CGPoint(x: 48, y: 32))
        // mặt mèo vẽ phấn
        ctx.strokePath(rgb(0xF7C6D3), width: 1.3) { p in
            p.addEllipse(in: CGRect(x: 58, y: 30, width: 20, height: 16))
            p.move(to: CGPoint(x: 60, y: 33)); p.addLine(to: CGPoint(x: 61, y: 26)); p.addLine(to: CGPoint(x: 65, y: 31))
            p.move(to: CGPoint(x: 76, y: 33)); p.addLine(to: CGPoint(x: 75, y: 26)); p.addLine(to: CGPoint(x: 71, y: 31))
            p.move(to: CGPoint(x: 66, y: 41)); p.addQuadCurve(to: CGPoint(x: 70, y: 41), control: CGPoint(x: 68, y: 43))
        }
        ctx.circle(64, 37.5, 1, rgb(0xF7C6D3))
        ctx.circle(72, 37.5, 1, rgb(0xF7C6D3))
        // phép tính và đường gạch
        ctx.strokePath(chalk, width: 1.1) { p in
            p.move(to: CGPoint(x: 20, y: 52)); p.addLine(to: CGPoint(x: 50, y: 52))
            p.move(to: CGPoint(x: 20, y: 58)); p.addLine(to: CGPoint(x: 42, y: 58))
            p.move(to: CGPoint(x: 20, y: 64)); p.addLine(to: CGPoint(x: 46, y: 64))
        }
        ctx.heart(center: CGPoint(x: 70, y: 58), size: 10, rgb(0xF4B0B0).opacity(0.85))
        // vết lau mờ
        ctx.ellipse(54, 62, 26, 6, Color.white.opacity(0.08))
        // khay phấn
        ctx.rect(8, 72, 84, 6, rgb(0x9C7350), radius: 2)
        ctx.rect(24, 69.5, 10, 3, Color.white, radius: 1.5)
        ctx.rect(37, 69.5, 7, 3, rgb(0xF4B0B0), radius: 1.5)
        ctx.rect(60, 67, 16, 6, rgb(0xE59A7A), radius: 1.5)
        ctx.rect(60, 70.5, 16, 2.5, rgb(0xF0E4D2), radius: 1)
    }

    private static func polaroid(_ ctx: GraphicsContext, _ cx: CGFloat, _ top: CGFloat, _ angle: Double, _ photo: Color,
                                 _ content: (GraphicsContext, CGRect) -> Void) {
        ctx.rotated(angle, around: CGPoint(x: cx, y: top)) { c0 in
            var c = c0
            // phóng to 1,25 lần quanh kẹp
            c.translateBy(x: cx, y: top)
            c.scaleBy(x: 1.25, y: 1.25)
            c.translateBy(x: -cx, y: -top)
            c.rect(cx - 9.5, top + 1, 19, 22, Color.black.opacity(0.08), radius: 1.5)
            c.rect(cx - 10, top, 19, 22, Color.white, radius: 1.5)
            let r = CGRect(x: cx - 8, y: top + 2, width: 15, height: 13)
            c.rect(r.minX, r.minY, r.width, r.height, photo)
            var cc = c
            cc.clip(to: Path(r))
            content(cc, r)
            // kẹp gỗ
            c.rect(cx - 2.5, top - 4, 4, 7, rgb(0xD9B48A), radius: 1)
            c.rect(cx - 2.5, top - 1.2, 4, 0.8, rgb(0xA97F58))
        }
    }

    private static func drawPhotoLine(_ ctx: GraphicsContext) {
        // đinh và dây treo võng
        ctx.circle(4, 26, 2.4, Palette.woodDark)
        ctx.circle(96, 26, 2.4, Palette.woodDark)
        ctx.strokePath(rgb(0xB89A7A), width: 1.1) { p in
            p.move(to: CGPoint(x: 4, y: 26)); p.addQuadCurve(to: CGPoint(x: 96, y: 26), control: CGPoint(x: 50, y: 48))
        }
        // đèn hạt nhỏ dọc dây
        let bulbs: [(CGFloat, CGFloat)] = [(26, 34), (49.5, 37), (72.5, 34.4)]
        for b in bulbs {
            ctx.circle(b.0, b.1 + 2.4, 4, rgb(0xFFE3A0).opacity(0.35))
            ctx.circle(b.0, b.1 + 2.4, 2, rgb(0xFFD66B))
        }
        polaroid(ctx, 15, 30.6, -8, rgb(0xCFE6F4)) { c, r in
            c.ellipse(r.minX - 4, r.maxY - 6, 14, 10, Palette.sage)
            c.ellipse(r.minX + 5, r.maxY - 5, 14, 9, rgb(0x8DB88F))
            c.circle(r.maxX - 4, r.minY + 4, 2.4, Palette.honey)
        }
        polaroid(ctx, 38, 36.2, 5, rgb(0xFBE3EA)) { c, r in
            c.heart(center: CGPoint(x: r.midX, y: r.midY + 0.5), size: 9, Palette.blush)
        }
        polaroid(ctx, 61, 36.4, -4, rgb(0xFFF2D6)) { c, r in
            // mặt mèo
            c.circle(r.midX, r.midY + 2, 5.5, Palette.catCream)
            c.polygon([CGPoint(x: r.midX - 5, y: r.midY - 1), CGPoint(x: r.midX - 4, y: r.midY - 6.5), CGPoint(x: r.midX - 1, y: r.midY - 3)], Palette.catCream)
            c.polygon([CGPoint(x: r.midX + 5, y: r.midY - 1), CGPoint(x: r.midX + 4, y: r.midY - 6.5), CGPoint(x: r.midX + 1, y: r.midY - 3)], Palette.catCream)
            c.circle(r.midX - 2, r.midY + 1.5, 0.7, Palette.catInk)
            c.circle(r.midX + 2, r.midY + 1.5, 0.7, Palette.catInk)
            c.ellipse(r.midX - 4.5, r.midY + 3, 2, 1.2, Palette.blush)
            c.ellipse(r.midX + 2.5, r.midY + 3, 2, 1.2, Palette.blush)
        }
        polaroid(ctx, 84, 31, 9, rgb(0x34406A)) { c, r in
            c.circle(r.midX + 2, r.midY - 1, 3.4, rgb(0xFBE7A6))
            c.circle(r.midX + 3.6, r.midY - 2.2, 3, rgb(0x34406A))
            c.circle(r.minX + 3, r.minY + 3, 0.6, Color.white)
            c.circle(r.minX + 5, r.maxY - 3, 0.5, Color.white)
            c.circle(r.maxX - 3, r.maxY - 2.5, 0.6, Color.white)
        }
    }

    private static func drawMacrame(_ ctx: GraphicsContext) {
        let cord = rgb(0xF1E3CC)
        let cordDark = rgb(0xD9C4A2)
        // móc treo + vòng gỗ
        ctx.rect(46, 0, 8, 3, Palette.woodDark, radius: 1)
        ctx.strokePath(Palette.woodDark, width: 2.4) { p in
            p.addEllipse(in: CGRect(x: 45, y: 3, width: 10, height: 10))
        }
        // dây thắt nút hình thoi
        ctx.strokePath(cord, width: 1.6) { p in
            p.move(to: CGPoint(x: 49, y: 13)); p.addLine(to: CGPoint(x: 30, y: 38)); p.addLine(to: CGPoint(x: 38, y: 56))
            p.move(to: CGPoint(x: 51, y: 13)); p.addLine(to: CGPoint(x: 70, y: 38)); p.addLine(to: CGPoint(x: 62, y: 56))
            p.move(to: CGPoint(x: 50, y: 13)); p.addLine(to: CGPoint(x: 42, y: 30)); p.addLine(to: CGPoint(x: 58, y: 44)); p.addLine(to: CGPoint(x: 52, y: 56))
            p.move(to: CGPoint(x: 50, y: 13)); p.addLine(to: CGPoint(x: 58, y: 30)); p.addLine(to: CGPoint(x: 42, y: 44)); p.addLine(to: CGPoint(x: 48, y: 56))
        }
        let knots: [(CGFloat, CGFloat)] = [(50, 14), (30, 38), (70, 38), (50, 37), (42, 30), (58, 30)]
        for k in knots {
            ctx.circle(k.0, k.1, 2.2, cordDark)
            ctx.circle(k.0 - 0.6, k.1 - 0.6, 0.8, Color.white.opacity(0.5))
        }
        // chậu tròn
        ctx.ellipse(28, 52, 44, 10, rgb(0x7E9C7E))
        var pot = Path()
        pot.move(to: CGPoint(x: 29, y: 57))
        pot.addQuadCurve(to: CGPoint(x: 71, y: 57), control: CGPoint(x: 50, y: 92))
        pot.closeSubpath()
        ctx.fill(pot, with: .color(rgb(0xF2B9A6)))
        ctx.ellipse(28, 53, 44, 8, rgb(0xF6CDBE))
        ctx.ellipse(32, 54.5, 36, 5, rgb(0x6E5A4C))
        ctx.strokePath(Color.white.opacity(0.55), width: 1.6) { p in
            p.move(to: CGPoint(x: 35, y: 63)); p.addQuadCurve(to: CGPoint(x: 41, y: 72), control: CGPoint(x: 36, y: 69))
        }
        // dây vòng quanh chậu
        ctx.strokePath(cord, width: 1.6) { p in
            p.move(to: CGPoint(x: 38, y: 56)); p.addLine(to: CGPoint(x: 44, y: 76))
            p.move(to: CGPoint(x: 62, y: 56)); p.addLine(to: CGPoint(x: 56, y: 76))
            p.move(to: CGPoint(x: 48, y: 56)); p.addLine(to: CGPoint(x: 48, y: 76))
            p.move(to: CGPoint(x: 52, y: 56)); p.addLine(to: CGPoint(x: 52, y: 76))
        }
        ctx.circle(50, 77, 3, cordDark)
        ctx.strokePath(cord, width: 1.2) { p in
            for dx in [-3.0, -1.0, 1.0, 3.0] as [CGFloat] {
                p.move(to: CGPoint(x: 50 + dx * 0.6, y: 79)); p.addLine(to: CGPoint(x: 50 + dx, y: 90))
            }
        }
        // dây trầu bà rủ xuống hai bên
        let green = rgb(0x7DB97A)
        let light = rgb(0xA4D39C)
        ctx.strokePath(rgb(0x6AA468), width: 1.2) { p in
            p.move(to: CGPoint(x: 32, y: 55)); p.addQuadCurve(to: CGPoint(x: 18, y: 92), control: CGPoint(x: 16, y: 66))
            p.move(to: CGPoint(x: 68, y: 55)); p.addQuadCurve(to: CGPoint(x: 80, y: 84), control: CGPoint(x: 84, y: 64))
        }
        let leaves: [(CGFloat, CGFloat, Double, Bool)] = [
            (34, 50, -30, false), (44, 47, -10, true), (56, 47, 15, false), (66, 50, 30, true), (50, 45, 0, false),
            (26, 60, -60, true), (20, 72, -80, false), (19, 84, -100, true), (16, 92, -90, false),
            (74, 60, 60, false), (80, 70, 80, true), (80, 80, 100, false)
        ]
        for l in leaves {
            ctx.rotated(l.2, around: CGPoint(x: l.0, y: l.1)) { c in
                c.ellipse(l.0 - 3.6, l.1 - 5, 7.2, 10, l.3 ? light : green)
            }
        }
    }

    // MARK: - Đèn thêm

    private static func drawGlobeLamp(_ ctx: GraphicsContext) {
        ctx.circle(50, 42, 42, rgb(0xFFE6A8).opacity(0.14))
        ctx.circle(50, 42, 33, rgb(0xFFE6A8).opacity(0.18))
        ctx.ellipse(24, 88, 52, 8, Color.black.opacity(0.1))
        // chân gỗ
        ctx.ellipse(28, 82, 44, 12, Palette.woodDark)
        ctx.ellipse(30, 80, 40, 9, Palette.wood)
        ctx.rect(46, 70, 8, 12, Palette.woodDark, radius: 2)
        // vòng kinh tuyến
        ctx.strokePath(rgb(0xD9A441), width: 3.2) { p in
            p.addArc(center: CGPoint(x: 50, y: 42), radius: 32, startAngle: .degrees(100), endAngle: .degrees(-100), clockwise: false)
        }
        // quả cầu
        let globe = Path(ellipseIn: CGRect(x: 22, y: 14, width: 56, height: 56))
        ctx.fill(globe, with: .color(rgb(0x8CC9E8)))
        var g = ctx
        g.clip(to: globe)
        g.circle(50, 42, 28, rgb(0xA8DAF0))
        // lục địa
        g.ellipse(26, 22, 22, 16, rgb(0xA6D49A))
        g.ellipse(34, 34, 12, 20, rgb(0xA6D49A))
        g.ellipse(54, 22, 20, 12, rgb(0xA6D49A))
        g.ellipse(58, 30, 14, 14, rgb(0xA6D49A))
        g.ellipse(60, 48, 12, 14, rgb(0xA6D49A))
        g.ellipse(36, 60, 26, 8, Color.white.opacity(0.9))
        g.ellipse(40, 14, 22, 5, Color.white.opacity(0.9))
        // ánh sáng bên trong
        g.circle(44, 34, 20, rgb(0xFFF4C8).opacity(0.35))
        g.ellipse(28, 22, 10, 16, Color.white.opacity(0.35))
        // đường xích đạo
        ctx.strokePath(Color.white.opacity(0.5), width: 0.8) { p in
            p.move(to: CGPoint(x: 22, y: 42)); p.addQuadCurve(to: CGPoint(x: 78, y: 42), control: CGPoint(x: 50, y: 50))
        }
        ctx.circle(50, 10, 2.4, rgb(0xD9A441))
        ctx.circle(50, 74, 2.4, rgb(0xD9A441))
        // máy bay giấy bay quanh
        ctx.polygon([CGPoint(x: 80, y: 18), CGPoint(x: 92, y: 14), CGPoint(x: 86, y: 24)], Color.white)
        ctx.polygon([CGPoint(x: 92, y: 14), CGPoint(x: 84, y: 20), CGPoint(x: 86, y: 24)], rgb(0xDCE4F4))
        ctx.strokePath(rgb(0xB0BCD8), width: 0.8) { p in
            p.move(to: CGPoint(x: 79, y: 20)); p.addQuadCurve(to: CGPoint(x: 70, y: 8), control: CGPoint(x: 70, y: 18))
        }
    }

    private static func drawStarProjector(_ ctx: GraphicsContext) {
        // sao được chiếu ra xung quanh
        let cast: [(CGFloat, CGFloat, CGFloat)] = [(10, 12, 7), (30, 4, 5), (76, 6, 6), (92, 22, 7), (8, 40, 5), (90, 46, 5), (54, 2, 4), (20, 26, 4)]
        for s in cast {
            ctx.draw(Text("★").font(.system(size: s.2)).foregroundColor(rgb(0xF6D58A).opacity(0.9)), at: CGPoint(x: s.0, y: s.1))
        }
        ctx.circle(50, 58, 30, rgb(0xB9C4FF).opacity(0.14))
        ctx.ellipse(18, 88, 64, 8, Color.black.opacity(0.1))
        // đế
        ctx.rect(22, 72, 56, 18, rgb(0x6E7CC2), radius: 7)
        ctx.rect(22, 84, 56, 6, rgb(0x5A67AA), radius: 4)
        ctx.circle(36, 80, 2.6, rgb(0xF6D58A))
        ctx.circle(46, 80, 2, Color.white.opacity(0.7))
        ctx.rect(56, 78.5, 14, 3, Color.white.opacity(0.4), radius: 1.5)
        // vòm có lỗ sao
        var dome = Path()
        dome.move(to: CGPoint(x: 20, y: 74))
        dome.addCurve(to: CGPoint(x: 80, y: 74), control1: CGPoint(x: 20, y: 30), control2: CGPoint(x: 80, y: 30))
        dome.closeSubpath()
        ctx.fill(dome, with: .color(rgb(0x3C4682)))
        var d = ctx
        d.clip(to: dome)
        d.circle(40, 48, 22, rgb(0x4E5AA0))
        let holes: [(CGFloat, CGFloat, CGFloat)] = [(34, 56, 7), (50, 46, 8), (64, 58, 7), (42, 66, 5), (58, 68, 5), (30, 68, 4), (70, 68, 4), (50, 60, 4)]
        for h in holes {
            d.draw(Text("★").font(.system(size: h.2)).foregroundColor(rgb(0xFFF1C2)), at: CGPoint(x: h.0, y: h.1))
        }
        ctx.strokePath(Color.white.opacity(0.35), width: 2) { p in
            p.move(to: CGPoint(x: 27, y: 62)); p.addQuadCurve(to: CGPoint(x: 38, y: 44), control: CGPoint(x: 28, y: 50))
        }
        ctx.rect(18, 72, 64, 4, rgb(0xF6D58A), radius: 2)
    }

    private static func drawLavaLamp(_ ctx: GraphicsContext) {
        ctx.circle(50, 50, 34, rgb(0xF7B6D0).opacity(0.16))
        ctx.ellipse(28, 88, 44, 8, Color.black.opacity(0.1))
        let metal = rgb(0x9D8FD6)
        let metalDark = rgb(0x8273C2)
        // đế hình nón cụt
        ctx.polygon([CGPoint(x: 38, y: 62), CGPoint(x: 62, y: 62), CGPoint(x: 72, y: 90), CGPoint(x: 28, y: 90)], metal)
        ctx.polygon([CGPoint(x: 56, y: 62), CGPoint(x: 62, y: 62), CGPoint(x: 72, y: 90), CGPoint(x: 62, y: 90)], metalDark)
        ctx.rect(30, 86, 40, 5, metalDark, radius: 2)
        // bình thủy tinh
        var glass = Path()
        glass.move(to: CGPoint(x: 44, y: 14))
        glass.addLine(to: CGPoint(x: 56, y: 14))
        glass.addLine(to: CGPoint(x: 64, y: 62))
        glass.addLine(to: CGPoint(x: 36, y: 62))
        glass.closeSubpath()
        ctx.fill(glass, with: .color(rgb(0xD9CCF6)))
        var g = ctx
        g.clip(to: glass)
        g.rect(30, 40, 40, 24, rgb(0xCDBEF2))
        // giọt sáp
        g.ellipse(41, 50, 18, 14, rgb(0xF59AB8))
        g.ellipse(46, 36, 10, 11, rgb(0xF59AB8))
        g.ellipse(48, 20, 7, 8, rgb(0xF59AB8))
        g.ellipse(53, 30, 5, 5, rgb(0xF7B0C8))
        g.ellipse(43, 52, 6, 4, Color.white.opacity(0.35))
        g.rect(40, 14, 3, 50, Color.white.opacity(0.35))
        // nắp
        ctx.polygon([CGPoint(x: 43, y: 6), CGPoint(x: 57, y: 6), CGPoint(x: 56, y: 15), CGPoint(x: 44, y: 15)], metal)
        ctx.rect(42.5, 4, 15, 3, metalDark, radius: 1.5)
        ctx.rect(35, 60, 30, 4, metalDark, radius: 2)
    }

    // MARK: - Bàn thêm

    /// Mặt bàn + chân như bàn gốc (mặt 40…49, chân tới 91).
    private static func simpleDesk(_ ctx: GraphicsContext, top: Color, leg: Color, drawer: Bool) {
        ctx.rect(8, 40, 84, 9, top, radius: 3)
        ctx.rect(10, 40.5, 80, 1.8, Color.white.opacity(0.35), radius: 1)
        ctx.rect(14, 49, 6, 42, leg, radius: 2)
        ctx.rect(80, 49, 6, 42, leg, radius: 2)
        if drawer {
            ctx.rect(54, 49, 26, 14, top, radius: 2)
            ctx.rect(54, 49, 26, 2, leg.opacity(0.4))
            ctx.rect(63, 55, 8, 2.4, leg, radius: 1.2)
        }
    }

    private static func drawFishbowlDesk(_ ctx: GraphicsContext) {
        simpleDesk(ctx, top: rgb(0xF4EEE6), leg: rgb(0xD8C9B6), drawer: false)
        // giá treo thanh ngang giữa hai chân
        ctx.rect(20, 76, 60, 3, rgb(0xD8C9B6), radius: 1.5)
        ctx.rect(26, 69, 8, 7, Palette.peach, radius: 1)
        ctx.rect(35, 71, 7, 5, Palette.lavender, radius: 1)
        // chồng sách
        ctx.rect(14, 33, 22, 7, rgb(0x8EB4D9), radius: 1.5)
        ctx.rect(16, 27, 19, 6, rgb(0xF4B0B0), radius: 1.5)
        ctx.rect(15, 22, 18, 5, rgb(0xF6D58A), radius: 1.5)
        ctx.rect(17, 34.5, 16, 1, Color.white.opacity(0.6))
        // bể cá tròn
        let bowl = Path(ellipseIn: CGRect(x: 44, y: 6, width: 40, height: 36))
        ctx.ellipse(46, 37, 36, 5, Color.black.opacity(0.08))
        ctx.fill(bowl, with: .color(rgb(0xE6F4FA).opacity(0.9)))
        var b = ctx
        b.clip(to: bowl)
        b.rect(40, 16, 50, 30, rgb(0x9FD6EA))
        b.ellipse(44, 13, 40, 6, rgb(0xC4E7F3))
        // sỏi và rong
        b.ellipse(46, 34, 36, 10, rgb(0xF1D9B8))
        let pebbles: [(CGFloat, CGFloat, UInt32)] = [(52, 36, 0xF4B0B0), (60, 37.5, 0xFFFFFF), (70, 36.5, 0xB7A6F0), (77, 37, 0xF6D58A)]
        for p in pebbles { b.circle(p.0, p.1, 1.8, rgb(p.2)) }
        b.strokePath(rgb(0x6FAE6C), width: 2) { p in
            p.move(to: CGPoint(x: 74, y: 36)); p.addQuadCurve(to: CGPoint(x: 74, y: 20), control: CGPoint(x: 78, y: 28))
            p.move(to: CGPoint(x: 78, y: 36)); p.addQuadCurve(to: CGPoint(x: 80, y: 24), control: CGPoint(x: 76, y: 30))
        }
        // cá vàng
        b.polygon([CGPoint(x: 66, y: 24), CGPoint(x: 72, y: 19.5), CGPoint(x: 71, y: 24), CGPoint(x: 72, y: 28.5)], rgb(0xF7A65A))
        b.ellipse(54, 19.5, 14, 9, rgb(0xF58B4C))
        b.ellipse(57, 20.5, 6, 3, rgb(0xFBC08A))
        b.circle(57, 23, 1, Palette.catInk)
        b.circle(52, 18, 1, Color.white.opacity(0.8))
        b.circle(50, 14, 0.8, Color.white.opacity(0.8))
        // vành miệng bể + ánh kính
        ctx.ellipse(50, 5, 28, 5, rgb(0xCFE9F3))
        ctx.strokePath(Color.white.opacity(0.75), width: 2) { p in
            p.move(to: CGPoint(x: 49, y: 20)); p.addQuadCurve(to: CGPoint(x: 52, y: 32), control: CGPoint(x: 48, y: 28))
        }
    }

    private static func drawTypewriterDesk(_ ctx: GraphicsContext) {
        let wood = rgb(0xB98A62)
        simpleDesk(ctx, top: wood, leg: rgb(0x8E6748), drawer: true)
        // ống cắm bút
        ctx.rect(78, 26, 10, 14, Palette.lavender, radius: 2)
        ctx.strokePath(rgb(0xF6D58A), width: 1.6) { p in p.move(to: CGPoint(x: 80, y: 26)); p.addLine(to: CGPoint(x: 78, y: 16)) }
        ctx.strokePath(rgb(0xE59A7A), width: 1.6) { p in p.move(to: CGPoint(x: 83, y: 26)); p.addLine(to: CGPoint(x: 84, y: 14)) }
        ctx.strokePath(rgb(0x6F9A72), width: 1.6) { p in p.move(to: CGPoint(x: 86, y: 26)); p.addLine(to: CGPoint(x: 90, y: 18)) }
        // giấy
        ctx.rect(30, 6, 26, 22, Color.white, radius: 1)
        ctx.rect(33, 10, 18, 1.3, Palette.catInk.opacity(0.35), radius: 0.6)
        ctx.rect(33, 13.5, 14, 1.3, Palette.catInk.opacity(0.35), radius: 0.6)
        ctx.heart(center: CGPoint(x: 49, y: 15), size: 4, Palette.blush)
        // máy đánh chữ
        let body = rgb(0x8FC9B6)
        let dark = rgb(0x6FAF9B)
        ctx.rect(22, 20, 42, 6, Palette.catInk.opacity(0.75), radius: 3)
        ctx.circle(21, 23, 3.4, Palette.catInk.opacity(0.75))
        ctx.circle(65, 23, 3.4, Palette.catInk.opacity(0.75))
        ctx.polygon([CGPoint(x: 24, y: 25), CGPoint(x: 62, y: 25), CGPoint(x: 68, y: 40), CGPoint(x: 18, y: 40)], body)
        ctx.rect(18, 36, 50, 4, dark, radius: 1.5)
        for row in 0..<2 {
            for col in 0..<7 {
                let x = 26 + CGFloat(col) * 5.4 + CGFloat(row) * 2
                ctx.circle(x, 29.5 + CGFloat(row) * 3.6, 1.5, rgb(0xFBF4E8))
            }
        }
        ctx.strokePath(Color.white.opacity(0.4), width: 1.2) { p in
            p.move(to: CGPoint(x: 26, y: 26.5)); p.addLine(to: CGPoint(x: 40, y: 26.5))
        }
        ctx.strokePath(Palette.catInk.opacity(0.6), width: 1.4) { p in
            p.move(to: CGPoint(x: 66, y: 21)); p.addLine(to: CGPoint(x: 72, y: 17))
        }
    }

    private static func drawLadderShelf(_ ctx: GraphicsContext) {
        let wood = rgb(0xD7B48C)
        let dark = rgb(0xB48C64)
        ctx.ellipse(10, 88, 80, 7, Color.black.opacity(0.1))
        // hai thanh thang
        ctx.polygon([CGPoint(x: 30, y: 4), CGPoint(x: 35, y: 4), CGPoint(x: 18, y: 92), CGPoint(x: 12, y: 92)], dark)
        ctx.polygon([CGPoint(x: 65, y: 4), CGPoint(x: 70, y: 4), CGPoint(x: 88, y: 92), CGPoint(x: 82, y: 92)], dark)
        // các tầng kệ (rộng dần xuống dưới)
        func shelf(_ y: CGFloat) -> (CGFloat, CGFloat) {
            let t = (y - 4) / 88
            return (32 - 18 * t, 68 + 18 * t)
        }
        let levels: [CGFloat] = [28, 52, 76]
        // đồ trên kệ (vẽ trước ván kệ)
        let (a1, _) = shelf(28)
        ctx.rect(a1 + 3, 18, 4, 10, rgb(0xE59A7A), radius: 0.8)
        ctx.rect(a1 + 7.5, 16, 4, 12, rgb(0x8EB4D9), radius: 0.8)
        ctx.rect(a1 + 12, 19, 4, 9, rgb(0xF6D58A), radius: 0.8)
        ctx.rect(54, 20, 10, 8, rgb(0xF4EEE6), radius: 2)
        ctx.ellipse(52, 11, 14, 11, Palette.sage)
        ctx.ellipse(56, 8, 8, 8, rgb(0x9CC39E))
        // tầng 2: khung ảnh + quả địa cầu nhỏ
        let (a2, _) = shelf(52)
        ctx.rect(a2 + 3, 37, 14, 15, rgb(0xFFFFFF), radius: 1.5)
        ctx.rect(a2 + 5, 39, 10, 9, rgb(0xFBE3EA))
        ctx.heart(center: CGPoint(x: a2 + 10, y: 43.5), size: 5, Palette.blush)
        ctx.rect(62, 49, 6, 3, Palette.woodDark, radius: 1)
        ctx.circle(65, 42, 7, rgb(0x8CC9E8))
        ctx.ellipse(60, 38, 6, 5, rgb(0xA6D49A))
        ctx.ellipse(65, 43, 5, 4, rgb(0xA6D49A))
        // tầng 3: sách nằm + giỏ len
        let (a3, _) = shelf(76)
        ctx.rect(a3 + 2, 71, 22, 5, rgb(0x7B6FB8), radius: 1)
        ctx.rect(a3 + 4, 66, 19, 5, rgb(0x8DB88F), radius: 1)
        ctx.rect(56, 64, 20, 12, rgb(0xE8C99A), radius: 3)
        ctx.strokePath(rgb(0xC9A475), width: 0.8) { p in
            for x in stride(from: CGFloat(59), to: 76, by: 4) {
                p.move(to: CGPoint(x: x, y: 65)); p.addLine(to: CGPoint(x: x, y: 75))
            }
        }
        ctx.circle(62, 63, 4, Palette.peach)
        ctx.circle(69, 63.5, 3.6, Palette.lavender)
        // ván kệ
        for y in levels {
            let (l, r) = shelf(y)
            ctx.rect(l - 2, y, r - l + 4, 4, wood, radius: 1.5)
            ctx.rect(l - 1, y + 0.5, r - l + 2, 1, Color.white.opacity(0.4), radius: 0.5)
        }
        ctx.rect(31, 3, 38, 4, wood, radius: 1.5)
    }

    // MARK: - Cây thêm

    private static func drawSunflowerPot(_ ctx: GraphicsContext) {
        ctx.ellipse(22, 90, 56, 7, Color.black.opacity(0.1))
        // thân + lá
        ctx.strokePath(rgb(0x6FAE6C), width: 4) { p in
            p.move(to: CGPoint(x: 50, y: 74)); p.addQuadCurve(to: CGPoint(x: 48, y: 36), control: CGPoint(x: 54, y: 56))
        }
        ctx.rotated(-35, around: CGPoint(x: 38, y: 58)) { c in c.ellipse(28, 53, 22, 10, rgb(0x84C27C)) }
        ctx.rotated(30, around: CGPoint(x: 62, y: 50)) { c in c.ellipse(52, 45, 22, 10, rgb(0x84C27C)) }
        // bông hướng dương có mặt cười
        let cx: CGFloat = 48, cy: CGFloat = 28, r: CGFloat = 20
        for i in 0..<12 {
            ctx.rotated(Double(i) * 30, around: CGPoint(x: cx, y: cy)) { c in
                c.ellipse(cx - r * 0.25, cy - r * 1.02, r * 0.5, r * 0.7, rgb(0xF2B530))
            }
        }
        for i in 0..<12 {
            ctx.rotated(Double(i) * 30 + 15, around: CGPoint(x: cx, y: cy)) { c in
                c.ellipse(cx - r * 0.22, cy - r * 0.95, r * 0.44, r * 0.62, rgb(0xFAD04A))
            }
        }
        ctx.circle(cx, cy, r * 0.5, rgb(0x8B5A3C))
        ctx.circle(cx - 3.5, cy - 1, 1.3, Palette.catInk)
        ctx.circle(cx + 3.5, cy - 1, 1.3, Palette.catInk)
        ctx.strokePath(Palette.catInk, width: 1) { p in
            p.move(to: CGPoint(x: cx - 2.5, y: cy + 2.5)); p.addQuadCurve(to: CGPoint(x: cx + 2.5, y: cy + 2.5), control: CGPoint(x: cx, y: cy + 5))
        }
        ctx.ellipse(cx - 7, cy + 1.5, 3.4, 2, Palette.blush)
        ctx.ellipse(cx + 3.6, cy + 1.5, 3.4, 2, Palette.blush)
        // chậu đất nung
        ctx.polygon([CGPoint(x: 32, y: 72), CGPoint(x: 68, y: 72), CGPoint(x: 64, y: 94), CGPoint(x: 36, y: 94)], rgb(0xE0906C))
        ctx.rect(29, 68, 42, 8, rgb(0xEBA582), radius: 2)
        ctx.rect(36, 80, 4, 10, Color.white.opacity(0.3), radius: 2)
    }

    private static func drawTerrarium(_ ctx: GraphicsContext) {
        ctx.ellipse(16, 90, 68, 7, Color.black.opacity(0.1))
        // đế gỗ
        ctx.ellipse(16, 82, 68, 12, Palette.woodDark)
        ctx.rect(16, 80, 68, 8, Palette.woodDark, radius: 3)
        ctx.ellipse(16, 76, 68, 12, Palette.wood)
        // bên trong: đất rêu, nấm, sen đá, đá
        ctx.ellipse(22, 72, 56, 12, rgb(0x8A6A52))
        ctx.ellipse(24, 69, 52, 10, rgb(0x8DB88F))
        ctx.ellipse(30, 68, 18, 6, rgb(0xA6D49A))
        // sen đá
        let rosette: [(CGFloat, CGFloat, Double)] = [(58, 64, -40), (62, 62, 0), (66, 64, 40), (60, 66, -70), (64, 66, 70)]
        for l in rosette {
            ctx.rotated(l.2, around: CGPoint(x: l.0, y: l.1)) { c in c.ellipse(l.0 - 2.5, l.1 - 6, 5, 10, rgb(0x9FCBB4)) }
        }
        ctx.circle(62, 66, 2.6, rgb(0xC3E3D2))
        // nấm nhỏ
        ctx.rect(37, 58, 4, 10, rgb(0xFBEFD9), radius: 2)
        ctx.ellipse(32, 53, 14, 9, rgb(0xE8736F))
        ctx.circle(36, 56, 1.2, Color.white)
        ctx.circle(41, 55, 1, Color.white)
        // cây dương xỉ
        ctx.strokePath(rgb(0x6FAE6C), width: 1.4) { p in
            p.move(to: CGPoint(x: 50, y: 68)); p.addQuadCurve(to: CGPoint(x: 48, y: 40), control: CGPoint(x: 54, y: 52))
        }
        for i in 0..<5 {
            let y = 46 + CGFloat(i) * 4.5
            ctx.ellipse(43 - CGFloat(i) * 0.4, y, 6, 2.6, rgb(0x7DB97A))
            ctx.ellipse(50.5, y + 1.5, 6, 2.6, rgb(0x7DB97A))
        }
        ctx.ellipse(70, 70, 7, 4, rgb(0xD8D2CC))
        // chuông kính
        var dome = Path()
        dome.move(to: CGPoint(x: 20, y: 78))
        dome.addLine(to: CGPoint(x: 20, y: 40))
        dome.addCurve(to: CGPoint(x: 80, y: 40), control1: CGPoint(x: 20, y: 10), control2: CGPoint(x: 80, y: 10))
        dome.addLine(to: CGPoint(x: 80, y: 78))
        ctx.fill(dome, with: .color(rgb(0xDDF0F7).opacity(0.28)))
        ctx.stroke(dome, with: .color(rgb(0xB9DCEA)), lineWidth: 1.6)
        ctx.strokePath(Color.white.opacity(0.8), width: 2.4) { p in
            p.move(to: CGPoint(x: 27, y: 62)); p.addLine(to: CGPoint(x: 27, y: 40))
            p.addQuadCurve(to: CGPoint(x: 38, y: 22), control: CGPoint(x: 28, y: 28))
        }
        // núm cầm trên đỉnh
        ctx.rect(46, 14, 8, 5, rgb(0xB9DCEA), radius: 1.5)
        ctx.circle(50, 12, 4, rgb(0xCDE8F2))
        ctx.circle(48.8, 10.8, 1.2, Color.white.opacity(0.9))
    }

    private static func drawTeacupSucculent(_ ctx: GraphicsContext) {
        ctx.ellipse(12, 88, 76, 8, Color.black.opacity(0.1))
        // đĩa lót
        ctx.ellipse(12, 80, 76, 14, rgb(0xEFC6D2))
        ctx.ellipse(18, 80, 64, 9, rgb(0xFBE3EA))
        // sen đá + xương rồng tròn nhô lên
        let petals: [(CGFloat, CGFloat, Double, UInt32)] = [
            (36, 46, -60, 0x9FCBB4), (44, 40, -25, 0xA9D5BC), (56, 40, 25, 0xA9D5BC), (64, 46, 60, 0x9FCBB4),
            (40, 42, -45, 0xB8DEC8), (60, 42, 45, 0xB8DEC8), (50, 38, 0, 0xB8DEC8)
        ]
        for p in petals {
            ctx.rotated(p.2, around: CGPoint(x: p.0, y: p.1 + 8)) { c in c.ellipse(p.0 - 5, p.1 - 8, 10, 18, rgb(p.3)) }
        }
        for p in petals {
            ctx.rotated(p.2, around: CGPoint(x: p.0, y: p.1 + 8)) { c in c.ellipse(p.0 - 1.5, p.1 - 7.2, 3, 3, rgb(0xF4B0C0)) }
        }
        ctx.circle(50, 48, 5, rgb(0xC9E8D6))
        // tách trà
        var cup = Path()
        cup.move(to: CGPoint(x: 22, y: 50))
        cup.addLine(to: CGPoint(x: 78, y: 50))
        cup.addCurve(to: CGPoint(x: 50, y: 86), control1: CGPoint(x: 78, y: 74), control2: CGPoint(x: 66, y: 86))
        cup.addCurve(to: CGPoint(x: 22, y: 50), control1: CGPoint(x: 34, y: 86), control2: CGPoint(x: 22, y: 74))
        cup.closeSubpath()
        // quai
        ctx.strokePath(rgb(0xF6B0C4), width: 4) { p in
            p.addEllipse(in: CGRect(x: 72, y: 56, width: 16, height: 14))
        }
        ctx.fill(cup, with: .color(rgb(0xF6B0C4)))
        var c = ctx
        c.clip(to: cup)
        let dots: [(CGFloat, CGFloat)] = [(30, 60), (44, 66), (58, 60), (70, 66), (36, 76), (52, 78), (64, 76)]
        for d in dots { c.circle(d.0, d.1, 2.2, Color.white.opacity(0.85)) }
        c.rect(18, 50, 64, 4, rgb(0xF9C9D6))
        ctx.ellipse(22, 47, 56, 7, rgb(0xFCE1E8))
        ctx.ellipse(25, 48, 50, 5, rgb(0x7A5E4C))
        ctx.strokePath(Color.white.opacity(0.6), width: 2) { p in
            p.move(to: CGPoint(x: 28, y: 58)); p.addQuadCurve(to: CGPoint(x: 34, y: 74), control: CGPoint(x: 28, y: 68))
        }
        // vài lá sen đá ló ra phía trước miệng tách
        ctx.rotated(-20, around: CGPoint(x: 42, y: 50)) { c in c.ellipse(37, 44, 10, 8, rgb(0xA9D5BC)) }
        ctx.rotated(20, around: CGPoint(x: 58, y: 50)) { c in c.ellipse(53, 44, 10, 8, rgb(0xA9D5BC)) }
        ctx.ellipse(44, 42, 12, 9, rgb(0xB8DEC8))
    }

    // MARK: - Ghế / thảm thêm

    private static func drawRocker(_ ctx: GraphicsContext) {
        let wood = rgb(0xC89B6D)
        let dark = rgb(0xA07448)
        ctx.ellipse(8, 88, 84, 8, Color.black.opacity(0.1))
        // tựa lưng song gỗ
        ctx.rect(22, 14, 7, 62, dark, radius: 3)
        ctx.rect(71, 14, 7, 62, dark, radius: 3)
        ctx.rect(22, 10, 56, 9, wood, radius: 4.5)
        for x in stride(from: CGFloat(34), to: 70, by: 9) {
            ctx.rect(x, 18, 4, 40, wood, radius: 2)
        }
        // chăn len khoác lên lưng ghế
        var throwBlanket = Path()
        throwBlanket.move(to: CGPoint(x: 26, y: 18))
        throwBlanket.addLine(to: CGPoint(x: 52, y: 18))
        throwBlanket.addQuadCurve(to: CGPoint(x: 46, y: 52), control: CGPoint(x: 54, y: 36))
        throwBlanket.addLine(to: CGPoint(x: 28, y: 50))
        throwBlanket.closeSubpath()
        ctx.fill(throwBlanket, with: .color(rgb(0xF4B6A4)))
        ctx.strokePath(rgb(0xFCEBD9), width: 2.4) { p in
            p.move(to: CGPoint(x: 27, y: 28)); p.addLine(to: CGPoint(x: 51, y: 28))
            p.move(to: CGPoint(x: 27, y: 38)); p.addLine(to: CGPoint(x: 50, y: 38))
        }
        ctx.strokePath(rgb(0xE59A88), width: 1) { p in
            for x in stride(from: CGFloat(30), to: 48, by: 3.5) {
                p.move(to: CGPoint(x: x, y: 51)); p.addLine(to: CGPoint(x: x, y: 55))
            }
        }
        // mặt ghế + nệm
        ctx.rect(14, 58, 72, 10, dark, radius: 4)
        ctx.rect(16, 52, 68, 10, rgb(0xB7A6F0), radius: 5)
        ctx.rect(20, 53.5, 50, 2.4, Color.white.opacity(0.45), radius: 1.2)
        // tay vịn
        ctx.strokePath(dark, width: 4.5) { p in
            p.move(to: CGPoint(x: 12, y: 48)); p.addLine(to: CGPoint(x: 28, y: 48))
            p.move(to: CGPoint(x: 72, y: 48)); p.addLine(to: CGPoint(x: 88, y: 48))
            p.move(to: CGPoint(x: 14, y: 48)); p.addLine(to: CGPoint(x: 16, y: 60))
            p.move(to: CGPoint(x: 86, y: 48)); p.addLine(to: CGPoint(x: 84, y: 60))
        }
        // chân + bập bênh cong
        ctx.strokePath(dark, width: 4) { p in
            p.move(to: CGPoint(x: 20, y: 66)); p.addLine(to: CGPoint(x: 18, y: 84))
            p.move(to: CGPoint(x: 80, y: 66)); p.addLine(to: CGPoint(x: 82, y: 84))
        }
        ctx.strokePath(wood, width: 5) { p in
            p.move(to: CGPoint(x: 4, y: 80)); p.addQuadCurve(to: CGPoint(x: 96, y: 80), control: CGPoint(x: 50, y: 96))
        }
    }

    private static func drawCatBeanbag(_ ctx: GraphicsContext) {
        let main = rgb(0xC9CDD8)
        let shade = rgb(0xB2B7C6)
        let inner = rgb(0xF4C6D2)
        ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
        // tai
        ctx.polygon([CGPoint(x: 14, y: 50), CGPoint(x: 20, y: 22), CGPoint(x: 40, y: 40)], main)
        ctx.polygon([CGPoint(x: 86, y: 50), CGPoint(x: 80, y: 22), CGPoint(x: 60, y: 40)], main)
        ctx.polygon([CGPoint(x: 20, y: 44), CGPoint(x: 22, y: 30), CGPoint(x: 33, y: 40)], inner)
        ctx.polygon([CGPoint(x: 80, y: 44), CGPoint(x: 78, y: 30), CGPoint(x: 67, y: 40)], inner)
        // thân tròn
        var body = Path()
        body.move(to: CGPoint(x: 8, y: 84))
        body.addCurve(to: CGPoint(x: 50, y: 34), control1: CGPoint(x: 2, y: 52), control2: CGPoint(x: 22, y: 34))
        body.addCurve(to: CGPoint(x: 92, y: 84), control1: CGPoint(x: 78, y: 34), control2: CGPoint(x: 98, y: 52))
        body.addQuadCurve(to: CGPoint(x: 8, y: 84), control: CGPoint(x: 50, y: 98))
        body.closeSubpath()
        ctx.fill(body, with: .color(main))
        // lõm chỗ ngồi
        ctx.ellipse(24, 46, 52, 18, shade.opacity(0.7))
        ctx.ellipse(27, 44, 46, 14, main)
        // mặt ngủ
        ctx.strokePath(Palette.catInk.opacity(0.75), width: 1.6) { p in
            p.move(to: CGPoint(x: 32, y: 70)); p.addQuadCurve(to: CGPoint(x: 42, y: 70), control: CGPoint(x: 37, y: 74))
            p.move(to: CGPoint(x: 58, y: 70)); p.addQuadCurve(to: CGPoint(x: 68, y: 70), control: CGPoint(x: 63, y: 74))
            p.move(to: CGPoint(x: 47, y: 77)); p.addQuadCurve(to: CGPoint(x: 50, y: 78), control: CGPoint(x: 48.5, y: 79))
            p.addQuadCurve(to: CGPoint(x: 53, y: 77), control: CGPoint(x: 51.5, y: 79))
        }
        ctx.polygon([CGPoint(x: 48, y: 74), CGPoint(x: 52, y: 74), CGPoint(x: 50, y: 76.5)], inner)
        ctx.ellipse(24, 74, 9, 5, Palette.blush.opacity(0.8))
        ctx.ellipse(67, 74, 9, 5, Palette.blush.opacity(0.8))
        // ria
        ctx.strokePath(Color.white.opacity(0.8), width: 1) { p in
            p.move(to: CGPoint(x: 22, y: 78)); p.addLine(to: CGPoint(x: 12, y: 76))
            p.move(to: CGPoint(x: 22, y: 81)); p.addLine(to: CGPoint(x: 13, y: 82))
            p.move(to: CGPoint(x: 78, y: 78)); p.addLine(to: CGPoint(x: 88, y: 76))
            p.move(to: CGPoint(x: 78, y: 81)); p.addLine(to: CGPoint(x: 87, y: 82))
        }
        ctx.strokePath(Color.white.opacity(0.5), width: 3) { p in
            p.move(to: CGPoint(x: 14, y: 70)); p.addQuadCurve(to: CGPoint(x: 22, y: 50), control: CGPoint(x: 13, y: 58))
        }
        // đuôi vòng ra trước
        ctx.strokePath(shade, width: 7) { p in
            p.move(to: CGPoint(x: 86, y: 86)); p.addQuadCurve(to: CGPoint(x: 62, y: 92), control: CGPoint(x: 80, y: 96))
        }
    }

    private static func drawPouf(_ ctx: GraphicsContext) {
        let knit = rgb(0x9FC7A6)
        let knitDark = rgb(0x86B28D)
        ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
        // thân đôn đan len
        ctx.rect(10, 52, 80, 36, knit, radius: 18)
        ctx.ellipse(10, 44, 80, 22, rgb(0xB3D5B8))
        // vân đan dọc (bím)
        var c = ctx
        c.clip(to: Path(roundedRect: CGRect(x: 10, y: 52, width: 80, height: 36), cornerRadius: 18))
        for x in stride(from: CGFloat(16), to: 90, by: 11) {
            for y in stride(from: CGFloat(58), to: 90, by: 6) {
                c.rotated(25, around: CGPoint(x: x, y: y)) { cc in cc.ellipse(x - 3, y - 1.3, 6, 2.6, knitDark.opacity(0.45)) }
                c.rotated(-25, around: CGPoint(x: x + 4.5, y: y)) { cc in cc.ellipse(x + 1.5, y - 1.3, 6, 2.6, knitDark.opacity(0.45)) }
            }
        }
        // mặt trên: đường xoắn đan
        ctx.strokePath(knitDark, width: 1.2) { p in
            p.addEllipse(in: CGRect(x: 22, y: 48, width: 56, height: 14))
            p.addEllipse(in: CGRect(x: 36, y: 52, width: 28, height: 6))
        }
        ctx.circle(50, 55, 2.2, knitDark)
        // sổ tay và bút đặt trên đôn
        ctx.rotated(-8, around: CGPoint(x: 70, y: 50)) { c in
            c.rect(60, 45, 20, 7, rgb(0xF6D58A), radius: 1.5)
            c.rect(60, 45, 20, 2, rgb(0xFFF2C8), radius: 1)
        }
        ctx.strokePath(Palette.peach, width: 1.8) { p in p.move(to: CGPoint(x: 62, y: 55)); p.addLine(to: CGPoint(x: 76, y: 52)) }
        ctx.strokePath(Color.white.opacity(0.5), width: 3) { p in
            p.move(to: CGPoint(x: 16, y: 64)); p.addQuadCurve(to: CGPoint(x: 22, y: 82), control: CGPoint(x: 15, y: 76))
        }
    }
}
