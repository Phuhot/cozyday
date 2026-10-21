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
