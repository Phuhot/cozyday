import SwiftUI

// Hình vẽ của Xếp Khối và Gộp Bánh — thuần GraphicsContext (không có View), vẽ bằng code, không dùng ảnh ngoài.
// Tách khỏi View để vẽ thử ra ảnh được cả ngoài Xcode.

enum PuzzleArt {
    // MARK: Kẹo dẻo (Xếp Khối)

    /// Màu kẹo dẻo pastel: (thân, sáng, viền đậm). Cố định, không đổi theo dark mode.
    static let candy: [(UInt32, UInt32, UInt32)] = [
        (0xF4A3B6, 0xFFD6E0, 0xD9768F), // dâu
        (0x9FD6B4, 0xD5F1DF, 0x67AE85), // bạc hà
        (0xB8A6EE, 0xE2D9FB, 0x8C77D0), // oải hương
        (0xF7CF72, 0xFFEDB8, 0xD5A23C), // chanh mật ong
        (0x96C8EF, 0xD2E8FA, 0x6499C9), // soda
        (0xF5AE83, 0xFFDCC6, 0xD7835A)  // đào
    ]

    static func candyColor(_ i: Int) -> (Color, Color, Color) {
        let c = candy[((i % candy.count) + candy.count) % candy.count]
        return (rgb(c.0), rgb(c.1), rgb(c.2))
    }

    /// Một viên kẹo dẻo vuông trong `r`. `face`: vẽ mắt cười nhỏ (chỉ khi ô đủ to).
    static func jelly(_ ctx: GraphicsContext, rect r: CGRect, color: Int, face: Bool = false) {
        let (body, light, dark) = candyColor(color)
        let s = min(r.width, r.height)
        let inset = s * 0.05
        let box = r.insetBy(dx: inset, dy: inset)
        let radius = s * 0.24
        // Đáy đậm như bóng thạch.
        ctx.fill(Path(roundedRect: box, cornerRadius: radius), with: .color(dark))
        let top = CGRect(x: box.minX, y: box.minY, width: box.width, height: box.height - s * 0.1)
        ctx.fill(Path(roundedRect: top, cornerRadius: radius),
                 with: .linearGradient(Gradient(colors: [light, body]), startPoint: CGPoint(x: top.midX, y: top.minY),
                                       endPoint: CGPoint(x: top.midX, y: top.maxY)))
        // Vệt bóng.
        ctx.fill(Path(roundedRect: CGRect(x: top.minX + s * 0.14, y: top.minY + s * 0.1, width: s * 0.36, height: s * 0.13),
                      cornerRadius: s * 0.065), with: .color(Color.white.opacity(0.75)))
        ctx.circle(top.maxX - s * 0.2, top.minY + s * 0.18, s * 0.05, Color.white.opacity(0.6))
        guard face, s >= 22 else { return }
        let ink = rgb(0x4A3C5C).opacity(0.75)
        let ey = top.midY + s * 0.06
        ctx.circle(top.midX - s * 0.15, ey, s * 0.05, ink)
        ctx.circle(top.midX + s * 0.15, ey, s * 0.05, ink)
        ctx.strokePath(ink, width: max(1, s * 0.045)) { p in
            p.move(to: CGPoint(x: top.midX - s * 0.07, y: ey + s * 0.1))
            p.addQuadCurve(to: CGPoint(x: top.midX + s * 0.07, y: ey + s * 0.1), control: CGPoint(x: top.midX, y: ey + s * 0.17))
        }
        ctx.ellipse(top.midX - s * 0.3, ey + s * 0.04, s * 0.12, s * 0.07, rgb(0xF48FA6).opacity(0.55))
        ctx.ellipse(top.midX + s * 0.18, ey + s * 0.04, s * 0.12, s * 0.07, rgb(0xF48FA6).opacity(0.55))
    }

