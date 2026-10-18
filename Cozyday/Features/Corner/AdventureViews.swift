import SwiftUI

/// Thẻ "Chuyến đi hôm nay": năng lượng nạp từ việc bạn làm trong ngày; đủ thì nghe kể chuyện.
struct AdventureCard: View {
    @Binding var showStory: Bool
    @Binding var showMemories: Bool
    @Environment(AppStore.self) private var store
    @Environment(DayClock.self) private var dayClock

    var body: some View {
        let today = dayClock.today
        let energy = store.adventureEnergy(on: today)
        let claimed = store.adventureClaimed(on: today)
        let name = store.profile.displayPetName
        CozyCard {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack {
                    Label("Chuyến đi hôm nay", systemImage: "map")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(energy)%")
                        .font(Typography.headline.monospacedDigit())
                        .foregroundStyle(energy >= Adventure.fullEnergy ? Palette.sage : Palette.peach)
                }
                ProgressView(value: Double(energy), total: Double(Adventure.fullEnergy))
                    .tint(energy >= Adventure.fullEnergy ? Palette.sage : Palette.peach)
                    .accessibilityLabel("Năng lượng đi chơi")
                    .accessibilityValue("\(energy) phần trăm")
                if claimed {
                    Text(Adventure.story(for: today, petName: name, species: store.petAppearance.species).title + " — đã kể xong hôm nay.")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                    Button("Đọc lại câu chuyện") { showStory = true }
                        .buttonStyle(SoftButtonStyle(tint: Palette.sage))
                } else if energy >= Adventure.fullEnergy {
                    Text("\(name) đã đi chơi về và muốn kể cho bạn nghe!")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.ink)
                    Button {
                        showStory = true
                    } label: {
                        Label("Nghe \(name) kể chuyện (+\(RewardConfig.adventureCoins) xu)", systemImage: "book")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Palette.sage))
                } else {
                    Text("Mỗi việc xong, phiên tập trung, nhật ký hoặc bài thở nạp \(Adventure.energyPerActivity)% năng lượng. Đủ 100%, \(name) sẽ đi chơi và về kể chuyện.")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                }
                if !store.adventureMemories.isEmpty {
                    Button {
                        showMemories = true
                    } label: {
                        Label("Sổ ký ức (\(store.adventureMemories.count))", systemImage: "books.vertical")
                            .font(Typography.callout.weight(.semibold))
                            .frame(minHeight: HitTarget.min)
                    }
                    .tint(Palette.lavender)
                }
            }
        }
    }
}

/// Câu chuyện của ngày. Mở lần đầu khi đủ năng lượng → nhận thưởng (một lần mỗi ngày).
struct AdventureStorySheet: View {
    let day: DayKey
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let story = Adventure.story(for: day, petName: store.profile.displayPetName, species: store.petAppearance.species)
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    ZStack {
                        Circle().fill(Palette.lavenderSoft).frame(width: 150, height: 150)
                        PetView(appearance: store.petAppearance, mood: .happy, name: store.profile.displayPetName)
                            .frame(width: 130, height: 130)
                    }
                    Text(story.title)
                        .font(Typography.title)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                    Text(story.text)
                        .font(Typography.body)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Label("Kỷ niệm: \(story.keepsake)", systemImage: "sparkles")
                        .font(Typography.callout)
                        .foregroundStyle(Palette.inkMuted)
                }
                .padding(Spacing.xl)
            }
            .cozyBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
        }
        .task {
            guard !store.adventureClaimed(on: day) else { return }
            var entry: LedgerEntry?
            if ui.run({ entry = try store.claimAdventure(day: day) }) {
                ui.reward(entry)
            }
        }
    }
}

/// Sổ ký ức: các chuyến đi đã nghe kể.
struct MemoryBookView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.adventureMemories) { memory in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(DateText.full(memory.day, calendar: store.calendar))
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(Palette.inkMuted)
                        Text(memory.story.title)
                            .font(Typography.headline)
                            .foregroundStyle(Palette.ink)
                        Text(memory.story.text)
                            .font(Typography.callout)
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(.vertical, Spacing.xs)
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .cozyBackground()
            .navigationTitle("Sổ ký ức")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() } }
            }
        }
    }
}
