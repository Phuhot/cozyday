import Foundation

/// Hình dạng thú cưng. `rawValue` = phần sau "species." trong ID vật phẩm.
enum PetSpecies: String, CaseIterable {
    case cat, bunny, hamster, bear, fox

    var name: String {
        switch self {
        case .cat: return "mèo"
        case .bunny: return "thỏ"
        case .hamster: return "hamster"
        case .bear: return "gấu nhỏ"
        case .fox: return "cáo"
        }
    }
}

/// Màu lông. Mã màu nằm ở lớp giao diện; ở đây chỉ là lựa chọn.
enum FurColor: String, CaseIterable {
    case cream, snow, ginger, smoke, cocoa, peach, midnight, lilac
}

/// Giai đoạn lớn lên theo cấp — chỉ thay đổi dáng vẻ, không có hình phạt.
enum PetStage: Int, CaseIterable, Comparable {
    case little = 1
    case growing = 2
    case grown = 3

    static func < (a: PetStage, b: PetStage) -> Bool { a.rawValue < b.rawValue }

    /// Cấp bắt đầu của giai đoạn.
    var startLevel: Int {
        switch self {
        case .little: return 1
        case .growing: return 4
        case .grown: return 10
        }
    }

    static func forLevel(_ level: Int) -> PetStage {
        if level >= PetStage.grown.startLevel { return .grown }
        if level >= PetStage.growing.startLevel { return .growing }
        return .little
    }

    var label: String {
        switch self {
        case .little: return "Nhóc con"
        case .growing: return "Đang lớn"
        case .grown: return "Trưởng thành"
        }
    }

    var next: PetStage? { PetStage(rawValue: rawValue + 1) }
}

/// Toàn bộ ngoại hình của thú cưng — suy ra từ các món đang dùng (không lưu riêng).
struct PetAppearance: Equatable {
    var species: PetSpecies = .cat
    var fur: FurColor = .cream
    var hat: String?
    var glasses: String?
    var neck: String?
    var outfit: String?
    var stage: PetStage = .growing

    init(species: PetSpecies = .cat, fur: FurColor = .cream, hat: String? = nil, glasses: String? = nil,
         neck: String? = nil, outfit: String? = nil, stage: PetStage = .growing) {
        self.species = species
        self.fur = fur
        self.hat = hat
        self.glasses = glasses
        self.neck = neck
        self.outfit = outfit
        self.stage = stage
    }

    /// `equipped`: vị trí → ID vật phẩm. ID lạ (không có trong danh mục) bị bỏ qua.
    init(equipped: [ItemSlot: String], level: Int) {
        func pick(_ slot: ItemSlot) -> String? {
            guard let id = equipped[slot], let item = Catalog.item(id), item.slot == slot else { return nil }
            return id
        }
        func suffix(_ id: String?) -> String? { id.flatMap { $0.split(separator: ".", maxSplits: 1).last.map(String.init) } }
        self.init(
            species: suffix(pick(.species)).flatMap(PetSpecies.init(rawValue:)) ?? .cat,
            fur: suffix(pick(.fur)).flatMap(FurColor.init(rawValue:)) ?? .cream,
            hat: pick(.hat), glasses: pick(.glasses), neck: pick(.neck), outfit: pick(.outfit),
            stage: PetStage.forLevel(level)
        )
    }

    /// Thử một món (xem trước trong tủ đồ) mà không thay đổi dữ liệu.
    func trying(_ item: CatalogItem) -> PetAppearance {
        var copy = self
        let tail = String(item.id.split(separator: ".", maxSplits: 1).last ?? "")
        switch item.slot {
        case .species: copy.species = PetSpecies(rawValue: tail) ?? copy.species
        case .fur: copy.fur = FurColor(rawValue: tail) ?? copy.fur
        case .hat: copy.hat = item.id
        case .glasses: copy.glasses = item.id
        case .neck: copy.neck = item.id
        case .outfit: copy.outfit = item.id
        default: break
        }
        return copy
    }

    func removing(_ slot: ItemSlot) -> PetAppearance {
        var copy = self
        switch slot {
        case .species: copy.species = .cat
        case .fur: copy.fur = .cream
        case .hat: copy.hat = nil
        case .glasses: copy.glasses = nil
        case .neck: copy.neck = nil
        case .outfit: copy.outfit = nil
        default: break
        }
        return copy
    }

    /// ID món đang dùng ở một vị trí của thú cưng (kể cả lựa chọn mặc định).
    func itemID(in slot: ItemSlot) -> String? {
        switch slot {
        case .species: return "species." + species.rawValue
        case .fur: return "fur." + fur.rawValue
        case .hat: return hat
        case .glasses: return glasses
        case .neck: return neck
        case .outfit: return outfit
        default: return nil
        }
    }
}
