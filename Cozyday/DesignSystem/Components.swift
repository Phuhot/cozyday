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
                    .strokeBorder(Palette.line, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Palette.lavender

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, Spacing.l)
            .frame(minHeight: HitTarget.min)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }
}

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Palette.lavender

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.l)
            .frame(minHeight: HitTarget.min)
            .background(tint.opacity(configuration.isPressed ? 0.22 : 0.14), in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
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
            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(Palette.honey)
            Text("\(coins)")
                .font(Typography.headline.monospacedDigit())
                .foregroundStyle(Palette.ink)
        }
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

/// Thông báo thưởng ngắn (tự ẩn) — không chặn thao tác.
struct RewardToast: View {
    let text: String

    var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "sparkles")
                .foregroundStyle(Palette.honey)
                .accessibilityHidden(true)
            Text(text)
                .font(Typography.callout.weight(.semibold))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s + 2)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.line))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
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
    /// Nền chung cho các màn hình.
    func cozyBackground() -> some View {
        background(Palette.background.ignoresSafeArea())
    }
}
