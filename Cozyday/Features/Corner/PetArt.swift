import SwiftUI

enum PetMood: Equatable {
    case idle
    case happy
    case focus
    case rest

    var label: String {
        switch self {
        case .idle: return "đang thư giãn"
        case .happy: return "đang vui"
        case .focus: return "đang tập trung cùng bạn"
        case .rest: return "đang nghỉ ngơi"
        }
    }
}

extension GraphicsContext {
    func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
        fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }

    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color, radius: CGFloat = 0) {
        fill(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius), with: .color(color))
    }

    func polygon(_ points: [CGPoint], _ color: Color) {
        var p = Path()
        p.addLines(points)
        p.closeSubpath()
        fill(p, with: .color(color))
    }

    func strokePath(_ color: Color, width: CGFloat, _ build: (inout Path) -> Void) {
        var p = Path()
        build(&p)
        stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}

/// Chú mèo tròn màu kem của Cozyday — vẽ hoàn toàn bằng code trong hệ tọa độ 100×100.
struct PetArt: View {
    var mood: PetMood

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            let ink = Palette.catInk
            let cream = Palette.catCream
            let shade = Palette.catShade

            // bóng
            ctx.ellipse(22, 84, 56, 9, Color.black.opacity(0.10))
            // đuôi
            ctx.strokePath(shade, width: 7) { p in
                p.move(to: CGPoint(x: 74, y: 78))
                p.addQuadCurve(to: CGPoint(x: 88, y: 56), control: CGPoint(x: 94, y: 76))
            }
            // tai
            ctx.polygon([CGPoint(x: 24, y: 44), CGPoint(x: 27, y: 18), CGPoint(x: 45, y: 32)], cream)
            ctx.polygon([CGPoint(x: 76, y: 44), CGPoint(x: 73, y: 18), CGPoint(x: 55, y: 32)], cream)
            ctx.polygon([CGPoint(x: 29, y: 38), CGPoint(x: 30, y: 25), CGPoint(x: 40, y: 32)], Palette.blush)
            ctx.polygon([CGPoint(x: 71, y: 38), CGPoint(x: 70, y: 25), CGPoint(x: 60, y: 32)], Palette.blush)
            // thân tròn
            ctx.ellipse(16, 28, 68, 60, cream)
            ctx.ellipse(33, 58, 34, 27, shade)
            // lá nhỏ trên đầu
            ctx.ellipse(47, 20, 6, 11, Palette.sage)

            // mắt theo tâm trạng
            switch mood {
            case .idle:
                ctx.ellipse(35, 47, 5, 6.5, ink)
                ctx.ellipse(60, 47, 5, 6.5, ink)
                ctx.ellipse(36.4, 48, 1.6, 1.6, .white)
                ctx.ellipse(61.4, 48, 1.6, 1.6, .white)
            case .happy:
                ctx.strokePath(ink, width: 2.4) { p in
                    p.move(to: CGPoint(x: 33, y: 52)); p.addQuadCurve(to: CGPoint(x: 42, y: 52), control: CGPoint(x: 37.5, y: 44))
                    p.move(to: CGPoint(x: 58, y: 52)); p.addQuadCurve(to: CGPoint(x: 67, y: 52), control: CGPoint(x: 62.5, y: 44))
                }
            case .focus:
                ctx.strokePath(ink, width: 2.4) { p in
                    p.move(to: CGPoint(x: 33, y: 51)); p.addLine(to: CGPoint(x: 42, y: 52))
                    p.move(to: CGPoint(x: 58, y: 52)); p.addLine(to: CGPoint(x: 67, y: 51))
                }
            case .rest:
                ctx.strokePath(ink, width: 2.4) { p in
                    p.move(to: CGPoint(x: 33, y: 50)); p.addQuadCurve(to: CGPoint(x: 42, y: 50), control: CGPoint(x: 37.5, y: 55))
                    p.move(to: CGPoint(x: 58, y: 50)); p.addQuadCurve(to: CGPoint(x: 67, y: 50), control: CGPoint(x: 62.5, y: 55))
                }
            }
            // má hồng
            ctx.ellipse(26, 55, 8, 4.5, Palette.blush.opacity(mood == .happy ? 1 : 0.75))
            ctx.ellipse(66, 55, 8, 4.5, Palette.blush.opacity(mood == .happy ? 1 : 0.75))
            // mũi + miệng
            ctx.polygon([CGPoint(x: 48.5, y: 55), CGPoint(x: 51.5, y: 55), CGPoint(x: 50, y: 57)], ink)
            ctx.strokePath(ink, width: 1.4) { p in
                p.move(to: CGPoint(x: 46, y: 58)); p.addQuadCurve(to: CGPoint(x: 50, y: 58), control: CGPoint(x: 48, y: 61))
                p.addQuadCurve(to: CGPoint(x: 54, y: 58), control: CGPoint(x: 52, y: 61))
            }
            // chân trước
            ctx.ellipse(36, 80, 10, 7, cream)
            ctx.ellipse(54, 80, 10, 7, cream)

            switch mood {
            case .focus:
                // cuốn sách nhỏ
                ctx.rect(36, 70, 28, 13, Palette.lavender, radius: 2)
                ctx.rect(49.5, 70, 1, 13, Color.white.opacity(0.7))
            case .rest:
                ctx.draw(Text("z").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundColor(Palette.lavender), at: CGPoint(x: 80, y: 24))
                ctx.draw(Text("z").font(.system(size: 6, weight: .bold, design: .rounded)).foregroundColor(Palette.lavender), at: CGPoint(x: 87, y: 15))
            case .happy:
                ctx.draw(Text("✦").font(.system(size: 8)).foregroundColor(Palette.honey), at: CGPoint(x: 15, y: 26))
                ctx.draw(Text("✦").font(.system(size: 6)).foregroundColor(Palette.honey), at: CGPoint(x: 86, y: 34))
            case .idle:
                break
            }
        }
        .accessibilityHidden(true)
    }
}

/// Mèo có chuyển động nhẹ: thở chậm khi idle/rest, nảy một lần khi vui.
/// Tắt toàn bộ chuyển động khi bật Giảm chuyển động.
struct PetView: View {
    var mood: PetMood
    var name: String
    var bounceTrigger: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var bounce = false

    var body: some View {
        PetArt(mood: mood)
            .scaleEffect(x: 1, y: breathe ? 1.025 : 1, anchor: .bottom)
            .offset(y: bounce ? -8 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { breathe = true }
            }
            .onDisappear { breathe = false }
            .onChange(of: bounceTrigger) { _, _ in
                guard !reduceMotion else { return }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { bounce = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bounce = false }
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Mèo \(name), \(mood.label)")
    }
}
