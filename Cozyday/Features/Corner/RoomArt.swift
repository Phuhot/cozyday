import SwiftUI

/// Hình vẽ gốc cho từng món đồ trong danh mục, vẽ bằng code.
/// Đồ thường: hệ tọa độ vuông 100×100. Tường & sàn / bầu trời: cả căn phòng, 125×100.
struct ItemArt: View {
    let itemID: String

    static func isScene(_ id: String) -> Bool { ItemPainter.isScene(id) }

    var body: some View {
        Canvas { context, size in
            var ctx = context
            let width: CGFloat = Self.isScene(itemID) ? RoomLayout.width : 100
            let k = min(size.width / width, size.height / 100)
            ctx.translateBy(x: (size.width - width * k) / 2, y: (size.height - 100 * k) / 2)
            ctx.scaleBy(x: k, y: k)
            Self.draw(itemID, in: ctx)
        }
        .accessibilityHidden(true)
    }

    static func draw(_ id: String, in ctx: GraphicsContext) {
        ItemPainter.draw(id, in: ctx)
    }
}

/// Một căn phòng với các vị trí cố định và thú cưng. Vị trí trống hiển thị khung gợi ý.
/// Thú cưng tự đi qua đi lại (tắt khi bật Giảm chuyển động); giữ để nhấc lên và thả sang chỗ khác,
/// vuốt qua lại trên người để nựng.
struct RoomView: View {
    var room: RoomKind = .study
    var equipped: [ItemSlot: String]
    var appearance = PetAppearance()
    var petMood: PetMood
    var petName: String
    var bounceTrigger: Int
    var haptics = true
    var speech: ((Int) -> String)?
    var onTapSlot: ((ItemSlot) -> Void)?
    var onStroke: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var start = Date()
    /// Vị trí "nhà" của thú cưng (tỉ lệ bề rộng phòng) sau khi được kéo thả.
    @State private var home: CGFloat?
    @State private var drag: CGSize?

    private var canWander: Bool { !reduceMotion && drag == nil && (petMood == .idle || petMood == .happy) }

    /// Chỗ đứng mặc định (tỉ lệ bề rộng phòng): khoảng sàn trống trước đồ đạc của từng phòng.
    private var defaultHome: CGFloat { RoomLayout.petHome(room) }

    /// Vị trí ngang (tỉ lệ bề rộng phòng), đang đi hay không, hướng mặt — theo chu kỳ 26 giây.
    private func wander(at date: Date) -> (x: CGFloat, walking: Bool, left: Bool) {
        let a = home ?? defaultHome
        let b = a > 0.45 ? a - 0.24 : a + 0.26
        let goesLeft = b < a
        guard canWander else { return (a, false, false) }
        let t = date.timeIntervalSince(start).truncatingRemainder(dividingBy: 26)
        func ease(_ v: Double) -> CGFloat { CGFloat(v * v * (3 - 2 * v)) }
        switch t {
        case ..<9: return (a, false, false)
        case ..<12: return (a + (b - a) * ease((t - 9) / 3), true, goesLeft)
        case ..<21: return (b, false, t > 19 ? !goesLeft : goesLeft)
        case ..<24: return (b - (b - a) * ease((t - 21) / 3), true, !goesLeft)
        default: return (a, false, false)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let k = h / 100
            ZStack(alignment: .topLeading) {
                ItemArt(itemID: equipped[room.themeSlot] ?? Catalog.defaultItem(for: room.themeSlot)?.id ?? "")
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)

                ForEach(RoomLayout.drawOrder(room)) { slot in
                    if let spot = RoomLayout.spot(slot) {
                        slotView(slot)
                            .frame(width: spot.size * k, height: spot.size * k)
                            .offset(x: spot.x * k, y: spot.y * k)
                    }
                }

                if colorScheme == .dark {
                    Color.black.opacity(0.12).allowsHitTesting(false)
                }

                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !canWander)) { timeline in
                    let spot = wander(at: timeline.date)
                    let size = w * 0.30
                    PetView(appearance: appearance, mood: petMood, name: petName, bounceTrigger: bounceTrigger,
                            walking: spot.walking, facingLeft: spot.left, interactive: speech != nil,
                            haptics: haptics, speech: speech,
                            react: speech == nil ? nil : { reaction, seed in
                                PetDialogue.reaction(reaction, petName: petName, species: appearance.species, seed: seed)
                            },
                            onPickUp: { drag = $0 },
                            onDrop: { translation in
                                let x = min(max((spot.x * w + translation.width) / w, 0.02), 0.68)
                                home = x
                                drag = nil
                                start = Date()
                            },
                            onStroke: onStroke)
                        .frame(width: size, height: size)
                        .offset(x: w * spot.x + (drag?.width ?? 0),
                                y: h * 0.86 - size + min(max(drag?.height ?? 0, -h * 0.5), h * 0.08))
                }
            }
        }
        .aspectRatio(RoomLayout.aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous).strokeBorder(Palette.line))
        .onChange(of: room) { _, _ in home = nil }
    }

    private func slotLabel(_ slot: ItemSlot) -> String {
        guard let id = equipped[slot], let item = Catalog.item(id) else { return slot.label + ": trống" }
        return slot.label + ": " + item.name
    }

    @ViewBuilder
    private func slotView(_ slot: ItemSlot) -> some View {
        let content = Group {
            if let id = equipped[slot] {
                ItemArt(itemID: id)
            } else if onTapSlot != nil {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Palette.inkMuted.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .overlay(Image(systemName: "plus").font(.caption).foregroundStyle(Palette.inkMuted.opacity(0.6)))
                    .padding(4)
            }
        }
        if let onTapSlot {
            Button { onTapSlot(slot) } label: { content.contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityLabel(slotLabel(slot))
                .accessibilityHint("Mở cửa hàng cho vị trí này")
        } else {
            content
        }
    }
}
