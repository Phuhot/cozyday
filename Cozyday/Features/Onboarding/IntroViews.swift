import SwiftUI
import AVFoundation
import UIKit

/// Video lặp không có thanh điều khiển (dùng AVPlayerLayer). Bắt đầu tắt tiếng; chạm nút loa để bật.
struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var muted: Bool

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        var looper: AVPlayerLooper?
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        view.looper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = muted
        // Không giành âm thanh của app khác khi đang tắt tiếng.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .clear
        player.play()
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.playerLayer.player?.isMuted = muted
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.playerLayer.player?.pause()
        view.looper = nil
    }
}

/// Màn đầu tiên: phát trailer của app, nút loa, nút mũi tên sang phần tóm tắt.
struct IntroVideoPage: View {
    var onNext: () -> Void
    var onSkip: () -> Void
    @State private var muted = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let url = Bundle.main.url(forResource: "intro", withExtension: "mp4"), !reduceMotion {
                LoopingVideoView(url: url, muted: muted)
                    .ignoresSafeArea()
                    .accessibilityLabel("Video giới thiệu CozyDay")
            } else {
                // Giảm chuyển động hoặc thiếu video: ảnh tĩnh thay thế.
                VStack(spacing: Spacing.l) {
                    PetArt(mood: .happy, appearance: PetAppearance(species: .duck, fur: .honey, hat: "hat.cloud", stage: .little))
                        .frame(width: 200, height: 200)
                    Text("CozyDay")
                        .font(Typography.largeTitle)
                        .foregroundStyle(Palette.ink)
                    Text("Một ngày gọn hơn. Một góc nhỏ vui hơn.")
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            VStack {
                HStack {
                    Button {
                        muted.toggle()
                    } label: {
                        Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.headline)
                            .frame(width: HitTarget.min, height: HitTarget.min)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel(muted ? "Bật tiếng" : "Tắt tiếng")
                    Spacer()
                    Button("Bỏ qua", action: onSkip)
                        .font(Typography.callout.weight(.semibold))
                        .padding(.horizontal, Spacing.m)
                        .frame(minHeight: HitTarget.min)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                Spacer()
                Button(action: onNext) {
                    Image(systemName: "arrow.right")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Palette.onAccent)
                        .frame(width: 64, height: 64)
                        .background(Palette.lavender, in: Circle())
                        .shadow(color: Palette.shadow.opacity(0.35), radius: 10, y: 4)
                }
                .accessibilityLabel("Tiếp tục")
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .tint(Palette.ink)
            .padding(Spacing.l)
        }
        .background(Palette.background.ignoresSafeArea())
    }
}

/// Bốn trang tóm tắt tính năng + một trang mẹo nhanh. Mũi tên để sang trang, vuốt cũng được.
struct FeatureTourView: View {
    var onFinish: () -> Void
    @State private var page = 0

    private struct Page {
        let title: String
        let text: String
        let art: AnyView
    }

    private var pages: [Page] {
        [
            Page(title: "Ngày gọn gàng",
                 text: "Xếp việc trên timeline, chạm vòng tròn khi xong. Mỗi việc xong cho XP và xu.",
                 art: AnyView(TourTimelineArt())),
            Page(title: "Một bạn nhỏ của riêng bạn",
                 text: "Cho ăn, dọn nhà, nựng bằng cách vuốt. Bạn nhỏ không bao giờ ốm hay bỏ đi khi bạn bận.",
                 art: AnyView(TourPetArt())),
            Page(title: "Trang trí năm không gian",
                 text: "Phòng học, phòng ngủ, bếp, phòng tắm và khu vườn, có cả sàn và tường để đổi.",
                 art: AnyView(TourRoomArt())),
            Page(title: "Sân chơi và máy gacha",
                 text: "Chơi minigame kiếm thêm xu. Quay gacha để săn trang phục hiếm, có món bí mật chỉ thấy bóng.",
                 art: AnyView(TourPlayArt())),
            Page(title: "Mẹo nhanh",
                 text: "",
                 art: AnyView(TourTips()))
        ]
    }

