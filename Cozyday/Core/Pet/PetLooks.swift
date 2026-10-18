import Foundation

/// Một bộ phối đồ có sẵn (hình dạng + màu lông + trang phục) để xem trong Bộ sưu tập
/// và mua/mặc cả bộ bằng một lần chạm.
struct PetLook: Identifiable, Equatable {
    let id: String
    let name: String
    let species: PetSpecies
    let fur: FurColor
    /// Mũ, kính, cổ, áo, phụ kiện (ID vật phẩm).
    let items: [String]

    /// Mọi ID vật phẩm của bộ, kể cả hình dạng và màu lông.
    var itemIDs: [String] { ["species." + species.rawValue, "fur." + fur.rawValue] + items }

    func appearance(stage: PetStage) -> PetAppearance {
        var look = PetAppearance(species: species, fur: fur, stage: stage)
        for id in items {
            if let item = Catalog.item(id) { look = look.trying(item) }
        }
        return look
    }

    /// Cấp cần đạt để mua đủ bộ.
    var requiredLevel: Int { itemIDs.compactMap { Catalog.item($0)?.requiredLevel }.max() ?? 1 }

    /// Các món còn thiếu (đồ mặc định luôn coi như đã có).
    func missing(owned: Set<String>) -> [CatalogItem] {
        itemIDs.compactMap(Catalog.item).filter { !Catalog.isOwned($0.id, owned: owned) }
    }

    func cost(owned: Set<String>) -> Int { missing(owned: owned).reduce(0) { $0 + $1.price } }
}

enum PetLooks {
    static let all: [PetLook] = [
        PetLook(id: "look.kitten", name: "Mèo con", species: .cat, fur: .cream, items: ["hat.sprout"]),
        PetLook(id: "look.ginger", name: "Mèo cam mùa đông", species: .cat, fur: .ginger, items: ["hat.beanie", "neck.scarf"]),
        PetLook(id: "look.noir", name: "Mèo đen quý tộc", species: .cat, fur: .midnight, items: ["hat.crown", "glasses.monocle", "neck.bowtie"]),
        PetLook(id: "look.catstar", name: "Mèo ngôi sao", species: .cat, fur: .snow, items: ["glasses.star", "outfit.tutu", "back.balloon"]),
        PetLook(id: "look.bunny", name: "Thỏ trắng", species: .bunny, fur: .snow, items: ["hat.bow", "neck.bowtie"]),
        PetLook(id: "look.bunnyflower", name: "Thỏ hồng đi biển", species: .bunny, fur: .peach, items: ["hat.flower", "neck.lei"]),
        PetLook(id: "look.bunnywizard", name: "Thỏ phù thủy", species: .bunny, fur: .lilac, items: ["hat.wizard", "outfit.cape"]),
        PetLook(id: "look.bunnyangel", name: "Thỏ thiên thần", species: .bunny, fur: .snow, items: ["hat.halo", "back.wings", "outfit.dress"]),
        PetLook(id: "look.hamparty", name: "Hamster tiệc tùng", species: .hamster, fur: .cream, items: ["hat.party", "back.lollipop"]),
        PetLook(id: "look.hamfarm", name: "Hamster nông trại", species: .hamster, fur: .cocoa, items: ["hat.straw", "outfit.overalls"]),
        PetLook(id: "look.hamcool", name: "Hamster sành điệu", species: .hamster, fur: .smoke, items: ["glasses.sun", "neck.bandana", "hat.cap"]),
        PetLook(id: "look.bear", name: "Gấu len", species: .bear, fur: .cocoa, items: ["hat.beanie", "outfit.sweater"]),
        PetLook(id: "look.bearscholar", name: "Gấu mọt sách", species: .bear, fur: .smoke, items: ["glasses.round", "neck.bell", "back.backpack"]),
        PetLook(id: "look.bearking", name: "Gấu vua", species: .bear, fur: .cream, items: ["hat.crown", "outfit.cape"]),
        PetLook(id: "look.fox", name: "Cáo mầm non", species: .fox, fur: .ginger, items: ["hat.sprout"]),
        PetLook(id: "look.foxrain", name: "Cáo trắng ngày mưa", species: .fox, fur: .snow, items: ["glasses.heart", "outfit.raincoat", "back.umbrella"]),
        PetLook(id: "look.foxnight", name: "Cáo đêm", species: .fox, fur: .midnight, items: ["hat.wizard", "back.bat"]),
        PetLook(id: "look.puppy", name: "Cún học trò", species: .puppy, fur: .cream, items: ["hat.cap", "back.backpack", "neck.collar"]),
        PetLook(id: "look.puppysailor", name: "Cún thủy thủ", species: .puppy, fur: .snow, items: ["outfit.sailor", "glasses.aviator"]),
        PetLook(id: "look.puppycowboy", name: "Cún cao bồi", species: .puppy, fur: .ginger, items: ["hat.cowboy", "neck.bandana"]),
        PetLook(id: "look.duck", name: "Vịt vàng", species: .duck, fur: .honey, items: ["neck.bowtie"]),
        PetLook(id: "look.duckswim", name: "Vịt đi bơi", species: .duck, fur: .snow, items: ["glasses.goggles", "back.balloon"]),
        PetLook(id: "look.duckchef", name: "Vịt đầu bếp", species: .duck, fur: .honey, items: ["hat.chef", "outfit.apron"]),
        PetLook(id: "look.frog", name: "Ếch xanh", species: .frog, fur: .mint, items: ["hat.flower"]),
        PetLook(id: "look.frogprince", name: "Hoàng tử ếch", species: .frog, fur: .mint, items: ["hat.crown", "outfit.cape"]),
        PetLook(id: "look.froglofi", name: "Ếch nghe nhạc", species: .frog, fur: .mint, items: ["hat.headphones", "outfit.hoodie"]),
        PetLook(id: "look.capy", name: "Capybara thư giãn", species: .capybara, fur: .cocoa, items: ["hat.sprout"]),
        PetLook(id: "look.capyonsen", name: "Capybara tắm suối", species: .capybara, fur: .ginger, items: ["outfit.yukata", "back.umbrella"]),
        PetLook(id: "look.capyguitar", name: "Capybara nghệ sĩ", species: .capybara, fur: .cocoa, items: ["hat.beret", "back.guitar"]),
        PetLook(id: "look.panda", name: "Gấu trúc ngủ ngon", species: .panda, fur: .snow, items: ["outfit.pajamas", "hat.cloud"]),
        PetLook(id: "look.pandakungfu", name: "Gấu trúc sành điệu", species: .panda, fur: .snow, items: ["glasses.pixel", "neck.medal"]),
        PetLook(id: "look.penguin", name: "Cánh cụt quý ông", species: .penguin, fur: .midnight, items: ["outfit.tux", "neck.bowtie"]),
        PetLook(id: "look.penguinwinter", name: "Cánh cụt Giáng sinh", species: .penguin, fur: .sky, items: ["hat.santa", "neck.scarf"]),
        PetLook(id: "look.penguinspace", name: "Cánh cụt vũ trụ", species: .penguin, fur: .midnight, items: ["outfit.astronaut"]),
        PetLook(id: "look.reindeer", name: "Tuần lộc nhỏ", species: .bear, fur: .cocoa, items: ["hat.antlers", "neck.bell", "outfit.sweater"]),
        PetLook(id: "look.pumpkin", name: "Mèo bí ngô", species: .cat, fur: .midnight, items: ["hat.pumpkin", "back.bat"]),
        PetLook(id: "look.fairy", name: "Tiên nhỏ", species: .bunny, fur: .mint, items: ["hat.tiara", "back.fairy", "outfit.tutu"]),
        PetLook(id: "look.frogfrog", name: "Ếch đội mũ ếch", species: .frog, fur: .mint, items: ["hat.frog", "neck.ruff"]),
        PetLook(id: "look.catears", name: "Hamster tai mèo", species: .hamster, fur: .peach, items: ["hat.catears", "neck.pearls"]),
        PetLook(id: "look.nerd", name: "Cáo lập trình viên", species: .fox, fur: .smoke, items: ["glasses.nerd", "outfit.hoodie", "neck.tie"])
    ]

