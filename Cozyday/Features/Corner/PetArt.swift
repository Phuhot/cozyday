import SwiftUI
import UIKit

/// Thú cưng của Cozyday — vẽ hoàn toàn bằng code (xem `PetPainter`).
struct PetArt: View {
    var mood: PetMood
    var appearance = PetAppearance()
    var pose = PetPose()

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            PetPainter(mood: mood, appearance: appearance, pose: pose).draw(in: ctx)
        }
        .accessibilityHidden(true)
    }
}

/// Thú cưng có chuyển động: thở, chớp mắt, vẫy đuôi, giật tai, liếc nhìn, nhảy khi vui.
/// Nếu `interactive`: chạm → thả tim, rung nhẹ và nói một câu; vuốt qua lại trên người → được nựng (mắt híp, má đỏ,
/// tim bay, rung nhẹ theo nhịp); giữ ~0,35 giây → nhấc lên, kéo đi rồi thả (báo qua `onPickUp` / `onDrop`).
/// Bật Giảm chuyển động: đứng yên hoàn toàn, vẫn chạm, nựng và nói được.
struct PetView: View {
    var appearance = PetAppearance()
    var mood: PetMood
    var name: String
    var bounceTrigger: Int = 0
    var walking = false
    var facingLeft = false
    var interactive = false
    var haptics = true
    /// Câu nói khi được chạm (số lần chạm → câu).
    var speech: ((Int) -> String)?
    /// Câu nói khi được nựng / nhấc lên / thả xuống.
    var react: ((PetReaction, Int) -> String)?
    /// Đang được nhấc: độ dời của ngón tay so với lúc nhấc (nil = vừa thả).
    var onPickUp: ((CGSize) -> Void)?
    /// Thả xuống: độ dời cuối cùng.
    var onDrop: ((CGSize) -> Void)?
    /// Mỗi lần ngón tay vuốt trên người (dùng tính tiến độ nựng của vòng chăm sóc).
    var onStroke: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var hopStart: Date?
    @State private var heartsStart: Date?
    @State private var bubble: String?
    @State private var taps = 0
    @State private var pettedUntil: Date?
    @State private var strokeDistance: CGFloat = 0
    @State private var lastStroke: CGPoint?
    @State private var strokes = 0
    @State private var lifted = false
    @State private var liftTranslation = CGSize.zero
    @State private var reactions = 0
    @GestureState private var holding = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            PetArt(mood: mood, appearance: appearance, pose: reduceMotion ? staticPose(at: timeline.date) : pose(at: timeline.date))
                .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
        }
        .overlay(alignment: .top) {
            if let bubble {
                SpeechBubble(text: bubble)
                    .frame(width: 180)
                    .alignmentGuide(.top) { $0[.bottom] + 2 }
                    .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if interactive { tapped() } }
        .gesture(pickUpOrStroke, including: interactive ? .all : .subviews)
        .onChange(of: holding) { _, isHolding in
            // Cử chỉ bị hủy (ví dụ cuộn trang giành mất): vẫn thả thú cưng xuống.
            if !isHolding { drop() }
        }
        .sensoryFeedback(trigger: taps) { _, _ in haptics ? .impact(weight: .light) : nil }
        .sensoryFeedback(trigger: strokes) { _, _ in haptics ? .impact(weight: .light, intensity: 0.5) : nil }
        .sensoryFeedback(trigger: lifted) { _, _ in haptics ? .impact(weight: .medium) : nil }
        .onChange(of: bounceTrigger) { _, _ in hopStart = Date() }
        .accessibilityElement()
        .accessibilityLabel("\(appearance.species.name.capitalized) \(name), \(mood.label)")
        .accessibilityAddTraits(interactive ? .isButton : [])
        .accessibilityHint(interactive ? "Chạm để vuốt ve" : "")
        .accessibilityAction { if interactive { tapped() } }
        .accessibilityAction(named: "Nựng") { if interactive { stroke(by: 80) } }
        .task { await trailerStroke() }
    }

    /// Trailer (bản Debug): vuốt qua lại khoảng 4 giây bằng đúng hàm mà cử chỉ vuốt gọi.
    private func trailerStroke() async {
        #if DEBUG
        guard interactive, PreviewMode.current == .trailerCuddle else { return }
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        for _ in 0..<130 where !Task.isCancelled {
            stroke(by: 14)
            try? await Task.sleep(nanoseconds: 33_000_000)
        }
        #endif
    }

    /// Giữ rồi kéo = nhấc lên; vuốt ngay = nựng.
    private var pickUpOrStroke: some Gesture {
        let pickUp = LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .updating($holding) { _, state, _ in state = true }
            .onChanged { value in
                // `.first` báo ngay khi chạm tay (chưa đủ giữ lâu) nên chỉ nhấc lên khi sang giai đoạn kéo.
                switch value {
                case .second(true, let drag):
                    if !lifted { liftUp() }
                    liftTranslation = drag?.translation ?? .zero
                    onPickUp?(liftTranslation)
                default:
                    break
                }
            }
            .onEnded { _ in drop() }
        let stroke = DragGesture(minimumDistance: 6)
            .onChanged { value in
                if let last = lastStroke {
                    self.stroke(by: hypot(value.location.x - last.x, value.location.y - last.y))
                }
                lastStroke = value.location
            }
            .onEnded { _ in lastStroke = nil }
        return pickUp.exclusively(before: stroke)
    }

    private func liftUp() {
        lifted = true
        liftTranslation = .zero
        onPickUp?(.zero)
        say(.pickedUp)
    }

    private func drop() {
        guard lifted else { return }
        lifted = false
        hopStart = Date()
        onDrop?(liftTranslation)
        liftTranslation = .zero
        say(.dropped)
    }

    /// Cộng dồn quãng vuốt: cứ ~60pt là thêm tim và rung nhẹ.
    private func stroke(by distance: CGFloat) {
        onStroke?()
        pettedUntil = Date().addingTimeInterval(0.9)
        strokeDistance += distance
        guard strokeDistance > 60 else { return }
        strokeDistance = 0
        strokes += 1
        heartsStart = Date()
        if strokes % 4 == 1 { say(.petted) }
    }

    private func say(_ reaction: PetReaction) {
        guard let react else { return }
        reactions += 1
        let line = react(reaction, reactions)
        withAnimation(Motion.quick) { bubble = line }
        UIAccessibility.post(notification: .announcement, argument: line)
        let token = reactions
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if reactions == token { withAnimation(Motion.quick) { bubble = nil } }
        }
    }

    private func tapped() {
        taps += 1
        hopStart = Date()
        heartsStart = Date()
        guard let speech else { return }
        let line = speech(taps - 1)
        withAnimation(Motion.quick) { bubble = line }
        UIAccessibility.post(notification: .announcement, argument: line)
        let token = taps
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if taps == token { withAnimation(Motion.quick) { bubble = nil } }
        }
    }

    /// Giảm chuyển động: không lắc lư, chỉ đổi nét mặt khi được nựng / nhấc.
    private func staticPose(at date: Date) -> PetPose {
        var p = PetPose()
        if let until = pettedUntil, until > Date() { p.petted = 1 }
        p.lifted = lifted
        return p
    }

    private func pose(at date: Date) -> PetPose {
        let t = date.timeIntervalSince(start)
        var p = PetPose()
        p.breath = CGFloat(sin(t * 2 * .pi / 3.2))
        p.blink = t.truncatingRemainder(dividingBy: 4.3) < 0.14
        p.tail = CGFloat(sin(t * 2 * .pi / (mood == .happy ? 0.9 : 1.9)))
        let earPhase = t.truncatingRemainder(dividingBy: 6.7)
        p.ear = earPhase < 0.3 ? CGFloat(sin(earPhase / 0.3 * .pi)) : 0
        p.look = mood == .focus ? 0 : CGFloat(sin(t / 3.1) * 0.8)
        if mood == .happy { p.tilt = sin(t * 2 * .pi / 1.6) * 3 }
        if walking {
            p.walk = CGFloat(t * 2 * .pi / 0.55)
            p.hop = abs(sin(t * 2 * .pi / 0.55)) * 1.6
        }
        if let h = hopStart {
            let d = date.timeIntervalSince(h)
            if d >= 0 && d < 0.7 { p.hop = CGFloat(abs(sin(d / 0.35 * .pi))) * 9 }
        }
        if let hs = heartsStart {
            let d = date.timeIntervalSince(hs)
            if d >= 0 && d < 1.4 { p.hearts = CGFloat(d / 1.4) }
        }
        p.z = CGFloat((t / 2.4).truncatingRemainder(dividingBy: 1))
        if let until = pettedUntil, until > date {
            p.petted = CGFloat(min(1, until.timeIntervalSince(date) / 0.3))
            p.tilt = sin(t * 2 * .pi / 0.7) * 5
            p.tail = CGFloat(sin(t * 2 * .pi / 0.5))
        }
        if lifted {
            p.lifted = true
            p.hop = 7
            p.tilt = sin(t * 2 * .pi / 1.2) * 7
            p.walk = nil
        }
        return p
    }
}

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.caption.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.m, style: .continuous).strokeBorder(Palette.line))
            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }
}
