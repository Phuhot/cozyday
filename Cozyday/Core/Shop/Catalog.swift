import Foundation

/// Các vị trí cố định trong phòng (slot) — không có kéo thả nội thất tự do.
enum RoomSlot: String, Codable, CaseIterable, Identifiable {
    case wall
    case lamp
    case desk
    case plant
    case seat

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wall: return "Đồ treo tường"
        case .lamp: return "Đèn"
        case .desk: return "Bàn"
        case .plant: return "Cây"
        case .seat: return "Ghế / thảm"
        }
    }
}

struct CatalogItem: Identifiable, Equatable {
    /// ID cố định — không bao giờ đổi giữa các phiên bản (được lưu trong dữ liệu & bản sao lưu).
    let id: String
    let slot: RoomSlot
    let name: String
    let price: Int
    let blurb: String

    var isFree: Bool { price == 0 }
}

/// Danh mục vật phẩm gốc của Cozyday. Danh mục nằm trong code (ID cố định) nên luôn
/// "seed" idempotent: cập nhật app không reset đồ hay xu của người dùng.
enum Catalog {
    static let items: [CatalogItem] = [
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

    static func item(_ id: String) -> CatalogItem? {
        items.first { $0.id == id }
    }

    static func items(in slot: RoomSlot) -> [CatalogItem] {
        items.filter { $0.slot == slot }
    }
}

enum PurchaseDecision: Equatable {
    case approved(LedgerEntry)
    case alreadyOwned
    case insufficientCoins(needed: Int, available: Int)
    case unknownItem

    var message: String? {
        switch self {
        case .approved: return nil
        case .alreadyOwned: return "Bạn đã có món này rồi."
        case .insufficientCoins(let needed, let available): return "Cần \(needed) xu, bạn đang có \(available) xu."
        case .unknownItem: return "Không tìm thấy món đồ này."
        }
    }
}

enum PurchasePolicy {
    /// Quyết định mua. Đồ miễn phí vẫn ghi một dòng sổ cái 0 xu để có lịch sử và khóa chống trùng.
    static func decide(itemID: String, owned: Set<String>, ledger: [LedgerEntry], now: Date) -> PurchaseDecision {
        guard let item = Catalog.item(itemID) else { return .unknownItem }
        let key = LedgerKeys.purchase(itemID)
        if owned.contains(itemID) || ledger.contains(where: { $0.key == key }) {
            return .alreadyOwned
        }
        let wallet = Wallet(entries: ledger)
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
    var slot: RoomSlot
    var itemID: String
}
