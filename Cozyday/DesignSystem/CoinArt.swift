import SwiftUI

/// Đồng xu CozyDay: vàng mật ong, viền đậm, dấu chân mèo dập nổi, vệt sáng. Vẽ trong khung 100×100.
enum CoinArt {
    static func draw(_ ctx: GraphicsContext, in rect: CGRect) {
        var c = ctx
        c.translateBy(x: rect.minX, y: rect.minY)
        c.scaleBy(x: rect.width / 100, y: rect.height / 100)
        // Cạnh dày phía dưới cho cảm giác đồng xu có độ dày.
        c.ellipse(4, 8, 92, 90, rgb(0xC9822A))
        c.ellipse(4, 2, 92, 92, rgb(0xE6A23A))
        c.fill(Path(ellipseIn: CGRect(x: 11, y: 9, width: 78, height: 78)),
               with: .linearGradient(Gradient(colors: [rgb(0xFFE38F), rgb(0xFFC94D)]),
                                     startPoint: CGPoint(x: 30, y: 10), endPoint: CGPoint(x: 70, y: 88)))
        c.stroke(Path(ellipseIn: CGRect(x: 17, y: 15, width: 66, height: 66)), with: .color(rgb(0xF0B445)), lineWidth: 2.5)
        // Dấu chân
        let paw = rgb(0xE39B32)
        c.ellipse(36, 48, 28, 22, paw)
        c.ellipse(29, 34, 11, 13, paw)
        c.ellipse(40, 26, 10, 13, paw)
        c.ellipse(51, 26, 10, 13, paw)
        c.ellipse(61, 34, 11, 13, paw)
        // Vệt sáng
        c.strokePath(Color.white.opacity(0.75), width: 5) { p in
            p.addArc(center: CGPoint(x: 50, y: 48), radius: 30, startAngle: .degrees(200), endAngle: .degrees(240), clockwise: false)
        }
        c.circle(80, 18, 3.5, Color.white.opacity(0.9))
    }
}

/// Biểu tượng xu dùng trong giao diện (thay biểu tượng hệ thống cũ).
struct CoinIcon: View {
    var size: CGFloat = 20

    var body: some View {
        Canvas { ctx, sz in
            CoinArt.draw(ctx, in: CGRect(origin: .zero, size: sz))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
