import SwiftUI

// Hình vẽ của Sân chơi — thuần GraphicsContext (không có View), vẽ bằng code, không dùng ảnh ngoài.
// Tách khỏi View để kiểm tra kiểu và vẽ thử ra ảnh được cả ngoài Xcode.

/// Tư thế của bạn nhỏ trong game (mỗi tư thế được dựng sẵn thành ảnh một lần, xem `PetSprites`).
enum PetSpriteKind: Int, CaseIterable, Hashable {
    case idle, happy, surprised, cheer

    var mood: PetMood {
        switch self {
        case .idle: return .idle
        case .happy, .cheer: return .happy
        case .surprised: return .idle
        }
    }

    var pose: PetPose {
        var p = PetPose()
        switch self {
        case .idle: break
        case .happy: p.petted = 1
        case .surprised: p.lifted = true
        case .cheer: p.petted = 1; p.hearts = 0.35
        }
        return p
    }
}

/// Vẽ bạn nhỏ vào một khung (trong app: ảnh dựng sẵn; khi vẽ thử: `PetPainter`).
typealias PetSpriteDrawer = (GraphicsContext, CGRect, PetSpriteKind, Bool) -> Void

enum GameArt {
    // MARK: Nhảy Mây

    /// Bầu trời đổi màu dần theo độ cao (pastel tím → xanh đêm có sao).
    static func sky(_ ctx: GraphicsContext, size: CGSize, altitude: Double, reduceMotion: Bool) {
        let t = min(1, max(0, altitude / 3000))
        func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Color {
            Color(red: (a.0 + (b.0 - a.0) * t) / 255, green: (a.1 + (b.1 - a.1) * t) / 255, blue: (a.2 + (b.2 - a.2) * t) / 255)
        }
        let top = mix((0xC9, 0xBD, 0xF0), (0x5C, 0x5A, 0x9E))
        let bottom = mix((0xFD, 0xEB, 0xDD), (0xB8, 0xA4, 0xE0))
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        // Sao nhỏ xuất hiện khi lên cao, trôi chậm (không trôi khi bật Giảm chuyển động).
        guard t > 0.15 else { return }
        let drift = reduceMotion ? 0 : altitude * 0.05
        for i in 0..<18 {
            let x = (Double(i) * 37.7).truncatingRemainder(dividingBy: 100) / 100 * size.width
            let y = ((Double(i) * 53.1 + drift).truncatingRemainder(dividingBy: 160)) / 160 * size.height
            ctx.circle(x, y, i % 3 == 0 ? 1.6 : 1, Color.white.opacity(0.35 + 0.5 * t))
        }
    }

    /// Đồi xa ở mặt đất (chỉ thấy lúc đầu).
    static func hills(_ ctx: GraphicsContext, width w: CGFloat, groundY: CGFloat) {
        var back = Path()
        back.move(to: CGPoint(x: 0, y: groundY))
        back.addQuadCurve(to: CGPoint(x: w * 0.55, y: groundY - 4), control: CGPoint(x: w * 0.25, y: groundY - w * 0.32))
        back.addQuadCurve(to: CGPoint(x: w, y: groundY), control: CGPoint(x: w * 0.85, y: groundY - w * 0.25))
        back.addLine(to: CGPoint(x: w, y: groundY + 400)); back.addLine(to: CGPoint(x: 0, y: groundY + 400)); back.closeSubpath()
        ctx.fill(back, with: .color(rgb(0xBFDDB9)))
        ctx.rect(0, groundY, w, 400, rgb(0x9CCB98))
        ctx.rect(0, groundY, w, 3, rgb(0x86B884))
        for i in 0..<7 {
            let x = w * (0.08 + 0.14 * CGFloat(i))
            ctx.circle(x, groundY + 10 + CGFloat(i % 2) * 6, 2.2, i % 2 == 0 ? rgb(0xF6C3D0) : rgb(0xFFF4C4))
        }
    }

