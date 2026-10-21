import SwiftUI
import UIKit

// Khung giao diện dùng chung (phiên 9): nền sheet, tiêu đề, nút đóng/hủy/lưu, hỏi lại khi bỏ thay đổi,
// chip có nhãn, huy hiệu xu/vé, bố cục tự xuống dòng. Mọi màn mới nên dùng các thành phần ở đây
// thay vì tự đặt nút "Xong"/"Đóng" ở chỗ khác nhau.
//
// Quy ước nút trên thanh tiêu đề:
// - Quay lại (màn được đẩy vào NavigationStack): nút "<" của hệ thống, góc trái.
// - Đóng (sheet chỉ để xem, hoặc sheet tự lưu như Cài đặt): `SheetCloseButton`, dấu "x" tròn, LUÔN ở góc phải.
// - Hủy (sheet có chỉnh sửa): `SheetCancelButton`, chữ "Hủy" ở góc trái; có thay đổi chưa lưu thì hỏi lại.
// - Xác nhận (Lưu, Áp dụng…): `SheetConfirmButton`, nút đầy màu ở góc phải.

// MARK: Token bổ sung

extension Palette {
    /// Nền sheet: kem như nền màn hình, không dùng xám hệ thống.
    static let sheetBackground = background
    /// Màu chữ đậm của từng màu nhấn: đặt trên nền nhạt của chính màu đó vẫn đủ tương phản (≥ 4.5:1).
    static let lavenderInk = Color.dynamic(light: 0x6A55B0, dark: 0xCDBFF7)
    static let sageInk = Color.dynamic(light: 0x4A7350, dark: 0xB5D8B6)
    static let peachInk = Color.dynamic(light: 0xA8533A, dark: 0xF6C6B0)
}

enum CozyLayout {
    /// Lề hai bên của mọi màn.
    static let screenPadding: CGFloat = Spacing.l
    /// Khoảng trống cuối nội dung để không bị thanh tab / đồng hồ nhỏ che.
    static let tabBarClearance: CGFloat = 96
}

extension Typography {
    /// Tiêu đề trong nội dung một màn hoặc sheet (rounded, đậm, màu ink).
    static let screenTitle = Font.system(.title3, design: .rounded).weight(.bold)
    /// Tiêu đề một nhóm nội dung.
    static let sectionTitle = Font.system(.headline, design: .rounded).weight(.semibold)
}

// MARK: Tiêu đề thanh điều hướng

enum CozyAppearance {
    /// Tiêu đề thanh điều hướng (cả tiêu đề lớn) dùng font rounded màu tím than như nội dung,
    /// thay vì SF đen tuyền mặc định. Gọi một lần khi app khởi động.
    @MainActor
    static func configure() {
        let ink = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: 0xF3EEF8) : UIColor(hex: 0x3E3550)
        }
        let bar = UINavigationBar.appearance()
        bar.titleTextAttributes = [.foregroundColor: ink, .font: rounded(.headline, weight: .bold)]
        bar.largeTitleTextAttributes = [.foregroundColor: ink, .font: rounded(.largeTitle, weight: .bold)]
    }

    private static func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let size = UIFont.preferredFont(forTextStyle: style).pointSize
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: Nền sheet

extension View {
    /// Nền kem cho sheet và Form/List bên trong (không còn nền xám hệ thống).
    func cozySheetBackground() -> some View {
        scrollContentBackground(.hidden)
            .cozyBackground()
            .presentationBackground(Palette.sheetBackground)
    }

    /// Thêm nút "x" đóng sheet ở góc phải (sheet chỉ để xem hoặc tự lưu).
    func sheetCloseToolbar(_ close: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) { SheetCloseButton(action: close) }
        }
    }

    /// Thanh công cụ của sheet chỉnh sửa: "Hủy" bên trái (hỏi lại nếu có thay đổi), nút xác nhận bên phải.
    /// Khi còn thay đổi chưa lưu, vuốt xuống không đóng được sheet (tránh mất chữ đang gõ).
    func editSheetToolbar(isDirty: Bool, canSave: Bool, saveTitle: String = "Lưu",
                          onCancel: @escaping () -> Void, onSave: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .cancellationAction) {
                SheetCancelButton(isDirty: isDirty, cancel: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                SheetConfirmButton(title: saveTitle, enabled: canSave, action: onSave)
            }
        }
        .interactiveDismissDisabled(isDirty)
    }
}

/// Form theo phong cách CozyDay: nền kem, hàng nền thẻ (sáng/tối đều theo bảng màu của app).
struct CozyForm<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Form {
            Group { content }
                .listRowBackground(Palette.surface)
        }
        .cozySheetBackground()
    }
}

// MARK: Nút trên thanh tiêu đề sheet

/// Nút đóng: dấu "x" trong vòng tròn, luôn ở góc phải, VoiceOver đọc "Đóng".
struct SheetCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CloseGlyph()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Đóng")
    }
}