    var body: some View {
        let all = pages
        VStack(spacing: Spacing.l) {
            HStack {
                Text("\(page + 1)/\(all.count)")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)
                Spacer()
                Button("Bỏ qua", action: onFinish)
                    .frame(minHeight: HitTarget.min)
            }
            TabView(selection: $page) {
                ForEach(Array(all.enumerated()), id: \.offset) { i, p in
                    ScrollView {
                        VStack(spacing: Spacing.l) {
                            p.art
                                .frame(maxWidth: .infinity)
                                .frame(height: 260)
                            Text(p.title)
                                .font(Typography.largeTitle)
                                .foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.center)
                            if !p.text.isEmpty {
                                Text(p.text)
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.inkMuted)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, Spacing.s)
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            HStack {
                if page > 0 {
                    Button {
                        withAnimation(Motion.gentle) { page -= 1 }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.title3.weight(.bold))
                            .frame(width: 52, height: 52)
                            .background(Palette.surface, in: Circle())
                    }
                    .accessibilityLabel("Trang trước")
                }
                Spacer()
                Button {
                    if page < all.count - 1 {
                        withAnimation(Motion.gentle) { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    HStack(spacing: Spacing.s) {
                        if page == all.count - 1 { Text("Bắt đầu thiết lập").font(Typography.headline) }
                        Image(systemName: "arrow.right").font(.title3.weight(.bold))
                    }
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, page == all.count - 1 ? Spacing.l : 0)
                    .frame(minWidth: 64, minHeight: 64)
                    .background(Palette.lavender, in: Capsule())
                }
                .accessibilityLabel(page < all.count - 1 ? "Trang sau" : "Bắt đầu thiết lập")
            }
        }
        .padding(Spacing.l)
        .cozyBackground()
    }
}

// MARK: Hình minh họa cho từng trang (vẽ bằng thành phần có sẵn của app)

private let tourDuck = PetAppearance(species: .duck, fur: .honey, hat: "hat.cloud", stage: .little)

private struct TourTimelineArt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            row("8:30", "Đi bộ 30 phút", Palette.sage, done: true)
            row("10:30", "Trả lời email của nhóm", TaskCategory.work.color, done: true)
            row("13:00", "Nấu bữa tối", Palette.honey, done: false)
            HStack(spacing: Spacing.xs) {
                Spacer()
                Text("+10 XP · +8 xu").font(Typography.headline).foregroundStyle(Palette.lavender)
                CoinIcon(size: 22)
            }
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .accessibilityHidden(true)
    }

    private func row(_ time: String, _ title: String, _ color: Color, done: Bool) -> some View {
        HStack(spacing: Spacing.s) {
            Text(time).font(Typography.caption.monospacedDigit()).foregroundStyle(Palette.inkMuted).frame(width: 44, alignment: .trailing)
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 5, height: 36)
            Text(title).font(Typography.callout.weight(.semibold)).strikethrough(done).foregroundStyle(Palette.ink)
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "circle").foregroundStyle(done ? Palette.sage : color)
        }
    }
}

private struct TourPetArt: View {
    var body: some View {
        HStack(spacing: -24) {
            PetArt(mood: .happy, appearance: PetAppearance(species: .cat, fur: .ginger, hat: "hat.beanie", neck: "neck.scarf", stage: .little))
                .frame(width: 130, height: 130)
            PetArt(mood: .happy, appearance: tourDuck)
                .frame(width: 170, height: 170)
            PetArt(mood: .happy, appearance: PetAppearance(species: .bunny, fur: .snow, hat: "hat.bow", stage: .little))
                .frame(width: 130, height: 130)
        }
        .accessibilityHidden(true)
    }
}

private struct TourRoomArt: View {
    var body: some View {
        RoomView(room: .bedroom,
                 equipped: [.bed: "bed.canopy", .nightstand: "nightstand.moon", .bedroomRug: "bedroomRug.rainbow",
                            .plush: "plush.teddy", .bedroomWall: "bedroomWall.fairy", .closet: "closet.vanity"],
                 appearance: tourDuck, petMood: .happy, petName: "", bounceTrigger: 0, haptics: false)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct TourPlayArt: View {
    var body: some View {
        HStack(spacing: Spacing.m) {
            Canvas { ctx, size in
                GachaMachineArt.draw(ctx, size: size, spin: -1)
            }
            .frame(width: 150, height: 200)
            VStack(spacing: Spacing.s) {
                ForEach(["cloud.fill", "basket.fill", "square.grid.3x3.fill"], id: \.self) { s in
                    Image(systemName: s)
                        .font(.title2)
                        .foregroundStyle(Palette.onAccent)
                        .frame(width: 56, height: 56)
                        .background(Palette.lavender, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct TourTips: View {
    private let tips: [(String, String)] = [
        ("checkmark.circle", "Chạm vòng tròn bên cạnh việc để đánh dấu xong."),
        ("calendar.badge.clock", "Mỗi ngày tối đa \(RewardConfig.taskRewardsPerDay) việc có thưởng. Việc xong sau đó vẫn được ghi nhận."),
        ("hand.draw", "Vuốt qua lại trên người thú cưng để nựng, giữ rồi kéo để dời chỗ."),
        ("gift", "Xu dùng mua đồ trong cửa hàng hoặc quay máy gacha. Món bí mật chỉ có trong máy.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(tips, id: \.1) { tip in
                HStack(alignment: .top, spacing: Spacing.m) {
                    Image(systemName: tip.0)
                        .font(.title3)
                        .foregroundStyle(Palette.lavender)
                        .frame(width: 32)
                    Text(tip.1)
                        .font(Typography.callout)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
    }
}