    /// Khối trong khay hoặc đang kéo: góc trên trái ở `origin`, mỗi ô cạnh `cell`.
    static func piece(_ ctx: GraphicsContext, shape: BlockShape, color: Int, origin: CGPoint, cell: CGFloat, face: Bool = true) {
        // Mặt cười chỉ vẽ ở ô gần tâm, nhìn như một viên kẹo có mặt.
        let anchor = shape.anchor
        for c in shape.cells {
            let rect = CGRect(x: origin.x + CGFloat(c.col) * cell, y: origin.y + CGFloat(c.row) * cell, width: cell, height: cell)
            jelly(ctx, rect: rect, color: color, face: face && c == anchor)
        }
    }

    /// Nền bàn 8×8: khay kem viền tím nhạt, mỗi ô là một lõm nhỏ.
    static func blockBoard(_ ctx: GraphicsContext, size: CGSize) {
        let outer = CGRect(origin: .zero, size: size)
        let cell = size.width / CGFloat(BlockPuzzleEngine.size)
        ctx.fill(Path(roundedRect: outer, cornerRadius: cell * 0.45), with: .color(rgb(0xE9DDF6)))
        ctx.fill(Path(roundedRect: outer.insetBy(dx: cell * 0.08, dy: cell * 0.08), cornerRadius: cell * 0.4), with: .color(rgb(0xF6F0FB)))
        for r in 0..<BlockPuzzleEngine.size {
            for c in 0..<BlockPuzzleEngine.size {
                let rect = CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell).insetBy(dx: cell * 0.09, dy: cell * 0.09)
                ctx.fill(Path(roundedRect: rect, cornerRadius: cell * 0.2), with: .color((r + c) % 2 == 0 ? rgb(0xE6DCF3) : rgb(0xEDE5F7)))
            }
        }
    }

    // MARK: Món ngọt (Gộp Bánh)

    /// Màu nền của ô theo bậc.
    static func tileBackground(_ level: Int) -> Color {
        let colors: [UInt32] = [0xFFF0F3, 0xFBEBD8, 0xFDE2EC, 0xEEE6FB, 0xFFE0E6, 0xE3F2E8,
                                0xFFF1D2, 0xF4E6D4, 0xE2EEFB, 0xF0E2FA, 0xFFEFC4]
        guard level >= 1 else { return rgb(0xF7EDE2) }
        return level <= colors.count ? rgb(colors[level - 1]) : rgb(0xFFE59A)
    }

    /// Nền bàn 4×4.
    static func mergeBoard(_ ctx: GraphicsContext, size: CGSize) {
        let n = CGFloat(SweetMergeEngine.size)
        let cell = size.width / n
        ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cell * 0.22), with: .color(rgb(0xEBD9C6)))
        for i in 0..<(SweetMergeEngine.size * SweetMergeEngine.size) {
            ctx.fill(Path(roundedRect: tileRect(i, cell: cell), cornerRadius: cell * 0.16), with: .color(rgb(0xF7EDE2)))
        }
    }

    /// Khung một ô (đã chừa khe) trên bàn 4×4.
    static func tileRect(_ index: Int, cell: CGFloat) -> CGRect {
        let r = index / SweetMergeEngine.size, c = index % SweetMergeEngine.size
        let gap = cell * 0.06
        return CGRect(x: CGFloat(c) * cell + gap, y: CGFloat(r) * cell + gap, width: cell - gap * 2, height: cell - gap * 2)
    }

    /// Một ô món ngọt: nền màu theo bậc, hình món và con số giá trị.
    static func sweetTile(_ ctx: GraphicsContext, level: Int, rect r: CGRect, showValue: Bool = true) {
        let s = min(r.width, r.height)
        ctx.fill(Path(roundedRect: r, cornerRadius: s * 0.18), with: .color(tileBackground(level)))
        ctx.stroke(Path(roundedRect: r.insetBy(dx: s * 0.02, dy: s * 0.02), cornerRadius: s * 0.16),
                   with: .color(Color.white.opacity(0.7)), lineWidth: max(1, s * 0.025))
        var c = ctx
        c.translateBy(x: r.minX, y: r.minY)
        c.scaleBy(x: s / 100, y: s / 100)
        if showValue {
            // Hình nằm phía trên, số ở dưới.
            var art = c
            art.translateBy(x: 12, y: 2)
            art.scaleBy(x: 0.76, y: 0.76)
            sweet(art, level: level)
            let value = SweetLadder.value(level)
            let fontSize: CGFloat = value >= 10000 ? 14 : (value >= 1000 ? 16 : 19)
            c.draw(Text("\(value)").font(.system(size: fontSize, weight: .heavy, design: .rounded)).foregroundColor(rgb(0x5A4868)),
                   at: CGPoint(x: 50, y: 86))
        } else {
            sweet(c, level: level)
        }
    }

    /// Hình món ngọt bậc `level` trong khung 100×100.
    static func sweet(_ ctx: GraphicsContext, level: Int) {
        let shadow = Color.black.opacity(0.06)
        switch level {
        case 1: candyWrap(ctx, shadow: shadow)
        case 2: cookie(ctx, shadow: shadow)
        case 3: donut(ctx, shadow: shadow)
        case 4: cupcake(ctx, shadow: shadow)
        case 5: layerCake(ctx, tiers: 1, shadow: shadow)
        case 6: layerCake(ctx, tiers: 2, shadow: shadow)
        case 7: layerCake(ctx, tiers: 3, shadow: shadow)
        case 8: puffTower(ctx, shadow: shadow)
        case 9: rainbowCake(ctx, shadow: shadow)
        case 10: castle(ctx, shadow: shadow)
        case 11: crown(ctx, shadow: shadow)
        default: sweetStar(ctx)
        }
    }

    private static func candyWrap(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(22, 80, 56, 9, shadow)
        let wrap = rgb(0xF6A8BC), wrapDark = rgb(0xE07F9B)
        ctx.polygon([CGPoint(x: 34, y: 50), CGPoint(x: 10, y: 34), CGPoint(x: 14, y: 50), CGPoint(x: 10, y: 66)], wrap)
        ctx.polygon([CGPoint(x: 66, y: 50), CGPoint(x: 90, y: 34), CGPoint(x: 86, y: 50), CGPoint(x: 90, y: 66)], wrap)
        ctx.strokePath(wrapDark, width: 2) { p in
            p.move(to: CGPoint(x: 16, y: 42)); p.addLine(to: CGPoint(x: 30, y: 50))
            p.move(to: CGPoint(x: 84, y: 42)); p.addLine(to: CGPoint(x: 70, y: 50))
        }
        ctx.circle(50, 50, 21, rgb(0xFFC2D1))
        ctx.rotated(-30, around: CGPoint(x: 50, y: 50)) { c in
            for dx in [-12.0, 0.0, 12.0] as [CGFloat] { c.rect(50 + dx - 3, 28, 6, 44, Color.white.opacity(0.75)) }
        }
        ctx.ellipse(36, 34, 12, 7, Color.white.opacity(0.7))
    }

    private static func cookie(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(18, 80, 64, 9, shadow)
        ctx.circle(50, 50, 31, rgb(0xD9AE73))
        ctx.circle(50, 48, 28, rgb(0xEBC48C))
        for (x, y, r) in [(38.0, 38.0, 4.5), (60.0, 34.0, 4.0), (64.0, 55.0, 5.0), (42.0, 60.0, 4.5), (52, 47, 3.5)] as [(CGFloat, CGFloat, CGFloat)] {
            ctx.circle(x, y, r, rgb(0x7A4E2E))
        }
        ctx.ellipse(30, 30, 14, 6, Color.white.opacity(0.35))
    }

    private static func donut(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(16, 80, 68, 9, shadow)
        ctx.circle(50, 52, 32, rgb(0xE2B077))
        // Lớp kem hồng gợn sóng.
        var glaze = Path()
        let n = 12
        for i in 0...n {
            let a = Double(i) / Double(n) * 2 * .pi
            let rr: Double = i % 2 == 0 ? 28 : 25
            let p = CGPoint(x: 50 + rr * cos(a), y: 49 + rr * sin(a))
            if i == 0 { glaze.move(to: p) } else { glaze.addLine(to: p) }
        }
        glaze.closeSubpath()
        ctx.fill(glaze, with: .color(rgb(0xF59DB8)))
        ctx.circle(50, 51, 10, rgb(0xC98F5A))
        ctx.circle(50, 51, 8, Color.white.opacity(0.9))
        let sprinkles: [(CGFloat, CGFloat, Double, UInt32)] = [(34, 38, 30, 0xFFFFFF), (62, 34, -20, 0xFFE07A), (70, 52, 60, 0x9FD6B4),
                                                                (60, 66, 10, 0xFFFFFF), (36, 62, -40, 0x96C8EF), (30, 50, 80, 0xFFE07A),
                                                                (48, 32, 0, 0x9FD6B4)]
        for (x, y, deg, col) in sprinkles {
            ctx.rotated(deg, around: CGPoint(x: x, y: y)) { c in c.rect(x - 4, y - 1.5, 8, 3, rgb(col), radius: 1.5) }
        }
    }

    private static func cupcake(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(20, 82, 60, 9, shadow)
        var cup = Path()
        cup.move(to: CGPoint(x: 24, y: 52)); cup.addLine(to: CGPoint(x: 76, y: 52))
        cup.addLine(to: CGPoint(x: 68, y: 84)); cup.addLine(to: CGPoint(x: 32, y: 84)); cup.closeSubpath()
        ctx.fill(cup, with: .color(rgb(0x96C8EF)))
        ctx.strokePath(rgb(0x6499C9), width: 2.5) { p in
            for x in [36.0, 46.0, 56.0, 66.0] as [CGFloat] { p.move(to: CGPoint(x: x - 2, y: 54)); p.addLine(to: CGPoint(x: x - 4 + (x - 50) * 0.1, y: 82)) }
        }
        let cream = rgb(0xFFF4F7), creamShade = rgb(0xF6D3DE)
        ctx.ellipse(20, 40, 60, 18, creamShade)
        ctx.ellipse(22, 37, 56, 17, cream)
        ctx.ellipse(28, 26, 44, 16, creamShade)
        ctx.ellipse(30, 23, 40, 15, cream)
        ctx.ellipse(38, 13, 24, 14, cream)
        ctx.circle(56, 12, 7, rgb(0xE5536E))
        ctx.circle(54, 10, 2, Color.white.opacity(0.8))
        ctx.strokePath(rgb(0x6F9A72), width: 2) { p in p.move(to: CGPoint(x: 57, y: 6)); p.addQuadCurve(to: CGPoint(x: 64, y: 1), control: CGPoint(x: 59, y: 1)) }
    }

    /// Bánh kem tròn 1–3 tầng: kem trắng, sốt dâu chảy, dâu trên đỉnh.
    private static func layerCake(_ ctx: GraphicsContext, tiers: Int, shadow: Color) {
        ctx.ellipse(10, 84, 80, 9, shadow)
        ctx.ellipse(8, 80, 84, 8, rgb(0xE8DCEB))
        let widths: [CGFloat] = tiers == 1 ? [66] : (tiers == 2 ? [72, 48] : [76, 56, 36])
        let h: CGFloat = tiers == 1 ? 34 : (tiers == 2 ? 24 : 19)
        var bottom: CGFloat = 82
        let sponge = [rgb(0xFFF6EE), rgb(0xFFEFF3), rgb(0xFFF6EE)]
        for (i, w) in widths.enumerated() {
            let x = 50 - w / 2
            let top = bottom - h
            ctx.rect(x, top, w, h, sponge[i % sponge.count], radius: 5)
            ctx.rect(x, bottom - 5, w, 5, rgb(0xF2DCCB), radius: 2.5)
            // Sốt dâu chảy.
            var drip = Path()
            drip.move(to: CGPoint(x: x, y: top + 3))
            let bumps = Int(w / 9)
            for b in 0..<bumps {
                let bx = x + w * (CGFloat(b) + 0.5) / CGFloat(bumps)
                let depth: CGFloat = b % 2 == 0 ? 8 : 4.5
                drip.addQuadCurve(to: CGPoint(x: x + w * CGFloat(b + 1) / CGFloat(bumps), y: top + 3), control: CGPoint(x: bx, y: top + 3 + depth * 2))
            }
            drip.addLine(to: CGPoint(x: x + w, y: top + 3))
            drip.addLine(to: CGPoint(x: x + w, y: top))
            drip.addLine(to: CGPoint(x: x, y: top))
            drip.closeSubpath()
            ctx.fill(Path(roundedRect: CGRect(x: x, y: top, width: w, height: 6), cornerRadius: 3), with: .color(rgb(0xF08AA5)))
            ctx.fill(drip, with: .color(rgb(0xF08AA5)))
            bottom = top
        }
        // Dâu trên đỉnh.
        let topY = bottom
        var berry = Path()
        berry.move(to: CGPoint(x: 42, y: topY - 9))
        berry.addQuadCurve(to: CGPoint(x: 58, y: topY - 9), control: CGPoint(x: 50, y: topY - 14))
        berry.addQuadCurve(to: CGPoint(x: 50, y: topY + 3), control: CGPoint(x: 58, y: topY - 1))
        berry.addQuadCurve(to: CGPoint(x: 42, y: topY - 9), control: CGPoint(x: 42, y: topY - 1))
        ctx.fill(berry, with: .color(rgb(0xE5536E)))
        ctx.ellipse(43, topY - 14, 14, 6, rgb(0x7FBF6A))
        for (dx, dy) in [(-3.0, -6.0), (3.0, -5.0), (0.0, -2.0)] as [(CGFloat, CGFloat)] { ctx.circle(50 + dx, topY + dy, 0.9, rgb(0xFFE07A)) }
        if tiers == 3 {
            ctx.rect(49, topY - 26, 3, 12, rgb(0x96C8EF), radius: 1.5)
            ctx.ellipse(47.5, topY - 34, 6, 9, rgb(0xFFC94D))
        }
    }

    /// Tháp bánh su kem.
    private static func puffTower(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(14, 84, 72, 9, shadow)
        ctx.ellipse(16, 80, 68, 8, rgb(0xE8DCEB))
        let rows: [(CGFloat, Int)] = [(72, 5), (60, 4), (48, 3), (36, 2), (24, 1)]
        for (y, count) in rows {
            let span = CGFloat(count) * 13
            for i in 0..<count {
                let x = 50 - span / 2 + 6.5 + CGFloat(i) * 13
                ctx.circle(x, y, 7.5, rgb(0xD9A35F))
                ctx.circle(x - 1, y - 1.5, 6.5, rgb(0xEDC27E))
                ctx.circle(x - 2.5, y - 3.5, 1.8, Color.white.opacity(0.6))
            }
        }
        // Sợi caramel.
        ctx.strokePath(rgb(0xFFF1C9), width: 1.6) { p in
            p.move(to: CGPoint(x: 22, y: 70)); p.addQuadCurve(to: CGPoint(x: 78, y: 58), control: CGPoint(x: 50, y: 74))
            p.move(to: CGPoint(x: 30, y: 52)); p.addQuadCurve(to: CGPoint(x: 70, y: 42), control: CGPoint(x: 50, y: 56))
        }
        ctx.circle(50, 13, 5, rgb(0xE5536E))
    }

    /// Lát bánh kem cầu vồng.
    private static func rainbowCake(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(10, 82, 80, 9, shadow)
        let layers: [UInt32] = [0xF4A3B6, 0xF7CF72, 0x9FD6B4, 0x96C8EF, 0xB8A6EE]
        var y: CGFloat = 76
        for col in layers {
            ctx.rect(14, y - 10, 72, 10, rgb(col))
            ctx.rect(14, y - 2.5, 72, 2.5, Color.white.opacity(0.85))
            y -= 10
        }
        ctx.rect(14, y - 7, 72, 9, rgb(0xFFF6EE), radius: 4)
        for i in 0..<5 {
            let x = 22 + CGFloat(i) * 14
            ctx.circle(x, y - 8, 5, rgb(0xFFF6EE))
            ctx.circle(x, y - 13, 2.5, rgb(layers[i]))
        }
    }

    /// Lâu đài bánh ngọt có tháp mái kem.
    private static func castle(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(8, 84, 84, 9, shadow)
        let wall = rgb(0xFFE7EF), wallShade = rgb(0xF6C8D6), roof = rgb(0xB8A6EE)
        ctx.rect(22, 44, 56, 38, wall, radius: 3)
        for x in [22.0, 36.0, 50.0, 64.0] as [CGFloat] { ctx.rect(x, 38, 8, 8, wall, radius: 1.5) }
        for (x, w, top) in [(10.0, 16.0, 34.0), (74.0, 16.0, 34.0), (42.0, 16.0, 22.0)] as [(CGFloat, CGFloat, CGFloat)] {
            ctx.rect(x, top, w, 82 - top, wallShade, radius: 3)
            ctx.polygon([CGPoint(x: x - 3, y: top + 1), CGPoint(x: x + w / 2, y: top - 18), CGPoint(x: x + w + 3, y: top + 1)], roof)
            ctx.circle(x + w / 2, top - 19, 2.5, rgb(0xFFC94D))
            ctx.rect(x + w / 2 - 2.5, top + 8, 5, 7, rgb(0x8C77D0).opacity(0.6), radius: 2.5)
        }
        // Cửa bánh quy.
        ctx.rect(42, 62, 16, 20, rgb(0xD9AE73), radius: 8)
        ctx.circle(54, 73, 1.4, rgb(0x7A4E2E))
        // Viền kem chấm bi.
        for i in 0..<6 { ctx.circle(25 + CGFloat(i) * 10, 56, 2, rgb(0xF08AA5)) }
    }

    private static func crown(_ ctx: GraphicsContext, shadow: Color) {
        ctx.ellipse(14, 80, 72, 9, shadow)
        let gold = rgb(0xF7CF72), goldDark = rgb(0xD5A23C)
        var c = Path()
        c.move(to: CGPoint(x: 16, y: 74)); c.addLine(to: CGPoint(x: 12, y: 32)); c.addLine(to: CGPoint(x: 32, y: 50))
        c.addLine(to: CGPoint(x: 50, y: 22)); c.addLine(to: CGPoint(x: 68, y: 50)); c.addLine(to: CGPoint(x: 88, y: 32))
        c.addLine(to: CGPoint(x: 84, y: 74)); c.closeSubpath()
        ctx.fill(c, with: .color(gold))
        ctx.rect(16, 66, 68, 10, goldDark, radius: 4)
        for (x, y, col) in [(12.0, 32.0, 0xF4A3B6), (50.0, 22.0, 0x96C8EF), (88.0, 32.0, 0x9FD6B4)] as [(CGFloat, CGFloat, UInt32)] {
            ctx.circle(x, y, 5.5, rgb(col))
            ctx.circle(x - 1.5, y - 1.5, 1.6, Color.white.opacity(0.8))
        }
        ctx.circle(50, 54, 7, rgb(0xF4A3B6))
        ctx.circle(32, 60, 4, rgb(0xB8A6EE))
        ctx.circle(68, 60, 4, rgb(0xB8A6EE))
        ctx.ellipse(22, 38, 6, 14, Color.white.opacity(0.35))
    }

    private static func sweetStar(_ ctx: GraphicsContext) {
        ctx.circle(50, 48, 40, rgb(0xFFE07A).opacity(0.35))
        var p = Path()
        for i in 0..<10 {
            let a = Double(i) / 10 * 2 * .pi - .pi / 2
            let r: Double = i % 2 == 0 ? 36 : 16
            let pt = CGPoint(x: 50 + r * cos(a), y: 48 + r * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(rgb(0xF7C948)))
        ctx.circle(43, 45, 3, rgb(0x4A3C5C))
        ctx.circle(57, 45, 3, rgb(0x4A3C5C))
        ctx.strokePath(rgb(0x4A3C5C), width: 2.2) { s in
            s.move(to: CGPoint(x: 45, y: 53)); s.addQuadCurve(to: CGPoint(x: 55, y: 53), control: CGPoint(x: 50, y: 58))
        }
    }

    // MARK: Hiệu ứng

    /// Mảnh kẹo bắn ra khi xóa đường (`t` 0…1).
    static func burst(_ ctx: GraphicsContext, center c: CGPoint, cell: CGFloat, color: Int, progress t: CGFloat) {
        let (body, light, _) = candyColor(color)
        let fade = Double(max(0, 1 - t))
        let size = cell * (1 - t * 0.6)
        ctx.fill(Path(roundedRect: CGRect(x: c.x - size / 2, y: c.y - size / 2, width: size, height: size), cornerRadius: size * 0.25),
                 with: .color(light.opacity(fade * 0.9)))
        for i in 0..<4 {
            let a = Double(i) / 4 * 2 * .pi + Double(color) * 0.7
            let d = cell * (0.2 + t * 0.7)
            ctx.circle(c.x + d * cos(a), c.y + d * sin(a), cell * 0.1 * (1 - t * 0.5), body.opacity(fade))
        }
    }
}

