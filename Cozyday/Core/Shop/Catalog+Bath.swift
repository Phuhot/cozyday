import Foundation

/// Phòng tắm: đồ thêm và biến thể màu.
extension Catalog {
    static let bathMore: [CatalogItem] = [
        // Tường & sàn
        CatalogItem(id: "bathTheme.hex", slot: .bathTheme, name: "Gạch tổ ong", price: 60, blurb: "Gạch lục giác vàng, có hai chú ong.", requiredLevel: 4),
        CatalogItem(id: "bathTheme.onsen", slot: .bathTheme, name: "Suối nước nóng", price: 110, blurb: "Vách gỗ, tre xanh, sàn đá cuội.", requiredLevel: 6),

        // Bồn tắm
        CatalogItem(id: "tub.shell", slot: .tub, name: "Bồn vỏ sò", price: 140, blurb: "Tắm trong vỏ sò có ngọc trai.", requiredLevel: 7),
        CatalogItem(id: "tub.duck", slot: .tub, name: "Bồn vịt vàng", price: 120, blurb: "Chú vịt khổng lồ chở đầy bọt.", requiredLevel: 5),
        CatalogItem(id: "tub.pool", slot: .tub, name: "Bể phao", price: 70, blurb: "Ba vòng phao, một quả bóng.", requiredLevel: 3),

        // Bồn rửa
        CatalogItem(id: "sink.vanity", slot: .sink, name: "Tủ rửa gỗ", price: 85, blurb: "Chậu sứ đặt trên tủ hai cánh.", requiredLevel: 4),
        CatalogItem(id: "sink.duck", slot: .sink, name: "Bồn rửa vịt con", price: 55, blurb: "Nước chảy từ mỏ vịt, có ghế bậc.", requiredLevel: 3),
        CatalogItem(id: "sink.cloud", slot: .sink, name: "Gương mây", price: 95, blurb: "Gương hình đám mây, chậu treo tường.", requiredLevel: 5),

        // Kệ
        CatalogItem(id: "bathShelf.candles", slot: .bathShelf, name: "Kệ nến thơm", price: 45, blurb: "Ba ngọn nến và chồng đá spa.", requiredLevel: 4),
        CatalogItem(id: "bathShelf.duckies", slot: .bathShelf, name: "Kệ vịt cao su", price: 35, blurb: "Vịt vua đội vương miện và hai bạn nhỏ.", requiredLevel: 3),
        CatalogItem(id: "bathShelf.macrame", slot: .bathShelf, name: "Chậu treo dây đan", price: 55, blurb: "Trầu bà rủ lá trái tim.", requiredLevel: 5),

        // Thảm
        CatalogItem(id: "bathMat.whale", slot: .bathMat, name: "Thảm cá voi", price: 45, blurb: "Cá voi xanh phun nước.", requiredLevel: 3),
        CatalogItem(id: "bathMat.cloud", slot: .bathMat, name: "Thảm mây", price: 40, blurb: "Mây trắng lim dim ngủ.", requiredLevel: 3),
        CatalogItem(id: "bathMat.pebbles", slot: .bathMat, name: "Thảm đá cuội", price: 50, blurb: "Bước chân mát như bờ suối.", requiredLevel: 5),

        // Đồ chơi
        CatalogItem(id: "bathToy.ducklings", slot: .bathToy, name: "Vịt mẹ vịt con", price: 30, blurb: "Cả nhà vịt bơi thành hàng.", requiredLevel: 3),
        CatalogItem(id: "bathToy.tugboat", slot: .bathToy, name: "Tàu kéo", price: 40, blurb: "Phì phò nhả khói trắng.", requiredLevel: 4),
        CatalogItem(id: "bathToy.sub", slot: .bathToy, name: "Tàu ngầm vàng", price: 55, blurb: "Ba ô cửa tròn nhìn xuống đáy bồn.", requiredLevel: 6),

        // Biến thể màu
        .variant(of: "bathTheme.aqua", "lavender", name: "Gạch oải hương", hue: 60, price: 40, blurb: "Gạch tím nhạt, sàn ca rô tím.", requiredLevel: 3),
        .variant(of: "bathTheme.pink", "sky", name: "Gạch xanh sữa", hue: 240, price: 45, blurb: "Xanh nhạt, điểm tim nhỏ.", requiredLevel: 3),
        .variant(of: "bathTheme.hex", "sky", name: "Tổ ong xanh", hue: 180, price: 65, blurb: "Gạch lục giác xanh trời.", requiredLevel: 5),
        .variant(of: "bathTheme.onsen", "sakura", name: "Suối anh đào", hue: 300, price: 120, blurb: "Vách gỗ hồng, tre đổi sắc.", requiredLevel: 7),
        .variant(of: "tub.bubble", "sky", name: "Bồn bọt xanh", hue: 240, price: 105, blurb: "Bồn xanh, vịt hồng trên bọt.", requiredLevel: 5),
        .variant(of: "tub.shell", "lilac", name: "Bồn vỏ sò tím", hue: 300, price: 150, blurb: "Vỏ sò tím như san hô đêm.", requiredLevel: 8),
        .variant(of: "tub.duck", "sky", name: "Bồn vịt xanh", hue: 180, price: 125, blurb: "Chú vịt xanh da trời.", requiredLevel: 6),
        .variant(of: "sink.shell", "aqua", name: "Gương vỏ sò xanh", hue: 180, price: 80, blurb: "Vỏ sò xanh ngọc.", requiredLevel: 5),
        .variant(of: "sink.vanity", "rose", name: "Tủ rửa hồng", hue: 300, price: 90, blurb: "Tủ hồng, gương viền hồng.", requiredLevel: 5),
        .variant(of: "sink.duck", "rose", name: "Bồn rửa vịt hồng", hue: 240, price: 60, blurb: "Vịt hồng, ghế bậc xanh.", requiredLevel: 4),
        .variant(of: "sink.cloud", "rose", name: "Gương mây hồng", hue: 120, price: 100, blurb: "Mây hồng lúc bình minh.", requiredLevel: 6),
        .variant(of: "bathShelf.towels", "sky", name: "Kệ khăn xanh", hue: 180, price: 30, blurb: "Khăn xanh, ngọc và hồng.", requiredLevel: 3),
        .variant(of: "bathShelf.bottles", "rose", name: "Kệ chai lọ hồng", hue: 180, price: 40, blurb: "Chai hồng, nến xanh.", requiredLevel: 3),
        .variant(of: "bathShelf.candles", "lilac", name: "Kệ nến tím", hue: 240, price: 50, blurb: "Lửa nến tím hồng huyền ảo.", requiredLevel: 5),
        .variant(of: "bathShelf.duckies", "rose", name: "Kệ vịt hồng", hue: 300, price: 40, blurb: "Nữ hoàng vịt hồng và hai bạn.", requiredLevel: 4),
        .variant(of: "bathMat.basic", "rose", name: "Thảm chân hồng", hue: 120, price: 15, blurb: "Bông mềm màu hồng.", requiredLevel: 3),
        .variant(of: "bathMat.wave", "lilac", name: "Thảm sóng tím", hue: 60, price: 45, blurb: "Biển tím lúc hoàng hôn.", requiredLevel: 4),
        .variant(of: "bathMat.whale", "rose", name: "Thảm cá voi hồng", hue: 120, price: 50, blurb: "Cá voi hồng phun nước.", requiredLevel: 4),
        .variant(of: "bathMat.whale", "mint", name: "Thảm cá voi bạc hà", hue: 300, price: 50, blurb: "Cá voi xanh bạc hà.", requiredLevel: 4),
        .variant(of: "bathToy.whale", "rose", name: "Cá voi hồng phun nước", hue: 120, price: 50, blurb: "Tia nước cũng màu hồng.", requiredLevel: 5),
        .variant(of: "bathToy.sub", "coral", name: "Tàu ngầm san hô", hue: 300, price: 60, blurb: "Tàu ngầm hồng, cửa sổ xanh lá.", requiredLevel: 7),
        .variant(of: "bathToy.tugboat", "teal", name: "Tàu kéo xanh ngọc", hue: 180, price: 45, blurb: "Ống khói xanh, khói vẫn trắng.", requiredLevel: 5)
    ]
}
