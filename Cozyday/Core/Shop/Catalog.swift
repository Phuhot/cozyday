import Foundation

/// Vị trí đặt đồ. Mỗi phòng có các vị trí cố định (không kéo thả tự do) cùng một vị trí "giấy dán tường & sàn";
/// thú cưng có 6 lớp ngoại hình. `rawValue` được lưu trong dữ liệu và bản sao lưu — không bao giờ đổi.
enum ItemSlot: String, Codable, CaseIterable, Identifiable {
    // Phòng học (có từ bản đầu)
    case wall
    case lamp
    case desk
    case plant
    case seat
    case studyTheme

    // Phòng ngủ
    case bedroomTheme
    case bed
    case nightstand
    case bedroomWall
    case closet
    case bedroomRug
    case plush

    // Bếp & bàn ăn
    case kitchenTheme
    case stove
    case fridge
    case dining
    case kitchenWall
    case treat

    // Phòng tắm
    case bathTheme
    case tub
    case sink
    case bathShelf
    case bathMat
    case bathToy

    // Khu vườn
    case gardenTheme
    case tree
    case flowerBed
    case gardenSeat
    case pond
    case gardenDeco

    // Thú cưng
    case species
    case fur
    case hat
    case glasses
    case neck
    case outfit
    case back

    var id: String { rawValue }

    /// Mọi vị trí trong các phòng.
    static let room: [ItemSlot] = RoomKind.allCases.flatMap(\.slots)
    static let pet: [ItemSlot] = [.species, .fur, .hat, .glasses, .neck, .outfit, .back]

    var isPet: Bool { ItemSlot.pet.contains(self) }
    var isTheme: Bool { RoomKind.allCases.contains { $0.themeSlot == self } }
    /// Phòng chứa vị trí này (nil với vị trí của thú cưng).
    var roomKind: RoomKind? { RoomKind.allCases.first { $0.slots.contains(self) } }

    var label: String {
        switch self {
        case .wall: return "Đồ treo tường"
        case .lamp: return "Đèn"
        case .desk: return "Bàn"
        case .plant: return "Cây"
        case .seat: return "Ghế / thảm"
        case .studyTheme, .bedroomTheme, .kitchenTheme, .bathTheme: return "Tường & sàn"
        case .gardenTheme: return "Bầu trời"
        case .bed: return "Giường"
        case .nightstand: return "Đầu giường"
        case .bedroomWall: return "Trang trí tường"
        case .closet: return "Tủ"
        case .bedroomRug: return "Thảm"
        case .plush: return "Đồ chơi"
        case .stove: return "Bếp"
        case .fridge: return "Tủ lạnh"
        case .dining: return "Bàn ăn"
        case .kitchenWall: return "Kệ & tường"
        case .treat: return "Món ăn"
        case .tub: return "Bồn tắm"
        case .sink: return "Bồn rửa"
        case .bathShelf: return "Kệ"
        case .bathMat: return "Thảm"
        case .bathToy: return "Đồ chơi"
        case .tree: return "Cây lớn"
        case .flowerBed: return "Luống hoa"
        case .gardenSeat: return "Chỗ ngồi"
        case .pond: return "Hồ nước"
        case .gardenDeco: return "Trang trí"
        case .species: return "Hình dạng"
        case .fur: return "Màu lông"
        case .hat: return "Mũ"
        case .glasses: return "Kính"
        case .neck: return "Cổ"
        case .outfit: return "Áo"
        case .back: return "Phụ kiện"
        }
    }

    /// Vị trí luôn có một lựa chọn (hình dạng, màu lông, tường & sàn): không "tháo" được, chỉ đổi về mặc định.
    var hasDefault: Bool { self == .species || self == .fur || isTheme }
}

/// Các không gian của Góc nhỏ. Phòng mở theo cấp (không tốn xu); đồ trong phòng mua bằng xu.
enum RoomKind: String, CaseIterable, Identifiable {
    case study
    case bedroom
    case kitchen
    case bath
    case garden

    var id: String { rawValue }

    var name: String {
        switch self {
        case .study: return "Phòng học"
        case .bedroom: return "Phòng ngủ"
        case .kitchen: return "Bếp & bàn ăn"
        case .bath: return "Phòng tắm"
        case .garden: return "Khu vườn"
        }
    }

    var symbol: String {
        switch self {
        case .study: return "books.vertical"
        case .bedroom: return "bed.double"
        case .kitchen: return "fork.knife"
        case .bath: return "bathtub"
        case .garden: return "tree"
        }
    }

    var requiredLevel: Int {
        switch self {
        case .study, .bedroom: return 1
        case .kitchen: return 2
        case .bath: return 3
        case .garden: return 4
        }
    }

    var themeSlot: ItemSlot {
        switch self {
        case .study: return .studyTheme
        case .bedroom: return .bedroomTheme
        case .kitchen: return .kitchenTheme
        case .bath: return .bathTheme
        case .garden: return .gardenTheme
        }
    }

    /// Vị trí trong phòng, vị trí tường & sàn đứng đầu.
    var slots: [ItemSlot] {
        switch self {
        case .study: return [.studyTheme, .wall, .lamp, .desk, .plant, .seat]
        case .bedroom: return [.bedroomTheme, .bed, .nightstand, .bedroomWall, .closet, .bedroomRug, .plush]
        case .kitchen: return [.kitchenTheme, .stove, .fridge, .dining, .kitchenWall, .treat]
        case .bath: return [.bathTheme, .tub, .sink, .bathShelf, .bathMat, .bathToy]
        case .garden: return [.gardenTheme, .tree, .flowerBed, .gardenSeat, .pond, .gardenDeco]
        }
    }

    func isUnlocked(level: Int) -> Bool { level >= requiredLevel }
}

