import Foundation

/// Trang phục thêm (mũ, kính, cổ, áo, phụ kiện), gồm cả món chỉ có trong gacha.
extension Catalog {
    static let costumeMore: [CatalogItem] = costumeShop + costumeGacha

    /// Bán trong cửa hàng.
    private static let costumeShop: [CatalogItem] = [
        // Mũ
        CatalogItem(id: "hat.bucket", slot: .hat, name: "Mũ tai bèo", price: 30, blurb: "Vành mềm, cài một bông cúc nhỏ."),
        CatalogItem(id: "hat.strawberry", slot: .hat, name: "Mũ dâu tây", price: 35, blurb: "Đỏ mọng, có cả cuống lá."),
        CatalogItem(id: "hat.sailorcap", slot: .hat, name: "Mũ thủy thủ", price: 40, blurb: "Trắng tinh, hợp với áo thủy thủ.", requiredLevel: 2),
        CatalogItem(id: "hat.mushroom", slot: .hat, name: "Mũ nấm đỏ", price: 50, blurb: "Chấm trắng như nấm trong truyện cổ tích.", requiredLevel: 3),
        CatalogItem(id: "hat.sunflower", slot: .hat, name: "Vòng hướng dương", price: 55, blurb: "Năm bông hoa nhỏ quay về phía nắng.", requiredLevel: 3),
        CatalogItem(id: "hat.viking", slot: .hat, name: "Mũ Viking", price: 75, blurb: "Hai chiếc sừng cong, sẵn sàng ra khơi.", requiredLevel: 5),
        CatalogItem(id: "hat.grad", slot: .hat, name: "Mũ tốt nghiệp", price: 110, blurb: "Tua vàng lủng lẳng sau bao ngày ôn bài.", requiredLevel: 7),

        // Áo
        CatalogItem(id: "outfit.catsweater", slot: .outfit, name: "Áo len mặt mèo", price: 50, blurb: "Một chú mèo nhỏ nằm giữa ngực áo."),
        CatalogItem(id: "outfit.duckcoat", slot: .outfit, name: "Áo mưa vịt con", price: 55, blurb: "Xanh da trời, in cả đàn vịt vàng.", requiredLevel: 2),
        CatalogItem(id: "outfit.patches", slot: .outfit, name: "Yếm nhung vá", price: 60, blurb: "Nhung hồng, có miếng vá trái tim.", requiredLevel: 2),
        CatalogItem(id: "outfit.bee", slot: .outfit, name: "Đồ ong mật", price: 65, blurb: "Sọc vàng đen và đôi cánh tí hon.", requiredLevel: 3),
        CatalogItem(id: "outfit.chefcoat", slot: .outfit, name: "Áo đầu bếp", price: 70, blurb: "Hai hàng cúc và chiếc khăn cổ đỏ.", requiredLevel: 4),
        CatalogItem(id: "outfit.dino", slot: .outfit, name: "Đồ khủng long", price: 85, blurb: "Có cả cái đuôi gai ló ra phía sau.", requiredLevel: 5),
        CatalogItem(id: "outfit.knight", slot: .outfit, name: "Giáp hiệp sĩ", price: 120, blurb: "Giáp bạc nhẹ tênh, khiên in trái tim.", requiredLevel: 8),

        // Kính
        CatalogItem(id: "glasses.3d", slot: .glasses, name: "Kính 3D", price: 25, blurb: "Một mắt đỏ, một mắt xanh."),
        CatalogItem(id: "glasses.sleepmask", slot: .glasses, name: "Bịt mắt ngủ", price: 30, blurb: "Kéo lên trán khi chưa buồn ngủ."),
        CatalogItem(id: "glasses.flower", slot: .glasses, name: "Kính bông hoa", price: 40, blurb: "Cánh hoa hồng xếp quanh mắt kính.", requiredLevel: 2),
        CatalogItem(id: "glasses.cateye", slot: .glasses, name: "Kính mắt mèo", price: 50, blurb: "Gọng hồng vểnh lên, đính đá nhỏ.", requiredLevel: 3),
        CatalogItem(id: "glasses.snorkel", slot: .glasses, name: "Mặt nạ lặn", price: 55, blurb: "Có ống thở, xuống hồ ngắm cá.", requiredLevel: 4),
        CatalogItem(id: "glasses.goldwire", slot: .glasses, name: "Kính gọng vàng", price: 75, blurb: "Gọng mảnh, có dây vòng qua cổ.", requiredLevel: 6),

        // Cổ
        CatalogItem(id: "neck.bib", slot: .neck, name: "Yếm ăn", price: 20, blurb: "Ăn bánh thoải mái, không sợ dính áo."),
        CatalogItem(id: "neck.clover", slot: .neck, name: "Dây cỏ bốn lá", price: 25, blurb: "Mang theo một chút may mắn."),
        CatalogItem(id: "neck.stripes", slot: .neck, name: "Khăn sọc dài", price: 35, blurb: "Đuôi khăn có tua, buông xuống một bên.", requiredLevel: 2),
        CatalogItem(id: "neck.whistle", slot: .neck, name: "Còi bạc", price: 40, blurb: "Tuýt một tiếng là tới giờ nghỉ.", requiredLevel: 3),
        CatalogItem(id: "neck.hibiscus", slot: .neck, name: "Vòng hoa dâm bụt", price: 50, blurb: "Hoa đỏ cam rực như mùa hè.", requiredLevel: 4),
        CatalogItem(id: "neck.camera", slot: .neck, name: "Máy ảnh nhỏ", price: 70, blurb: "Chụp lại một ngày bình yên.", requiredLevel: 6),

        // Phụ kiện
        CatalogItem(id: "back.icecream", slot: .back, name: "Kem ốc quế", price: 25, blurb: "Hai viên dâu và bạc hà, thêm quả anh đào."),
        CatalogItem(id: "back.kite", slot: .back, name: "Cánh diều", price: 35, blurb: "Diều bốn màu, đuôi thắt nơ."),
        CatalogItem(id: "back.balloons", slot: .back, name: "Chùm bóng bay", price: 40, blurb: "Ba quả bóng tròn, cầm chặt kẻo bay.", requiredLevel: 2),
        CatalogItem(id: "back.bearpack", slot: .back, name: "Ba lô gấu", price: 50, blurb: "Chú gấu bông ôm chặt sau lưng.", requiredLevel: 2),
        CatalogItem(id: "back.wand", slot: .back, name: "Đũa ngôi sao", price: 60, blurb: "Vẫy một cái là hết mệt.", requiredLevel: 3),
        CatalogItem(id: "back.turtle", slot: .back, name: "Mai rùa", price: 70, blurb: "Đeo như ba lô, đi chậm cũng được.", requiredLevel: 4),
        CatalogItem(id: "back.butterfly", slot: .back, name: "Cánh bướm", price: 85, blurb: "Cánh cam viền tím, chấm trắng.", requiredLevel: 5),
        CatalogItem(id: "back.leafcape", slot: .back, name: "Áo choàng lá", price: 100, blurb: "Kết từ những chiếc lá trong vườn.", requiredLevel: 7)
    ]

