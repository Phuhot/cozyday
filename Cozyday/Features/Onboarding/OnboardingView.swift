import SwiftUI

/// Tối đa ba bước, bước nào cũng có thể bỏ qua. Thói quen gợi ý chỉ được tạo khi người dùng chọn.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @State private var step = 0
    @State private var species: PetSpecies = .cat
    @State private var userName = ""
    @State private var petName = ProfileRecord.defaultPetName
    @State private var goals: Set<UsageGoal> = []
    @State private var habits: Set<String> = []
    /// Video giới thiệu → tóm tắt tính năng → ba bước thiết lập.
    @State private var phase: Phase = PreviewMode.current == .tour ? .tour : .video

    enum Phase { case video, tour, setup }

    var body: some View {
        switch phase {
        case .video:
            IntroVideoPage(onNext: { withAnimation(Motion.gentle) { phase = .tour } },
                           onSkip: { withAnimation(Motion.gentle) { phase = .setup } })
                .transition(.opacity)
        case .tour:
            FeatureTourView(onFinish: { withAnimation(Motion.gentle) { phase = .setup } })
                .transition(.move(edge: .trailing).combined(with: .opacity))
        case .setup:
            setup
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private var setup: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bước \(step + 1)/3")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)
                Spacer()
                Button("Bỏ qua") { finish(skipAll: true) }
                    .frame(minHeight: HitTarget.min)
            }
            .padding(.horizontal, Spacing.l)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    switch step {
                    case 0: namesStep
                    case 1: goalsStep
                    default: habitsStep
                    }
                }
                .padding(Spacing.l)
            }

            HStack(spacing: Spacing.m) {
                if step > 0 {
                    Button("Quay lại") { step -= 1 }
                        .buttonStyle(SoftButtonStyle())
                }
                Button(step < 2 ? "Tiếp tục" : "Bắt đầu") {
                    if step < 2 { step += 1 } else { finish(skipAll: false) }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Spacing.l)
        }
        .cozyBackground()
        .animation(Motion.quick, value: step)
    }

    private var namesStep: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            PetView(appearance: PetAppearance(species: species, stage: .little), mood: .happy, name: ProfileRecord.defaultPetName)
                .frame(width: 150, height: 150)
                .frame(maxWidth: .infinity)
            Picker("Bạn nhỏ đầu tiên", selection: $species) {
                ForEach(PetSpecies.starters, id: \.self) { pet in Text(pet.name.capitalized).tag(pet) }
            }.pickerStyle(.menu)
            Text("Bạn sẽ đón một bạn nhỏ miễn phí. Các loài khác chờ bạn khám phá trong Bộ sưu tập.")
                .font(Typography.caption).foregroundStyle(Palette.inkMuted)
            Text("Chào mừng tới CozyDay")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
            Text("Sắp xếp ngày của bạn trên một timeline gọn gàng. Mỗi việc hoàn thành cho xu để bạn nhỏ trang trí góc phòng.")
                .foregroundStyle(Palette.inkMuted)
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Mình nên gọi bạn là gì?").font(Typography.headline)
                TextField("Tên của bạn (không bắt buộc)", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)
                Text("Đặt tên cho bạn nhỏ").font(Typography.headline)
                TextField("Tên bạn nhỏ", text: $petName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("Bạn muốn CozyDay giúp gì?")
                .font(Typography.title)
            Text("Chọn bao nhiêu cũng được. Phần này chỉ để gợi ý, có thể bỏ qua.")
                .foregroundStyle(Palette.inkMuted)
            FlowChips(items: UsageGoal.allCases.map { (id: $0.rawValue, label: $0.label) }, selected: Set(goals.map(\.rawValue))) { id in
                guard let g = UsageGoal(rawValue: id) else { return }
                if goals.contains(g) { goals.remove(g) } else { goals.insert(g) }
            }
        }
    }

    private var habitsStep: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text("Thêm vài thói quen?")
                .font(Typography.title)
            Text("Những việc bạn chọn sẽ lặp lại hằng ngày từ hôm nay. Có thể sửa hoặc xóa bất cứ lúc nào.")
                .foregroundStyle(Palette.inkMuted)
            VStack(spacing: Spacing.s) {
                ForEach(HabitSuggestion.all) { h in
                    let on = habits.contains(h.id)
                    Button {
                        if on { habits.remove(h.id) } else { habits.insert(h.id) }
                    } label: {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(on ? Palette.sage : Palette.inkMuted)
                                .font(.title3)
                            VStack(alignment: .leading) {
                                Text(h.title).font(Typography.body.weight(.medium)).foregroundStyle(Palette.ink)
                                Text("\(TimeOfDay.label(h.startMinute)) · \(TimeOfDay.durationLabel(h.duration))")
                                    .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                            }
                            Spacer()
                        }
                        .padding(Spacing.m)
                        .frame(minHeight: HitTarget.min)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private func finish(skipAll: Bool) {
        let chosenHabits = skipAll ? [] : HabitSuggestion.all.filter { habits.contains($0.id) }
        ui.run {
            try store.completeOnboarding(
                userName: userName,
                petName: petName,
                goals: skipAll ? [] : Array(goals),
                habits: chosenHabits, species: species
            )
        }
    }
}

/// Dãy chip xuống dòng tự động.
struct FlowChips: View {
    let items: [(id: String, label: String)]
    let selected: Set<String>
    let toggle: (String) -> Void

    var body: some View {
        FlowLayout(spacing: Spacing.s) {
            ForEach(items, id: \.id) { item in
                ChipToggle(title: item.label, isOn: selected.contains(item.id)) { toggle(item.id) }
            }
        }
    }
}