struct CatalogItem: Identifiable, Equatable {
    /// ID cố định — không bao giờ đổi giữa các phiên bản (được lưu trong dữ liệu & bản sao lưu).
    let id: String
    let slot: ItemSlot
    let name: String
    let price: Int
    let blurb: String
    /// Cấp của thú cưng cần đạt để mở khóa (cấp = XP / 100 + 1).
    var requiredLevel: Int = 1

    var isFree: Bool { price == 0 }
    /// Lựa chọn mặc định (mèo, lông kem): luôn thuộc về bạn, đang dùng khi vị trí đó trống. Không ghi vào kho.
    var isDefault: Bool { Catalog.defaultIDs.contains(id) }
}

/// Danh mục vật phẩm gốc của Cozyday. Danh mục nằm trong code (ID cố định) nên luôn
/// "seed" idempotent: cập nhật app không reset đồ hay xu của người dùng.
enum Catalog {
    static let defaultIDs: Set<String> = [
        "species.cat", "fur.cream",
        "studyTheme.cream", "bedroomTheme.lilac", "kitchenTheme.mint", "bathTheme.aqua", "gardenTheme.day"
    ]

    static let items: [CatalogItem] = roomItems + petItems

    static let roomItems: [CatalogItem] = [
        CatalogItem(id: "desk.pine", slot: .desk, name: "Bàn gỗ thông", price: 0, blurb: "Mộc mạc, vừa đủ cho một cuốn sổ."),
        CatalogItem(id: "desk.lavender", slot: .desk, name: "Bàn lavender", price: 40, blurb: "Màu tím nhạt dịu mắt."),
        CatalogItem(id: "desk.sage", slot: .desk, name: "Bàn viết xanh sage", price: 70, blurb: "Rộng rãi, có ngăn kéo nhỏ."),

        CatalogItem(id: "seat.rug", slot: .seat, name: "Thảm tròn kem", price: 0, blurb: "Chỗ nằm yêu thích của mèo."),
        CatalogItem(id: "seat.cushion", slot: .seat, name: "Đệm ngồi tím", price: 30, blurb: "Êm như mây."),
        CatalogItem(id: "seat.armchair", slot: .seat, name: "Ghế bành nhỏ", price: 90, blurb: "Hợp để đọc sách buổi tối."),

        CatalogItem(id: "plant.cactus", slot: .plant, name: "Xương rồng mini", price: 0, blurb: "Không cần tưới nhiều."),
        CatalogItem(id: "plant.monstera", slot: .plant, name: "Cây lá xẻ", price: 35, blurb: "Lá to, xanh mát."),
        CatalogItem(id: "plant.tulip", slot: .plant, name: "Chậu tulip", price: 55, blurb: "Ba bông hoa nhỏ."),

        CatalogItem(id: "lamp.candle", slot: .lamp, name: "Nến thơm", price: 20, blurb: "Ánh sáng ấm, mùi vani."),
        CatalogItem(id: "lamp.desk", slot: .lamp, name: "Đèn bàn tròn", price: 45, blurb: "Đủ sáng cho buổi học muộn."),
        CatalogItem(id: "lamp.paper", slot: .lamp, name: "Đèn giấy", price: 75, blurb: "Tròn và mềm như mặt trăng."),

        CatalogItem(id: "wall.clock", slot: .wall, name: "Đồng hồ tròn", price: 25, blurb: "Nhắc nhẹ rằng thời gian vẫn trôi."),
        CatalogItem(id: "wall.poster", slot: .wall, name: "Tranh đồi xanh", price: 35, blurb: "Một buổi sáng yên tĩnh."),
        CatalogItem(id: "wall.shelf", slot: .wall, name: "Kệ sách nhỏ", price: 60, blurb: "Ba cuốn sách và một chậu cây."),

        // Phòng học — thêm
        CatalogItem(id: "wall.corkboard", slot: .wall, name: "Bảng ghim ảnh", price: 45, blurb: "Ảnh kỷ niệm và vài tờ giấy nhớ."),
        CatalogItem(id: "lamp.mushroom", slot: .lamp, name: "Đèn nấm", price: 55, blurb: "Chiếc nấm đỏ chấm bi tỏa sáng."),
        CatalogItem(id: "desk.computer", slot: .desk, name: "Bàn có máy tính", price: 110, blurb: "Màn hình nhỏ dán đầy sticker.", requiredLevel: 4),
        CatalogItem(id: "plant.bonsai", slot: .plant, name: "Cây bonsai", price: 80, blurb: "Kiên nhẫn từng chút một.", requiredLevel: 3),
        CatalogItem(id: "seat.beanbag", slot: .seat, name: "Ghế lười", price: 65, blurb: "Ngồi xuống là không muốn dậy."),
        CatalogItem(id: "studyTheme.cream", slot: .studyTheme, name: "Kem ấm", price: 0, blurb: "Tường tím nhạt, sàn gỗ sáng."),
        CatalogItem(id: "studyTheme.mint", slot: .studyTheme, name: "Sọc bạc hà", price: 40, blurb: "Tường sọc xanh mát, sàn gỗ."),
        CatalogItem(id: "studyTheme.night", slot: .studyTheme, name: "Đêm sao", price: 70, blurb: "Tường xanh đêm điểm sao, cửa sổ có trăng.", requiredLevel: 3),
        CatalogItem(id: "studyTheme.sakura", slot: .studyTheme, name: "Hoa anh đào", price: 90, blurb: "Cánh hoa hồng bay ngoài cửa sổ.", requiredLevel: 5),

        // Phòng ngủ
        CatalogItem(id: "bedroomTheme.lilac", slot: .bedroomTheme, name: "Tím oải hương", price: 0, blurb: "Dịu nhẹ cho giấc ngủ."),
        CatalogItem(id: "bedroomTheme.cloud", slot: .bedroomTheme, name: "Mây xanh", price: 40, blurb: "Tường xanh trời có mây trắng."),
        CatalogItem(id: "bedroomTheme.candy", slot: .bedroomTheme, name: "Sọc kẹo ngọt", price: 50, blurb: "Sọc hồng trắng như kẹo."),
        CatalogItem(id: "bedroomTheme.galaxy", slot: .bedroomTheme, name: "Thiên hà", price: 100, blurb: "Ngủ giữa những vì sao.", requiredLevel: 5),
        CatalogItem(id: "bed.mat", slot: .bed, name: "Nệm đơn", price: 0, blurb: "Nệm mỏng, gối tròn."),
        CatalogItem(id: "bed.wood", slot: .bed, name: "Giường gỗ", price: 60, blurb: "Chăn kẻ ô ấm áp."),
        CatalogItem(id: "bed.canopy", slot: .bed, name: "Giường rèm", price: 120, blurb: "Rèm voan như trong truyện cổ tích.", requiredLevel: 4),
        CatalogItem(id: "bed.cloud", slot: .bed, name: "Giường đám mây", price: 150, blurb: "Mềm như đang bay.", requiredLevel: 7),
        CatalogItem(id: "nightstand.crate", slot: .nightstand, name: "Thùng gỗ", price: 0, blurb: "Đặt cốc nước và cuốn sách."),
        CatalogItem(id: "nightstand.lamp", slot: .nightstand, name: "Tủ & đèn ngủ", price: 40, blurb: "Chụp đèn vàng dịu."),
        CatalogItem(id: "nightstand.radio", slot: .nightstand, name: "Radio cổ", price: 55, blurb: "Phát nhạc nhẹ trước khi ngủ."),
        CatalogItem(id: "nightstand.moon", slot: .nightstand, name: "Đèn mặt trăng", price: 70, blurb: "Một vầng trăng nhỏ bên gối.", requiredLevel: 3),
        CatalogItem(id: "bedroomWall.garland", slot: .bedroomWall, name: "Dây cờ", price: 25, blurb: "Cờ tam giác nhiều màu."),
        CatalogItem(id: "bedroomWall.fairy", slot: .bedroomWall, name: "Dây đèn đom đóm", price: 45, blurb: "Lấp lánh mỗi tối."),
        CatalogItem(id: "bedroomWall.moon", slot: .bedroomWall, name: "Tranh trăng sao", price: 50, blurb: "Trăng khuyết ngủ trên mây."),
        CatalogItem(id: "bedroomWall.dreamcatcher", slot: .bedroomWall, name: "Lưới bắt giấc mơ", price: 65, blurb: "Giữ lại những giấc mơ đẹp.", requiredLevel: 3),
        CatalogItem(id: "closet.dresser", slot: .closet, name: "Tủ ngăn kéo", price: 50, blurb: "Ba ngăn tay nắm tròn."),
        CatalogItem(id: "closet.mirror", slot: .closet, name: "Gương đứng", price: 60, blurb: "Ngắm bộ đồ mới."),
        CatalogItem(id: "closet.wardrobe", slot: .closet, name: "Tủ quần áo", price: 80, blurb: "Hai cánh, có móc treo khăn."),
        CatalogItem(id: "closet.vanity", slot: .closet, name: "Bàn trang điểm", price: 95, blurb: "Gương tròn viền đèn.", requiredLevel: 4),
        CatalogItem(id: "bedroomRug.round", slot: .bedroomRug, name: "Thảm tròn", price: 0, blurb: "Thảm len mềm."),
        CatalogItem(id: "bedroomRug.heart", slot: .bedroomRug, name: "Thảm trái tim", price: 35, blurb: "Hồng và lông xù."),
        CatalogItem(id: "bedroomRug.cloud", slot: .bedroomRug, name: "Thảm mây", price: 45, blurb: "Bước chân lên mây."),
        CatalogItem(id: "bedroomRug.rainbow", slot: .bedroomRug, name: "Thảm cầu vồng", price: 70, blurb: "Bảy sắc dưới chân.", requiredLevel: 3),
        CatalogItem(id: "plush.yarn", slot: .plush, name: "Cuộn len", price: 15, blurb: "Đồ chơi yêu thích muôn thuở."),
        CatalogItem(id: "plush.ball", slot: .plush, name: "Bóng sọc", price: 20, blurb: "Lăn lông lốc khắp phòng."),
        CatalogItem(id: "plush.teddy", slot: .plush, name: "Gấu bông", price: 40, blurb: "Bạn ngủ cùng mỗi đêm."),
        CatalogItem(id: "plush.dino", slot: .plush, name: "Khủng long bông", price: 60, blurb: "Hung dữ… một chút xíu.", requiredLevel: 3),

        // Bếp & bàn ăn
        CatalogItem(id: "kitchenTheme.mint", slot: .kitchenTheme, name: "Gạch bạc hà", price: 0, blurb: "Gạch men xanh nhạt.", requiredLevel: 2),
        CatalogItem(id: "kitchenTheme.gingham", slot: .kitchenTheme, name: "Ca rô đỏ", price: 45, blurb: "Như một buổi dã ngoại.", requiredLevel: 2),
        CatalogItem(id: "kitchenTheme.lemon", slot: .kitchenTheme, name: "Chanh vàng", price: 55, blurb: "Tường vàng chanh tươi sáng.", requiredLevel: 2),
        CatalogItem(id: "kitchenTheme.wood", slot: .kitchenTheme, name: "Gỗ ấm", price: 75, blurb: "Ốp gỗ kiểu nhà gỗ trên núi.", requiredLevel: 3),
        CatalogItem(id: "stove.basic", slot: .stove, name: "Bếp nhỏ", price: 0, blurb: "Hai bếp và một chiếc nồi.", requiredLevel: 2),
        CatalogItem(id: "stove.retro", slot: .stove, name: "Bếp cổ điển", price: 70, blurb: "Màu kem, núm xoay tròn.", requiredLevel: 2),
        CatalogItem(id: "stove.oven", slot: .stove, name: "Lò nướng bánh", price: 90, blurb: "Mùi bánh quy thơm lừng.", requiredLevel: 4),
        CatalogItem(id: "stove.hearth", slot: .stove, name: "Bếp củi", price: 110, blurb: "Lửa reo tí tách.", requiredLevel: 6),
        CatalogItem(id: "fridge.mini", slot: .fridge, name: "Tủ lạnh mini", price: 30, blurb: "Vừa đủ sữa và trái cây.", requiredLevel: 2),
        CatalogItem(id: "fridge.retro", slot: .fridge, name: "Tủ lạnh retro", price: 70, blurb: "Bo tròn màu xanh ngọc.", requiredLevel: 2),
        CatalogItem(id: "fridge.pink", slot: .fridge, name: "Tủ lạnh hồng", price: 80, blurb: "Màu hồng sữa dâu.", requiredLevel: 3),
        CatalogItem(id: "fridge.magnets", slot: .fridge, name: "Tủ lạnh nam châm", price: 95, blurb: "Dán đầy nam châm và tranh vẽ.", requiredLevel: 4),
        CatalogItem(id: "dining.stool", slot: .dining, name: "Bàn đẩu", price: 0, blurb: "Bàn thấp và một chiếc đẩu.", requiredLevel: 2),
        CatalogItem(id: "dining.round", slot: .dining, name: "Bàn tròn", price: 50, blurb: "Hai ghế tựa nhỏ.", requiredLevel: 2),
        CatalogItem(id: "dining.picnic", slot: .dining, name: "Bàn khăn ca rô", price: 65, blurb: "Khăn trải bàn đỏ trắng.", requiredLevel: 3),
        CatalogItem(id: "dining.long", slot: .dining, name: "Bàn dài có nến", price: 100, blurb: "Cho những bữa tối thật đặc biệt.", requiredLevel: 5),
        CatalogItem(id: "kitchenWall.clock", slot: .kitchenWall, name: "Đồng hồ trái chanh", price: 30, blurb: "Tích tắc vị chua.", requiredLevel: 2),
        CatalogItem(id: "kitchenWall.pans", slot: .kitchenWall, name: "Giá treo nồi", price: 35, blurb: "Chảo, muôi, xẻng đủ cả.", requiredLevel: 2),
        CatalogItem(id: "kitchenWall.fruit", slot: .kitchenWall, name: "Tranh trái cây", price: 40, blurb: "Lê, táo và chùm nho.", requiredLevel: 2),
        CatalogItem(id: "kitchenWall.jars", slot: .kitchenWall, name: "Kệ hũ gia vị", price: 45, blurb: "Hũ kẹo, hũ bánh, hũ trà.", requiredLevel: 3),
        CatalogItem(id: "treat.tea", slot: .treat, name: "Ấm trà", price: 15, blurb: "Trà nóng và một chiếc tách.", requiredLevel: 2),
        CatalogItem(id: "treat.bread", slot: .treat, name: "Giỏ bánh mì", price: 25, blurb: "Bánh mì mới ra lò.", requiredLevel: 2),
        CatalogItem(id: "treat.ramen", slot: .treat, name: "Bát mì", price: 30, blurb: "Có trứng và hành lá.", requiredLevel: 2),
        CatalogItem(id: "treat.pizza", slot: .treat, name: "Pizza", price: 35, blurb: "Một lát đã bị ăn mất.", requiredLevel: 3),
        CatalogItem(id: "treat.cake", slot: .treat, name: "Bánh kem dâu", price: 40, blurb: "Mừng một ngày làm việc tốt.", requiredLevel: 3),

        // Phòng tắm
        CatalogItem(id: "bathTheme.aqua", slot: .bathTheme, name: "Gạch xanh nước", price: 0, blurb: "Mát và sạch sẽ.", requiredLevel: 3),
        CatalogItem(id: "bathTheme.pink", slot: .bathTheme, name: "Gạch hồng", price: 40, blurb: "Hồng phấn dễ thương.", requiredLevel: 3),
        CatalogItem(id: "bathTheme.ocean", slot: .bathTheme, name: "Đại dương", price: 70, blurb: "Sóng và bong bóng trên tường.", requiredLevel: 4),
        CatalogItem(id: "bathTheme.marble", slot: .bathTheme, name: "Đá cẩm thạch", price: 90, blurb: "Sang trọng như spa.", requiredLevel: 5),
        CatalogItem(id: "tub.basin", slot: .tub, name: "Chậu tắm gỗ", price: 0, blurb: "Chậu tròn kiểu suối nước nóng.", requiredLevel: 3),
        CatalogItem(id: "tub.shower", slot: .tub, name: "Vòi sen", price: 60, blurb: "Rèm tắm chấm bi.", requiredLevel: 3),
        CatalogItem(id: "tub.claw", slot: .tub, name: "Bồn tắm chân", price: 80, blurb: "Bồn sứ trắng có chân.", requiredLevel: 3),
        CatalogItem(id: "tub.bubble", slot: .tub, name: "Bồn đầy bọt", price: 100, blurb: "Bọt xà phòng tràn ra ngoài.", requiredLevel: 5),
        CatalogItem(id: "sink.basic", slot: .sink, name: "Bồn rửa", price: 0, blurb: "Bồn rửa tay và cốc bàn chải.", requiredLevel: 3),
        CatalogItem(id: "sink.mirror", slot: .sink, name: "Bồn rửa & gương", price: 45, blurb: "Gương tròn viền gỗ.", requiredLevel: 3),
        CatalogItem(id: "sink.shell", slot: .sink, name: "Gương vỏ sò", price: 75, blurb: "Như nàng tiên cá.", requiredLevel: 4),
        CatalogItem(id: "bathShelf.towels", slot: .bathShelf, name: "Kệ khăn", price: 25, blurb: "Khăn gấp gọn ba màu.", requiredLevel: 3),
        CatalogItem(id: "bathShelf.bottles", slot: .bathShelf, name: "Kệ chai lọ", price: 35, blurb: "Dầu gội, sữa tắm, nến thơm.", requiredLevel: 3),
        CatalogItem(id: "bathShelf.fern", slot: .bathShelf, name: "Kệ dương xỉ", price: 45, blurb: "Cây thích hơi ẩm.", requiredLevel: 4),
        CatalogItem(id: "bathMat.basic", slot: .bathMat, name: "Thảm chân", price: 0, blurb: "Thảm bông hút nước.", requiredLevel: 3),
        CatalogItem(id: "bathMat.duck", slot: .bathMat, name: "Thảm vịt vàng", price: 30, blurb: "Hình chú vịt nhỏ.", requiredLevel: 3),
        CatalogItem(id: "bathMat.wave", slot: .bathMat, name: "Thảm sóng", price: 40, blurb: "Xanh như biển.", requiredLevel: 4),
        CatalogItem(id: "bathToy.duck", slot: .bathToy, name: "Vịt cao su", price: 10, blurb: "Kêu chít chít.", requiredLevel: 3),
        CatalogItem(id: "bathToy.boat", slot: .bathToy, name: "Thuyền giấy", price: 20, blurb: "Ra khơi trong bồn tắm.", requiredLevel: 3),
        CatalogItem(id: "bathToy.bubbles", slot: .bathToy, name: "Bong bóng xà phòng", price: 25, blurb: "Bay lơ lửng khắp phòng.", requiredLevel: 3),
        CatalogItem(id: "bathToy.whale", slot: .bathToy, name: "Cá voi phun nước", price: 45, blurb: "Phun một tia nước nhỏ.", requiredLevel: 4),

        // Khu vườn
        CatalogItem(id: "gardenTheme.day", slot: .gardenTheme, name: "Ngày nắng", price: 0, blurb: "Trời xanh, mây trắng, cỏ non.", requiredLevel: 4),
        CatalogItem(id: "gardenTheme.sunset", slot: .gardenTheme, name: "Hoàng hôn", price: 50, blurb: "Trời cam hồng cuối ngày.", requiredLevel: 4),
        CatalogItem(id: "gardenTheme.night", slot: .gardenTheme, name: "Đêm đom đóm", price: 80, blurb: "Trăng tròn và đom đóm.", requiredLevel: 5),
        CatalogItem(id: "gardenTheme.snow", slot: .gardenTheme, name: "Mùa đông", price: 100, blurb: "Tuyết phủ trắng khu vườn.", requiredLevel: 6),
        CatalogItem(id: "tree.sapling", slot: .tree, name: "Cây non", price: 0, blurb: "Rồi sẽ lớn, như bạn.", requiredLevel: 4),
        CatalogItem(id: "tree.apple", slot: .tree, name: "Cây táo", price: 60, blurb: "Táo đỏ chín mọng.", requiredLevel: 4),
        CatalogItem(id: "tree.pine", slot: .tree, name: "Cây thông", price: 70, blurb: "Xanh quanh năm.", requiredLevel: 5),
        CatalogItem(id: "tree.sakura", slot: .tree, name: "Cây anh đào", price: 100, blurb: "Hoa hồng phủ kín cành.", requiredLevel: 6),
        CatalogItem(id: "flowerBed.daisy", slot: .flowerBed, name: "Hoa cúc", price: 0, blurb: "Cúc trắng nhụy vàng.", requiredLevel: 4),
        CatalogItem(id: "flowerBed.tulip", slot: .flowerBed, name: "Luống tulip", price: 40, blurb: "Đỏ, vàng và hồng.", requiredLevel: 4),
        CatalogItem(id: "flowerBed.mushroom", slot: .flowerBed, name: "Nấm đỏ", price: 45, blurb: "Nấm chấm bi mọc sau mưa.", requiredLevel: 4),
        CatalogItem(id: "flowerBed.sunflower", slot: .flowerBed, name: "Hướng dương", price: 55, blurb: "Luôn quay về phía mặt trời.", requiredLevel: 5),
        CatalogItem(id: "gardenSeat.stump", slot: .gardenSeat, name: "Gốc cây", price: 0, blurb: "Ghế tự nhiên.", requiredLevel: 4),
        CatalogItem(id: "gardenSeat.bench", slot: .gardenSeat, name: "Ghế băng", price: 50, blurb: "Ngồi ngắm mây trôi.", requiredLevel: 4),
        CatalogItem(id: "gardenSeat.swing", slot: .gardenSeat, name: "Xích đu", price: 85, blurb: "Đung đưa nhè nhẹ.", requiredLevel: 5),
        CatalogItem(id: "gardenSeat.hammock", slot: .gardenSeat, name: "Võng", price: 95, blurb: "Ngủ trưa giữa vườn.", requiredLevel: 6),
        CatalogItem(id: "pond.puddle", slot: .pond, name: "Vũng nước", price: 0, blurb: "Để nhảy vào sau cơn mưa.", requiredLevel: 4),
        CatalogItem(id: "pond.lily", slot: .pond, name: "Hồ hoa súng", price: 60, blurb: "Có một chú ếch ngồi chơi.", requiredLevel: 4),
        CatalogItem(id: "pond.koi", slot: .pond, name: "Hồ cá koi", price: 90, blurb: "Hai chú cá đỏ trắng.", requiredLevel: 5),
        CatalogItem(id: "pond.fountain", slot: .pond, name: "Đài phun nước", price: 110, blurb: "Nước reo róc rách.", requiredLevel: 6),
        CatalogItem(id: "gardenDeco.fence", slot: .gardenDeco, name: "Hàng rào gỗ", price: 20, blurb: "Rào trắng nhỏ xinh.", requiredLevel: 4),
        CatalogItem(id: "gardenDeco.mailbox", slot: .gardenDeco, name: "Hộp thư", price: 30, blurb: "Chờ thư từ bạn bè.", requiredLevel: 4),
        CatalogItem(id: "gardenDeco.birdhouse", slot: .gardenDeco, name: "Nhà chim", price: 40, blurb: "Có chú chim vàng ghé thăm.", requiredLevel: 4),
        CatalogItem(id: "gardenDeco.lantern", slot: .gardenDeco, name: "Đèn lồng giấy", price: 50, blurb: "Sáng dịu khi trời tối.", requiredLevel: 5),
        CatalogItem(id: "gardenDeco.tent", slot: .gardenDeco, name: "Lều cắm trại", price: 120, blurb: "Cắm trại ngay trong vườn.", requiredLevel: 7)
    ]

