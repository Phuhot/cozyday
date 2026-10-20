import Foundation

/// Khu vườn: đồ thêm và biến thể màu.
extension Catalog {
    static let gardenMore: [CatalogItem] = [
        // Bầu trời
        CatalogItem(id: "gardenTheme.rainbow", slot: .gardenTheme, name: "Cầu vồng sau mưa", price: 70, blurb: "Trời vừa tạnh, cầu vồng bắc qua đồi.", requiredLevel: 4),
        CatalogItem(id: "gardenTheme.autumn", slot: .gardenTheme, name: "Mùa thu", price: 80, blurb: "Đồi vàng cam, lá phong bay khắp vườn.", requiredLevel: 5),
        CatalogItem(id: "gardenTheme.aurora", slot: .gardenTheme, name: "Cực quang", price: 140, blurb: "Dải sáng xanh tím uốn lượn trên trời đêm.", requiredLevel: 8),
        .variant(of: "gardenTheme.sunset", "lilac", name: "Chiều hồng", hue: -50, price: 55, blurb: "Trời hồng phấn, cỏ nhuộm nắng cam.", requiredLevel: 5),
        .variant(of: "gardenTheme.night", "teal", name: "Đêm xanh ngọc", hue: -40, price: 85, blurb: "Đêm trong vắt màu xanh ngọc.", requiredLevel: 6),
        .variant(of: "gardenTheme.autumn", "rose", name: "Thu hồng", hue: -30, price: 85, blurb: "Đồi hồng đào, trời trong.", requiredLevel: 6),

        // Cây lớn
        CatalogItem(id: "tree.palm", slot: .tree, name: "Cây dừa", price: 90, blurb: "Ba trái dừa và nắng biển.", requiredLevel: 5),
        CatalogItem(id: "tree.maple", slot: .tree, name: "Cây phong", price: 95, blurb: "Lá đỏ cam rơi thành đống dưới gốc.", requiredLevel: 6),
        CatalogItem(id: "tree.willow", slot: .tree, name: "Cây liễu", price: 110, blurb: "Cành mềm rủ xuống như rèm.", requiredLevel: 7),
        .variant(of: "tree.maple", "gold", name: "Cây phong vàng", hue: 16, price: 95, blurb: "Tán lá vàng như mật ong.", requiredLevel: 6),
        .variant(of: "tree.sakura", "lilac", name: "Cây hoa tím", hue: -40, price: 105, blurb: "Hoa tím phủ kín cành.", requiredLevel: 6),
        .variant(of: "tree.pine", "blue", name: "Thông xanh lam", hue: 40, price: 75, blurb: "Lá kim ngả xanh lam như sương sớm.", requiredLevel: 5),

        // Luống hoa
        CatalogItem(id: "flowerBed.veggie", slot: .flowerBed, name: "Luống rau", price: 50, blurb: "Cà rốt nhú đầu, bắp cải tròn xoe.", requiredLevel: 4),
        CatalogItem(id: "flowerBed.lavender", slot: .flowerBed, name: "Oải hương", price: 60, blurb: "Bông tím thơm, có ong ghé thăm.", requiredLevel: 5),
        CatalogItem(id: "flowerBed.strawberry", slot: .flowerBed, name: "Luống dâu", price: 65, blurb: "Dâu chín đỏ, hái đầy một giỏ.", requiredLevel: 6),
        .variant(of: "flowerBed.mushroom", "blue", name: "Nấm xanh", hue: 200, price: 50, blurb: "Nấm xanh lam mọc sau mưa.", requiredLevel: 5),
        .variant(of: "flowerBed.tulip", "pastel", name: "Tulip phấn", hue: 120, price: 45, blurb: "Tulip xanh, tím và cam nhạt.", requiredLevel: 4),
        .variant(of: "flowerBed.lavender", "pink", name: "Oải hương hồng", hue: 60, price: 65, blurb: "Bông hồng phấn thơm dịu.", requiredLevel: 6),

        // Chỗ ngồi
        CatalogItem(id: "gardenSeat.picnic", slot: .gardenSeat, name: "Khăn dã ngoại", price: 55, blurb: "Giỏ mây, bánh kẹp và nước chanh.", requiredLevel: 4),
        CatalogItem(id: "gardenSeat.parasol", slot: .gardenSeat, name: "Ghế xếp & ô", price: 80, blurb: "Nằm dưới ô sọc nhâm nhi nước chanh.", requiredLevel: 5),
        CatalogItem(id: "gardenSeat.mushroom", slot: .gardenSeat, name: "Bàn ghế nấm", price: 100, blurb: "Tiệc trà trên chiếc nấm khổng lồ.", requiredLevel: 7),
        .variant(of: "gardenSeat.bench", "mint", name: "Ghế băng bạc hà", hue: 110, price: 55, blurb: "Ghế gỗ sơn xanh bạc hà.", requiredLevel: 4),
        .variant(of: "gardenSeat.hammock", "blue", name: "Võng xanh", hue: 180, price: 95, blurb: "Võng sọc xanh mát.", requiredLevel: 6),
        .variant(of: "gardenSeat.picnic", "blue", name: "Khăn ca rô xanh", hue: 200, price: 55, blurb: "Khăn ca rô xanh trắng.", requiredLevel: 4),

        // Hồ nước
        CatalogItem(id: "pond.duck", slot: .pond, name: "Hồ vịt", price: 75, blurb: "Vịt mẹ dẫn hai vịt con bơi.", requiredLevel: 4),
        CatalogItem(id: "pond.bridge", slot: .pond, name: "Hồ có cầu", price: 120, blurb: "Cây cầu cong đỏ bắc qua hồ.", requiredLevel: 7),
        CatalogItem(id: "pond.well", slot: .pond, name: "Giếng ước", price: 85, blurb: "Thả một đồng xu, ước một điều.", requiredLevel: 5),
        .variant(of: "pond.puddle", "pink", name: "Ủng hồng", hue: -60, price: 20, blurb: "Đôi ủng hồng bên vũng nước xanh rêu.", requiredLevel: 4),
        .variant(of: "pond.bridge", "wood", name: "Hồ cầu gỗ", hue: 30, price: 115, blurb: "Cầu gỗ mộc, nước xanh trong.", requiredLevel: 7),
        .variant(of: "pond.well", "blue", name: "Giếng mái xanh", hue: 190, price: 85, blurb: "Mái ngói xanh, nước trong.", requiredLevel: 5),

        // Trang trí
        CatalogItem(id: "gardenDeco.windmill", slot: .gardenDeco, name: "Cối xay gió", price: 75, blurb: "Bốn cánh quay chầm chậm theo gió.", requiredLevel: 5),
        CatalogItem(id: "gardenDeco.gnome", slot: .gardenDeco, name: "Chú lùn giữ vườn", price: 45, blurb: "Mũ đỏ, râu trắng, cầm xẻng nhỏ.", requiredLevel: 4),
        CatalogItem(id: "gardenDeco.scarecrow", slot: .gardenDeco, name: "Bù nhìn", price: 60, blurb: "Cười tươi, chẳng dọa được con quạ nào.", requiredLevel: 5),
        CatalogItem(id: "gardenDeco.beehive", slot: .gardenDeco, name: "Tổ ong", price: 70, blurb: "Tổ rơm thơm mật, ong bay vòng quanh.", requiredLevel: 6),
        .variant(of: "gardenDeco.mailbox", "pink", name: "Hộp thư hồng", hue: 120, price: 35, blurb: "Hộp thư màu hồng phấn.", requiredLevel: 4),
        .variant(of: "gardenDeco.gnome", "green", name: "Chú lùn mũ xanh", hue: 120, price: 45, blurb: "Mũ xanh lá, áo hồng.", requiredLevel: 4)
    ]
}
