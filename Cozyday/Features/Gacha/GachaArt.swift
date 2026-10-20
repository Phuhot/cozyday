import SwiftUI

/// Hình máy gacha vẽ bằng code: vòm kính đầy viên nang, thân hồng, núm xoay, máng ra quà.
enum GachaMachineArt {
    private static let capsuleColors: [UInt32] = [0xF4A6B8, 0xA9D3F5, 0xC7B4F0, 0xFFD27F, 0xA8DDB5, 0xFFB38A]

    /// `spin` < 0: đứng yên. Đang quay: núm xoay, viên nang lắc, một viên lăn ra máng.
    static func draw(_ ctx: GraphicsContext, size: CGSize, spin: Double) {
        let s = min(size.width / 200, size.height / 260)
        var c = ctx
        c.translateBy(x: (size.width - 200 * s) / 2, y: (size.height - 260 * s) / 2)
        c.scaleBy(x: s, y: s)
        let shake = spin >= 0 ? sin(spin * 40) * 2.2 * max(0, 1 - spin / 1.1) : 0

        // Bóng dưới chân
        c.ellipse(36, 246, 128, 12, Color.black.opacity(0.08))
        // Thân
        c.rect(40, 140, 120, 104, rgb(0xF7B6C8), radius: 22)
        c.rect(40, 140, 120, 18, rgb(0xEFA0B6), radius: 9)
        c.rect(52, 236, 18, 12, rgb(0xE48FA7), radius: 4)
        c.rect(130, 236, 18, 12, rgb(0xE48FA7), radius: 4)
        // Khe xu
        c.rect(122, 170, 22, 8, rgb(0xD97F98), radius: 4)
        c.circle(133, 192, 3, rgb(0xFFE08A))
        // Máng ra quà
        c.rect(60, 196, 52, 36, rgb(0xFFF6EE), radius: 10)
        c.rect(64, 200, 44, 28, rgb(0xF3DCE3), radius: 8)
        // Núm xoay
        let angle = spin >= 0 ? min(spin / 0.7, 1) * 360 : 0
        c.circle(100, 168, 15, Color.white)
        c.rotated(angle, around: CGPoint(x: 100, y: 168)) { k in
            k.rect(97, 155, 6, 26, Palette.lavender, radius: 3)
        }
        c.circle(100, 168, 4, Palette.lavender)

        // Vòm kính
        let dome = CGRect(x: 30, y: 16, width: 140, height: 132)
        c.fill(Path(ellipseIn: dome), with: .color(rgb(0xE3F2FF).opacity(0.9)))
        var inside = c
        inside.clip(to: Path(ellipseIn: dome.insetBy(dx: 4, dy: 4)))
        let pile: [(CGFloat, CGFloat)] = [(60, 118), (88, 124), (116, 120), (142, 112), (72, 94), (102, 98), (130, 90),
                                          (56, 72), (86, 70), (116, 66), (140, 70), (98, 44)]
        for (i, p) in pile.enumerated() {
            let jig = spin >= 0 ? sin(spin * 30 + Double(i)) * 3 * max(0, 1 - spin / 1.2) : 0
            capsule(inside, center: CGPoint(x: p.0 + shake + jig, y: p.1 - abs(jig)), radius: 13,
                    color: rgb(capsuleColors[i % capsuleColors.count]), tilt: Double(i * 37 % 90) - 45)
        }
        // Ánh sáng trên kính
        c.strokePath(Color.white.opacity(0.8), width: 6) { p in
            p.addArc(center: CGPoint(x: 100, y: 82), radius: 56, startAngle: .degrees(200), endAngle: .degrees(245), clockwise: false)
        }
        c.stroke(Path(ellipseIn: dome), with: .color(Color.white.opacity(0.9)), lineWidth: 3)
        // Nắp vòm + ngôi sao
        c.rect(78, 8, 44, 14, rgb(0xF7B6C8), radius: 7)
        star(c, center: CGPoint(x: 100, y: 6), r: 9, color: rgb(0xFFD27F))

        // Viên nang lăn ra máng khi gần quay xong.
        if spin > 0.55 {
            let k = min(1, (spin - 0.55) / 0.45)
            let y = 196 + 18 * k - (k > 0.7 ? sin((k - 0.7) / 0.3 * .pi) * 6 : 0)
            capsule(c, center: CGPoint(x: 86, y: y), radius: 11, color: rgb(0xC7B4F0), tilt: k * 200)
        }
    }

    static func capsule(_ ctx: GraphicsContext, center: CGPoint, radius r: CGFloat, color: Color, tilt: Double = -20) {
        ctx.rotated(tilt, around: center) { k in
            let top = Path { p in
                p.addArc(center: center, radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.closeSubpath()
            }
            k.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)), with: .color(Color.white))
            k.fill(top, with: .color(color))
            k.fill(Path(CGRect(x: center.x - r, y: center.y - r * 0.08, width: 2 * r, height: r * 0.16)), with: .color(color.opacity(0.55)))
            k.circle(center.x - r * 0.35, center.y - r * 0.45, r * 0.18, Color.white.opacity(0.7))
            k.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(0.5)), lineWidth: 1.2)
        }
    }

    private static func star(_ ctx: GraphicsContext, center: CGPoint, r: CGFloat, color: Color) {
        var p = Path()
        for i in 0..<10 {
            let rad = i % 2 == 0 ? r : r * 0.45
            let a = Double(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: center.x + rad * cos(a), y: center.y + rad * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
    }
}
