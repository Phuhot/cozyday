import SwiftUI

/// CI-only routing is controlled by PreviewMode (always nil in Release).
struct GachaFilmPreview: View {
    @Environment(AppStore.self) private var store
    @State private var pulls: [GachaPull]?
    @State private var failure: String?
    var body: some View {
        Group {
            if let pulls { GachaResultView(pulls: pulls) }
            else if let failure { Text(failure) }
            else { ProgressView("Chuẩn bị lượt quay") }
        }
        .task {
            guard pulls == nil else { return }
            do { pulls = try store.pullGacha(count: 1) }
            catch { failure = error.localizedDescription }
        }
    }
}

/// Chiếu riêng phim mở viên nang để quay video xem trước (CI). Không ghi gì vào kho.
struct GachaScenePreview: View {
    @Environment(AppStore.self) private var store
    @State private var done = false
    var body: some View {
        let defaults = UserDefaults.standard
        let tier = ItemRarity(rawValue: defaults.string(forKey: "CozyFilmTier") ?? "") ?? .epic
        if done {
            Text("Hết phim").font(Typography.title).frame(maxWidth: .infinity, maxHeight: .infinity).cozyBackground()
        } else {
            GachaCutsceneView(appearance: store.petAppearance, tier: tier, short: defaults.bool(forKey: "CozyFilmShort")) { done = true }
        }
    }
}

struct GachaArtReviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing:Spacing.m) {
                Text("Máy Mây Mây · xưởng thiết kế").font(Typography.title)
                Text("Hình mẫu từ renderer thật · cùng pet và màu lông").font(Typography.caption)
                ForEach(["hat.g_teacup","outfit.g_pirate","hat.galaxy"],id:\.self) { id in
                    if let item=Catalog.item(id) {
                        HStack {
                            GachaRewardArt(item:item,appearance:PetAppearance(species:.capybara,fur:.cocoa,stage:.grown)).frame(width:145,height:145)
                            VStack(alignment:.leading,spacing:Spacing.s) {
                                Text(item.tier.label).font(Typography.headline).foregroundStyle(item.tier.color)
                                Text(item.name).font(Typography.callout)
                                Text(item.blurb).font(Typography.caption).foregroundStyle(Palette.inkMuted)
                            }
                        }.padding(Spacing.s).background(Palette.surface,in:RoundedRectangle(cornerRadius:Radius.m))
                    }
                }
            }.padding(Spacing.l)
        }.cozyBackground()
    }
}
