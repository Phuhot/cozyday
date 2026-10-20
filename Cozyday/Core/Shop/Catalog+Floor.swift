import Foundation

/// Sàn mua riêng cho từng phòng (vị trí `…Floor`). Vẽ ở FloorArt, chỉ phủ phần sàn (y ≥ 62 trong phòng 125×100).
/// Các phòng dùng chung mẫu sàn (phần sau dấu chấm của ID) nhưng mỗi phòng có ID riêng; vườn có mẫu ngoài trời.
extension Catalog {
    static let floorItems: [CatalogItem] = studyFloors + bedroomFloors + kitchenFloors + bathFloors + gardenFloors

    /// Tên và lời giới thiệu của từng mẫu sàn.
    private static let floorPatterns: [String: (name: String, blurb: String)] = [
        "oak": ("Gỗ sồi mật ong", "Ván gỗ sáng màu, ấm chân."),
        "birch": ("Gỗ bạch dương", "Ván trắng ngà, phòng sáng hẳn lên."),
        "walnut": ("Gỗ óc chó", "Nâu trầm, hợp ánh đèn vàng."),
        "herringbone": ("Ván xương cá", "Ván nhỏ lát chéo thành hình mũi tên."),
        "tatami": ("Chiếu tatami", "Chiếu cói viền xanh, thơm mùi cỏ khô."),
        "dots": ("Thảm chấm bi", "Thảm len tím, chấm trắng li ti."),
        "star": ("Thảm sao đêm", "Sao vàng trên nền xanh dịu."),
        "cloud": ("Thảm trời xanh", "Mây trắng trôi dưới chân."),
        "checker": ("Gạch ca rô hồng", "Ô hồng xen ô kem."),
        "hex": ("Gạch tổ ong", "Gạch lục giác xanh bạc hà."),
        "subway": ("Gạch thẻ bạc hà", "Gạch chữ nhật xếp so le."),
        "terrazzo": ("Đá mài hạt kẹo", "Hạt đá màu rải khắp sàn."),
        "heart": ("Gạch trái tim", "Ô gạch nào cũng có một trái tim."),
        "marble": ("Đá trắng vân hồng", "Mát lạnh và bóng loáng."),
        "grass": ("Cỏ hoa dại", "Cỏ non lấm tấm hoa nhỏ."),
        "clover": ("Đồng cỏ ba lá", "Hoa ba lá trắng nở khắp nơi."),
        "path": ("Lối đá", "Mấy phiến đá dẫn vào vườn."),
        "sand": ("Bãi cát", "Có vỏ sò và một con sao biển."),
        "plaza": ("Sân đá lát", "Đá vuông xen rêu xanh."),
        "deck": ("Sàn gỗ ngoài trời", "Ván gỗ để ngồi hóng gió."),
        "deckWhite": ("Sàn gỗ sơn trắng", "Ván sơn trắng kiểu nhà ven biển.")
    ]

    /// Một mẫu sàn đặt trong phòng `slot`.
    private static func floor(_ slot: ItemSlot, _ pattern: String, _ price: Int, level: Int = 1) -> CatalogItem {
        let info = floorPatterns[pattern] ?? (pattern, "")
        return CatalogItem(id: "\(slot.rawValue).\(pattern)", slot: slot, name: info.name, price: price, blurb: info.blurb,
                           requiredLevel: level)
    }

    /// Biến thể màu của một mẫu sàn (vẽ lại mẫu gốc qua bộ lọc xoay sắc độ).
    private static func floorVariant(_ slot: ItemSlot, _ pattern: String, _ tag: String, name: String, hue: Double, price: Int,
                                     blurb: String, level: Int = 1) -> CatalogItem {
        let base = "\(slot.rawValue).\(pattern)"
        return CatalogItem(id: "\(base)~\(tag)", slot: slot, name: name, price: price, blurb: blurb,
                           requiredLevel: level, variantOf: base, hue: hue)
    }

    static let studyFloors: [CatalogItem] = [
        floor(.studyFloor, "oak", 25),
        floor(.studyFloor, "birch", 35),
        floor(.studyFloor, "dots", 40),
        floor(.studyFloor, "checker", 45),
        floor(.studyFloor, "walnut", 50),
        floor(.studyFloor, "terrazzo", 55, level: 2),
        floor(.studyFloor, "tatami", 60, level: 2),
        floor(.studyFloor, "herringbone", 70, level: 2),
        floor(.studyFloor, "cloud", 65, level: 3),
        floor(.studyFloor, "star", 75, level: 3),
        floorVariant(.studyFloor, "dots", "mint", name: "Thảm chấm bi bạc hà", hue: -120, price: 45, blurb: "Xanh mát cho giờ học dài."),
        floorVariant(.studyFloor, "checker", "mint", name: "Gạch ca rô bạc hà", hue: 150, price: 50, blurb: "Ô xanh xen ô kem.")
    ]

