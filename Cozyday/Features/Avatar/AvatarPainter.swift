import SwiftUI

extension PetMood {
    /// Biểu cảm trong ảnh đại diện (`AvatarCatalog.moods`).
    init(avatarID: String) {
        switch avatarID {
        case "idle": self = .idle
        case "rest": self = .rest
        case "focus": self = .focus
        default: self = .happy
        }
    }
}

/// Vẽ ảnh đại diện trong khung 100×100: nền → phong cảnh phía sau → mặt đất → thú cưng → hiệu ứng → tên.
/// Thuần vẽ (không trạng thái) nên dùng chung cho màn hình, ảnh xuất ra và icon của app.
struct AvatarPainter {
    var background: String
    var scene: String
    var effect: String
    var mood: PetMood
    var appearance: PetAppearance
    /// Dòng chữ in ở đáy ảnh (tên + cấp), `nil` = không in.
    var caption: String?
    var pose = PetPose()
    /// Giây trôi qua — làm hiệu ứng lấp lánh / rơi / bay nhẹ. 0 = ảnh tĩnh.
    var time: Double = 0

    /// Icon của app (AppIcon-1024.png được xuất từ đúng hình này): vịt con vàng đội mây trên đệm mây, trời hồng.
    static var appIcon: AvatarPainter {
        AvatarPainter(background: "sky", scene: "cloud", effect: "sparkles", mood: .happy,
                      appearance: PetAppearance(species: .duck, fur: .honey, hat: "hat.cloud", stage: .little), caption: nil)
    }

    func draw(in ctx: GraphicsContext) {
        let style = Self.backdrop(background)
        drawBackground(ctx, style)
        drawSceneBack(ctx, dark: style.dark)
        drawGround(ctx, dark: style.dark)
        drawPet(ctx)
        drawEffect(ctx, dark: style.dark)
        if let caption { drawCaption(ctx, caption) }
    }

    // MARK: Nền

    struct Backdrop {
        let stops: [UInt32]
        var dark = false
    }

    static func backdrop(_ id: String) -> Backdrop {
        switch id {
        case "peach": return Backdrop(stops: [0xFFE3DA, 0xFFC9D4, 0xF7AFC6])
        case "lavender": return Backdrop(stops: [0xF1E8FD, 0xDCCBF6, 0xC5B1EC])
        case "mint": return Backdrop(stops: [0xE8F7EE, 0xC6EAD5, 0x9ED4B6])
        case "lemon": return Backdrop(stops: [0xFFF8DC, 0xFFEBA6, 0xFFD27F])
        case "cream": return Backdrop(stops: [0xFFFAF1, 0xFBEEDB, 0xF2DEC2])
        case "night": return Backdrop(stops: [0x4E3F98, 0x7A68C4, 0xB5A2E8], dark: true)
        case "ocean": return Backdrop(stops: [0xCDEFF7, 0x93D3EB, 0x5FB0DA])
        case "sunset": return Backdrop(stops: [0xFFD9A8, 0xFBA6B4, 0xA994E8])
        case "galaxy": return Backdrop(stops: [0x241C46, 0x4A3383, 0xB0609E], dark: true)
        default: return Backdrop(stops: [0xBFE3FF, 0xDCD3FF, 0xFFD1E3])
        }
    }