    /// Chỉ có trong máy gacha. Món "Bí mật" chỉ hiện bóng đen cho tới khi quay trúng.
    private static let costumeGacha: [CatalogItem] = [
        // Quý: Bộ Mùa xuân
        CatalogItem(id: "hat.sakura", slot: .hat, name: "Vòng anh đào", price: 0,
                    blurb: "Bộ Mùa xuân. Hoa anh đào nở kín một vòng.", rarity: .epic, gachaOnly: true),
        CatalogItem(id: "outfit.sakura", slot: .outfit, name: "Kimono anh đào", price: 0,
                    blurb: "Bộ Mùa xuân. Hồng phấn, thắt đai có dây vàng.", rarity: .epic, gachaOnly: true),
        CatalogItem(id: "back.petalwings", slot: .back, name: "Đôi cánh hoa", price: 0,
                    blurb: "Bộ Mùa xuân. Sáu cánh hoa xòe sau lưng.", rarity: .epic, gachaOnly: true),

        // Quý: Bộ Hải tặc
        CatalogItem(id: "hat.pirate", slot: .hat, name: "Mũ hải tặc", price: 0,
                    blurb: "Bộ Hải tặc. Mũ ba góc viền vàng, cắm lông đỏ.", rarity: .epic, gachaOnly: true),
        CatalogItem(id: "glasses.eyepatch", slot: .glasses, name: "Bịt mắt hải tặc", price: 0,
                    blurb: "Bộ Hải tặc. Một mắt vẫn đủ nhìn ra kho báu.", rarity: .epic, gachaOnly: true),
        CatalogItem(id: "back.parrot", slot: .back, name: "Vẹt đậu vai", price: 0,
                    blurb: "Bộ Hải tặc. Bạn đồng hành lắm lời nhất.", rarity: .epic, gachaOnly: true),

        // Bí mật: Bộ Thiên hà
        CatalogItem(id: "hat.galaxy", slot: .hat, name: "Vương miện thiên hà", price: 0,
                    blurb: "Bộ Thiên hà. Hai hành tinh nhỏ bay vòng quanh.", rarity: .secret, gachaOnly: true),
        CatalogItem(id: "back.starcape", slot: .back, name: "Áo choàng ngân hà", price: 0,
                    blurb: "Bộ Thiên hà. Cổ áo dựng cao, vạt áo đầy sao.", rarity: .secret, gachaOnly: true),
        CatalogItem(id: "neck.moon", slot: .neck, name: "Dây chuyền trăng khuyết", price: 0,
                    blurb: "Bộ Thiên hà. Vầng trăng vàng nhỏ và một ngôi sao.", rarity: .secret, gachaOnly: true),

        // Bí mật: Bộ Rồng mây
        CatalogItem(id: "hat.dragon", slot: .hat, name: "Mũ rồng mây", price: 0,
                    blurb: "Bộ Rồng mây. Sừng vàng, vây tai và bờm hồng.", rarity: .secret, gachaOnly: true),
        CatalogItem(id: "back.dragonwings", slot: .back, name: "Cánh rồng mây", price: 0,
                    blurb: "Bộ Rồng mây. Mép cánh là những cụm mây trắng.", rarity: .secret, gachaOnly: true),
        CatalogItem(id: "neck.dragonpearl", slot: .neck, name: "Ngọc rồng", price: 0,
                    blurb: "Bộ Rồng mây. Viên ngọc sáng giữ trong móng vàng.", rarity: .secret, gachaOnly: true)
    ]
}
