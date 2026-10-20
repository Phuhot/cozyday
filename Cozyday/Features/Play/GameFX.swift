import SwiftUI

// Hiệu ứng dùng chung cho các game theo lượt: hạt bắn tung, rung màn, nảy lên khi xuất hiện.
// Chỉ chạy khung hình trong lúc hiệu ứng còn sống (dưới 1,2 giây), rồi tự dừng.

/// Một lần bắn hạt: mỗi điểm gốc bắn ra vài hạt màu, rơi theo trọng lực và mờ dần.
struct ParticleBurst: Equatable {
    var id: Int
    /// Điểm gốc trong hệ tọa độ của vùng vẽ.
    var origins: [CGPoint]
    /// Màu theo từng điểm gốc (thiếu thì lặp lại).
    var colors: [Color]
    var perOrigin: Int = 4
    /// Độ mạnh: 1 = bình thường, lớn hơn thì bay xa hơn.
    var power: CGFloat = 1
    /// Kích thước hạt chuẩn (điểm).
    var size: CGFloat = 7
}

struct ParticleBurstView: View {
    let burst: ParticleBurst
    var lifetime: Double = 0.9
    @State private var start = Date()
    @State private var done = false

    var body: some View {
        if !done {
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { context in
                let t = context.date.timeIntervalSince(start)
                Canvas { ctx, _ in draw(ctx, t: t) }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                try? await Task.sleep(nanoseconds: UInt64(lifetime * 1_000_000_000))
                done = true
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, t: Double) {
        guard t < lifetime, !burst.origins.isEmpty else { return }
        let life = t / lifetime
        let gravity: CGFloat = 900
        for (o, origin) in burst.origins.enumerated() {
            let color = burst.colors.isEmpty ? Color.white : burst.colors[o % burst.colors.count]
            for k in 0..<burst.perOrigin {
                // Hướng và tốc độ cố định theo (lần bắn, gốc, hạt): không cần lưu trạng thái từng hạt.
                let h = Self.hash(burst.id &* 7919 &+ o &* 131 &+ k)
                let angle = Double(h % 3600) / 3600 * 2 * .pi
                let speed = (180 + CGFloat((h >> 12) % 220)) * burst.power
                let vx = CGFloat(cos(angle)) * speed
                let vy = CGFloat(sin(angle)) * speed - 260 * burst.power
                let x = origin.x + vx * CGFloat(t)
                let y = origin.y + vy * CGFloat(t) + 0.5 * gravity * CGFloat(t * t)
                let s = burst.size * (0.6 + CGFloat((h >> 20) % 10) / 12) * CGFloat(1 - life * 0.6)
                var c = ctx
                c.opacity = max(0, 1 - life * life)
                c.translateBy(x: x, y: y)
                c.rotate(by: .radians(angle + t * 6))
                switch k % 3 {
                case 0: c.fill(Self.sparkle(s), with: .color(color))
                case 1: c.fill(Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s)), with: .color(color))
                default: c.fill(Path(roundedRect: CGRect(x: -s / 2, y: -s / 3, width: s, height: s * 0.66), cornerRadius: s * 0.2),
                                with: .color(color))
                }
            }
        }
    }

    /// Ngôi sao lấp lánh 4 cánh.
    static func sparkle(_ s: CGFloat) -> Path {
        var p = Path()
        let r = s * 0.9, w = s * 0.22
        p.move(to: CGPoint(x: 0, y: -r))
        p.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: w, y: -w))
        p.addQuadCurve(to: CGPoint(x: 0, y: r), control: CGPoint(x: w, y: w))
        p.addQuadCurve(to: CGPoint(x: -r, y: 0), control: CGPoint(x: -w, y: w))
        p.addQuadCurve(to: CGPoint(x: 0, y: -r), control: CGPoint(x: -w, y: -w))
        p.closeSubpath()
        return p
    }

    static func hash(_ v: Int) -> Int {
        var x = UInt64(bitPattern: Int64(v)) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        return Int(truncatingIfNeeded: (x ^ (x >> 31)) & 0x7FFF_FFFF)
    }
}

/// Rung ngang tắt dần. Mỗi lần tăng `shakes` thêm 1 (trong withAnimation) là một lần rung.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var amplitude: CGFloat = 7

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let f = shakes - floor(shakes)
        let dx = amplitude * (1 - f) * sin(f * .pi * 8)
        let dy = amplitude * 0.35 * (1 - f) * sin(f * .pi * 6)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: dy))
    }
}

/// Nảy lên từ nhỏ mỗi khi `trigger` đổi (khối mới vào khay…), có độ trễ để nảy lần lượt.
struct PopInOnChange<T: Equatable>: ViewModifier {
    let trigger: T
    var delay: Double = 0
    let reduceMotion: Bool
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, _ in
                guard !reduceMotion else { return }
                scale = 0.2
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(delay)) { scale = 1 }
            }
    }
}

/// Chữ thưởng to, nảy ra rồi bay lên mờ dần (combo, món mới…).
struct BigCallout: View {
    let title: String
    var subtitle: String?
    var colors: [Color] = [rgb(0xFF8FB1), rgb(0xB38CFF)]
    let reduceMotion: Bool
    @State private var scale: CGFloat = 0.3
    @State private var rise: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                .shadow(color: .white, radius: 0, x: 0, y: 2)
                .shadow(color: colors.last?.opacity(0.45) ?? .clear, radius: 8, y: 3)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(rgb(0x6B4A8A))
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.85), in: Capsule())
            }
        }
        .fixedSize()
        .scaleEffect(reduceMotion ? 1 : scale)
        .offset(y: reduceMotion ? 0 : -rise)
        .opacity(opacity)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.5)) { scale = 1 }
            withAnimation(.easeIn(duration: 0.5).delay(0.75)) {
                rise = 40
                opacity = 0
            }
        }
    }
}
