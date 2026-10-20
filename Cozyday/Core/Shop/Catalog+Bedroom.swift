import Foundation

/// Phòng ngủ: đồ thêm và biến thể màu.
extension Catalog {
    static let bedroomMore: [CatalogItem] = [
        // Tường & sàn
        CatalogItem(id: "bedroomTheme.forest", slot: .bedroomTheme, name: "Rừng thông nhỏ", price: 60, blurb: "Hàng thông xanh và nấm đỏ trên tường.", requiredLevel: 2),
        CatalogItem(id: "bedroomTheme.attic", slot: .bedroomTheme, name: "Gác mái gỗ", price: 90, blurb: "Mái dốc, cửa sổ tròn, đèn bóng nhỏ.", requiredLevel: 4),

        // Giường
        CatalogItem(id: "bed.bunk", slot: .bed, name: "Giường tầng", price: 110, blurb: "Leo thang lên tầng trên ngắm sao.", requiredLevel: 3),
        CatalogItem(id: "bed.cat", slot: .bed, name: "Giường mèo", price: 130, blurb: "Đầu giường là chú mèo đang ngủ gật.", requiredLevel: 5),
        CatalogItem(id: "bed.hammock", slot: .bed, name: "Giường võng", price: 95, blurb: "Đung đưa ru mình ngủ.", requiredLevel: 4),

        // Đầu giường
        CatalogItem(id: "nightstand.books", slot: .nightstand, name: "Chồng sách", price: 35, blurb: "Năm cuốn sách và cốc ca cao ấm."),
        CatalogItem(id: "nightstand.lantern", slot: .nightstand, name: "Đèn lồng giấy", price: 60, blurb: "Ánh cam dịu trên chiếc ghế đẩu.", requiredLevel: 2),
        CatalogItem(id: "nightstand.clock", slot: .nightstand, name: "Đồng hồ báo thức", price: 50, blurb: "Hai quả chuông gọi bạn dậy đúng giờ.", requiredLevel: 2),

        // Trang trí tường
        CatalogItem(id: "bedroomWall.mobile", slot: .bedroomWall, name: "Treo trăng sao", price: 55, blurb: "Trăng, sao và mây khẽ xoay.", requiredLevel: 2),
        CatalogItem(id: "bedroomWall.photos", slot: .bedroomWall, name: "Dây ảnh kỷ niệm", price: 40, blurb: "Bốn tấm ảnh kẹp kẹp gỗ."),
        CatalogItem(id: "bedroomWall.hoops", slot: .bedroomWall, name: "Khung thêu", price: 60, blurb: "Hoa, trái tim và cây nấm thêu tay.", requiredLevel: 3),

        // Tủ
        CatalogItem(id: "closet.bunny", slot: .closet, name: "Tủ thỏ", price: 120, blurb: "Đôi tai dài, cửa dán cà rốt.", requiredLevel: 5),
        CatalogItem(id: "closet.bookcase", slot: .closet, name: "Kệ sách cao", price: 90, blurb: "Sách, quả địa cầu và hai giỏ mây.", requiredLevel: 3),
        CatalogItem(id: "closet.rack", slot: .closet, name: "Giá treo đồ", price: 70, blurb: "Váy chấm bi, áo len, áo mưa vàng.", requiredLevel: 2),

        // Thảm
        CatalogItem(id: "bedroomRug.star", slot: .bedroomRug, name: "Thảm ngôi sao", price: 50, blurb: "Ngôi sao vàng đang ngủ say.", requiredLevel: 2),
        CatalogItem(id: "bedroomRug.fluffy", slot: .bedroomRug, name: "Thảm lông xù", price: 40, blurb: "Bước lên êm như bông."),
        CatalogItem(id: "bedroomRug.cat", slot: .bedroomRug, name: "Thảm mặt mèo", price: 60, blurb: "Chú mèo cam lim dim dưới chân.", requiredLevel: 3),

        // Đồ chơi
        CatalogItem(id: "plush.whale", slot: .plush, name: "Cá voi bông", price: 45, blurb: "Phun ra một trái tim nước.", requiredLevel: 2),
        CatalogItem(id: "plush.octopus", slot: .plush, name: "Bạch tuộc bông", price: 50, blurb: "Tám xúc tu, à không, năm thôi.", requiredLevel: 3),
        CatalogItem(id: "plush.egg", slot: .plush, name: "Trứng khủng long", price: 80, blurb: "Vừa nở, vỏ còn đội trên đầu.", requiredLevel: 6),

        // Biến thể màu
        .variant(of: "bedroomTheme.candy", "mint", name: "Sọc kẹo bạc hà", hue: 180, price: 55, blurb: "Sọc xanh mát, sàn xanh nhạt.", requiredLevel: 2),
        .variant(of: "bedroomTheme.lilac", "sky", name: "Xanh sữa", hue: 300, price: 35, blurb: "Tường xanh nhạt, sàn hồng phấn."),
        .variant(of: "bedroomTheme.forest", "sakura", name: "Rừng thông hồng", hue: 300, price: 70, blurb: "Thông hồng như kẹo bông.", requiredLevel: 3),
        .variant(of: "bedroomTheme.attic", "sea", name: "Gác mái xanh biển", hue: 180, price: 100, blurb: "Ván gỗ sơn xanh, mát như biển.", requiredLevel: 6),
        .variant(of: "bed.cat", "rose", name: "Giường mèo hồng", hue: 300, price: 140, blurb: "Mèo hồng ôm chăn xanh.", requiredLevel: 6),
        .variant(of: "bed.bunk", "rose", name: "Giường tầng hồng", hue: 300, price: 120, blurb: "Khung hồng, chăn tím và xanh.", requiredLevel: 4),
        .variant(of: "bed.canopy", "mint", name: "Giường rèm bạc hà", hue: 180, price: 130, blurb: "Rèm voan xanh mát.", requiredLevel: 5),
        .variant(of: "nightstand.lantern", "sky", name: "Đèn lồng xanh", hue: 180, price: 65, blurb: "Ánh xanh dịu như trăng.", requiredLevel: 3),
        .variant(of: "nightstand.clock", "teal", name: "Đồng hồ xanh ngọc", hue: 180, price: 55, blurb: "Chuông xanh trên tủ hồng.", requiredLevel: 3),
        .variant(of: "nightstand.lamp", "rose", name: "Tủ & đèn hồng", hue: 300, price: 45, blurb: "Chụp đèn hồng như kẹo."),
        .variant(of: "bedroomWall.mobile", "rose", name: "Treo trăng sao hồng", hue: 300, price: 60, blurb: "Thanh treo hồng, sao tím.", requiredLevel: 3),
        .variant(of: "bedroomWall.hoops", "rose", name: "Khung thêu hồng", hue: 300, price: 65, blurb: "Ba vòng thêu viền hồng.", requiredLevel: 4),
        .variant(of: "bedroomWall.dreamcatcher", "sky", name: "Lưới bắt giấc mơ xanh", hue: 180, price: 70, blurb: "Vòng xanh, lông vũ ngũ sắc.", requiredLevel: 4),
        .variant(of: "closet.bunny", "mint", name: "Tủ thỏ bạc hà", hue: 180, price: 125, blurb: "Thỏ xanh, cà rốt cũng đổi màu.", requiredLevel: 6),
        .variant(of: "closet.wardrobe", "rose", name: "Tủ quần áo hồng", hue: 60, price: 85, blurb: "Hai cánh hồng phấn."),
        .variant(of: "closet.wardrobe", "sky", name: "Tủ quần áo xanh", hue: 300, price: 85, blurb: "Xanh như bầu trời sáng.", requiredLevel: 2),
        .variant(of: "bedroomRug.star", "sky", name: "Thảm sao xanh", hue: 180, price: 55, blurb: "Ngôi sao xanh ngủ ngon.", requiredLevel: 3),
        .variant(of: "bedroomRug.heart", "lilac", name: "Thảm trái tim tím", hue: 300, price: 40, blurb: "Tím nhạt và lông xù."),
        .variant(of: "bedroomRug.fluffy", "rose", name: "Thảm lông xù hồng", hue: 240, price: 45, blurb: "Hồng phấn, êm như bông."),
        .variant(of: "plush.whale", "rose", name: "Cá voi hồng", hue: 120, price: 50, blurb: "Chú cá voi màu kẹo dâu.", requiredLevel: 3),
        .variant(of: "plush.octopus", "sky", name: "Bạch tuộc xanh", hue: 240, price: 55, blurb: "Đeo nơ xanh lá.", requiredLevel: 4),
        .variant(of: "plush.egg", "lilac", name: "Trứng khủng long tím", hue: 120, price: 90, blurb: "Bé khủng long tím vừa chào đời.", requiredLevel: 7)
    ]
}