private struct CloseGlyph: View {
    var body: some View {
        let glyph = Image(systemName: "xmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Palette.inkMuted)
        Group {
            if #available(iOS 26, *) {
                // iOS 26 tự vẽ nền kính quanh nút trên thanh công cụ.
                glyph
            } else {
                glyph
                    .frame(width: 30, height: 30)
                    .background(Palette.surfaceMuted, in: Circle())
            }
        }
        .frame(minWidth: HitTarget.min, minHeight: HitTarget.min)
        .contentShape(Rectangle())
    }
}

/// "Hủy" cho sheet chỉnh sửa. Có thay đổi chưa lưu → hỏi "Bỏ thay đổi?" trước khi đóng.
struct SheetCancelButton: View {
    var isDirty: Bool
    let cancel: () -> Void
    @State private var asking = false

    var body: some View {
        Button("Hủy") {
            if isDirty { asking = true } else { cancel() }
        }
        .foregroundStyle(Palette.ink)
        .confirmationDialog("Bỏ những thay đổi chưa lưu?", isPresented: $asking, titleVisibility: .visible) {
            Button("Bỏ thay đổi", role: .destructive) { cancel() }
            Button("Tiếp tục sửa", role: .cancel) {}
        }
    }
}

/// Nút xác nhận (Lưu, Áp dụng…): nền đầy màu, khác hẳn "Hủy"; mờ đi khi chưa lưu được.
struct SheetConfirmButton: View {
    var title = "Lưu"
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.callout.weight(.bold))
                .foregroundStyle(enabled ? Palette.onAccent : Palette.inkMuted)
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: 32)
                .background(enabled ? Palette.lavender : Palette.surfaceMuted, in: Capsule())
                .frame(minHeight: HitTarget.min)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: Chip có nhãn

/// Nút dạng chip: biểu tượng + chữ (không bao giờ chỉ có biểu tượng), cao tối thiểu 44pt, co giãn theo cỡ chữ.
struct CozyChip: View {
    enum Style { case soft, filled }

    let title: String
    var symbol: String?
    var tint: Color = Palette.lavender
    var style: Style = .soft
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(style == .filled ? Palette.onAccent : tint)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .foregroundStyle(style == .filled ? Palette.onAccent : Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(Typography.callout.weight(.semibold))
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: HitTarget.min)
            .background(style == .filled ? tint : Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(style == .filled ? Color.clear : tint.opacity(0.45), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Chọn một trong vài lựa chọn (thay segmented control của hệ thống, vốn không phóng to theo cỡ chữ).
struct CozySegmented<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    var tint: Color = Palette.lavender

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let isOn = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .font(Typography.callout.weight(.semibold))
                        .foregroundStyle(isOn ? Palette.onAccent : Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, Spacing.m)
                        .frame(maxWidth: .infinity, minHeight: HitTarget.min - 6)
                        .background(isOn ? tint : Color.clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Palette.surfaceMuted, in: Capsule())
    }
}

// MARK: Huy hiệu

/// Số vé máy gacha, cùng kiểu với `CoinBadge`.
struct TicketBadge: View {
    let tickets: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.peach)
                .rotationEffect(.degrees(-12))
            Text("\(tickets)")
                .font(Typography.headline.monospacedDigit())
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
        }
        .fixedSize()
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs + 2)
        .background(Palette.surfaceMuted, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tickets) vé máy gacha")
    }
}

/// Chip nhỏ báo đang bật chế độ "Dữ liệu thử nghiệm".
struct TesterModeChip: View {
    var body: some View {
        Label("Dữ liệu thử nghiệm", systemImage: "testtube.2")
            .font(Typography.caption.weight(.bold))
            .foregroundStyle(Palette.peachInk)
            .lineLimit(1)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xxs + 1)
            .background(Palette.peach.opacity(0.16), in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.peach.opacity(0.5)))
            .fixedSize()
            .accessibilityLabel("Đang bật Dữ liệu thử nghiệm")
    }
}

/// Số nhỏ trên góc một biểu tượng (ví dụ số việc trong Hộp chờ).
struct CountBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(Palette.nowLine, in: Capsule())
            .accessibilityHidden(true)
    }
}

// MARK: Bố cục tự xuống dòng

/// Xếp các phần tử theo hàng, hết chỗ thì xuống dòng (chip không bị cắt ở mép phải khi chữ lớn).
struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.s
    var lineSpacing: CGFloat = Spacing.s

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let view = subviews[index]
            var size = view.sizeThatFits(.unspecified)
            if size.width > maxWidth {
                size = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
                size.width = min(size.width, maxWidth)
            }
            let needed = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if !current.items.isEmpty && needed > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width = current.items.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.items.append((index, size))
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let lines = arrange(maxWidth: maxWidth, subviews: subviews)
        let height = lines.reduce(0) { $0 + $1.height } + CGFloat(max(0, lines.count - 1)) * lineSpacing
        let widest = lines.map(\.width).max() ?? 0
        return CGSize(width: maxWidth.isFinite ? maxWidth : widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(maxWidth: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                                           anchor: .topLeading,
                                           proposal: ProposedViewSize(width: item.size.width, height: item.size.height))
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }
}

// MARK: Tiêu đề nhóm

/// Tiêu đề một nhóm nội dung trong màn (rounded, màu ink nhạt), có thể kèm một dòng phụ.
struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(Typography.sectionTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