    private func drawBackground(_ ctx: GraphicsContext, _ style: Backdrop) {
        let full = Path(CGRect(x: 0, y: 0, width: 100, height: 100))
        ctx.fill(full, with: .linearGradient(Gradient(colors: style.stops.map(rgb)),
                                             startPoint: CGPoint(x: 50, y: 0), endPoint: CGPoint(x: 50, y: 100)))
        if style.dark {
            // Bụi sao xa
            for (i, p) in Self.dust.enumerated() {
                ctx.circle(p.x, p.y, i % 3 == 0 ? 0.45 : 0.3, Color.white.opacity(0.55))
            }
        } else {
            // Quầng sáng mềm sau lưng thú cưng
            ctx.fill(Path(ellipseIn: CGRect(x: 5, y: 2, width: 90, height: 90)),
                     with: .radialGradient(Gradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0)]),
                                           center: CGPoint(x: 50, y: 47), startRadius: 0, endRadius: 45))
        }
    }

    private static let dust: [CGPoint] = [
        CGPoint(x: 8, y: 9), CGPoint(x: 21, y: 5), CGPoint(x: 33, y: 12), CGPoint(x: 46, y: 4), CGPoint(x: 62, y: 9),
        CGPoint(x: 72, y: 4), CGPoint(x: 93, y: 8), CGPoint(x: 5, y: 27), CGPoint(x: 95, y: 25), CGPoint(x: 9, y: 47),
        CGPoint(x: 92, y: 44), CGPoint(x: 4, y: 60), CGPoint(x: 96, y: 63), CGPoint(x: 14, y: 36), CGPoint(x: 86, y: 33),
        CGPoint(x: 27, y: 20), CGPoint(x: 55, y: 15), CGPoint(x: 80, y: 16)
    ]

    // MARK: Phong cảnh

    private func drawSceneBack(_ ctx: GraphicsContext, dark: Bool) {
        switch scene {
        case "cloud":
            Self.puff(ctx, cx: 17, cy: 22, w: 25, Color.white.opacity(dark ? 0.35 : 0.85))
            Self.puff(ctx, cx: 86, cy: 35, w: 20, Color.white.opacity(dark ? 0.3 : 0.8))
        case "meadow":
            Self.puff(ctx, cx: 20, cy: 18, w: 22, Color.white.opacity(dark ? 0.3 : 0.8))
            ctx.ellipse(-30, 70, 80, 40, rgb(dark ? 0x4F7D66 : 0xA9D9B9))
            ctx.ellipse(50, 68, 85, 42, rgb(dark ? 0x4A765F : 0x9BD1AE))
        case "moon":
            Self.crescent(ctx, cx: 80, cy: 18, r: 8.5, color: rgb(0xFFF3C4))
            Self.puff(ctx, cx: 14, cy: 76, w: 25, rgb(dark ? 0xE7DDFF : 0xFFFFFF).opacity(0.8))
            Self.puff(ctx, cx: 88, cy: 78, w: 22, rgb(dark ? 0xE7DDFF : 0xFFFFFF).opacity(0.8))
        case "beach":
            ctx.circle(18, 18, 7, rgb(0xFFE08A).opacity(dark ? 0.7 : 1))
            ctx.circle(18, 18, 9.5, rgb(0xFFE08A).opacity(0.25))
            ctx.rect(0, 66, 100, 20, rgb(dark ? 0x3E7FA8 : 0x86CCEA))
            for (y, x0) in [(70.0, 6.0), (74.0, 58.0), (78.0, 24.0)] {
                ctx.strokePath(Color.white.opacity(0.7), width: 0.8) { p in
                    p.move(to: CGPoint(x: x0, y: y))
                    p.addCurve(to: CGPoint(x: x0 + 16, y: y), control1: CGPoint(x: x0 + 5, y: y - 1.6), control2: CGPoint(x: x0 + 11, y: y + 1.6))
                }
            }
        case "rainbow":
            let colors: [UInt32] = [0xFFB3BA, 0xFFD8A8, 0xFFF1A8, 0xBDEBC8, 0xB8DBFF, 0xD7C4FF]
            for (i, c) in colors.enumerated() {
                let r = 46 - CGFloat(i) * 3.6
                ctx.strokePath(rgb(c).opacity(dark ? 0.75 : 0.95), width: 3.8) { p in
                    p.addArc(center: CGPoint(x: 50, y: 80), radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                }
            }
            Self.puff(ctx, cx: 8, cy: 80, w: 22, Color.white.opacity(0.95))
            Self.puff(ctx, cx: 92, cy: 80, w: 22, Color.white.opacity(0.95))
        case "snow":
            ctx.ellipse(-25, 62, 75, 40, rgb(dark ? 0xC9D3EC : 0xE6EEF8))
            ctx.ellipse(48, 60, 80, 42, rgb(dark ? 0xBFC9E6 : 0xDCE7F5))
            Self.pine(ctx, x: 11, base: 74, h: 22)
            Self.pine(ctx, x: 89, base: 72, h: 26)
            Self.pine(ctx, x: 79, base: 77, h: 15)
        case "sakura":
            Self.blossomBranch(ctx)
        default:
            break
        }
    }

    private func drawGround(_ ctx: GraphicsContext, dark: Bool) {
        switch scene {
        case "cloud", "rainbow":
            Self.cushion(ctx, Color.white.opacity(dark ? 0.9 : 0.95))
        case "moon":
            Self.cushion(ctx, rgb(0xF4EEFF).opacity(0.97))
        case "meadow":
            ctx.ellipse(-20, 80, 140, 44, rgb(dark ? 0x5E9277 : 0x8CC9A6))
            let flowers: [(CGFloat, CGFloat, CGFloat, UInt32)] = [
                (12, 88, 2.6, 0xFFFFFF), (22, 95, 2.0, 0xFFD6E0), (85, 89, 2.6, 0xFFFFFF), (77, 96, 1.8, 0xFFF1B8), (93, 96, 1.8, 0xFFD6E0)
            ]
            for f in flowers { Self.flower(ctx, f.0, f.1, f.2, rgb(f.3)) }
        case "beach":
            ctx.ellipse(-25, 79, 150, 46, rgb(dark ? 0xC9B48C : 0xF6E2B3))
            Self.starfish(ctx, 13, 92, 3.2, rgb(0xF4A07A))
            ctx.ellipse(84, 91, 6, 4, rgb(0xFBC8D4))
            ctx.ellipse(85.5, 91.6, 3, 2, rgb(0xFFE6EC))
        case "snow":
            ctx.ellipse(-25, 80, 150, 46, rgb(0xFBFDFF))
        case "sakura":
            ctx.ellipse(-25, 80, 150, 46, rgb(dark ? 0xC79AB4 : 0xFBD9E4))
            for (x, y, a) in [(14.0, 90.0, 20.0), (25.0, 95.0, -30.0), (80.0, 92.0, 40.0), (90.0, 88.0, -10.0)] {
                Self.petal(ctx, x, y, 2.4, a, rgb(0xF7A8C0))
            }
        default:
            break
        }
    }

    // MARK: Thú cưng

    private var petRect: CGRect {
        caption == nil ? CGRect(x: 3, y: -0.5, width: 94, height: 94) : CGRect(x: 10, y: -3, width: 80, height: 80)
    }

    private func drawPet(_ ctx: GraphicsContext) {
        var c = ctx
        let r = petRect
        c.translateBy(x: r.minX, y: r.minY)
        c.scaleBy(x: r.width / 100, y: r.height / 100)
        PetPainter(mood: mood, appearance: appearance, pose: pose).draw(in: c)
    }

    // MARK: Hiệu ứng

    private func twinkle(_ i: Int) -> CGFloat {
        guard time > 0 else { return 1 }
        return 0.75 + 0.25 * CGFloat(sin(time * 2.2 + Double(i) * 1.7))
    }

    /// Vị trí quanh viền (tránh mặt thú cưng).
    private static let rim: [(CGFloat, CGFloat, CGFloat)] = [
        (11, 30, 1.0), (24, 11, 0.7), (82, 12, 1.0), (91, 40, 0.8), (8, 55, 0.7), (90, 62, 0.65), (17, 45, 0.5), (77, 28, 0.6)
    ]

    private func drawEffect(_ ctx: GraphicsContext, dark: Bool) {
        switch effect {
        case "sparkles":
            for (i, p) in Self.rim.enumerated() {
                let color = i % 3 == 1 ? rgb(0xFFE9A8) : Color.white
                Self.sparkle(ctx, p.0, p.1, 3.4 * p.2 * twinkle(i), color.opacity(0.95))
            }
        case "hearts":
            let colors: [UInt32] = [0xFF8FAB, 0xFF9DB5, 0xFFB3C6]
            for (i, p) in Self.rim.enumerated() {
                let rise = time > 0 ? CGFloat(sin(time * 1.4 + Double(i))) * 1.2 : 0
                ctx.rotated(Double(i % 2 == 0 ? 12 : -14), around: CGPoint(x: p.0, y: p.1 + rise)) { c in
                    c.heart(center: CGPoint(x: p.0, y: p.1 + rise), size: 5.2 * p.2, rgb(colors[i % 3]).opacity(0.92))
                }
            }
        case "stars":
            for (i, p) in Self.rim.enumerated() {
                Self.star(ctx, p.0, p.1, 2.8 * p.2 * twinkle(i), rgb(i % 2 == 0 ? 0xFFE27A : 0xFFF3C4))
            }
            for p in Self.dust.prefix(10) { ctx.circle(p.x, p.y + 2, 0.5, rgb(0xFFF3C4).opacity(0.8)) }
        case "bubbles":
            for (i, p) in Self.rim.enumerated() {
                let rise = time > 0 ? CGFloat((time * 3 + Double(i) * 9).truncatingRemainder(dividingBy: 20)) : 0
                let r = 2.6 * p.2 + 0.6
                let y = p.1 - rise + 6
                ctx.stroke(Path(ellipseIn: CGRect(x: p.0 - r, y: y - r, width: r * 2, height: r * 2)),
                           with: .color(Color.white.opacity(0.85)), lineWidth: 0.5)
                ctx.circle(p.0 - r * 0.35, y - r * 0.35, r * 0.25, Color.white.opacity(0.9))
                ctx.circle(p.0, y, r, rgb(0xCDEBFF).opacity(0.25))
            }
        case "snow":
            for (i, p) in Self.flakes.enumerated() {
                let fall = time > 0 ? CGFloat((time * 4 + Double(i) * 7).truncatingRemainder(dividingBy: 100)) : 0
                let y = (p.y + fall).truncatingRemainder(dividingBy: 100)
                ctx.circle(p.x, y, i % 4 == 0 ? 1.1 : 0.7, Color.white.opacity(0.95))
            }
        case "petals":
            for (i, p) in Self.flakes.prefix(14).enumerated() {
                let fall = time > 0 ? CGFloat((time * 3 + Double(i) * 7).truncatingRemainder(dividingBy: 100)) : 0
                let y = (p.y + fall).truncatingRemainder(dividingBy: 100)
                Self.petal(ctx, p.x, y, 2.0, Double(i * 37) + time * 30, rgb(i % 2 == 0 ? 0xF7A8C0 : 0xFFC9D8))
            }
        case "fireflies":
            for (i, p) in Self.rim.enumerated() {
                let glow = twinkle(i)
                ctx.fill(Path(ellipseIn: CGRect(x: p.0 - 4, y: p.1 - 4, width: 8, height: 8)),
                         with: .radialGradient(Gradient(colors: [rgb(0xFFF2A0).opacity(0.7 * glow), rgb(0xFFF2A0).opacity(0)]),
                                               center: CGPoint(x: p.0, y: p.1), startRadius: 0, endRadius: 4))
                ctx.circle(p.0, p.1, 0.9, rgb(0xFFF7C8))
            }
        case "confetti":
            let colors: [UInt32] = [0xFF8FAB, 0xFFD45E, 0x7FD1AE, 0x8EC5FF, 0xC3A6FF]
            for (i, p) in Self.flakes.enumerated() where i % 2 == 0 || p.y < 30 {
                ctx.rotated(Double(i * 41), around: CGPoint(x: p.x, y: p.y)) { c in
                    c.rect(p.x - 1.1, p.y - 0.5, 2.2, 1.0, rgb(colors[i % colors.count]), radius: 0.3)
                }
            }
        default:
            break
        }
    }

    private static let flakes: [CGPoint] = [
        CGPoint(x: 6, y: 8), CGPoint(x: 18, y: 22), CGPoint(x: 30, y: 6), CGPoint(x: 44, y: 14), CGPoint(x: 58, y: 3),
        CGPoint(x: 70, y: 18), CGPoint(x: 84, y: 7), CGPoint(x: 95, y: 20), CGPoint(x: 9, y: 38), CGPoint(x: 92, y: 36),
        CGPoint(x: 4, y: 58), CGPoint(x: 96, y: 55), CGPoint(x: 13, y: 70), CGPoint(x: 88, y: 74), CGPoint(x: 38, y: 28),
        CGPoint(x: 64, y: 30), CGPoint(x: 22, y: 50), CGPoint(x: 79, y: 48), CGPoint(x: 50, y: 92), CGPoint(x: 30, y: 84),
        CGPoint(x: 72, y: 88), CGPoint(x: 52, y: 22)
    ]

    // MARK: Tên

    private func drawCaption(_ ctx: GraphicsContext, _ text: String) {
        let w = min(84, CGFloat(text.count) * 3.4 + 12)
        let rect = CGRect(x: 50 - w / 2, y: 84, width: w, height: 11)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 5.5), with: .color(Color.white.opacity(0.92)))
        ctx.stroke(Path(roundedRect: rect, cornerRadius: 5.5), with: .color(rgb(0xE6DAF5)), lineWidth: 0.5)
        ctx.draw(Text(text).font(.system(size: 5.6, weight: .bold, design: .rounded)).foregroundColor(rgb(0x4A3C5C)),
                 at: CGPoint(x: 50, y: rect.midY))
    }

    // MARK: Hình nhỏ

    /// Đám mây phồng: đáy elip + ba cụm tròn.
    static func puff(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, w: CGFloat, _ color: Color) {
        var p = Path()
        let h = w * 0.32
        p.addEllipse(in: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h))
        p.addEllipse(in: CGRect(x: cx - w * 0.18 - h * 0.55, y: cy - h * 0.35 - h * 0.55, width: h * 1.1, height: h * 1.1))
        p.addEllipse(in: CGRect(x: cx + w * 0.12 - h * 0.7, y: cy - h * 0.5 - h * 0.7, width: h * 1.4, height: h * 1.4))
        ctx.fill(p, with: .color(color))
    }

    /// Đệm mây lớn dưới chân (giống icon).
    static func cushion(_ ctx: GraphicsContext, _ color: Color) {
        var p = Path()
        p.addEllipse(in: CGRect(x: 8, y: 83.1, width: 84, height: 23.6))
        for (fx, fy, fr) in [(-0.36, 0.02, 0.10), (-0.20, -0.03, 0.13), (0.0, -0.05, 0.15), (0.20, -0.03, 0.13), (0.36, 0.02, 0.10)] {
            let cx = 50 + CGFloat(fx) * 84, cy = 87.4 + CGFloat(fy) * 84, r = CGFloat(fr) * 84
            p.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
        ctx.fill(p, with: .color(color))
    }

    /// Lấp lánh bốn cánh.
    static func sparkle(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
        let k = r * 0.28
        var p = Path()
        p.move(to: CGPoint(x: x, y: y - r))
        p.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x + k, y: y - k))
        p.addQuadCurve(to: CGPoint(x: x, y: y + r), control: CGPoint(x: x + k, y: y + k))
        p.addQuadCurve(to: CGPoint(x: x - r, y: y), control: CGPoint(x: x - k, y: y + k))
        p.addQuadCurve(to: CGPoint(x: x, y: y - r), control: CGPoint(x: x - k, y: y - k))
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
    }

    static func star(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        var points: [CGPoint] = []
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2
            let rr = i % 2 == 0 ? r : r * 0.48
            points.append(CGPoint(x: cx + rr * CGFloat(cos(a)), y: cy + rr * CGFloat(sin(a))))
        }
        ctx.polygon(points, color)
    }

    static func flower(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
        for i in 0..<5 {
            let a = Double(i) * 2 * .pi / 5
            ctx.circle(x + r * 0.9 * CGFloat(cos(a)), y + r * 0.9 * CGFloat(sin(a)), r * 0.55, color)
        }
        ctx.circle(x, y, r * 0.45, rgb(0xF5C04A))
    }

    static func petal(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ degrees: Double, _ color: Color) {
        ctx.rotated(degrees, around: CGPoint(x: x, y: y)) { c in
            c.ellipse(x - r, y - r * 0.55, r * 2, r * 1.1, color)
        }
    }

    static func starfish(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
        var points: [CGPoint] = []
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2
            let rr = i % 2 == 0 ? r : r * 0.45
            points.append(CGPoint(x: x + rr * CGFloat(cos(a)), y: y + rr * CGFloat(sin(a))))
        }
        ctx.polygon(points, color)
    }

    static func pine(_ ctx: GraphicsContext, x: CGFloat, base: CGFloat, h: CGFloat) {
        ctx.rect(x - h * 0.06, base - h * 0.15, h * 0.12, h * 0.2, rgb(0x9C7A62))
        for i in 0..<3 {
            let top = base - h + CGFloat(i) * h * 0.25
            let w = h * (0.36 + CGFloat(i) * 0.14)
            let bottom = top + h * 0.45
            ctx.polygon([CGPoint(x: x, y: top), CGPoint(x: x + w / 2, y: bottom), CGPoint(x: x - w / 2, y: bottom)], rgb(0x7FB5A0))
            ctx.polygon([CGPoint(x: x, y: top), CGPoint(x: x + w * 0.16, y: top + h * 0.12), CGPoint(x: x - w * 0.16, y: top + h * 0.12)], Color.white)
        }
    }

    /// Trăng khuyết: phần đĩa sáng nằm ngoài một đĩa thứ hai lệch lên phải.
    static func crescent(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, color: Color) {
        let c2 = CGPoint(x: cx + r * 0.48, y: cy - r * 0.36)
        let r2 = r * 0.9
        // Giao điểm hai đường tròn.
        let dx = c2.x - cx, dy = c2.y - cy
        let d = sqrt(dx * dx + dy * dy)
        let a = (r * r - r2 * r2 + d * d) / (2 * d)
        let h = sqrt(max(0, r * r - a * a))
        let mx = cx + a * dx / d, my = cy + a * dy / d
        let p1 = CGPoint(x: mx + h * dy / d, y: my - h * dx / d)
        let p2 = CGPoint(x: mx - h * dy / d, y: my + h * dx / d)
        func angle(_ p: CGPoint, _ c: CGPoint) -> Angle { .radians(Double(atan2(p.y - c.y, p.x - c.x))) }
        var path = Path()
        path.move(to: p1)
        path.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: angle(p1, CGPoint(x: cx, y: cy)),
                    endAngle: angle(p2, CGPoint(x: cx, y: cy)), clockwise: false)
        path.addArc(center: c2, radius: r2, startAngle: angle(p2, c2), endAngle: angle(p1, c2), clockwise: true)
        path.closeSubpath()
        ctx.fill(Path(ellipseIn: CGRect(x: cx - r * 1.5, y: cy - r * 1.5, width: r * 3, height: r * 3)),
                 with: .radialGradient(Gradient(colors: [color.opacity(0.35), color.opacity(0)]),
                                       center: CGPoint(x: cx, y: cy), startRadius: r * 0.6, endRadius: r * 1.5))
        ctx.fill(path, with: .color(color))
    }

    /// Cành anh đào vươn từ góc trên bên trái.
    static func blossomBranch(_ ctx: GraphicsContext) {
        ctx.strokePath(rgb(0x8E6A5A), width: 2.2) { p in
            p.move(to: CGPoint(x: -2, y: 8))
            p.addQuadCurve(to: CGPoint(x: 30, y: 16), control: CGPoint(x: 14, y: 6))
        }
        ctx.strokePath(rgb(0x8E6A5A), width: 1.4) { p in
            p.move(to: CGPoint(x: 15, y: 10))
            p.addQuadCurve(to: CGPoint(x: 22, y: 26), control: CGPoint(x: 21, y: 15))
        }
        ctx.strokePath(rgb(0x8E6A5A), width: 1.6) { p in
            p.move(to: CGPoint(x: 102, y: 22))
            p.addQuadCurve(to: CGPoint(x: 80, y: 12), control: CGPoint(x: 90, y: 22))
        }
        let blooms: [(CGFloat, CGFloat, CGFloat)] = [(6, 6, 3), (14, 11, 3.4), (25, 13, 3), (31, 18, 2.6), (21, 25, 2.8),
                                                     (18, 4, 2.2), (82, 11, 3), (92, 18, 3.2), (88, 25, 2.4), (99, 14, 2.6)]
        for (i, b) in blooms.enumerated() {
            flower(ctx, b.0, b.1, b.2, rgb(i % 2 == 0 ? 0xF9B9CC : 0xFFD3E0))
        }
    }
}
