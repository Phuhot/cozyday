import Foundation

/// Bếp & bàn ăn: đồ thêm và biến thể màu.
extension Catalog {
    static let kitchenMore: [CatalogItem] = [
        // Tường & sàn
        CatalogItem(id: "kitchenTheme.bakery", slot: .kitchenTheme, name: "Tiệm bánh hồng", price: 85, blurb: "Tường sọc hồng, mái hiên viền vỏ sò.", requiredLevel: 4),
        CatalogItem(id: "kitchenTheme.night", slot: .kitchenTheme, name: "Bếp đêm trăng", price: 110, blurb: "Dây đèn vàng ấm, ngoài cửa có trăng.", requiredLevel: 6),
        .variant(of: "kitchenTheme.mint", "lilac", name: "Gạch oải hương", hue: 130, price: 40, blurb: "Gạch men tím nhạt.", requiredLevel: 2),
        .variant(of: "kitchenTheme.gingham", "blue", name: "Ca rô xanh", hue: 205, price: 45, blurb: "Khăn dã ngoại màu biển.", requiredLevel: 3),
        .variant(of: "kitchenTheme.lemon", "peach", name: "Cam đào", hue: -25, price: 55, blurb: "Tường màu đào chín.", requiredLevel: 3),
        .variant(of: "kitchenTheme.bakery", "mint", name: "Tiệm bánh bạc hà", hue: 150, price: 85, blurb: "Sọc xanh mát như kem bạc hà.", requiredLevel: 5),

        // Bếp
        CatalogItem(id: "stove.induction", slot: .stove, name: "Bếp từ nồi canh", price: 80, blurb: "Nồi canh rau củ sôi lăn tăn.", requiredLevel: 3),
        CatalogItem(id: "stove.waffle", slot: .stove, name: "Xe bánh waffle", price: 100, blurb: "Khuôn hình tim, kem và dâu ở trên.", requiredLevel: 5),
        CatalogItem(id: "stove.pizza", slot: .stove, name: "Lò pizza gạch", price: 130, blurb: "Lửa củi và một chiếc pizza đang phồng.", requiredLevel: 6),
        CatalogItem(id: "stove.cat", slot: .stove, name: "Bếp mặt mèo", price: 140, blurb: "Núm xoay làm mắt, chân là đệm thịt.", requiredLevel: 7),
        .variant(of: "stove.basic", "blue", name: "Bếp nồi men xanh", hue: 200, price: 40, blurb: "Nồi men xanh, lửa ga xanh.", requiredLevel: 2),
        .variant(of: "stove.oven", "mint", name: "Lò nướng bạc hà", hue: 140, price: 90, blurb: "Lò mái vòm màu xanh mát.", requiredLevel: 4),

        // Tủ lạnh
        CatalogItem(id: "fridge.icebox", slot: .fridge, name: "Tủ đá gỗ xưa", price: 90, blurb: "Khối đá lạnh nằm trên nóc.", requiredLevel: 4),
        CatalogItem(id: "fridge.double", slot: .fridge, name: "Tủ lạnh hai cánh", price: 120, blurb: "Có vòi nước và tranh bé vẽ.", requiredLevel: 5),
        CatalogItem(id: "fridge.glass", slot: .fridge, name: "Tủ kính trái cây", price: 140, blurb: "Nhìn rõ từng miếng dưa, chùm nho.", requiredLevel: 7),
        CatalogItem(id: "fridge.cat", slot: .fridge, name: "Tủ lạnh mèo ngủ", price: 160, blurb: "Tay nắm là một bàn chân hồng.", requiredLevel: 8),
        .variant(of: "fridge.retro", "lilac", name: "Tủ lạnh retro tím", hue: 100, price: 70, blurb: "Bo tròn màu khoai môn.", requiredLevel: 3),
        .variant(of: "fridge.glass", "mint", name: "Tủ kính bạc hà", hue: -50, price: 140, blurb: "Khung xanh bạc hà, đầy trái cây.", requiredLevel: 7),

        // Bàn ăn
        CatalogItem(id: "dining.stump", slot: .dining, name: "Bàn gốc cây", price: 70, blurb: "Ngồi ghế nấm, ăn giữa rừng.", requiredLevel: 3),
        CatalogItem(id: "dining.bar", slot: .dining, name: "Quầy bar ghế cao", price: 85, blurb: "Hai ghế cao và đèn thả ấm.", requiredLevel: 3),
        CatalogItem(id: "dining.kotatsu", slot: .dining, name: "Bàn sưởi kotatsu", price: 95, blurb: "Chui chân vào chăn là ấm ngay.", requiredLevel: 4),
        CatalogItem(id: "dining.booth", slot: .dining, name: "Ghế quán ăn retro", price: 120, blurb: "Ghế da đỏ, có chai tương cà.", requiredLevel: 6),
        .variant(of: "dining.bar", "mint", name: "Quầy bar bạc hà", hue: 150, price: 85, blurb: "Ghế cao xanh mát, đèn hồng.", requiredLevel: 3),
        .variant(of: "dining.booth", "mint", name: "Ghế quán ăn bạc hà", hue: 150, price: 120, blurb: "Ghế da xanh bạc hà.", requiredLevel: 6),

        // Kệ & tường
        CatalogItem(id: "kitchenWall.herbs", slot: .kitchenWall, name: "Bó rau thơm treo", price: 40, blurb: "Húng quế, tỏi và chuỗi ớt phơi.", requiredLevel: 2),
        CatalogItem(id: "kitchenWall.menu", slot: .kitchenWall, name: "Bảng menu phấn", price: 45, blurb: "Hôm nay có cà phê và bánh ngọt.", requiredLevel: 3),
        CatalogItem(id: "kitchenWall.spice", slot: .kitchenWall, name: "Kệ lọ gia vị", price: 50, blurb: "Ớt bột, nghệ, tiêu và cối giã.", requiredLevel: 3),
        CatalogItem(id: "kitchenWall.cherry", slot: .kitchenWall, name: "Đồng hồ anh đào", price: 55, blurb: "Hai quả anh đào, một quả biết giờ.", requiredLevel: 5),
        CatalogItem(id: "kitchenWall.plates", slot: .kitchenWall, name: "Đĩa sứ treo tường", price: 60, blurb: "Năm chiếc đĩa, mỗi chiếc một kiểu.", requiredLevel: 4),
        .variant(of: "kitchenWall.clock", "orange", name: "Đồng hồ trái cam", hue: -22, price: 30, blurb: "Tích tắc vị ngọt.", requiredLevel: 2),

        // Món ăn
        CatalogItem(id: "treat.banhmi", slot: .treat, name: "Ổ bánh mì", price: 25, blurb: "Vỏ giòn, nhiều đồ chua và ngò.", requiredLevel: 2),
        CatalogItem(id: "treat.pho", slot: .treat, name: "Tô phở", price: 35, blurb: "Thịt bò tái, rau thơm, lát chanh.", requiredLevel: 2),
        CatalogItem(id: "treat.dumpling", slot: .treat, name: "Xửng há cảo", price: 30, blurb: "Ba chiếc há cảo còn nóng hổi.", requiredLevel: 3),
        CatalogItem(id: "treat.boba", slot: .treat, name: "Trà sữa trân châu", price: 30, blurb: "Trân châu đen, nắp in mặt mèo.", requiredLevel: 4),
        CatalogItem(id: "treat.mooncake", slot: .treat, name: "Bánh trung thu", price: 45, blurb: "Nhân trứng muối, kèm đèn ông sao.", requiredLevel: 5),
        .variant(of: "treat.boba", "matcha", name: "Trà sữa matcha", hue: 70, price: 30, blurb: "Trà xanh béo, trân châu dẻo.", requiredLevel: 4),
    ]
}
