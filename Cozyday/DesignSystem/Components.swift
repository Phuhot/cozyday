import SwiftUI

struct CozyCard<Content: View>: View {
    var padding: CGFloat = Spacing.l
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .strokeBorder(Palette.line.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Palette.shadow.opacity(0.08), radius: 12, y: 5)
    }
}

/// Nút chính: bo tròn mềm, có bóng màu, nhún nhẹ khi bấm.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Palette.lavender
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, Spacing.l)
            .frame(minHeight: HitTarget.min + 6)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .shadow(color: color.opacity(configuration.isPressed ? 0.15 : 0.32), radius: configuration.isPressed ? 4 : 10, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : Motion.bouncy, value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Palette.lavender
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.l)
            .frame(minHeight: HitTarget.min + 6)
            .background(tint.opacity(configuration.isPressed ? 0.22 : 0.14), in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : Motion.bouncy, value: configuration.isPressed)
    }
}

struct ChipToggle: View {
    let title: String
    let isOn: Bool
    var tint: Color = Palette.lavender
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.callout.weight(.medium))
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: HitTarget.min)
                .foregroundStyle(isOn ? Palette.onAccent : Palette.ink)
                .background(isOn ? tint : Palette.surfaceMuted, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct CoinBadge: View {
    let coins: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            CoinIcon(size: 20)
            Text("\(coins)")
                .font(Typography.headline.monospacedDigit())
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
        }
        .fixedSize()
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs + 2)
        .background(Palette.surfaceMuted, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(coins) xu")
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Palette.lavender)
                .accessibilityHidden(true)
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(Palette.ink)
            Text(message)
                .font(Typography.callout)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

/// Thông báo lỗi nhỏ dạng banner, có nút đóng.
struct ErrorBanner: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.danger)
                .accessibilityHidden(true)
            Text(message)
                .font(Typography.callout)
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .frame(width: HitTarget.min, height: HitTarget.min)
            }
            .accessibilityLabel("Đóng thông báo lỗi")
        }
        .padding(.leading, Spacing.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.m).strokeBorder(Palette.danger.opacity(0.4)))
        .padding(.horizontal, Spacing.l)
    }
}

/// Popup thưởng kiểu "boing": thú cưng của bạn bật lên cùng bong bóng lời thoại, tự ẩn, không chặn thao tác.
struct PetRewardPopup: View {
    let text: String
    let appearance: PetAppearance
    var seed: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    private static let cheers = [
        "Giỏi quá đi!", "Mình nhảy một cái ăn mừng nè!", "Thêm một dấu tích xanh!", "Yay, thêm một việc nữa!",
        "Xong rồi, uống ngụm nước nha!", "Đáng một cái ôm!", "Mình vỗ tay bộp bộp!", "Ăn mừng thôi!",
        "Mình ghi vào sổ rồi nha!", "Gạch được một việc, sướng ghê!"
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            PetArt(mood: .happy, appearance: appearance)
                .frame(width: 74, height: 74)
                .rotationEffect(.degrees(shown || reduceMotion ? 0 : -12))
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.lavender)
                Text(Self.cheers[abs(seed) % Self.cheers.count])
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(Palette.bubbleInk)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(Palette.bubble, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous))
            .padding(.bottom, 18)
        }
        .padding(.trailing, Spacing.s)
        .background(Palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .shadow(color: Palette.shadow.opacity(0.18), radius: 16, y: 8)
        .scaleEffect(shown || reduceMotion ? 1 : 0.4)
        .opacity(shown || reduceMotion ? 1 : 0)
        .onAppear { withAnimation(reduceMotion ? nil : Motion.bouncy) { shown = true } }
        .accessibilityElement(children: .combine)
    }
}

extension LedgerEntry {
    var rewardText: String {
        var parts: [String] = []
        if xp > 0 { parts.append("+\(xp) XP") }
        if coins > 0 { parts.append("+\(coins) xu") }
        return parts.joined(separator: " · ")
    }
}

extension View {
    /// Nền chung cho các màn hình: màu kem kèm họa tiết dấu chân, tim, sao rất mờ.
    func cozyBackground() -> some View {
        background(
            ZStack {
                Palette.background
                CozyBackdrop()
            }
            .ignoresSafeArea()
        )
    }
}

/// Họa tiết nền mờ (dấu chân, tim, ngôi sao) rải cố định — kiểu sticker dễ thương, không gây rối mắt.
struct CozyBackdrop: View {
    var body: some View {
        Canvas { ctx, size in
            let tile: CGFloat = 150
            let cols = Int(size.width / tile) + 1, rows = Int(size.height / tile) + 1
            for r in 0...rows {
                for c in 0...cols {
                    let ox = CGFloat(c) * tile + (r % 2 == 0 ? 0 : tile / 2)
                    let oy = CGFloat(r) * tile
                    var t = ctx
                    t.translateBy(x: ox, y: oy)
                    switch (r + c) % 3 {
                    case 0: Self.paw(t, at: CGPoint(x: 30, y: 40), angle: -18)
                    case 1: t.heart(center: CGPoint(x: 40, y: 50), size: 16, Palette.lavender.opacity(0.10))
                    default: Self.star(t, at: CGPoint(x: 36, y: 46))
                    }
                    if (r * 7 + c * 3) % 4 == 0 { t.circle(110, 104, 3, Palette.peach.opacity(0.12)) }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func paw(_ ctx: GraphicsContext, at p: CGPoint, angle: Double) {
        ctx.rotated(angle, around: p) { c in
            let color = Palette.lavender.opacity(0.09)
            c.ellipse(p.x - 9, p.y - 4, 18, 15, color)
            c.circle(p.x - 10, p.y - 10, 4, color)
            c.circle(p.x - 3.5, p.y - 15, 4, color)
            c.circle(p.x + 3.5, p.y - 15, 4, color)
            c.circle(p.x + 10, p.y - 10, 4, color)
        }
    }

    private static func star(_ ctx: GraphicsContext, at p: CGPoint) {
        var path = Path()
        for i in 0..<10 {
            let r: CGFloat = i % 2 == 0 ? 9 : 4
            let a = Double(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: p.x + r * cos(a), y: p.y + r * sin(a))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(Palette.honey.opacity(0.13)))
    }
}