/// Vẽ bàn Xếp Khối tĩnh từ trạng thái engine (+ bóng mờ chỗ sắp thả và các đường sẽ xóa).
struct BlockBoardPainter {
    var board: [Int]
    /// Ô bóng mờ của khối đang kéo.
    var ghost: [BlockCell] = []
    var ghostColor = 0
    var ghostValid = true
    var highlightRows: [Int] = []
    var highlightCols: [Int] = []

    func draw(in ctx: GraphicsContext, size: CGSize) {
        let n = BlockPuzzleEngine.size
        let cell = size.width / CGFloat(n)
        PuzzleArt.blockBoard(ctx, size: size)
        // Đường sẽ xóa nếu thả ở đây: tô sáng trước.
        for r in highlightRows {
            ctx.fill(Path(roundedRect: CGRect(x: cell * 0.05, y: CGFloat(r) * cell + cell * 0.05, width: size.width - cell * 0.1, height: cell * 0.9),
                          cornerRadius: cell * 0.25), with: .color(rgb(0xFFF3B0).opacity(0.9)))
        }
        for c in highlightCols {
            ctx.fill(Path(roundedRect: CGRect(x: CGFloat(c) * cell + cell * 0.05, y: cell * 0.05, width: cell * 0.9, height: size.height - cell * 0.1),
                          cornerRadius: cell * 0.25), with: .color(rgb(0xFFF3B0).opacity(0.9)))
        }
        for i in board.indices where board[i] != 0 {
            let rect = CGRect(x: CGFloat(i % n) * cell, y: CGFloat(i / n) * cell, width: cell, height: cell)
            PuzzleArt.jelly(ctx, rect: rect, color: board[i] - 1)
        }
        guard !ghost.isEmpty else { return }
        var g = ctx
        g.opacity = ghostValid ? 0.5 : 0.22
        for c in ghost where BlockPuzzleEngine.contains(c) {
            let rect = CGRect(x: CGFloat(c.col) * cell, y: CGFloat(c.row) * cell, width: cell, height: cell)
            if ghostValid {
                PuzzleArt.jelly(g, rect: rect, color: ghostColor)
            } else {
                // Chỗ không thả được: chỉ một viền xám mềm, không đỏ gắt.
                g.stroke(Path(roundedRect: rect.insetBy(dx: cell * 0.12, dy: cell * 0.12), cornerRadius: cell * 0.22),
                         with: .color(rgb(0x786E87)), style: StrokeStyle(lineWidth: max(1.5, cell * 0.07), dash: [cell * 0.14, cell * 0.1]))
            }
        }
    }
}