    static let petItems: [CatalogItem] = [
        CatalogItem(id: "species.cat", slot: .species, name: "Mèo", price: 0, blurb: "Tai nhọn, đuôi cong, thích nằm thảm."),
        CatalogItem(id: "species.bunny", slot: .species, name: "Thỏ", price: 60, blurb: "Tai dài, đuôi bông, nhảy lò cò khi vui.", requiredLevel: 2),
        CatalogItem(id: "species.hamster", slot: .species, name: "Hamster", price: 70, blurb: "Má phúng phính, giấu hạt trong má.", requiredLevel: 3),
        CatalogItem(id: "species.bear", slot: .species, name: "Gấu nhỏ", price: 80, blurb: "Tai tròn, mõm sáng màu, rất thích mật ong.", requiredLevel: 4),
        CatalogItem(id: "species.fox", slot: .species, name: "Cáo", price: 100, blurb: "Đuôi xù chóp trắng, tò mò mọi thứ.", requiredLevel: 6),
        CatalogItem(id: "species.puppy", slot: .species, name: "Cún con", price: 80, blurb: "Tai cụp, đuôi ngoáy tít khi gặp bạn.", requiredLevel: 2),
        CatalogItem(id: "species.duck", slot: .species, name: "Vịt con", price: 60, blurb: "Mỏ cam, lạch bạch theo bạn khắp nhà.", requiredLevel: 2),
        CatalogItem(id: "species.frog", slot: .species, name: "Ếch xanh", price: 70, blurb: "Ộp ộp, thích ngồi trên lá súng.", requiredLevel: 3),
        CatalogItem(id: "species.capybara", slot: .species, name: "Capybara", price: 90, blurb: "Bình thản trước mọi chuyện, mê tắm suối nước nóng.", requiredLevel: 3),
        CatalogItem(id: "species.panda", slot: .species, name: "Gấu trúc", price: 110, blurb: "Mắt quầng tròn, mê măng tre.", requiredLevel: 5),
        CatalogItem(id: "species.penguin", slot: .species, name: "Chim cánh cụt", price: 100, blurb: "Bụng tròn, đi lạch bạch.", requiredLevel: 5),

        CatalogItem(id: "fur.cream", slot: .fur, name: "Kem sữa", price: 0, blurb: "Màu lông nguyên bản."),
        CatalogItem(id: "fur.snow", slot: .fur, name: "Trắng tuyết", price: 25, blurb: "Trắng mịn như bông."),
        CatalogItem(id: "fur.ginger", slot: .fur, name: "Cam gừng", price: 30, blurb: "Ấm áp như nắng chiều."),
        CatalogItem(id: "fur.smoke", slot: .fur, name: "Xám khói", price: 30, blurb: "Dịu dàng, hơi bí ẩn."),
        CatalogItem(id: "fur.cocoa", slot: .fur, name: "Nâu cacao", price: 35, blurb: "Như một cốc cacao nóng."),
        CatalogItem(id: "fur.peach", slot: .fur, name: "Hồng đào", price: 40, blurb: "Ngọt ngào và vui tươi.", requiredLevel: 2),
        CatalogItem(id: "fur.midnight", slot: .fur, name: "Đen nửa đêm", price: 45, blurb: "Lông đen, mắt vàng như trăng.", requiredLevel: 3),
        CatalogItem(id: "fur.lilac", slot: .fur, name: "Tím lilac", price: 55, blurb: "Hiếm có, như hoa tử đinh hương.", requiredLevel: 5),
        CatalogItem(id: "fur.honey", slot: .fur, name: "Vàng mật ong", price: 35, blurb: "Vàng ươm như nắng sớm."),
        CatalogItem(id: "fur.mint", slot: .fur, name: "Xanh bạc hà", price: 45, blurb: "Mát lạnh, hợp với ếch và vịt.", requiredLevel: 3),
        CatalogItem(id: "fur.sky", slot: .fur, name: "Xanh da trời", price: 50, blurb: "Như một buổi trưa không mây.", requiredLevel: 4),

        CatalogItem(id: "hat.sprout", slot: .hat, name: "Mầm lá", price: 0, blurb: "Chiếc lá nhỏ mọc trên đầu."),
        CatalogItem(id: "hat.bow", slot: .hat, name: "Nơ hồng", price: 20, blurb: "Nhỏ xinh, cài một bên tai."),
        CatalogItem(id: "hat.party", slot: .hat, name: "Mũ tiệc", price: 25, blurb: "Mỗi ngày đều đáng ăn mừng."),
        CatalogItem(id: "hat.beanie", slot: .hat, name: "Mũ len", price: 30, blurb: "Có quả bông trên chóp."),
        CatalogItem(id: "hat.flower", slot: .hat, name: "Vòng hoa", price: 35, blurb: "Hoa cúc trắng và vàng."),
        CatalogItem(id: "hat.straw", slot: .hat, name: "Mũ cói", price: 40, blurb: "Cho những buổi dã ngoại.", requiredLevel: 2),
        CatalogItem(id: "hat.wizard", slot: .hat, name: "Mũ phù thủy", price: 90, blurb: "Đầy sao, hơi to so với đầu.", requiredLevel: 6),
        CatalogItem(id: "hat.crown", slot: .hat, name: "Vương miện", price: 120, blurb: "Dành cho người chăm chỉ lâu ngày.", requiredLevel: 8),
        CatalogItem(id: "hat.catears", slot: .hat, name: "Bờm tai mèo", price: 30, blurb: "Thêm một đôi tai nữa."),
        CatalogItem(id: "hat.cap", slot: .hat, name: "Mũ lưỡi trai", price: 30, blurb: "Đội ngược cho ngầu."),
        CatalogItem(id: "hat.beret", slot: .hat, name: "Mũ nồi", price: 35, blurb: "Nghệ sĩ Paris."),
        CatalogItem(id: "hat.santa", slot: .hat, name: "Mũ Noel", price: 40, blurb: "Ho ho ho!"),
        CatalogItem(id: "hat.antlers", slot: .hat, name: "Gạc tuần lộc", price: 40, blurb: "Kéo xe trượt tuyết giúp ông già Noel."),
        CatalogItem(id: "hat.chef", slot: .hat, name: "Mũ đầu bếp", price: 45, blurb: "Hôm nay nấu món gì nhỉ?", requiredLevel: 2),
        CatalogItem(id: "hat.pumpkin", slot: .hat, name: "Mũ bí ngô", price: 45, blurb: "Cho mùa lễ hội hóa trang.", requiredLevel: 2),
        CatalogItem(id: "hat.frog", slot: .hat, name: "Mũ ếch", price: 50, blurb: "Hai con mắt lồi trên đỉnh.", requiredLevel: 3),
        CatalogItem(id: "hat.headphones", slot: .hat, name: "Tai nghe", price: 55, blurb: "Nghe lo-fi khi tập trung.", requiredLevel: 3),
        CatalogItem(id: "hat.cowboy", slot: .hat, name: "Mũ cao bồi", price: 60, blurb: "Yee-haw!", requiredLevel: 4),
        CatalogItem(id: "hat.cloud", slot: .hat, name: "Đám mây nhỏ", price: 65, blurb: "Một đám mây đi theo trên đầu.", requiredLevel: 4),
        CatalogItem(id: "hat.halo", slot: .hat, name: "Vòng thiên thần", price: 70, blurb: "Ngoan cả tuần rồi đó.", requiredLevel: 5),
        CatalogItem(id: "hat.tiara", slot: .hat, name: "Vương miện pha lê", price: 80, blurb: "Lấp lánh như công chúa.", requiredLevel: 5),

        CatalogItem(id: "glasses.round", slot: .glasses, name: "Kính tròn", price: 30, blurb: "Trông thật thông thái."),
        CatalogItem(id: "glasses.sun", slot: .glasses, name: "Kính râm", price: 40, blurb: "Ngầu một chút cũng được."),
        CatalogItem(id: "glasses.heart", slot: .glasses, name: "Kính trái tim", price: 45, blurb: "Nhìn đâu cũng thấy dễ thương.", requiredLevel: 3),
        CatalogItem(id: "glasses.monocle", slot: .glasses, name: "Kính một mắt", price: 60, blurb: "Quý ông, quý cô lịch lãm.", requiredLevel: 5),
        CatalogItem(id: "glasses.nerd", slot: .glasses, name: "Kính gọng vuông", price: 30, blurb: "Mọt sách chính hiệu."),
        CatalogItem(id: "glasses.goggles", slot: .glasses, name: "Kính bơi", price: 35, blurb: "Sẵn sàng lặn xuống hồ."),
        CatalogItem(id: "glasses.star", slot: .glasses, name: "Kính ngôi sao", price: 40, blurb: "Ngôi sao của buổi tiệc.", requiredLevel: 2),
        CatalogItem(id: "glasses.aviator", slot: .glasses, name: "Kính phi công", price: 55, blurb: "Bay lên nào!", requiredLevel: 4),
        CatalogItem(id: "glasses.pixel", slot: .glasses, name: "Kính pixel", price: 65, blurb: "Deal with it.", requiredLevel: 5),

        CatalogItem(id: "neck.bowtie", slot: .neck, name: "Nơ cổ", price: 20, blurb: "Chỉn chu cho ngày làm việc."),
        CatalogItem(id: "neck.scarf", slot: .neck, name: "Khăn len", price: 25, blurb: "Ấm cổ những ngày se lạnh."),
        CatalogItem(id: "neck.bandana", slot: .neck, name: "Khăn bandana", price: 25, blurb: "Họa tiết chấm bi."),
        CatalogItem(id: "neck.bell", slot: .neck, name: "Vòng chuông", price: 30, blurb: "Leng keng mỗi bước đi."),
        CatalogItem(id: "neck.lei", slot: .neck, name: "Vòng hoa cổ", price: 35, blurb: "Như vừa đi nghỉ biển về.", requiredLevel: 3),
        CatalogItem(id: "neck.collar", slot: .neck, name: "Vòng cổ thẻ tên", price: 20, blurb: "Thẻ tên hình trái tim."),
        CatalogItem(id: "neck.tie", slot: .neck, name: "Cà vạt", price: 30, blurb: "Họp hành nghiêm túc."),
        CatalogItem(id: "neck.ruff", slot: .neck, name: "Cổ áo bèo", price: 40, blurb: "Bèo nhún trắng tinh.", requiredLevel: 2),
        CatalogItem(id: "neck.pearls", slot: .neck, name: "Chuỗi ngọc trai", price: 60, blurb: "Quý phái nhẹ nhàng.", requiredLevel: 4),
        CatalogItem(id: "neck.medal", slot: .neck, name: "Huy chương vàng", price: 80, blurb: "Quán quân chăm chỉ.", requiredLevel: 6),

        CatalogItem(id: "outfit.sweater", slot: .outfit, name: "Áo len", price: 50, blurb: "Áo len sọc, mềm và ấm."),
        CatalogItem(id: "outfit.overalls", slot: .outfit, name: "Yếm jean", price: 55, blurb: "Có túi nhỏ đựng bút chì.", requiredLevel: 2),
        CatalogItem(id: "outfit.raincoat", slot: .outfit, name: "Áo mưa vàng", price: 60, blurb: "Sẵn sàng cho ngày mưa.", requiredLevel: 3),
        CatalogItem(id: "outfit.cape", slot: .outfit, name: "Áo choàng", price: 90, blurb: "Áo choàng siêu anh hùng.", requiredLevel: 6),
        CatalogItem(id: "outfit.apron", slot: .outfit, name: "Tạp dề", price: 40, blurb: "Có túi nhỏ hình trái tim."),
        CatalogItem(id: "outfit.pajamas", slot: .outfit, name: "Đồ ngủ sao", price: 50, blurb: "Xanh đêm in sao vàng."),
        CatalogItem(id: "outfit.hoodie", slot: .outfit, name: "Áo hoodie", price: 55, blurb: "Rộng rãi, có dây rút."),
        CatalogItem(id: "outfit.dress", slot: .outfit, name: "Váy hoa", price: 60, blurb: "Hoa nhí trên nền vàng.", requiredLevel: 2),
        CatalogItem(id: "outfit.tutu", slot: .outfit, name: "Váy tutu", price: 65, blurb: "Xoay một vòng nào.", requiredLevel: 3),
        CatalogItem(id: "outfit.sailor", slot: .outfit, name: "Áo thủy thủ", price: 70, blurb: "Cổ xanh, nơ đỏ.", requiredLevel: 4),
        CatalogItem(id: "outfit.yukata", slot: .outfit, name: "Áo yukata", price: 85, blurb: "Đi xem pháo hoa mùa hè.", requiredLevel: 5),
        CatalogItem(id: "outfit.tux", slot: .outfit, name: "Áo vest", price: 90, blurb: "Bảnh bao dự tiệc.", requiredLevel: 6),
        CatalogItem(id: "outfit.astronaut", slot: .outfit, name: "Đồ phi hành gia", price: 130, blurb: "Mục tiêu: mặt trăng.", requiredLevel: 8),

        CatalogItem(id: "back.lollipop", slot: .back, name: "Kẹo mút", price: 20, blurb: "Kẹo cầu vồng xoắn ốc."),
        CatalogItem(id: "back.balloon", slot: .back, name: "Bóng bay", price: 25, blurb: "Bóng bay hình trái tim."),
        CatalogItem(id: "back.backpack", slot: .back, name: "Ba lô nhỏ", price: 40, blurb: "Đựng bút, sổ và đồ ăn vặt."),
        CatalogItem(id: "back.umbrella", slot: .back, name: "Ô che nắng", price: 45, blurb: "Ô giấy kiểu cổ điển.", requiredLevel: 2),
        CatalogItem(id: "back.bat", slot: .back, name: "Cánh dơi", price: 60, blurb: "Hơi tinh nghịch một chút.", requiredLevel: 3),
        CatalogItem(id: "back.guitar", slot: .back, name: "Đàn ghi-ta", price: 75, blurb: "Hát một bài cho bạn nghe.", requiredLevel: 4),
        CatalogItem(id: "back.fairy", slot: .back, name: "Cánh tiên", price: 80, blurb: "Trong suốt, lấp lánh.", requiredLevel: 4),
        CatalogItem(id: "back.wings", slot: .back, name: "Cánh thiên thần", price: 90, blurb: "Lông vũ trắng muốt.", requiredLevel: 5)
    ]

