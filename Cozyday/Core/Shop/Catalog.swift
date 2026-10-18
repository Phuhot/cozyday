import Foundation

/// Vị trí đặt đồ. Phòng có 5 vị trí cố định (không kéo thả tự do); thú cưng có 6 lớp ngoại hình.
/// `rawValue` được lưu trong dữ liệu và bản sao lưu — không bao giờ đổi.
enum ItemSlot: String, Codable, CaseIterable, Identifiable {
    case wall
    case lamp
    case desk
    case plant
    case seat

    case species
    case fur
    case hat
    case glasses
    case neck
    case outfit

    var id: String { rawValue }

    static let room: [ItemSlot] = [.wall, .lamp, .desk, .plant, .seat]
    static let pet: [ItemSlot] = [.species, .fur, .hat, .glasses, .neck, .outfit]

    var isPet: Bool { ItemSlot.pet.contains(self) }

    var label: String {
        switch self {
        case .wall: return "Đồ treo tường"
        case .lamp: return "Đèn"
        case .desk: return "Bàn"
        case .plant: return "Cây"
        case .seat: return "Ghế / thảm"
        case .species: return "Hình dạng"
        case .fur: return "Màu lông"
        case .hat: return "Mũ"
        case .glasses: return "Kính"
        case .neck: return "Cổ"
        case .outfit: return "Áo"
        }
    }

    /// Vị trí luôn có một lựa chọn (hình dạng, màu lông): không "tháo" được, chỉ đổi về mặc định.
    var hasDefault: Bool { self == .species || self == .fur }
}

struct CatalogItem: Identifiable, Equatable {
    /// ID cố định — không bao giờ đổi giữa các phiên bản (được lưu trong dữ liệu & bản sao lưu).
    let id: String
    let slot: ItemSlot
    let name: String
    let price: Int
    let blurb: String
    /// Cấp của thú cưng cần đạt để mở khóa (cấp = XP / 100 + 1).
    var requiredLevel: Int = 1

    var isFree: Bool { price == 0 }
    /// Lựa chọn mặc định (mèo, lông kem): luôn thuộc về bạn, đang dùng khi vị trí đó trống. Không ghi vào kho.
    var isDefault: Bool { Catalog.defaultIDs.contains(id) }
}

/// Danh mục vật phẩm gốc của Cozyday. Danh mục nằm trong code (ID cố định) nên luôn
/// "seed" idempotent: cập nhật app không reset đồ hay xu của người dùng.
enum Catalog {
    static let defaultIDs: Set<String> = ["species.cat", "fur.cream"]

    static let items: [CatalogItem] = roomItems + petItems

    static let roomItems: [CatalogItem] = [
        CatalogItem(id: "desk.pine", slot: .desk, name: "Bàn gỗ thông", price: 0, blurb: "Mộc mạc, vừa đủ cho một cuốn sổ."),
        CatalogItem(id: "desk.lavender", slot: .desk, name: "Bàn lavender", price: 40, blurb: "Màu tím nhạt dịu mắt."),
        CatalogItem(id: "desk.sage", slot: .desk, name: "Bàn viết xanh sage", price: 70, blurb: "Rộng rãi, có ngăn kéo nhỏ."),

        CatalogItem(id: "seat.rug", slot: .seat, name: "Thảm tròn kem", price: 0, blurb: "Chỗ nằm yêu thích của mèo."),
        CatalogItem(id: "seat.cushion", slot: .seat, name: "Đệm ngồi tím", price: 30, blurb: "Êm như mây."),
        CatalogItem(id: "seat.armchair", slot: .seat, name: "Ghế bành nhỏ", price: 90, blurb: "Hợp để đọc sách buổi tối."),

        CatalogItem(id: "plant.cactus", slot: .plant, name: "Xương rồng mini", price: 0, blurb: "Không cần tưới nhiều."),
        CatalogItem(id: "plant.monstera", slot: .plant, name: "Cây lá xẻ", price: 35, blurb: "Lá to, xanh mát."),
        CatalogItem(id: "plant.tulip", slot: .plant, name: "Chậu tulip", price: 55, blurb: "Ba bông hoa nhỏ."),

        CatalogItem(id: "lamp.candle", slot: .lamp, name: "Nến thơm", price: 20, blurb: "Ánh sáng ấm, mùi vani."),
        CatalogItem(id: "lamp.desk", slot: .lamp, name: "Đèn bàn tròn", price: 45, blurb: "Đủ sáng cho buổi học muộn."),
        CatalogItem(id: "lamp.paper", slot: .lamp, name: "Đèn giấy", price: 75, blurb: "Tròn và mềm như mặt trăng."),

        CatalogItem(id: "wall.clock", slot: .wall, name: "Đồng hồ tròn", price: 25, blurb: "Nhắc nhẹ rằng thời gian vẫn trôi."),
        CatalogItem(id: "wall.poster", slot: .wall, name: "Tranh đồi xanh", price: 35, blurb: "Một buổi sáng yên tĩnh."),
        CatalogItem(id: "wall.shelf", slot: .wall, name: "Kệ sách nhỏ", price: 60, blurb: "Ba cuốn sách và một chậu cây.")
    ]

