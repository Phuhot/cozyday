import SwiftUI

/// Phim mở viên nang (một phim cho cả lượt quay, lấy độ hiếm cao nhất), dùng thú cưng thật của bạn.
/// Kết quả đã được lưu trước khi phim chạy; phim không ghi gì vào kho. Bỏ qua được bất cứ lúc nào.
/// Hình: `GachaFilmPainter`. Thời gian, cảnh và âm thanh: `GachaStoryboard`.
struct GachaCutsceneView: View {
    let appearance: PetAppearance
    let tier: ItemRarity
    let short: Bool
    let finished: () -> Void
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("playground.sound") private var soundOn = true
    @State private var start = Date()
    @State private var ended = false
    @State private var sound: GameSound?

    private var cut: GachaStoryboard.Cut { short || reduceMotion ? .short : .full }
    private var duration: Double { GachaStoryboard.duration(cut) }

    var body: some View {
        TimelineView(.animation(paused: ended)) { timeline in
            let t = min(duration, max(0, timeline.date.timeIntervalSince(start)))
            ZStack {
                Canvas { context, size in
                    GachaFilmPainter.draw(context, size: size, time: t, cut: cut, pet: appearance, tier: tier, still: reduceMotion)
                }
                .ignoresSafeArea()
                .accessibilityLabel(t < GachaStoryboard.popTime(cut) ? "Bạn nhỏ đang mở viên nang" : "Đã mở món \(tier.label)")
                tierTitle(t)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: finish) {
                Label("Bỏ qua", systemImage: "forward.end.fill")
                    .font(Typography.callout.weight(.semibold))
                    .padding(.horizontal, Spacing.m).padding(.vertical, Spacing.s)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .foregroundStyle(.white)
            .frame(minHeight: HitTarget.min)
            .padding(.trailing, Spacing.l)
            .padding(.top, Spacing.s)
        }
        .background(Color(red: 0.14, green: 0.11, blue: 0.21).ignoresSafeArea())
        .statusBarHidden()
        .task {
            start = Date()
            // Không đổi chính sách phiên âm thanh của âm tập trung chỉ vì cảnh này.
            let audio = GameSound(enabled: soundOn && !FocusAudio.inUse)
            sound = audio
            audio.prepare()
            let cues = GachaStoryboard.sounds(cut, tier: tier)
            var next = 0
            while !Task.isCancelled && !ended {
                let elapsed = Date().timeIntervalSince(start)
                while next < cues.count && elapsed >= cues[next].time {
                    audio.play(cue(cues[next].sound)); next += 1
                }
                if elapsed >= duration { finish(); return }
                do { try await Task.sleep(nanoseconds: 16_000_000) } catch { return }
            }
        }
        .onChange(of: phase) { _, value in if value != .active { finish() } }
        .onDisappear { sound?.stop() }
    }

    /// Tên độ hiếm hiện lên sau khi viên nang bật mở.
    @ViewBuilder private func tierTitle(_ t: Double) -> some View {
        let pop = GachaStoryboard.popTime(cut)
        let appear = min(max((t - pop - 0.6) / 0.35, 0), 1)
        if appear > 0 {
            VStack(spacing: Spacing.xs) {
                Text(tier.label.uppercased())
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(GachaFilmPainter.color(tier, gold: 0))
                    .shadow(color: GachaFilmPainter.color(tier, gold: 0).opacity(0.8), radius: 14)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
                Text("Một món quà cho bạn nhỏ")
                    .font(Typography.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .scaleEffect(reduceMotion ? 1 : 0.8 + 0.2 * appear)
            .opacity(appear)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 110)
            .accessibilityHidden(true)
        }
    }

    private func cue(_ s: GachaStoryboard.Sound) -> GameCue {
        switch s {
        case .lampOn, .poke: return .flip
        case .steps, .click, .sniff: return .tick
        case .knob: return .pickup
        case .drop: return .place
        case .bounce: return .bounce
        case .rumble: return .whoosh
        case .reveal: return tier == .secret ? .merge4 : tier == .epic ? .merge3 : tier == .rare ? .merge2 : .merge1
        case .cheer: return tier >= .epic ? .newBest : .win
        }
    }

    private func finish() {
        guard !ended else { return }
        ended = true
        sound?.stop()
        finished()
    }
}
