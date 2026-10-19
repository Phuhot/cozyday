import Foundation

// Ảnh đại diện "khoe bạn nhỏ": nền + phong cảnh + hiệu ứng + biểu cảm + trang phục.
// Chỉ là lựa chọn hiển thị: không tốn xu, không ảnh hưởng thưởng. Một vài lựa chọn mở theo cấp (giống các phòng).

/// Một lựa chọn trong ảnh đại diện (nền, phong cảnh, hiệu ứng, biểu cảm).
struct AvatarOption: Equatable, Identifiable {
    let id: String
    let name: String
    var requiredLevel: Int = 1

    func isUnlocked(level: Int) -> Bool { level >= requiredLevel }
}

enum AvatarPart: String, CaseIterable, Identifiable {
    case background, scene, effect, mood

    var id: String { rawValue }

    var label: String {
        switch self {
        case .background: return "Nền"
        case .scene: return "Phong cảnh"
        case .effect: return "Hiệu ứng"
        case .mood: return "Biểu cảm"
        }
    }

    var options: [AvatarOption] {
        switch self {
        case .background: return AvatarCatalog.backgrounds
        case .scene: return AvatarCatalog.scenes
        case .effect: return AvatarCatalog.effects
        case .mood: return AvatarCatalog.moods
        }
    }
}

enum AvatarCatalog {
    static let backgrounds: [AvatarOption] = [
        AvatarOption(id: "sky", name: "Trời hồng"),
        AvatarOption(id: "peach", name: "Đào hồng"),
        AvatarOption(id: "lavender", name: "Lavender"),
        AvatarOption(id: "mint", name: "Bạc hà"),
        AvatarOption(id: "lemon", name: "Chanh vàng"),
        AvatarOption(id: "cream", name: "Kem sữa"),
        AvatarOption(id: "night", name: "Đêm tím", requiredLevel: 3),
        AvatarOption(id: "ocean", name: "Biển xanh", requiredLevel: 4),
        AvatarOption(id: "sunset", name: "Hoàng hôn", requiredLevel: 5),
        AvatarOption(id: "galaxy", name: "Thiên hà", requiredLevel: 8)
    ]

    static let scenes: [AvatarOption] = [
        AvatarOption(id: "none", name: "Không có"),
        AvatarOption(id: "cloud", name: "Đệm mây"),
        AvatarOption(id: "meadow", name: "Đồi hoa"),
        AvatarOption(id: "moon", name: "Trăng khuyết", requiredLevel: 3),
        AvatarOption(id: "beach", name: "Bãi biển", requiredLevel: 4),
        AvatarOption(id: "rainbow", name: "Cầu vồng", requiredLevel: 5),
        AvatarOption(id: "snow", name: "Đồi tuyết", requiredLevel: 6),
        AvatarOption(id: "sakura", name: "Anh đào", requiredLevel: 7)
    ]

    static let effects: [AvatarOption] = [
        AvatarOption(id: "none", name: "Không có"),
        AvatarOption(id: "sparkles", name: "Lấp lánh"),
        AvatarOption(id: "hearts", name: "Trái tim"),
        AvatarOption(id: "stars", name: "Sao nhỏ"),
        AvatarOption(id: "bubbles", name: "Bong bóng", requiredLevel: 4),
        AvatarOption(id: "snow", name: "Tuyết rơi", requiredLevel: 6),
        AvatarOption(id: "petals", name: "Cánh hoa", requiredLevel: 7),
        AvatarOption(id: "fireflies", name: "Đom đóm", requiredLevel: 8),
        AvatarOption(id: "confetti", name: "Pháo giấy", requiredLevel: 10)
    ]

    static let moods: [AvatarOption] = [
        AvatarOption(id: "happy", name: "Vui vẻ"),
        AvatarOption(id: "idle", name: "Hiền hòa"),
        AvatarOption(id: "rest", name: "Ngủ say"),
        AvatarOption(id: "focus", name: "Chăm chú")
    ]

    static func option(_ part: AvatarPart, _ id: String) -> AvatarOption? {
        part.options.first { $0.id == id }
    }
}

/// Lựa chọn của người dùng. Lưu ID dạng chuỗi nên đọc được cả bản sao lưu có ID lạ (đời sau):
/// ID không còn hợp lệ / chưa mở khóa → dùng lựa chọn mặc định khi hiển thị, không lỗi.
struct AvatarConfig: Codable, Equatable {
    var background: String
    var scene: String
    var effect: String
    var mood: String
    /// Trang phục riêng cho ảnh (vị trí → ID món; `""` = không dùng). `nil` = mặc theo đồ thú cưng đang dùng.
    var look: [String: String]?
    /// In tên thú cưng + cấp lên ảnh.
    var showName: Bool

    /// Giống icon của app: trời hồng, đệm mây, lấp lánh.
    static let standard = AvatarConfig(background: "sky", scene: "cloud", effect: "sparkles", mood: "happy", look: nil, showName: false)

    static let maxLookEntries = 16

    func id(_ part: AvatarPart) -> String {
        switch part {
        case .background: return background
        case .scene: return scene
        case .effect: return effect
        case .mood: return mood
        }
    }

    mutating func set(_ part: AvatarPart, _ id: String) {
        switch part {
        case .background: background = id
        case .scene: scene = id
        case .effect: effect = id
        case .mood: mood = id
        }
    }

    /// ID thật sự được vẽ ở cấp hiện tại.
    func resolved(_ part: AvatarPart, level: Int) -> String {
        let chosen = id(part)
        if let option = AvatarCatalog.option(part, chosen), option.isUnlocked(level: level) { return chosen }
        return Self.standard.id(part)
    }

    /// Ngoại hình dùng trong ảnh: đồ đang mặc, rồi đè bằng trang phục riêng — chỉ những món đã có
    /// (hoặc mặc định) và đúng vị trí. Giai đoạn lớn luôn theo cấp thật.
    func appearance(equipped: [ItemSlot: String], owned: Set<String>, level: Int) -> PetAppearance {
        guard let look else { return PetAppearance(equipped: equipped, level: level) }
        var map = equipped
        for slot in ItemSlot.pet {
            guard let id = look[slot.rawValue] else { continue }
            if id.isEmpty {
                map[slot] = nil
            } else if let item = Catalog.item(id), item.slot == slot, Catalog.isOwned(id, owned: owned) {
                map[slot] = id
            }
        }
        return PetAppearance(equipped: map, level: level)
    }

    /// Đổi một vị trí trang phục trong ảnh (bắt đầu từ đồ đang mặc nếu chưa có trang phục riêng).
    mutating func setLook(_ slot: ItemSlot, to itemID: String?, current: PetAppearance) {
        var map = look ?? Dictionary(uniqueKeysWithValues: ItemSlot.pet.map { ($0.rawValue, current.itemID(in: $0) ?? "") })
        map[slot.rawValue] = itemID ?? ""
        look = map
    }

    /// Kiểm tra khi đọc từ bản sao lưu: chỉ giới hạn độ dài (ID lạ vẫn được giữ, chỉ không vẽ).
    var isWellFormed: Bool {
        let fields = [background, scene, effect, mood]
        guard fields.allSatisfy({ !$0.isEmpty && $0.count <= 40 }) else { return false }
        guard let look else { return true }
        return look.count <= Self.maxLookEntries && look.allSatisfy { $0.key.count <= 40 && $0.value.count <= 60 }
    }
}