    static let bedroomFloors: [CatalogItem] = [
        floor(.bedroomFloor, "dots", 25),
        floor(.bedroomFloor, "oak", 30),
        floor(.bedroomFloor, "birch", 35),
        floor(.bedroomFloor, "cloud", 55),
        floor(.bedroomFloor, "heart", 60, level: 2),
        floor(.bedroomFloor, "tatami", 60, level: 2),
        floor(.bedroomFloor, "star", 70, level: 3),
        floor(.bedroomFloor, "herringbone", 75, level: 3),
        floor(.bedroomFloor, "marble", 100, level: 5),
        floorVariant(.bedroomFloor, "dots", "rose", name: "Thảm chấm bi hồng", hue: 100, price: 40, blurb: "Hồng phấn, êm chân."),
        floorVariant(.bedroomFloor, "cloud", "pink", name: "Thảm trời hồng", hue: 130, price: 65, blurb: "Mây trôi trên trời bình minh.", level: 3),
        floorVariant(.bedroomFloor, "heart", "lilac", name: "Gạch trái tim tím", hue: -70, price: 70, blurb: "Tim tím trên nền oải hương.", level: 3)
    ]

    static let kitchenFloors: [CatalogItem] = [
        floor(.kitchenFloor, "checker", 30, level: 2),
        floor(.kitchenFloor, "oak", 40, level: 2),
        floor(.kitchenFloor, "subway", 45, level: 2),
        floor(.kitchenFloor, "hex", 50, level: 2),
        floor(.kitchenFloor, "terrazzo", 55, level: 2),
        floor(.kitchenFloor, "walnut", 55, level: 3),
        floor(.kitchenFloor, "heart", 60, level: 3),
        floor(.kitchenFloor, "herringbone", 80, level: 3),
        floor(.kitchenFloor, "marble", 110, level: 5),
        floorVariant(.kitchenFloor, "checker", "mint", name: "Gạch ca rô bạc hà", hue: 150, price: 40, blurb: "Ô xanh xen ô kem.", level: 2),
        floorVariant(.kitchenFloor, "hex", "pink", name: "Gạch tổ ong hồng", hue: -150, price: 55, blurb: "Hồng như sữa dâu.", level: 3)
    ]

    static let bathFloors: [CatalogItem] = [
        floor(.bathFloor, "subway", 30, level: 3),
        floor(.bathFloor, "checker", 35, level: 3),
        floor(.bathFloor, "hex", 40, level: 3),
        floor(.bathFloor, "terrazzo", 60, level: 3),
        floor(.bathFloor, "heart", 65, level: 4),
        floor(.bathFloor, "walnut", 70, level: 4),
        floor(.bathFloor, "cloud", 70, level: 4),
        floor(.bathFloor, "marble", 90, level: 4),
        floorVariant(.bathFloor, "hex", "sea", name: "Gạch tổ ong xanh biển", hue: 50, price: 45, blurb: "Xanh như nước hồ bơi.", level: 3),
        floorVariant(.bathFloor, "hex", "lilac", name: "Gạch tổ ong tím", hue: 110, price: 50, blurb: "Tím nhạt như bọt xà phòng.", level: 4),
        floorVariant(.bathFloor, "subway", "pink", name: "Gạch thẻ hồng", hue: 180, price: 40, blurb: "Hồng phấn xếp so le.", level: 3)
    ]

    static let gardenFloors: [CatalogItem] = [
        floor(.gardenFloor, "grass", 30, level: 4),
        floor(.gardenFloor, "clover", 40, level: 4),
        floor(.gardenFloor, "path", 45, level: 4),
        floor(.gardenFloor, "sand", 55, level: 4),
        floor(.gardenFloor, "plaza", 70, level: 5),
        floor(.gardenFloor, "deck", 90, level: 6),
        floorVariant(.gardenFloor, "grass", "autumn", name: "Cỏ mùa thu", hue: -45, price: 50, blurb: "Cỏ ngả vàng, lá rụng lác đác.", level: 5),
        floorVariant(.gardenFloor, "sand", "pink", name: "Cát hồng", hue: -35, price: 65, blurb: "Bãi cát hồng như lúc hoàng hôn.", level: 5),
        floorVariant(.gardenFloor, "clover", "mint", name: "Cỏ ba lá bạc hà", hue: 30, price: 45, blurb: "Xanh mát sau cơn mưa.", level: 4),
        floor(.gardenFloor, "deckWhite", 100, level: 6)
    ]
}
