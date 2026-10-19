import Foundation

extension AppStore {
    static let avatarKey = "avatar.config"

    static func loadAvatar(from defaults: UserDefaults) -> AvatarConfig {
        guard let data = defaults.data(forKey: avatarKey),
              let config = try? JSONDecoder().decode(AvatarConfig.self, from: data),
              config.isWellFormed else { return .standard }
        return config
    }

    /// Ngoại hình thú cưng trong ảnh đại diện (trang phục riêng chỉ gồm những món đã có).
    var avatarAppearance: PetAppearance {
        avatar.appearance(equipped: equippedMap, owned: ownedIDs, level: wallet.level)
    }

    /// Dòng chữ in trên ảnh khi bật "Hiện tên".
    var avatarCaption: String? {
        avatar.showName ? "\(profile.displayPetName) · Cấp \(wallet.level)" : nil
    }

    func saveAvatar(_ config: AvatarConfig) throws {
        guard config.isWellFormed else { throw StoreError.invalid("Lựa chọn ảnh đại diện không hợp lệ.") }
        let data = try JSONEncoder().encode(config)
        defaults.set(data, forKey: Self.avatarKey)
        avatar = config
    }
}
