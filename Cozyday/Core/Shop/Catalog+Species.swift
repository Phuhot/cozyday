import Foundation

/// Hình dạng (loài) mới với dáng người khác nhau.
extension Catalog {
    static let speciesMore: [CatalogItem] = [
        CatalogItem(id: "species.ghost", slot: .species, name: "Ma bông", price: 120,
                    blurb: "Bay lơ lửng, vạt áo gợn sóng, sợ tối hơn cả bạn.", requiredLevel: 3, rarity: .rare),
        CatalogItem(id: "species.slime", slot: .species, name: "Thạch dẻo", price: 100,
                    blurb: "Mềm rung rinh, bóng loáng, chọc vào là lún.", requiredLevel: 2),
        CatalogItem(id: "species.mushroom", slot: .species, name: "Nấm nhỏ", price: 110,
                    blurb: "Mũ nấm chấm bi to hơn cả người, thích chỗ ẩm mát.", requiredLevel: 4),
        CatalogItem(id: "species.shark", slot: .species, name: "Cá mập con", price: 120,
                    blurb: "Vây lưng dựng đứng, cười không có răng nào.", requiredLevel: 4),
        CatalogItem(id: "species.owl", slot: .species, name: "Cú mèo", price: 110,
                    blurb: "Mắt tròn xoe, thức khuya đọc sách cùng bạn.", requiredLevel: 3),
        CatalogItem(id: "species.dragon", slot: .species, name: "Rồng con", price: 260,
                    blurb: "Sừng nhỏ, cánh bé xíu, hắt xì ra khói ấm.", requiredLevel: 1, rarity: .epic, gachaOnly: true),
        CatalogItem(id: "species.unicorn", slot: .species, name: "Kỳ lân", price: 400,
                    blurb: "Sừng vàng, bờm màu kẹo, bước đi lấp lánh.", requiredLevel: 1, rarity: .secret, gachaOnly: true)
    ]
}
