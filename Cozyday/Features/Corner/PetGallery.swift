#if DEBUG
import SwiftUI

/// Chỉ có trong bản Debug: lưới nhiều kiểu thú cưng để CI chụp ảnh và soát hình vẽ.
struct PetGalleryView: View {
    private struct Cell: Identifiable {
        let id = UUID()
        let title: String
        let mood: PetMood
        let look: PetAppearance
    }

    private let cells: [Cell] = [
        Cell(title: "Mèo con", mood: .idle, look: PetAppearance(stage: .little)),
        Cell(title: "Mèo cam", mood: .happy, look: PetAppearance(fur: .ginger, hat: "hat.beanie", neck: "neck.scarf")),
        Cell(title: "Mèo đen", mood: .idle, look: PetAppearance(fur: .midnight, hat: "hat.crown", glasses: "glasses.monocle", stage: .grown)),
        Cell(title: "Thỏ", mood: .idle, look: PetAppearance(species: .bunny, fur: .snow, hat: "hat.bow", neck: "neck.bowtie")),
        Cell(title: "Thỏ hồng", mood: .happy, look: PetAppearance(species: .bunny, fur: .peach, hat: "hat.flower", neck: "neck.lei")),
        Cell(title: "Thỏ tím", mood: .idle, look: PetAppearance(species: .bunny, fur: .lilac, hat: "hat.wizard", outfit: "outfit.cape", stage: .grown)),
        Cell(title: "Hamster", mood: .happy, look: PetAppearance(species: .hamster, hat: "hat.party")),
        Cell(title: "Hamster nâu", mood: .idle, look: PetAppearance(species: .hamster, fur: .cocoa, hat: "hat.straw", outfit: "outfit.overalls")),
        Cell(title: "Hamster xám", mood: .idle, look: PetAppearance(species: .hamster, fur: .smoke, glasses: "glasses.sun", neck: "neck.bandana")),
        Cell(title: "Gấu", mood: .idle, look: PetAppearance(species: .bear, fur: .cocoa, hat: "hat.beanie", outfit: "outfit.sweater")),
        Cell(title: "Gấu xám", mood: .focus, look: PetAppearance(species: .bear, fur: .smoke, glasses: "glasses.round", neck: "neck.bell")),
        Cell(title: "Gấu lớn", mood: .happy, look: PetAppearance(species: .bear, hat: "hat.crown", outfit: "outfit.cape", stage: .grown)),
        Cell(title: "Cáo", mood: .idle, look: PetAppearance(species: .fox, fur: .ginger, hat: "hat.sprout")),
        Cell(title: "Cáo trắng", mood: .happy, look: PetAppearance(species: .fox, fur: .snow, glasses: "glasses.heart", outfit: "outfit.raincoat")),
        Cell(title: "Cáo đêm", mood: .rest, look: PetAppearance(species: .fox, fur: .midnight, hat: "hat.wizard", stage: .grown))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(cells) { cell in
                    VStack(spacing: 2) {
                        PetArt(mood: cell.mood, appearance: cell.look)
                            .frame(width: 104, height: 104)
                        Text(cell.title).font(.caption2).foregroundStyle(Palette.inkMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Palette.roomWall, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(12)
        }
        .cozyBackground()
    }
}
#endif
