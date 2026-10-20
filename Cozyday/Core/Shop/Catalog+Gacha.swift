import Foundation

/// Đồ riêng của máy gacha "Mây Mây" (không bán ở cửa hàng, không giảm giá). Bộ Mùa xuân, Hải tặc, Thiên hà,
/// Rồng mây và hai loài rồng con, kỳ lân nằm ở Catalog+Costume / Catalog+Species; file này thêm phần còn lại của máy.
///
/// ID đã phát hành là cố định. Đồ đổi màu của máy dùng đuôi "~g_…" để không bao giờ trùng với đồ đổi màu
/// bán ở cửa hàng; đồ vẽ mới dùng tiền tố "<vị trí>.g_…". Giá chỉ để hiển thị và tham khảo, máy không bán theo giá.
extension Catalog {
    static let gachaItems: [CatalogItem] = gachaCommon + gachaRare + gachaEpic + gachaSecret

    /// Thường: đồ quen thuộc trong bảng màu riêng của máy.
    private static let gachaCommon: [CatalogItem] = [
        // Mũ
        .variant(of: "hat.beanie", "g_mint", name: "Mũ len bạc hà", hue: 150, price: 30,
                 blurb: "Len xanh bạc hà, quả bông trắng trên chóp.", gachaOnly: true),
        .variant(of: "hat.bow", "g_sky", name: "Nơ xanh trời", hue: -135, price: 25,
                 blurb: "Nơ lụa xanh nhạt cài lệch một bên.", gachaOnly: true),
        .variant(of: "hat.party", "g_lemon", name: "Mũ tiệc vàng chanh", hue: 150, price: 25,
                 blurb: "Chóp vàng, quả bông xanh lá.", gachaOnly: true),
        .variant(of: "hat.strawberry", "g_blueberry", name: "Mũ việt quất", hue: -120, price: 35,
                 blurb: "Tím xanh như quả việt quất chín.", gachaOnly: true),
        .variant(of: "hat.bucket", "g_peach", name: "Mũ tai bèo hồng đào", hue: -100, price: 30,
                 blurb: "Vành mềm màu hồng đào, cài bông cúc.", gachaOnly: true),

        // Kính
        .variant(of: "glasses.star", "g_mint", name: "Kính sao bạc hà", hue: 110, price: 30,
                 blurb: "Hai ngôi sao xanh mát trên sống mũi.", gachaOnly: true),
        .variant(of: "glasses.cateye", "g_sky", name: "Kính mắt mèo xanh biển", hue: -150, price: 35,
                 blurb: "Gọng xanh biển vểnh lên hai bên.", gachaOnly: true),
        .variant(of: "glasses.flower", "g_sun", name: "Kính hoa cúc vàng", hue: 60, price: 35,
                 blurb: "Cánh hoa vàng nắng xếp quanh mắt kính.", gachaOnly: true),

        // Cổ
        .variant(of: "neck.bowtie", "g_coral", name: "Nơ cổ san hô", hue: 110, price: 20,
                 blurb: "Màu cam hồng, thắt gọn dưới cằm.", gachaOnly: true),
        .variant(of: "neck.bandana", "g_cherry", name: "Khăn bandana đỏ", hue: 145, price: 25,
                 blurb: "Nền đỏ, chấm bi trắng như khăn cao bồi.", gachaOnly: true),
        .variant(of: "neck.scarf", "g_pine", name: "Khăn len xanh thông", hue: 150, price: 25,
                 blurb: "Màu lá thông, hợp ngày se lạnh.", gachaOnly: true),

        // Áo
        .variant(of: "outfit.sweater", "g_rose", name: "Áo len hồng phấn", hue: -145, price: 40,
                 blurb: "Sọc trắng trên nền hồng phấn.", gachaOnly: true),
        .variant(of: "outfit.raincoat", "g_mint", name: "Áo mưa bạc hà", hue: 108, price: 40,
                 blurb: "Xanh bạc hà, cúc tròn màu đen.", gachaOnly: true),
        .variant(of: "outfit.overalls", "g_rose", name: "Yếm jean hồng", hue: 130, price: 40,
                 blurb: "Vải jean nhuộm hồng, cúc vàng.", gachaOnly: true),

        // Phụ kiện
        .variant(of: "back.balloon", "g_sky", name: "Bóng tim xanh", hue: -135, price: 25,
                 blurb: "Bóng bay trái tim màu xanh trời.", gachaOnly: true),
        .variant(of: "back.backpack", "g_pink", name: "Ba lô hồng", hue: 170, price: 35,
                 blurb: "Ba lô nhỏ màu hồng, quai cài vàng.", gachaOnly: true),
        .variant(of: "back.kite", "g_dusk", name: "Diều hoàng hôn", hue: -40, price: 30,
                 blurb: "Bốn ô màu chiều tà, đuôi thắt nơ.", gachaOnly: true),

        // Đồ phòng
        .variant(of: "bathToy.duck", "g_pink", name: "Vịt cao su hồng", hue: -60, price: 15,
                 blurb: "Kêu chít chít, hồng như kẹo dâu.", requiredLevel: 3, gachaOnly: true)
    ]

