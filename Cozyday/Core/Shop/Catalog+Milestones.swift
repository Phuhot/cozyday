import Foundation

extension Catalog {
    static let milestoneItems: [CatalogItem] = [
        .variant(of: "wall.poster", "dawn", name: "Tranh bình minh", hue: 22, price: 150,
                 blurb: "Một bình minh mới, dành cho chặng đường cấp 15.", requiredLevel: 15),
        .variant(of: "lamp.paper", "moonlight", name: "Đèn giấy ánh trăng", hue: 180, price: 200,
                 blurb: "Ánh xanh dịu để đọc sách sau một ngày dài. Mở ở cấp 21.", requiredLevel: 21),
        .variant(of: "wall.shelf", "jubilee", name: "Kệ sách mừng trưởng thành", hue: -35, price: 250,
                 blurb: "Góc sách màu chiều tà cho cột mốc cấp 30.", requiredLevel: 30)
    ]
}