    static func look(_ id: String) -> PetLook? { all.first { $0.id == id } }
}

/// Tiến độ sưu tầm đồ thú cưng (không tính đồ mặc định).
struct CollectionProgress: Equatable {
    var ownedPetItems: Int
    var totalPetItems: Int
    var ownedRoomItems: Int
    var totalRoomItems: Int
    var completeLooks: Int
    var totalLooks: Int

    init(owned: Set<String>) {
        let pet = Catalog.petItems.filter { !$0.isDefault }
        let room = Catalog.roomItems.filter { !$0.isDefault }
        ownedPetItems = pet.filter { owned.contains($0.id) }.count
        totalPetItems = pet.count
        ownedRoomItems = room.filter { owned.contains($0.id) }.count
        totalRoomItems = room.count
        completeLooks = PetLooks.all.filter { $0.missing(owned: owned).isEmpty }.count
        totalLooks = PetLooks.all.count
    }
}

extension PetSpecies {
    /// Màu lông "tự nhiên" để giới thiệu loài trong Bộ sưu tập.
    var naturalFur: FurColor {
        switch self {
        case .cat, .hamster: return .cream
        case .bunny, .panda: return .snow
        case .bear, .capybara: return .cocoa
        case .fox: return .ginger
        case .puppy: return .honey
        case .duck: return .honey
        case .frog: return .mint
        case .penguin: return .midnight
        }
    }

    /// Bộ "chỉ có loài này" (màu lông tự nhiên, không trang phục) — dùng khi xem thử một loài.
    var introLook: PetLook {
        PetLook(id: "species." + rawValue, name: name.prefix(1).uppercased() + name.dropFirst(), species: self, fur: naturalFur, items: [])
    }
}