    /// Đám mây bệ: `rect` là mép trên/trái/phải theo điểm màn hình. Mây di chuyển màu bạc hà có vệt gió.
    static func cloud(_ ctx: GraphicsContext, rect r: CGRect, moving: Bool) {
        let body = moving ? rgb(0xDDF3E6) : Color.white
        let shade = moving ? rgb(0xA9DDB8) : rgb(0xD9CFF2)
        let h = r.height
        ctx.fill(Path(roundedRect: CGRect(x: r.minX, y: r.minY + h * 0.35, width: r.width, height: h * 0.75), cornerRadius: h * 0.37),
                 with: .color(shade))
        ctx.fill(Path(roundedRect: CGRect(x: r.minX, y: r.minY + h * 0.1, width: r.width, height: h * 0.8), cornerRadius: h * 0.4),
                 with: .color(body))
        let bumps = max(2, Int(r.width / (h * 1.1)))
        for i in 0..<bumps {
            let cx = r.minX + r.width * (CGFloat(i) + 0.5) / CGFloat(bumps)
            let rad = h * (i % 2 == 0 ? 0.42 : 0.34)
            ctx.circle(cx, r.minY + h * 0.22, rad, body)
        }
        ctx.ellipse(r.minX + r.width * 0.18, r.minY + h * 0.18, r.width * 0.22, h * 0.18, Color.white.opacity(0.8))
        if moving {
            ctx.strokePath(rgb(0x7FBF93).opacity(0.8), width: 1.4) { p in
                p.move(to: CGPoint(x: r.minX - h * 0.9, y: r.minY + h * 0.45)); p.addLine(to: CGPoint(x: r.minX - h * 0.25, y: r.minY + h * 0.45))
                p.move(to: CGPoint(x: r.maxX + h * 0.25, y: r.minY + h * 0.65)); p.addLine(to: CGPoint(x: r.maxX + h * 0.9, y: r.minY + h * 0.65))
            }
        }
    }