/// Vẽ bàn Gộp Bánh tĩnh (dùng cho ảnh minh họa và vẽ thử; trong game mỗi món là một view riêng để trượt mượt).
struct SweetBoardPainter {
    var levels: [Int]

    func draw(in ctx: GraphicsContext, size: CGSize) {
        PuzzleArt.mergeBoard(ctx, size: size)
        let cell = size.width / CGFloat(SweetMergeEngine.size)
        for (i, l) in levels.enumerated() where l > 0 {
            PuzzleArt.sweetTile(ctx, level: l, rect: PuzzleArt.tileRect(i, cell: cell))
        }
    }
}

extension PuzzleArt {
    /// Ảnh minh họa Xếp Khối: bàn nhỏ có vài viên kẹo, một khối đang thả, bạn nhỏ đứng cạnh.
    static func blocksThumbnail(_ ctx: GraphicsContext, size: CGSize, pet: (CGRect) -> Void) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [rgb(0xF3ECFB), rgb(0xFDEFE4)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        let side = min(size.height * 0.86, size.width * 0.5)
        var b = ctx
        b.translateBy(x: size.width * 0.08, y: (size.height - side) / 2)
        var board = Array(repeating: 0, count: 64)
        let filled: [(Int, Int)] = [(7, 0), (7, 1), (7, 2), (7, 3), (7, 5), (7, 6), (7, 7), (6, 0), (6, 1), (6, 6), (6, 7), (5, 0), (5, 7), (4, 7), (3, 0), (2, 6), (2, 7)]
        for (k, (r, c)) in filled.enumerated() { board[r * 8 + c] = k % 6 + 1 }
        BlockBoardPainter(board: board, ghost: [BlockCell(row: 7, col: 4), BlockCell(row: 6, col: 4), BlockCell(row: 6, col: 5)],
                          ghostColor: 2, highlightRows: [7]).draw(in: b, size: CGSize(width: side, height: side))
        let cell = side / 8
        piece(ctx, shape: BlockPuzzleEngine.shape(9), color: 3, origin: CGPoint(x: size.width * 0.66, y: size.height * 0.12), cell: cell * 0.9)
        pet(CGRect(x: size.width * 0.62, y: size.height * 0.42, width: size.height * 0.52, height: size.height * 0.52))
    }

    /// Ảnh minh họa Gộp Bánh.
    static func mergeThumbnail(_ ctx: GraphicsContext, size: CGSize, pet: (CGRect) -> Void) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [rgb(0xFDEBF1), rgb(0xFEF6EC)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        let side = min(size.height * 0.86, size.width * 0.5)
        var b = ctx
        b.translateBy(x: size.width * 0.08, y: (size.height - side) / 2)
        SweetBoardPainter(levels: [1, 0, 0, 2,
                                   0, 3, 1, 0,
                                   2, 4, 5, 0,
                                   3, 5, 6, 7]).draw(in: b, size: CGSize(width: side, height: side))
        pet(CGRect(x: size.width * 0.62, y: size.height * 0.4, width: size.height * 0.54, height: size.height * 0.54))
        let s = size.height * 0.3
        sweetTile(ctx, level: 4, rect: CGRect(x: size.width * 0.66, y: size.height * 0.08, width: s, height: s))
    }
}