    static let petItems: [CatalogItem] = [
        CatalogItem(id: "species.cat", slot: .species, name: "Mèo", price: 0, blurb: "Tai nhọn, đuôi cong, thích nằm thảm."),
        CatalogItem(id: "species.bunny", slot: .species, name: "Thỏ", price: 60, blurb: "Tai dài, đuôi bông, nhảy lò cò khi vui.", requiredLevel: 2),
        CatalogItem(id: "species.hamster", slot: .species, name: "Hamster", price: 70, blurb: "Má phúng phính, giấu hạt trong má.", requiredLevel: 3),
        CatalogItem(id: "species.bear", slot: .species, name: "Gấu nhỏ", price: 80, blurb: "Tai tròn, mõm sáng màu, rất thích mật ong.", requiredLevel: 4),
        CatalogItem(id: "species.fox", slot: .species, name: "Cáo", price: 100, blurb: "Đuôi xù chóp trắng, tò mò mọi thứ.", requiredLevel: 6),

        CatalogItem(id: "fur.cream", slot: .fur, name: "Kem sữa", price: 0, blurb: "Màu lông nguyên bản."),
        CatalogItem(id: "fur.snow", slot: .fur, name: "Trắng tuyết", price: 25, blurb: "Trắng mịn như bông."),
        CatalogItem(id: "fur.ginger", slot: .fur, name: "Cam gừng", price: 30, blurb: "Ấm áp như nắng chiều."),
        CatalogItem(id: "fur.smoke", slot: .fur, name: "Xám khói", price: 30, blurb: "Dịu dàng, hơi bí ẩn."),
        CatalogItem(id: "fur.cocoa", slot: .fur, name: "Nâu cacao", price: 35, blurb: "Như một cốc cacao nóng."),
        CatalogItem(id: "fur.peach", slot: .fur, name: "Hồng đào", price: 40, blurb: "Ngọt ngào và vui tươi.", requiredLevel: 2),
        CatalogItem(id: "fur.midnight", slot: .fur, name: "Đen nửa đêm", price: 45, blurb: "Lông đen, mắt vàng như trăng.", requiredLevel: 3),
        CatalogItem(id: "fur.lilac", slot: .fur, name: "Tím lilac", price: 55, blurb: "Hiếm có, như hoa tử đinh hương.", requiredLevel: 5),

        CatalogItem(id: "hat.sprout", slot: .hat, name: "Mầm lá", price: 0, blurb: "Chiếc lá nhỏ mọc trên đầu."),
        CatalogItem(id: "hat.bow", slot: .hat, name: "Nơ hồng", price: 20, blurb: "Nhỏ xinh, cài một bên tai."),
        CatalogItem(id: "hat.party", slot: .hat, name: "Mũ tiệc", price: 25, blurb: "Mỗi ngày đều đáng ăn mừng."),
        CatalogItem(id: "hat.beanie", slot: .hat, name: "Mũ len", price: 30, blurb: "Có quả bông trên chóp."),
        CatalogItem(id: "hat.flower", slot: .hat, name: "Vòng hoa", price: 35, blurb: "Hoa cúc trắng và vàng."),
        CatalogItem(id: "hat.straw", slot: .hat, name: "Mũ cói", price: 40, blurb: "Cho những buổi dã ngoại.", requiredLevel: 2),
        CatalogItem(id: "hat.wizard", slot: .hat, name: "Mũ phù thủy", price: 90, blurb: "Đầy sao, hơi to so với đầu.", requiredLevel: 6),
        CatalogItem(id: "hat.crown", slot: .hat, name: "Vương miện", price: 120, blurb: "Dành cho người chăm chỉ lâu ngày.", requiredLevel: 8),

        CatalogItem(id: "glasses.round", slot: .glasses, name: "Kính tròn", price: 30, blurb: "Trông thật thông thái."),
        CatalogItem(id: "glasses.sun", slot: .glasses, name: "Kính râm", price: 40, blurb: "Ngầu một chút cũng được."),
        CatalogItem(id: "glasses.heart", slot: .glasses, name: "Kính trái tim", price: 45, blurb: "Nhìn đâu cũng thấy dễ thương.", requiredLevel: 3),
        CatalogItem(id: "glasses.monocle", slot: .glasses, name: "Kính một mắt", price: 60, blurb: "Quý ông, quý cô lịch lãm.", requiredLevel: 5),

        CatalogItem(id: "neck.bowtie", slot: .neck, name: "Nơ cổ", price: 20, blurb: "Chỉn chu cho ngày làm việc."),
        CatalogItem(id: "neck.scarf", slot: .neck, name: "Khăn len", price: 25, blurb: "Ấm cổ những ngày se lạnh."),
        CatalogItem(id: "neck.bandana", slot: .neck, name: "Khăn bandana", price: 25, blurb: "Họa tiết chấm bi."),
        CatalogItem(id: "neck.bell", slot: .neck, name: "Vòng chuông", price: 30, blurb: "Leng keng mỗi bước đi."),
        CatalogItem(id: "neck.lei", slot: .neck, name: "Vòng hoa cổ", price: 35, blurb: "Như vừa đi nghỉ biển về.", requiredLevel: 3),

        CatalogItem(id: "outfit.sweater", slot: .outfit, name: "Áo len", price: 50, blurb: "Áo len sọc, mềm và ấm."),
        CatalogItem(id: "outfit.overalls", slot: .outfit, name: "Yếm jean", price: 55, blurb: "Có túi nhỏ đựng bút chì.", requiredLevel: 2),
        CatalogItem(id: "outfit.raincoat", slot: .outfit, name: "Áo mưa vàng", price: 60, blurb: "Sẵn sàng cho ngày mưa.", requiredLevel: 3),
        CatalogItem(id: "outfit.cape", slot: .outfit, name: "Áo choàng", price: 90, blurb: "Áo choàng siêu anh hùng.", requiredLevel: 6)
    ]

