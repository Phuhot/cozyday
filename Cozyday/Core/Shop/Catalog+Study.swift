import Foundation

/// Phòng học: đồ thêm và biến thể màu.
extension Catalog {
    static let studyMore: [CatalogItem] = [
        // Tường & sàn
        CatalogItem(id: "studyTheme.library", slot: .studyTheme, name: "Thư viện gỗ", price: 85, blurb: "Ốp gỗ chân tường, kệ sách nhỏ cạnh cửa sổ.", requiredLevel: 4),
        CatalogItem(id: "studyTheme.rain", slot: .studyTheme, name: "Ngày mưa", price: 60, blurb: "Mưa rơi ngoài kính, ô vàng treo bên tường.", requiredLevel: 2),
        .variant(of: "studyTheme.cream", "peach", name: "Kem đào", hue: -40, price: 35, blurb: "Tường hồng đào, sàn gỗ ấm.", requiredLevel: 2),
        .variant(of: "studyTheme.mint", "pink", name: "Sọc hồng phấn", hue: 160, price: 45, blurb: "Tường sọc hồng, sàn sơn xanh nhạt.", requiredLevel: 2),
        .variant(of: "studyTheme.night", "plum", name: "Đêm tím mận", hue: 40, price: 75, blurb: "Tường tím thẫm, trăng vàng nhạt.", requiredLevel: 4),
        .variant(of: "studyTheme.library", "lilac", name: "Thư viện tím", hue: -110, price: 90, blurb: "Giấy dán tường hồng nhạt, ốp gỗ sơn tím.", requiredLevel: 5),

        // Đồ treo tường
        CatalogItem(id: "wall.chalkboard", slot: .wall, name: "Bảng phấn", price: 40, blurb: "Điểm A+, mặt mèo và một trái tim.", requiredLevel: 2),
        CatalogItem(id: "wall.photoline", slot: .wall, name: "Dây treo ảnh", price: 55, blurb: "Bốn tấm ảnh kẹp gỗ, xen đèn hạt.", requiredLevel: 3),
        CatalogItem(id: "wall.macrame", slot: .wall, name: "Chậu treo dây thắt", price: 70, blurb: "Trầu bà rủ xuống từ giỏ dây thắt nút.", requiredLevel: 5),
        .variant(of: "wall.clock", "mint", name: "Đồng hồ bạc hà", hue: -110, price: 30, blurb: "Viền xanh bạc hà, kim đen nhỏ."),
        .variant(of: "wall.poster", "autumn", name: "Tranh đồi thu", hue: -80, price: 40, blurb: "Đồi nâu, mặt trời hồng lúc cuối thu.", requiredLevel: 2),
        .variant(of: "wall.chalkboard", "slate", name: "Bảng phấn khung xanh", hue: 60, price: 45, blurb: "Khung sơn xanh lá, mặt bảng xám đá.", requiredLevel: 3),

        // Đèn
        CatalogItem(id: "lamp.globe", slot: .lamp, name: "Đèn địa cầu", price: 80, blurb: "Quả địa cầu sáng dịu, máy bay giấy bay quanh.", requiredLevel: 4),
        CatalogItem(id: "lamp.star", slot: .lamp, name: "Đèn chiếu sao", price: 95, blurb: "Bật lên là trần nhà đầy sao.", requiredLevel: 6),
        CatalogItem(id: "lamp.lava", slot: .lamp, name: "Đèn dung nham", price: 65, blurb: "Giọt sáp hồng trôi chầm chậm.", requiredLevel: 3),
        .variant(of: "lamp.mushroom", "blue", name: "Đèn nấm xanh", hue: 200, price: 60, blurb: "Nấm xanh lam chấm bi trắng.", requiredLevel: 2),
        .variant(of: "lamp.mushroom", "violet", name: "Đèn nấm tím", hue: 260, price: 60, blurb: "Như mọc trong khu rừng phép thuật.", requiredLevel: 3),
        .variant(of: "lamp.lava", "mint", name: "Đèn dung nham bạc hà", hue: -110, price: 70, blurb: "Sáp xanh lam trôi trong nước bạc hà.", requiredLevel: 4),

        // Bàn
        CatalogItem(id: "desk.fishbowl", slot: .desk, name: "Bàn bể cá", price: 85, blurb: "Một chú cá vàng bơi cạnh chồng sách.", requiredLevel: 3),
        CatalogItem(id: "desk.typewriter", slot: .desk, name: "Bàn máy đánh chữ", price: 100, blurb: "Gõ lách cách từng dòng nhật ký.", requiredLevel: 5),
        CatalogItem(id: "desk.ladder", slot: .desk, name: "Kệ thang", price: 75, blurb: "Ba tầng sách, ảnh và giỏ len.", requiredLevel: 2),
        .variant(of: "desk.pine", "mint", name: "Bàn gỗ bạc hà", hue: 100, price: 35, blurb: "Bàn gỗ sơn xanh bạc hà."),
        .variant(of: "desk.pine", "rose", name: "Bàn gỗ hồng", hue: -40, price: 35, blurb: "Bàn gỗ sơn hồng phấn."),
        .variant(of: "desk.ladder", "sky", name: "Kệ thang xanh", hue: 170, price: 80, blurb: "Kệ thang sơn xanh trời.", requiredLevel: 3),

        // Cây
        CatalogItem(id: "plant.sunflower", slot: .plant, name: "Chậu hướng dương", price: 45, blurb: "Bông hoa cười mỗi khi bạn học xong.", requiredLevel: 2),
        CatalogItem(id: "plant.terrarium", slot: .plant, name: "Bình rêu", price: 90, blurb: "Khu rừng tí hon trong chuông kính.", requiredLevel: 6),
        CatalogItem(id: "plant.teacup", slot: .plant, name: "Sen đá trong tách", price: 40, blurb: "Tách trà chấm bi trồng sen đá."),
        .variant(of: "plant.tulip", "blue", name: "Chậu tulip xanh", hue: 220, price: 55, blurb: "Ba bông tulip màu xanh hiếm thấy.", requiredLevel: 2),
        .variant(of: "plant.tulip", "pink", name: "Chậu tulip hồng", hue: 320, price: 55, blurb: "Hoa hồng đậm trong chậu xanh lam."),
        .variant(of: "plant.teacup", "lilac", name: "Sen đá tách tím", hue: -70, price: 45, blurb: "Tách tím chấm bi trắng.", requiredLevel: 2),

        // Ghế / thảm
        CatalogItem(id: "seat.rocker", slot: .seat, name: "Ghế bập bênh", price: 110, blurb: "Đung đưa đọc sách, có chăn len khoác.", requiredLevel: 5),
        CatalogItem(id: "seat.catbean", slot: .seat, name: "Ghế lười mèo", price: 85, blurb: "Ghế lười có tai, đang ngủ say.", requiredLevel: 3),
        CatalogItem(id: "seat.pouf", slot: .seat, name: "Đôn len", price: 50, blurb: "Đôn đan len, để sẵn sổ tay.", requiredLevel: 2),
        .variant(of: "seat.beanbag", "pink", name: "Ghế lười hồng", hue: -50, price: 70, blurb: "Hồng như kẹo dâu."),
        .variant(of: "seat.beanbag", "mint", name: "Ghế lười bạc hà", hue: 100, price: 70, blurb: "Xanh mát cho ngày hè.", requiredLevel: 2),
        .variant(of: "seat.armchair", "sage", name: "Ghế bành xanh rêu", hue: 90, price: 95, blurb: "Bọc vải xanh rêu, nệm kem.", requiredLevel: 3)
    ]
}