    static func item(_ id: String) -> CatalogItem? {
        items.first { $0.id == id }
    }

    static func items(in slot: ItemSlot) -> [CatalogItem] {
        items.filter { $0.slot == slot }
    }

    static func defaultItem(for slot: ItemSlot) -> CatalogItem? {
        items(in: slot).first { $0.isDefault }
    }

    /// Đồ mặc định luôn được coi là đã sở hữu.
    static func isOwned(_ id: String, owned: Set<String>) -> Bool {
        defaultIDs.contains(id) || owned.contains(id)
    }
}

enum PurchaseDecision: Equatable {
    case approved(LedgerEntry)
    case alreadyOwned
    case insufficientCoins(needed: Int, available: Int)
    case levelLocked(required: Int, current: Int)
    case unknownItem

    var message: String? {
        switch self {
        case .approved: return nil
        case .alreadyOwned: return "Bạn đã có món này rồi."
        case .insufficientCoins(let needed, let available): return "Cần \(needed) xu, bạn đang có \(available) xu."
        case .levelLocked(let required, let current): return "Mở khóa ở cấp \(required) (hiện đang cấp \(current))."
        case .unknownItem: return "Không tìm thấy món đồ này."
        }
    }
}

enum PurchasePolicy {
    /// Quyết định mua. Đồ miễn phí vẫn ghi một dòng sổ cái 0 xu để có lịch sử và khóa chống trùng.
    static func decide(itemID: String, owned: Set<String>, ledger: [LedgerEntry], now: Date) -> PurchaseDecision {
        guard let item = Catalog.item(itemID) else { return .unknownItem }
        let key = LedgerKeys.purchase(itemID)
        if Catalog.isOwned(itemID, owned: owned) || ledger.contains(where: { $0.key == key }) {
            return .alreadyOwned
        }
        let wallet = Wallet(entries: ledger)
        guard wallet.level >= item.requiredLevel else {
            return .levelLocked(required: item.requiredLevel, current: wallet.level)
        }
        guard wallet.coins >= item.price else {
            return .insufficientCoins(needed: item.price, available: wallet.coins)
        }
        return .approved(LedgerEntry(
            id: UUID(), key: key, kind: .purchase,
            xp: 0, coins: -item.price,
            createdAt: now, refID: itemID, memo: item.name
        ))
    }
}

struct OwnedItemRecord: Codable, Equatable {
    var itemID: String
    var acquiredAt: Date
    var transactionID: UUID?
}

struct EquippedRecord: Codable, Equatable {
    var slot: ItemSlot
    var itemID: String
}