    /// Hiếm: hình vẽ riêng của máy, hoặc bản đổi màu đã đẹp sẵn của món nhiều chi tiết.
    private static let gachaRare: [CatalogItem] = [
        // Bộ Tiệc trà
        CatalogItem(id: "hat.g_teacup", slot: .hat, name: "Mũ tách trà", price: 60,
                    blurb: "Bộ Tiệc trà. Tách sứ viền hoa, hơi trà còn bay.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "outfit.g_teadress", slot: .outfit, name: "Váy tiệc trà", price: 70,
                    blurb: "Bộ Tiệc trà. Cổ ren trắng, gấu váy in tách trà nhỏ.", rarity: .rare, gachaOnly: true),

        CatalogItem(id: "hat.g_duckling", slot: .hat, name: "Vịt con trên đầu", price: 60,
                    blurb: "Một chú vịt con ngồi yên, không chịu xuống.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "glasses.g_lemon", slot: .glasses, name: "Kính lát chanh", price: 55,
                    blurb: "Hai lát chanh mọng nước làm mắt kính.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "glasses.g_bubble", slot: .glasses, name: "Kính bong bóng", price: 60,
                    blurb: "Mắt kính óng ánh như bong bóng xà phòng.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "neck.g_shell", slot: .neck, name: "Vòng vỏ sò", price: 55,
                    blurb: "Vỏ sò trắng xen hạt ngọc, nhặt từ bãi biển.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "neck.g_cherry", slot: .neck, name: "Dây chuyền quả cherry", price: 50,
                    blurb: "Hai quả cherry đỏ chung một cuống.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "outfit.g_strawberry", slot: .outfit, name: "Áo dâu tây", price: 70,
                    blurb: "Đỏ chấm hạt vàng, cổ áo là đài lá xanh.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "back.g_snail", slot: .back, name: "Vỏ ốc sên", price: 70,
                    blurb: "Vỏ xoắn ốc đeo sau lưng, đi chậm mà chắc.", rarity: .rare, gachaOnly: true),
        CatalogItem(id: "back.g_starlantern", slot: .back, name: "Đèn ông sao", price: 75,
                    blurb: "Đèn giấy năm cánh, tua rua đỏ, rước đêm trung thu.", rarity: .rare, gachaOnly: true),

        .variant(of: "back.butterfly", "g_azure", name: "Cánh bướm xanh biếc", hue: 185, price: 85,
                 blurb: "Cánh xanh ngọc viền xanh đậm, chấm trắng.", rarity: .rare, gachaOnly: true),
        .variant(of: "hat.mushroom", "g_violet", name: "Mũ nấm tím", hue: -90, price: 50,
                 blurb: "Nấm tím chấm trắng, như mọc trong rừng đêm.", rarity: .rare, gachaOnly: true),

        // Đồ phòng
        CatalogItem(id: "lamp.g_jellyfish", slot: .lamp, name: "Đèn sứa", price: 80,
                    blurb: "Chiếc sứa thủy tinh phát sáng, tua dài lơ lửng.", rarity: .rare, gachaOnly: true)
    ]

    /// Quý: món nhiều lớp, có chất liệu (vàng, ngọc, vải xếp nếp) và dáng nhận ra từ xa.
    private static let gachaEpic: [CatalogItem] = [
        CatalogItem(id: "outfit.g_pirate", slot: .outfit, name: "Áo khoác thuyền trưởng", price: 150,
                    blurb: "Bộ Hải tặc. Áo đỏ thẫm, khuy vàng, thắt lưng khóa đầu lâu.", rarity: .epic, gachaOnly: true),
        CatalogItem(id: "nightstand.g_musicbox", slot: .nightstand, name: "Hộp nhạc xoay", price: 150,
                    blurb: "Hộp gỗ viền vàng, chú mèo múa xoay trên đỉnh.", rarity: .epic, gachaOnly: true)
    ]

    /// Bí mật: dáng không trùng món nào, có chất liệu và một chi tiết riêng.
    private static let gachaSecret: [CatalogItem] = [
        CatalogItem(id: "bed.g_moon", slot: .bed, name: "Giường trăng khuyết", price: 300,
                    blurb: "Ngủ trong lòng vầng trăng, có sao treo đung đưa.", rarity: .secret, gachaOnly: true)
    ]
}