    static func star(_ ctx: GraphicsContext, center c: CGPoint, radius r: CGFloat, color: Color = rgb(0xF6C445), glow: Bool = true) {
        if glow { ctx.circle(c.x, c.y, r * 1.45, rgb(0xFFF1B8).opacity(0.3)) }
        var p = Path()
        for i in 0..<10 {
            let rr = i % 2 == 0 ? r : r * 0.48
            let a = Double(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
        ctx.stroke(p, with: .color(rgb(0xD99A2B)), style: StrokeStyle(lineWidth: max(1, r * 0.12), lineJoin: .round))
        ctx.circle(c.x - r * 0.2, c.y - r * 0.25, r * 0.16, Color.white.opacity(0.8))
    }

    // MARK: Giỏ Quà

    static func garden(_ ctx: GraphicsContext, size: CGSize, groundY: CGFloat) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [rgb(0xD8E9FB), rgb(0xFDEFE2)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: groundY)))
        for (x, y, s) in [(0.18, 0.12, 1.0), (0.72, 0.2, 0.8), (0.45, 0.33, 0.6)] as [(CGFloat, CGFloat, CGFloat)] {
            let w = size.width * 0.28 * s
            cloud(ctx, rect: CGRect(x: size.width * x - w / 2, y: size.height * y, width: w, height: w * 0.3), moving: false)
        }
        var hill = Path()
        hill.move(to: CGPoint(x: 0, y: groundY - size.width * 0.05))
        hill.addQuadCurve(to: CGPoint(x: size.width, y: groundY - size.width * 0.08), control: CGPoint(x: size.width * 0.5, y: groundY - size.width * 0.2))
        hill.addLine(to: CGPoint(x: size.width, y: size.height)); hill.addLine(to: CGPoint(x: 0, y: size.height)); hill.closeSubpath()
        ctx.fill(hill, with: .color(rgb(0xC3E2BC)))
        ctx.rect(0, groundY, size.width, size.height - groundY, rgb(0xA4D2A0))
        ctx.rect(0, groundY, size.width, 3, rgb(0x8BBF88))
        for i in 0..<9 {
            let x = size.width * (0.05 + 0.11 * CGFloat(i))
            let y = groundY + 12 + CGFloat(i % 3) * 7
            ctx.circle(x, y, 2.4, [rgb(0xF6C3D0), rgb(0xFFF4C4), rgb(0xD3C1EE)][i % 3])
        }
    }

    /// Giỏ đan cầm trước người bạn nhỏ. `rect`: miệng giỏ ở mép trên.
    static func basket(_ ctx: GraphicsContext, rect r: CGRect, handle: Bool = true) {
        let wood = rgb(0xC98F5A), dark = rgb(0x9C6A3D), light = rgb(0xE2B47E)
        if handle { basketHandle(ctx, rect: r) }
        var body = Path()
        body.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.12))
        body.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.12))
        body.addLine(to: CGPoint(x: r.maxX - r.width * 0.1, y: r.maxY))
        body.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.1, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.12))
        body.closeSubpath()
        ctx.fill(body, with: .color(wood))
        var weave = ctx
        weave.clip(to: body)
        for i in 0..<4 {
            let y = r.minY + r.height * (0.32 + 0.2 * CGFloat(i))
            weave.rect(r.minX, y, r.width, r.height * 0.07, dark.opacity(0.55))
        }
        for i in 0..<7 {
            let x = r.minX + r.width * (CGFloat(i) + 0.5) / 7
            weave.rect(x - r.width * 0.015, r.minY, r.width * 0.03, r.height, light.opacity(0.5))
        }
        ctx.fill(Path(roundedRect: CGRect(x: r.minX - r.width * 0.04, y: r.minY, width: r.width * 1.08, height: r.height * 0.2),
                      cornerRadius: r.height * 0.1), with: .color(light))
    }

    /// Quai giỏ (vẽ phía sau bạn nhỏ trong game).
    static func basketHandle(_ ctx: GraphicsContext, rect r: CGRect) {
        ctx.strokePath(rgb(0x9C6A3D), width: max(2, r.height * 0.09)) { p in
            p.move(to: CGPoint(x: r.minX + r.width * 0.12, y: r.minY + r.height * 0.1))
            p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.minY + r.height * 0.1),
                           control: CGPoint(x: r.midX, y: r.minY - r.height * 0.75))
        }
    }

    /// Món rơi. Món cần tránh có hình dạng riêng (vệt bùn / mây xám có giọt mưa) và huy hiệu "✕";
    /// món tốt có dấu "+" nhỏ — không chỉ khác nhau bằng màu.
    static func drop(_ ctx: GraphicsContext, kind: DropKind, center c: CGPoint, radius r: CGFloat) {
        switch kind {
        case .apple:
            ctx.circle(c.x, c.y + r * 0.08, r, rgb(0xEF6B6B))
            ctx.circle(c.x - r * 0.35, c.y - r * 0.25, r * 0.22, Color.white.opacity(0.55))
            ctx.strokePath(rgb(0x7A5234), width: max(1.2, r * 0.14)) { p in
                p.move(to: CGPoint(x: c.x, y: c.y - r * 0.75)); p.addLine(to: CGPoint(x: c.x + r * 0.1, y: c.y - r * 1.2))
            }
            ctx.rotated(-30, around: CGPoint(x: c.x + r * 0.35, y: c.y - r * 1.05)) { l in
                l.ellipse(c.x + r * 0.1, c.y - r * 1.2, r * 0.6, r * 0.3, rgb(0x7FBF6A))
            }
        case .cherry:
            ctx.strokePath(rgb(0x6E9A50), width: max(1.2, r * 0.13)) { p in
                p.move(to: CGPoint(x: c.x - r * 0.45, y: c.y + r * 0.2)); p.addQuadCurve(to: CGPoint(x: c.x + r * 0.15, y: c.y - r * 1.05), control: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.6))
                p.move(to: CGPoint(x: c.x + r * 0.5, y: c.y + r * 0.25)); p.addQuadCurve(to: CGPoint(x: c.x + r * 0.15, y: c.y - r * 1.05), control: CGPoint(x: c.x + r * 0.5, y: c.y - r * 0.5))
            }
            for dx in [-0.45, 0.5] as [CGFloat] {
                ctx.circle(c.x + r * dx, c.y + r * 0.45, r * 0.55, rgb(0xD94F6A))
                ctx.circle(c.x + r * dx - r * 0.18, c.y + r * 0.28, r * 0.15, Color.white.opacity(0.6))
            }
        case .star:
            star(ctx, center: c, radius: r * 1.05)
        case .gift:
            let box = CGRect(x: c.x - r, y: c.y - r * 0.6, width: r * 2, height: r * 1.6)
            ctx.fill(Path(roundedRect: box, cornerRadius: r * 0.25), with: .color(rgb(0xF4A9C4)))
            ctx.rect(box.minX - r * 0.1, box.minY - r * 0.35, box.width + r * 0.2, r * 0.45, rgb(0xE88AAE), radius: r * 0.15)
            ctx.rect(c.x - r * 0.15, box.minY - r * 0.35, r * 0.3, box.height + r * 0.35, rgb(0xFFF4C4))
            ctx.ellipse(c.x - r * 0.75, box.minY - r * 0.9, r * 0.7, r * 0.55, rgb(0xFFF4C4))
            ctx.ellipse(c.x + r * 0.05, box.minY - r * 0.9, r * 0.7, r * 0.55, rgb(0xFFF4C4))
        case .mud:
            var splat = Path()
            let n = 9
            for i in 0...n {
                let a = Double(i) / Double(n) * 2 * .pi
                let rr = r * (i % 2 == 0 ? 1.05 : 0.78)
                let pt = CGPoint(x: c.x + rr * cos(a), y: c.y + rr * 0.85 * sin(a))
                if i == 0 { splat.move(to: pt) } else { splat.addLine(to: pt) }
            }
            splat.closeSubpath()
            ctx.fill(splat, with: .color(rgb(0x8A6A52)))
            ctx.circle(c.x - r * 0.3, c.y - r * 0.2, r * 0.22, rgb(0x6E523F))
            ctx.circle(c.x + r * 0.35, c.y + r * 0.25, r * 0.16, rgb(0x6E523F))
            ctx.circle(c.x + r * 0.1, c.y + r * 1.2, r * 0.16, rgb(0x8A6A52))
            badge(ctx, at: CGPoint(x: c.x + r * 0.85, y: c.y - r * 0.75), r: r * 0.42)
        case .rain:
            let cr = CGRect(x: c.x - r * 1.1, y: c.y - r * 0.75, width: r * 2.2, height: r * 1.0)
            ctx.fill(Path(roundedRect: CGRect(x: cr.minX, y: cr.minY + cr.height * 0.35, width: cr.width, height: cr.height * 0.65), cornerRadius: cr.height * 0.32),
                     with: .color(rgb(0x9C9AAE)))
            ctx.circle(cr.minX + cr.width * 0.35, cr.minY + cr.height * 0.4, cr.height * 0.42, rgb(0x9C9AAE))
            ctx.circle(cr.minX + cr.width * 0.65, cr.minY + cr.height * 0.32, cr.height * 0.5, rgb(0x9C9AAE))
            for (i, dx) in ([-0.6, 0, 0.6] as [CGFloat]).enumerated() {
                let y = c.y + r * (0.55 + CGFloat(i % 2) * 0.3)
                var d = Path()
                d.move(to: CGPoint(x: c.x + r * dx, y: y - r * 0.3))
                d.addQuadCurve(to: CGPoint(x: c.x + r * dx, y: y + r * 0.25), control: CGPoint(x: c.x + r * dx + r * 0.25, y: y + r * 0.1))
                d.addQuadCurve(to: CGPoint(x: c.x + r * dx, y: y - r * 0.3), control: CGPoint(x: c.x + r * dx - r * 0.25, y: y + r * 0.1))
                ctx.fill(d, with: .color(rgb(0x6FA5E0)))
            }
            badge(ctx, at: CGPoint(x: c.x + r * 0.95, y: c.y - r * 0.8), r: r * 0.42)
        }
        if kind.isGood && kind != .star {
            ctx.draw(Text("+").font(.system(size: max(7, r * 0.9), weight: .heavy, design: .rounded)).foregroundColor(Color.white),
                     at: CGPoint(x: c.x + r * 0.05, y: c.y + r * 0.1))
        }
    }

    /// Huy hiệu "✕" trên món cần tránh.
    private static func badge(_ ctx: GraphicsContext, at p: CGPoint, r: CGFloat) {
        ctx.circle(p.x, p.y, r, Color.white)
        ctx.circle(p.x, p.y, r * 0.82, rgb(0x6B5A7A))
        ctx.strokePath(Color.white, width: max(1.2, r * 0.3)) { path in
            path.move(to: CGPoint(x: p.x - r * 0.38, y: p.y - r * 0.38)); path.addLine(to: CGPoint(x: p.x + r * 0.38, y: p.y + r * 0.38))
            path.move(to: CGPoint(x: p.x + r * 0.38, y: p.y - r * 0.38)); path.addLine(to: CGPoint(x: p.x - r * 0.38, y: p.y + r * 0.38))
        }
    }

    /// Hạt lấp lánh nhỏ khi hứng/nhặt được (bỏ qua khi bật Giảm chuyển động).
    static func sparkle(_ ctx: GraphicsContext, at c: CGPoint, progress t: CGFloat, color: Color) {
        let fade = Double(max(0, 1 - t))
        for i in 0..<6 {
            let a = Double(i) / 6 * 2 * .pi
            let d = 6 + t * 18
            ctx.circle(c.x + d * cos(a), c.y + d * sin(a) - t * 6, 2.2 * (1 - t * 0.5), color.opacity(fade))
        }
    }

    // MARK: Lật thẻ

    /// Mặt sau của thẻ: lavender có họa tiết dấu chân.
    static func cardBack(_ ctx: GraphicsContext, size: CGSize) {
        let r = CGRect(origin: .zero, size: size)
        ctx.fill(Path(roundedRect: r, cornerRadius: min(size.width, size.height) * 0.16),
                 with: .linearGradient(Gradient(colors: [rgb(0xB7A6F0), rgb(0x8D78CF)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
        ctx.stroke(Path(roundedRect: r.insetBy(dx: 4, dy: 4), cornerRadius: min(size.width, size.height) * 0.12),
                   with: .color(Color.white.opacity(0.45)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let k = min(size.width, size.height) / 60
        let color = Color.white.opacity(0.8)
        ctx.ellipse(c.x - 8 * k, c.y - 2 * k, 16 * k, 13 * k, color)
        for (dx, dy) in [(-9.0, -8.0), (-3.0, -13.0), (3.0, -13.0), (9.0, -8.0)] {
            ctx.circle(c.x + dx * k, c.y + dy * k, 3.4 * k, color)
        }
    }
}

// MARK: Đồ ăn

enum FoodArt {
    /// Vẽ món ăn trong khung 100×100.
    static func draw(_ id: String, in ctx: GraphicsContext) {
        switch id {
        case "food.apple":
            ctx.ellipse(18, 84, 64, 10, Color.black.opacity(0.06))
            ctx.circle(50, 56, 30, rgb(0xEF6B6B))
            ctx.circle(38, 44, 8, Color.white.opacity(0.5))
            ctx.strokePath(rgb(0x7A5234), width: 4) { p in p.move(to: CGPoint(x: 50, y: 30)); p.addLine(to: CGPoint(x: 53, y: 16)) }
            ctx.rotated(-25, around: CGPoint(x: 62, y: 20)) { l in l.ellipse(52, 14, 22, 11, rgb(0x7FBF6A)) }
        case "food.carrot":
            ctx.ellipse(18, 84, 64, 10, Color.black.opacity(0.06))
            ctx.rotated(35, around: CGPoint(x: 50, y: 52)) { c in
                var p = Path()
                p.move(to: CGPoint(x: 34, y: 26)); p.addQuadCurve(to: CGPoint(x: 66, y: 26), control: CGPoint(x: 50, y: 18))
                p.addLine(to: CGPoint(x: 52, y: 88)); p.addQuadCurve(to: CGPoint(x: 48, y: 88), control: CGPoint(x: 50, y: 92)); p.closeSubpath()
                c.fill(p, with: .color(rgb(0xF29A4A)))
                c.strokePath(rgb(0xD97B2E), width: 2) { s in
                    s.move(to: CGPoint(x: 40, y: 42)); s.addLine(to: CGPoint(x: 48, y: 42))
                    s.move(to: CGPoint(x: 53, y: 58)); s.addLine(to: CGPoint(x: 59, y: 58))
                    s.move(to: CGPoint(x: 44, y: 70)); s.addLine(to: CGPoint(x: 50, y: 70))
                }
                for dx in [-8.0, 0.0, 8.0] {
                    c.ellipse(46 + dx, 6, 8, 22, rgb(0x7FBF6A))
                }
            }
        case "food.oatcookie":
            ctx.ellipse(16, 80, 68, 10, Color.black.opacity(0.06))
            ctx.circle(50, 54, 32, rgb(0xDDB57E))
            ctx.circle(50, 54, 27, rgb(0xE8C690))
            for (x, y) in [(38.0, 44.0), (58.0, 40.0), (62.0, 60.0), (44.0, 64.0), (52, 52)] as [(CGFloat, CGFloat)] {
                ctx.ellipse(x - 3.5, y - 2.5, 7, 5, rgb(0x9C6A3D))
            }
        case "food.riceball":
            ctx.ellipse(16, 82, 68, 10, Color.black.opacity(0.06))
            var tri = Path()
            tri.move(to: CGPoint(x: 50, y: 18))
            tri.addQuadCurve(to: CGPoint(x: 84, y: 76), control: CGPoint(x: 86, y: 54))
            tri.addQuadCurve(to: CGPoint(x: 16, y: 76), control: CGPoint(x: 50, y: 92))
            tri.addQuadCurve(to: CGPoint(x: 50, y: 18), control: CGPoint(x: 14, y: 54))
            ctx.fill(tri, with: .color(rgb(0xFFFDF8)))
            ctx.stroke(tri, with: .color(rgb(0xE4DFEA)), lineWidth: 2)
            ctx.rect(36, 60, 28, 24, rgb(0x3E5A4A), radius: 4)
            ctx.ellipse(36, 42, 6, 4, rgb(0x4A3C5C))
            ctx.ellipse(58, 42, 6, 4, rgb(0x4A3C5C))
            ctx.ellipse(31, 50, 8, 4, Palette.blush)
            ctx.ellipse(61, 50, 8, 4, Palette.blush)
        case "food.veggiesoup":
            ctx.ellipse(12, 80, 76, 10, Color.black.opacity(0.06))
            ctx.strokePath(Color.white.opacity(0.9), width: 3) { p in
                for x in [38.0, 50.0, 62.0] as [CGFloat] {
                    p.move(to: CGPoint(x: x, y: 34)); p.addQuadCurve(to: CGPoint(x: x, y: 14), control: CGPoint(x: x + 7, y: 24))
                }
            }
            var bowl = Path()
            bowl.move(to: CGPoint(x: 14, y: 48)); bowl.addLine(to: CGPoint(x: 86, y: 48))
            bowl.addQuadCurve(to: CGPoint(x: 14, y: 48), control: CGPoint(x: 50, y: 110)); bowl.closeSubpath()
            ctx.fill(bowl, with: .color(rgb(0x8D78CF)))
            ctx.ellipse(14, 40, 72, 16, rgb(0xF3C77A))
            ctx.circle(36, 47, 5, rgb(0x7FBF6A))
            ctx.circle(52, 45, 4, rgb(0xF29A4A))
            ctx.circle(64, 48, 5, rgb(0x7FBF6A))
            ctx.rect(42, 72, 16, 3, Color.white.opacity(0.6), radius: 1.5)
        case "food.picnic":
            ctx.ellipse(8, 82, 84, 10, Color.black.opacity(0.06))
            ctx.strokePath(rgb(0x9C6A3D), width: 4) { p in
                p.move(to: CGPoint(x: 28, y: 40)); p.addQuadCurve(to: CGPoint(x: 72, y: 40), control: CGPoint(x: 50, y: 6))
            }
            ctx.rect(14, 40, 72, 44, rgb(0xC98F5A), radius: 8)
            for i in 0..<4 { ctx.rect(14, 46 + CGFloat(i) * 10, 72, 3, rgb(0x9C6A3D).opacity(0.5)) }
            // Khăn kẻ ô
            ctx.rect(20, 34, 60, 14, rgb(0xF6C3D0), radius: 3)
            for i in 0..<6 { ctx.rect(20 + CGFloat(i) * 10, 34, 5, 14, Color.white.opacity(0.6)) }
            ctx.circle(34, 32, 6, rgb(0xEF6B6B))
            ctx.ellipse(52, 24, 22, 12, rgb(0xE8C690))
        default:
            ctx.circle(50, 50, 30, Palette.inkMuted.opacity(0.4))
        }
    }

    /// Vết cắn để vẽ lên món đang ăn (0…3 miếng).
    static func bites(_ ctx: GraphicsContext, count: Int, background: Color) {
        let spots: [(CGFloat, CGFloat)] = [(80, 34), (84, 56), (72, 76)]
        for (x, y) in spots.prefix(count) {
            ctx.circle(x, y, 13, background)
        }
    }
}

// MARK: Bụi trong phòng

enum DustArt {
    /// Một đốm bụi / lá khô / giấy vụn, tâm tại `c`, cỡ `s` (điểm).
    static func spot(_ ctx: GraphicsContext, kind: Int, center c: CGPoint, size s: CGFloat) {
        switch kind % 3 {
        case 0: // cụm bụi xám
            let color = rgb(0xB8AFA4)
            ctx.circle(c.x - s * 0.22, c.y + s * 0.05, s * 0.28, color.opacity(0.85))
            ctx.circle(c.x + s * 0.18, c.y - s * 0.02, s * 0.32, color.opacity(0.9))
            ctx.circle(c.x + s * 0.02, c.y + s * 0.2, s * 0.24, color.opacity(0.8))
            ctx.circle(c.x + s * 0.42, c.y + s * 0.22, s * 0.08, color.opacity(0.7))
            ctx.circle(c.x - s * 0.45, c.y - s * 0.12, s * 0.06, color.opacity(0.7))
        case 1: // lá khô
            ctx.rotated(28, around: c) { l in
                var p = Path()
                p.move(to: CGPoint(x: c.x - s * 0.45, y: c.y))
                p.addQuadCurve(to: CGPoint(x: c.x + s * 0.45, y: c.y), control: CGPoint(x: c.x, y: c.y - s * 0.4))
                p.addQuadCurve(to: CGPoint(x: c.x - s * 0.45, y: c.y), control: CGPoint(x: c.x, y: c.y + s * 0.4))
                l.fill(p, with: .color(rgb(0xD9A15C)))
                l.strokePath(rgb(0xA87436), width: max(0.8, s * 0.05)) { v in
                    v.move(to: CGPoint(x: c.x - s * 0.4, y: c.y)); v.addLine(to: CGPoint(x: c.x + s * 0.4, y: c.y))
                }
            }
        default: // giấy vụn
            ctx.rotated(-14, around: c) { l in
                l.rect(c.x - s * 0.32, c.y - s * 0.24, s * 0.64, s * 0.48, Color.white.opacity(0.95), radius: s * 0.06)
                l.strokePath(rgb(0xB9B0C6), width: max(0.7, s * 0.04)) { v in
                    v.move(to: CGPoint(x: c.x - s * 0.22, y: c.y - s * 0.08)); v.addLine(to: CGPoint(x: c.x + s * 0.2, y: c.y - s * 0.08))
                    v.move(to: CGPoint(x: c.x - s * 0.22, y: c.y + s * 0.08)); v.addLine(to: CGPoint(x: c.x + s * 0.1, y: c.y + s * 0.08))
                }
            }
        }
    }
}
