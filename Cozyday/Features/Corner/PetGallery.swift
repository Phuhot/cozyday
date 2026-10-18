#if DEBUG
import SwiftUI

/// Chỉ có trong bản Debug: lưới mọi bộ phối sẵn (nhiều loài, giai đoạn, nét mặt) để CI chụp ảnh và soát hình vẽ.
struct PetGalleryView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(Array(PetLooks.all.enumerated()), id: \.offset) { i, look in
                    VStack(spacing: 0) {
                        PetArt(mood: [PetMood.idle, .happy, .idle, .rest][i % 4],
                               appearance: look.appearance(stage: [PetStage.little, .growing, .grown][i % 3]))
                            .frame(width: 70, height: 70)
                        Text(look.name).font(.system(size: 8)).foregroundStyle(Palette.inkMuted).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(8)
        }
        .cozyBackground()
    }
}
#endif