    static func item(_ id: String) -> CatalogItem? {
        items.first { $0.id == id }
    }

    static func items(in slot: ItemSlot) -> [CatalogItem] {
        items.filter { $0.slot == slot }
    }

    static func defaultItem(for slot: ItemSlot) -> CatalogItem? {
        items(in: slot).first { $0.isDefault }
    }

    /// Đồ mặc định luôn được coi là đã sở hữu.
    static func isOwned(_ id: String, owned: Set<String>) -> Bool {
        defaultIDs.contains(id) || owned.contains(id)
    }
}

enum PurchaseDecision: Equatable {
    case approved(LedgerEntry)
    case alreadyOwned
    case insufficientCoins(needed: Int, available: Int)
    case levelLocked(required: Int, current: Int)
    case unknownItem

    var message: String? {
        switch self {
        case .approved: return nil
        case .alreadyOwned: return "Bạn đã có món này rồi."
        case .insufficientCoins(let needed, let available): return "Cần \(needed) xu, bạn đang có \(available) xu."
        case .levelLocked(let required, let current): return "Mở khóa ở cấp \(required) (hiện đang cấp \(current))."
        case .unknownItem: return "Không tìm thấy món đồ này."
        }
    }
}

enum PurchasePolicy {
    /// Quyết định mua. Đồ miễn phí vẫn ghi một dòng sổ cái 0 xu để có lịch sử và khóa chống trùng.
    static func decide(itemID: String, owned: Set<String>, ledger: [LedgerEntry], now: Date) -> PurchaseDecision {
        guard let item = Catalog.item(itemID) else { return .unknownItem }
        let key = LedgerKeys.purchase(itemID)
        if Catalog.isOwned(itemID, owned: owned) || ledger.contains(where: { $0.key == key }) {
            return .alreadyOwned
        }
        let wallet = Wallet(entries: ledger)
        guard wallet.level >= item.requiredLevel else {
            return .levelLocked(required: item.requiredLevel, current: wallet.level)
        }
        guard wallet.coins >= item.price else {
            return .insufficientCoins(needed: item.price, available: wallet.coins)
        }
        return .approved(LedgerEntry(
            id: UUID(), key: key, kind: .purchase,
            xp: 0, coins: -item.price,
            createdAt: now, refID: itemID, memo: item.name
        ))
    }
}

struct OwnedItemRecord: Codable, Equatable {
    var itemID: String
    var acquiredAt: Date
    var transactionID: UUID?
}

struct EquippedRecord: Codable, Equatable {
    var slot: ItemSlot
    var itemID: String
}
