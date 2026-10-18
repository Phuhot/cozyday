import Foundation

/// Chuyến phiêu lưu mỗi ngày: thú cưng nạp năng lượng từ những gì bạn làm trong ngày
/// (hoàn thành việc, phiên tập trung, nhật ký, bài thở). Đủ năng lượng thì đi chơi và về kể chuyện.
/// Năng lượng suy ra từ sổ cái — không lưu riêng, không bao giờ bị trừ.
struct AdventureStory: Equatable {
    var title: String
    var text: String
    /// Món kỷ niệm nhặt được (chỉ để kể, không phải vật phẩm trong cửa hàng).
    var keepsake: String
}

struct AdventureMemory: Identifiable, Equatable {
    var day: DayKey
    var story: AdventureStory
    var id: DayKey { day }
}

enum Adventure {
    static let energyPerActivity = 25
    static let fullEnergy = 100

    static let countedKinds: Set<LedgerKind> = [.taskCompleted, .focusCompleted, .journalWritten, .breathing]

    static func energy(on day: DayKey, ledger: [LedgerEntry], calendar: Calendar) -> Int {
        let count = ledger.filter { countedKinds.contains($0.kind) && DayKey($0.createdAt, calendar: calendar) == day }.count
        return min(fullEnergy, count * energyPerActivity)
    }

    static func isReady(on day: DayKey, ledger: [LedgerEntry], calendar: Calendar) -> Bool {
        energy(on: day, ledger: ledger, calendar: calendar) >= fullEnergy
    }

    static func reward(day: DayKey, existingKeys: Set<String>, petName: String, now: Date) -> LedgerEntry? {
        let key = LedgerKeys.adventure(day)
        guard !existingKeys.contains(key) else { return nil }
        return LedgerEntry(
            id: UUID(), key: key, kind: .adventure,
            xp: RewardConfig.adventureXP, coins: RewardConfig.adventureCoins,
            createdAt: now, refID: day.string, memo: story(for: day, petName: petName).title
        )
    }

    // MARK: Mùa — theo tháng của ngày

    enum Season: CaseIterable {
        case spring, summer, autumn, winter

        static func of(month: Int) -> Season {
            switch month {
            case 2...4: return .spring
            case 5...7: return .summer
            case 8...10: return .autumn
            default: return .winter
            }
        }
    }

    struct SeasonFlavor {
        var titles: [String]
        /// Câu tả cảnh, đứng riêng thành một câu.
        var scenes: [String]
        /// Cụm động từ, không có chủ ngữ.
        var acts: [String]
        var keepsakes: [String]
        var festivals: [String]
        var rain: String
        var dish: String
    }

    static func flavor(for season: Season) -> SeasonFlavor {
        switch season {
        case .spring:
            return SeasonFlavor(
                titles: ["Dạo chơi ngày xuân", "Nắng xuân", "Mầm xanh đầu xuân"],
                scenes: [
                    "Trời đầu xuân lất phất mưa phùn, cây cối đâm chồi xanh non.",
                    "Hoa đào, hoa mận nở rộ, đi đâu cũng thấy sắc hồng sắc trắng.",
                    "Nắng xuân dịu dàng, ấm vừa đủ để muốn đi dạo mãi.",
                    "Chim én bay lượn khắp trời, như đang rủ nhau đi chơi xuân."
                ],
                acts: ["dừng lại ngắm một cành đào vừa hé nụ", "hít hà mùi hoa bưởi thơm ngát",
                       "ngồi xem những mầm non nhú lên khỏi đất"],
                keepsakes: ["một cánh hoa đào", "một bao lì xì nhỏ xíu", "một chồi lộc non", "một nhành hoa mơ trắng"],
                festivals: ["chợ hoa xuân", "hội làng đầu năm"],
                rain: "một cơn mưa phùn lất phất",
                dish: "bánh trôi"
            )
        case .summer:
            return SeasonFlavor(
                titles: ["Một ngày hè", "Tiếng ve mùa hạ", "Nắng hè rực rỡ"],
                scenes: [
                    "Nắng hè chang chang, tiếng ve kêu râm ran khắp nơi.",
                    "Hoa phượng đỏ rực cả một góc trời.",
                    "Gió nồm mát rượi thổi qua, xua đi cái nóng.",
                    "Trời xanh ngắt, mây trắng trôi lững lờ như kẹo bông."
                ],
                acts: ["ăn một que kem mát lạnh", "nghe ve kêu đến suýt ngủ gật", "lội chân xuống dòng nước mát"],
                keepsakes: ["một cánh phượng ép khô", "một vỏ ve sầu", "một chiếc quạt giấy nhỏ", "một vỏ sò trắng"],
                festivals: ["lễ hội thả diều", "hội chợ mùa hè"],
                rain: "một cơn mưa rào mùa hạ",
                dish: "thạch rau câu dừa"
            )
        case .autumn:
            return SeasonFlavor(
                titles: ["Gió heo may", "Chiều thu", "Mùa cốm mới"],
                scenes: [
                    "Gió heo may về, mang theo mùi hoa sữa thoang thoảng.",
                    "Lá vàng rơi xào xạc, trời trong xanh và cao vút.",
                    "Cốm mới đã về, cả con phố thơm mùi lúa non.",
                    "Chiều thu nắng nhạt, mọi thứ như chậm lại một chút."
                ],
                acts: ["đạp lên lá khô nghe xào xạc", "ngồi nhâm nhi một nắm cốm thơm",
                       "ngắm vầng trăng tròn treo trên ngọn cây"],
                keepsakes: ["một chiếc lá vàng giòn tan", "một chiếc đèn ông sao tí hon", "một chiếc lá bàng đỏ",
                            "một chùm hoa sữa nhỏ"],
                festivals: ["đêm hội Trung thu", "hội rước đèn ông sao"],
                rain: "một cơn mưa ngâu rả rích",
                dish: "bánh trung thu nhân đậu xanh"
            )
        case .winter:
            return SeasonFlavor(
                titles: ["Ngày se lạnh", "Khăn len và gió bấc", "Chiều đông ấm áp"],
                scenes: [
                    "Trời trở lạnh, ai cũng quấn khăn len thật ấm.",
                    "Sương sớm giăng mờ, hơi thở phả ra thành làn khói trắng.",
                    "Gió bấc thổi hun hút, chỉ muốn ngồi cạnh bếp lửa hồng.",
                    "Những ô cửa sổ sáng đèn vàng, trông ấm áp vô cùng."
                ],
                acts: ["quàng khăn len đi dạo thật chậm", "hơ tay bên một bếp lửa nhỏ",
                       "nhâm nhi một củ khoai lang nướng nóng hổi"],
                keepsakes: ["một chiếc găng tay len bé xíu", "một quả thông phủ sương", "một chiếc chuông nhỏ màu đỏ",
                            "một bông dã quỳ vàng"],
                festivals: ["hội chợ Giáng sinh", "phiên chợ cuối năm"],
                rain: "một cơn mưa lạnh đầu đông",
                dish: "khoai lang nướng mật ong"
            )
        }
    }

    // MARK: Nét riêng của từng loài

    struct SpeciesFlavor {
        var title: String
        var place: String
        /// Cụm động từ, không có chủ ngữ.
        var loves: String
        var snack: String
        var keepsake: String
        /// Cách phản ứng khi trời mưa (cụm động từ).
        var rain: String
    }

    static func flavor(for species: PetSpecies) -> SpeciesFlavor {
        switch species {
        case .cat:
            return SpeciesFlavor(title: "Mái nhà ngập nắng", place: "mái nhà ngập nắng",
                                 loves: "nằm phơi nắng đến lim dim, thỉnh thoảng lại gừ gừ",
                                 snack: "một miếng cá khô", keepsake: "một cuộn len nhỏ màu hồng",
                                 rain: "chui vội vào mái hiên, ngồi liếm lông cho khô")
        case .bunny:
            return SpeciesFlavor(title: "Vườn cà rốt", place: "vườn cà rốt của bác nông dân",
                                 loves: "nhảy lò cò qua từng luống rau, hai tai vểnh lên vì vui",
                                 snack: "một khúc cà rốt giòn", keepsake: "một chiếc lá cỏ ba lá",
                                 rain: "núp dưới một cây nấm to, hai tai cụp xuống cho khỏi ướt")
        case .hamster:
            return SpeciesFlavor(title: "Cánh đồng hướng dương", place: "cánh đồng hoa hướng dương",
                                 loves: "nhặt hạt hướng dương nhét đầy hai má",
                                 snack: "một nắm hạt hướng dương", keepsake: "một hạt dưa hấu đen bóng",
                                 rain: "chui vào một vỏ hạt dẻ to, chỉ ló mỗi cái mũi ra ngoài")
        case .bear:
            return SpeciesFlavor(title: "Rừng sồi và mật ong", place: "khu rừng sồi có dòng suối nhỏ",
                                 loves: "gãi lưng vào gốc sồi rồi nếm một chút mật ong",
                                 snack: "một hũ mật ong nhỏ", keepsake: "một chiếc lá sồi to",
                                 rain: "lấy một chiếc lá to che đầu làm ô")
        case .fox:
            return SpeciesFlavor(title: "Rừng lá phong đỏ", place: "cánh rừng lá phong đỏ",
                                 loves: "nhảy vồ vào đống lá khô, lá bay tung tóe",
                                 snack: "vài quả việt quất", keepsake: "một chiếc lá phong đỏ rực",
                                 rain: "cuộn chiếc đuôi xù lại làm chăn, ngồi dưới gốc cây nghe mưa")
        case .puppy:
            return SpeciesFlavor(title: "Chạy trên bãi cỏ", place: "bãi cỏ rộng bên sông",
                                 loves: "chạy hết vòng này đến vòng khác, tai bay phần phật",
                                 snack: "một chiếc bánh quy hình khúc xương", keepsake: "một quả bóng tennis cũ",
                                 rain: "chạy qua mấy vũng nước bắn tung tóe rồi mới chịu vào trú")
        case .duck:
            return SpeciesFlavor(title: "Bơi quanh ao nhỏ", place: "cái ao nhỏ có đàn cá cờ",
                                 loves: "bơi một vòng quanh ao, vừa bơi vừa quạc quạc",
                                 snack: "mấy hạt ngô vàng", keepsake: "một chiếc lông vịt trắng muốt",
                                 rain: "mừng quá, lạch bạch ra giữa sân tắm mưa, quạc quạc không ngớt")
        case .frog:
            return SpeciesFlavor(title: "Hồ lá súng", place: "hồ đầy lá súng",
                                 loves: "nhảy từ lá súng này sang lá súng khác, ộp ộp vui vẻ",
                                 snack: "một quả dâu tằm chín", keepsake: "một bông súng tím nhỏ",
                                 rain: "ngồi trên một chiếc lá súng, ộp ộp hát theo tiếng mưa")
        case .capybara:
            return SpeciesFlavor(title: "Suối nước nóng", place: "suối nước nóng trong núi",
                                 loves: "ngâm mình trong làn nước ấm, trên đầu đội một quả quýt",
                                 snack: "một quả quýt thơm", keepsake: "một viên đá suối còn ấm",
                                 rain: "cứ thế ngồi yên dưới mưa, lim dim như đang tắm suối")
        case .panda:
            return SpeciesFlavor(title: "Rừng tre xanh", place: "rừng tre xanh mát",
                                 loves: "nhai măng tre thật chậm, rồi lăn một vòng trên cỏ",
                                 snack: "một khúc tre non", keepsake: "một chiếc lá tre cuộn tròn",
                                 rain: "ngồi dưới rặng tre, vừa nghe mưa vừa nhai măng")
        case .penguin:
            return SpeciesFlavor(title: "Biển xanh trong vắt", place: "bờ biển nước trong vắt",
                                 loves: "trượt bụng trên cát ướt rồi lao ùm xuống nước",
                                 snack: "một con cá nhỏ", keepsake: "một viên sỏi nhẵn để tặng bạn",
                                 rain: "thích chí trượt bụng trên nền đất ướt, bì bõm như ở nhà")
        }
    }

    // MARK: Câu chuyện — chọn cố định theo ngày (cùng một ngày luôn ra cùng một câu chuyện)

    static let places = [
        "bờ hồ sen", "khu vườn sau nhà", "thư viện nhỏ cuối phố", "đồi cỏ lau", "chợ hoa buổi sáng",
        "con hẻm có giàn hoa giấy", "tiệm bánh mì đầu ngõ", "bãi biển lúc hoàng hôn", "khu rừng thông",
        "sân thượng đầy chậu cây", "ga tàu cũ", "cánh đồng lúa",
        "quán trà nhỏ ven đường", "cây cầu gỗ bắc qua suối", "tiệm sách cũ", "vườn hoa hướng dương",
        "bến thuyền nhỏ", "ngọn đồi có cối xay gió", "công viên gần nhà", "hiên nhà bà hàng xóm",
        "khu chợ phiên cuối tuần", "bờ suối trong veo", "vườn rau của bác Tư", "con dốc hoa dã quỳ",
        "rặng tre đầu làng", "tiệm kem đầu phố", "bãi cỏ ven sông", "căn chòi trên cây",
        "ngọn hải đăng nhỏ", "vườn cam trĩu quả", "con đường lát đá", "tiệm hoa góc phố",
        "bờ đê lộng gió", "khu vườn thảo mộc", "đồi chè xanh mướt", "làng gốm ven sông", "tiệm đồ cổ"
    ]
    /// Nơi ngoài trời — cho dã ngoại, gieo hạt, hội thi.
    static let outdoorPlaces = [
        "bờ hồ sen", "khu vườn sau nhà", "đồi cỏ lau", "bãi biển lúc hoàng hôn", "khu rừng thông",
        "cánh đồng lúa", "bãi cỏ ven sông", "vườn hoa hướng dương", "bờ suối trong veo", "đồi chè xanh mướt",
        "công viên gần nhà", "vườn cam trĩu quả", "ngọn đồi có cối xay gió", "khu vườn thảo mộc"
    ]
    static let nightPlaces = [
        "bờ đê lộng gió", "sân thượng đầy chậu cây", "đồi cỏ lau", "căn chòi trên cây",
        "bãi cỏ ven sông", "mái nhà kho cũ", "bãi cát trắng", "ngọn đồi sau làng"
    ]
    /// Việc làm trong chuyến đi (cụm động từ, không có chủ ngữ).
    static let meetings = [
        "gặp một chú ốc sên đi chậm rãi", "làm quen với một chú chim sẻ hay hát",
        "ngồi xem mây trôi cùng một bạn mèo hàng xóm", "giúp một bạn kiến khiêng hạt gạo",
        "nghe bà cụ bán hoa kể chuyện ngày xưa", "đuổi theo một cánh bướm vàng",
        "nằm dưới gốc cây nghe gió thổi", "đếm được mười chín chiếc lá rơi",
        "tập huýt sáo (gần được rồi)", "chia nửa chiếc bánh quy với một chú sóc",
        "xếp hàng mua một que kem", "tập đứng một chân như bác cò",
        "kết lá khô thành một chiếc vương miện", "ngồi đung đưa trên xích đu",
        "học cách gấp thuyền giấy", "nằm tìm những đám mây hình con thỏ",
        "thổi bồ công anh bay khắp trời", "nhảy qua mấy vũng nước nhỏ",
        "chơi trốn tìm với cái bóng của mình", "ngồi nghe tiếng chuông gió leng keng",
        "vẽ một bức tranh bằng que lên cát", "hái mấy quả mâm xôi chín đỏ",
        "tập đi thăng bằng trên một khúc gỗ", "đứng ngửi mùi bánh nướng bên cửa sổ tiệm bánh",
        "ngồi ngắm một đàn kiến xếp hàng", "nghe một bài hát lạ từ chiếc radio cũ",
        "gặp lại một người bạn cũ và tíu tít cả buổi", "học được cách huýt sáo hai nốt",
        "ngắm những chiếc thuyền buồm nhỏ trôi qua", "uống một cốc trà hoa cúc ấm",
        "tìm ra một lối tắt rợp bóng cây", "giúp bác làm vườn tưới mấy luống rau"
    ]
    /// Nhân vật gặp gỡ: `who` dùng sau "một", `detail` là nét riêng.
    static let friends: [(who: String, detail: String)] = [
        ("chú ốc sên", "đi chậm rãi chẳng vội gì"), ("bạn chim sẻ", "hay hát"),
        ("bạn mèo hàng xóm", "lông xù như cục bông"), ("bạn kiến", "chăm chỉ nhất xóm"),
        ("bà cụ bán hoa", "cười hiền khô"), ("chú sóc", "đuôi xù thật to"),
        ("bạn nhím", "hơi nhút nhát"), ("bác rùa", "đã già mà vẫn tinh nghịch"),
        ("cô bướm", "có đôi cánh vàng chanh"), ("chú cú mèo", "đeo kính tròn"),
        ("bạn đom đóm", "lúc nào cũng mang theo đèn"), ("bác đưa thư", "đạp xe kêu leng keng"),
        ("bạn chuột đồng", "mê sưu tầm cúc áo"), ("chị ong mật", "lúc nào cũng bận rộn"),
        ("chú chuồn chuồn ớt", "đỏ chót"), ("cậu bé", "đang tập thả diều"),
        ("cô bé", "buộc tóc hai bên"), ("bác làm bánh", "tay lúc nào cũng dính bột"),
        ("chú vẹt", "biết nói “xin chào”"), ("bạn cua", "đi ngang rất điệu"),
        ("bạn bọ rùa", "có bảy chấm đen"), ("chú dế mèn", "kéo đàn rất hay"),
        ("bác cò", "thích đứng một chân"), ("bạn gà con", "mới nở hôm qua"),
        ("bạn rái cá", "lúc nào cũng ôm một viên sỏi"), ("bạn cáo nhỏ", "mê sưu tầm lá"),
        ("bác gấu", "bán mật ong ở chợ"), ("bạn chim gõ kiến", "gõ nhịp rất đều"),
        ("cô mèo mướp", "mở tiệm may"), ("bạn thỏ trắng", "đeo giỏ cà rốt"),
        ("bạn sâu đo", "đi đâu cũng đo đường"), ("ông lão câu cá", "kể chuyện rất duyên")
    ]
    /// Sự kiện nhỏ giữa đường — mỗi mục là một câu trọn vẹn.
    static let events = [
        "Giữa chừng, trời đổ một cơn mưa bóng mây rồi tạnh ngay, để lại một chiếc cầu vồng nhỏ.",
        "Một cơn gió nghịch ngợm thổi bay chiếc mũ, phải chạy theo mãi mới bắt được.",
        "Có lúc một đám mây trông y hệt chiếc bánh bao, nhìn mà thấy đói bụng.",
        "Đi một đoạn thì gặp một vũng nước nhỏ, soi vào thấy mình đang cười.",
        "Tự nhiên có mùi bánh nướng thơm lừng bay tới từ đâu đó.",
        "Bỗng nghe tiếng sáo diều vi vu ở đâu đó trên cao.",
        "Một chiếc lá rơi đúng lên đầu, như ai vừa đội cho một chiếc mũ.",
        "Đến khúc quanh thì gặp một bạn mèo đang ngủ chắn ngang đường, đành rón rén bước qua.",
        "Mặt trời ló ra sau mây, mọi thứ bỗng sáng bừng lên.",
        "Có một đàn chim bay ngang, xếp thành hình chữ V thật đẹp.",
        "Trên đường có một chiếc ghế đá, ngồi nghỉ chân một lát thấy dễ chịu ghê.",
        "Một bác bán hàng rong cho nếm thử một miếng bánh, ngon ơi là ngon.",
        "Tiếng chuông chùa xa xa vọng lại, nghe thật yên bình.",
        "Một chú bướm cứ bay theo suốt một đoạn đường, như muốn làm bạn đồng hành.",
        "Gió thổi qua làm cả rặng cây rì rào như đang trò chuyện.",
        "Có lúc trượt chân trên đám rêu, may mà chỉ lấm tấm chút bùn, cười xòa cho qua.",
        "Một hạt mưa rơi trúng mũi, mát lạnh và buồn cười.",
        "Bầu trời hôm ấy xanh đến mức chỉ muốn nằm xuống ngắm mãi.",
        "Đi ngang qua một khu vườn, có người vẫy tay chào thật tươi.",
        "Một đám bồ công anh bay lên, trông như tuyết rơi ngược.",
        "Bỗng thấy bóng mình in trên tường, dài ngoằng và rất buồn cười.",
        "Có tiếng ai đó đang tập đàn, sai một nốt rồi lại đàn tiếp, nghe rất dễ thương.",
        "Có một con đường đầy lá, mỗi bước đi lại kêu xào xạc.",
        "Bỗng ngửi thấy mùi hoa nhài thoang thoảng trong gió."
    ]
    static let keepsakes = [
        "một chiếc lá hình trái tim", "một viên sỏi tròn nhẵn", "một chiếc lông vũ màu xanh",
        "một bông hoa dại tím", "một vỏ ốc nhỏ", "một tấm bưu thiếp cũ", "một hạt dẻ bóng loáng",
        "một chiếc cúc áo màu vàng", "một quả thông nhỏ", "một mẩu ruy băng đỏ",
        "một tờ giấy vẽ ngôi sao", "một chiếc chuông gió bằng tre",
        "một chiếc vỏ sò có vân hồng", "một hòn bi ve trong suốt", "một nhành oải hương khô",
        "một chiếc kẹo bọc giấy bạc", "một sợi dây buộc tóc có nơ", "một mẩu phấn màu xanh",
        "một hạt giống hướng dương", "một con tem in hình con cá", "một mẩu gỗ lũa nhỏ",
        "một chiếc kẹp giấy hình ngôi sao", "một viên đá có sọc trắng", "một chiếc thuyền giấy nhỏ",
        "một bông bồ công anh còn nguyên", "một chiếc lá bạc hà thơm mát", "một nút chai bần",
        "một chiếc chìa khóa nhỏ xíu", "một tấm ảnh chụp mây", "một chiếc huy hiệu hình mặt trời",
        "một chiếc lông chim sẻ", "một hạt cườm màu tím", "một quả chuông nhỏ kêu leng keng",
        "một mảnh thủy tinh biển màu xanh ngọc", "một chiếc móc khóa hình quả dâu",
        "một mẩu bút chì ngắn", "một chiếc lá non xanh mướt", "một chiếc hộp thiếc nhỏ có vẽ hoa",
        "một chiếc nhẫn cỏ tự kết"
    ]
    /// Câu kết — câu trọn vẹn, không cần chủ ngữ.
    static let endings = [
        "Rồi chạy một mạch về nhà vì nhớ bạn.",
        "Món quà nhỏ ấy là để dành tặng bạn đó.",
        "Về đến nhà là kể ngay cho bạn nghe, mắt sáng lấp lánh.",
        "Trên đường về còn tự hứa sẽ có ngày quay lại đó.",
        "Đi về mỏi chân nên ngủ gật luôn, trong mơ vẫn thấy bạn.",
        "Kỷ vật ấy được cất thật kỹ vào góc phòng.",
        "Rồi ngân nga suốt quãng đường về nhà.",
        "Tối nay chắc chắn sẽ là một giấc ngủ thật ngon.",
        "Hôm nay đúng là một ngày thật đẹp.",
        "Về tới cửa, việc đầu tiên là tìm bạn để ôm một cái.",
        "Cả buổi tối cứ cười tủm tỉm mãi thôi.",
        "Chuyến đi ngắn thôi mà vui ơi là vui.",
        "Giờ thì chỉ muốn cuộn tròn bên cạnh bạn nghỉ một chút.",
        "Ai hỏi gì cũng chỉ đáp: “Hôm nay vui lắm!”",
        "Lần sau nhất định sẽ rủ bạn đi cùng.",
        "Đường về có gió mát, bước chân nhẹ tênh.",
        "Về nhà, kỷ vật được đặt lên bậu cửa sổ cho nắng chiếu vào.",
        "Chuyện hôm nay chắc phải kể ba ngày mới hết.",
        "Về nhà ăn một bữa thật no rồi ngủ một giấc thật dài.",
        "Thế giới ngoài kia rộng thật, nhưng nhà vẫn là nơi ấm nhất.",
        "Từ giờ, mỗi lần nhìn kỷ vật ấy sẽ lại nhớ đến hôm nay.",
        "Một ngày nhỏ xíu thôi, mà đầy ắp những điều dễ thương.",
        "Về tới nhà là lăn ra ngủ, miệng vẫn còn mỉm cười.",
        "Mong là bạn cũng đang có một ngày dễ chịu như thế."
    ]

    // Chi tiết cho từng khuôn truyện.
    static let helpNeeds = [
        "đang đuổi theo chiếc khăn bị gió thổi bay", "cần người giữ thang để hái quả",
        "muốn mang một giỏ hoa qua bên kia cầu", "đang tìm chiếc chìa khóa bị đánh rơi",
        "đang cố treo một chiếc đèn lồng lên cao", "lỡ làm đổ cả giỏ táo lăn lông lốc",
        "đang loay hoay gom đống lá rụng trước cửa", "muốn gửi thư mà không với tới hòm thư",
        "đang tìm đường về nhà", "muốn trồng một cái cây mà chưa biết bắt đầu từ đâu",
        "đang khiêng một chiếc ghế hơi nặng", "đang gỡ con diều mắc trên cành cây"
    ]
    static let helpActs = [
        "{n} xắn tay vào giúp ngay, chẳng mấy chốc đã xong.",
        "{n} chạy lại giúp một tay, hai bên vừa làm vừa cười.",
        "{n} nghĩ một lúc rồi tìm ra cách, thế là xong ngay!",
        "{n} giúp từng chút một, chậm mà chắc.",
        "Có {n} phụ một tay, việc khó hóa thành việc vui."
    ]
    static let treasureSpots = [
        "dưới gốc cây sồi già", "sau một tảng đá phủ rêu", "trong một hộp thiếc cũ", "giữa hai rễ cây to",
        "dưới chiếc ghế đá", "trong một chiếc tổ chim bỏ trống", "dưới một chậu hoa lật úp"
    ]
    static let commonFestivals = ["lễ hội đèn lồng", "hội chợ đồ thủ công", "đêm nhạc ngoài trời", "phiên chợ quê"]
    static let festivalActs = [
        "thử chơi ném vòng và trúng ngay lần thứ ba", "xem múa lân đến quên cả chớp mắt",
        "ăn một cây kẹo bông to như đám mây", "đứng xem một bác nặn tò he khéo tay",
        "nhún nhảy theo điệu nhạc dù chẳng ai bảo", "mua một chiếc chong chóng giấy quay tít",
        "ngồi xem múa rối nước, cười khúc khích suốt buổi", "chơi một ván ô ăn quan với các bạn nhỏ"
    ]
    static let cooks = [
        "bác làm bánh ở đầu ngõ", "bà ngoại của bạn sóc", "cô mèo mướp mở quán chè",
        "chú gấu béo bán bánh bao", "bạn thỏ trắng mê nấu ăn", "bác cú mèo đeo tạp dề"
    ]
    static let dishes = [
        "bánh quy hình ngôi sao", "chè đậu xanh", "súp bí đỏ", "bánh rán", "trà gừng mật ong",
        "cơm nắm rong biển", "bánh flan", "sữa chua trái cây", "bánh kếp chuối", "xôi gấc",
        "bánh bao nhân đậu", "sinh tố dâu"
    ]
    static let cookMoments = [
        "Bột bay tứ tung, dính cả lên mũi.",
        "Mẻ đầu hơi cháy một chút, mẻ sau thì thơm phức.",
        "Khuấy mãi, khuấy mãi, cuối cùng nồi cũng sôi lục bục.",
        "Nếm thử thấy hơi nhạt, thêm chút đường là vừa xinh.",
        "Thành phẩm trông hơi méo, nhưng ăn thì ngon tuyệt.",
        "Cả căn bếp thơm nức, ai đi ngang cũng ngoái lại nhìn.",
        "Vừa làm vừa hát, nên món ăn hình như ngọt hơn."
    ]
    static let contests = [
        "xếp lá", "huýt sáo", "nhảy xa", "kể chuyện cười", "vẽ mây", "xây lâu đài cát",
        "thả thuyền giấy", "gấp máy bay giấy", "kết vòng hoa", "ngủ trưa", "trang trí bánh quy",
        "thổi bong bóng xà phòng"
    ]
    static let contestMoments = [
        "làm hết sức mình, lưỡi thè ra vì tập trung", "vừa làm vừa cười khúc khích",
        "có lúc suýt hỏng nhưng rồi lại gỡ được", "học lỏm được mấy mẹo hay từ các bạn bên cạnh",
        "làm chậm mà chắc, chẳng vội chút nào"
    ]
    static let awards = [
        "Dễ thương nhất", "Cố gắng hết mình", "Sáng tạo nhất", "Nụ cười tươi nhất",
        "Bạn đồng hành vui vẻ", "Ý tưởng bất ngờ", "Kiên nhẫn nhất", "Trái tim ấm áp"
    ]
    static let drawings = [
        "một trái tim hơi méo", "hình hai đứa mình đang ngồi uống trà", "một ông mặt trời đang cười",
        "một bông hoa năm cánh", "hình chính mình đang vẫy tay", "một cầu vồng bảy màu"
    ]
    static let letterClosings = [
        "Dòng cuối ghi: “Mong bạn có một buổi tối thật êm.”",
        "Dòng cuối ghi: “Hôm nay bạn đã làm tốt lắm rồi.”",
        "Dòng cuối ghi: “Nhớ uống nước và nghỉ ngơi nha.”",
        "Dòng cuối ghi: “Mai mình lại đi chơi tiếp nhé.”",
        "Dòng cuối ghi: “Cảm ơn bạn đã ở bên mình.”",
        "Dòng cuối ghi: “Mình thương bạn nhiều lắm.”",
        "Dòng cuối ghi: “Ngủ ngon nha, hẹn gặp bạn ngày mai.”"
    ]
    static let wishes = [
        "cho bạn đêm nào cũng ngủ thật ngon", "ngày mai trời cũng đẹp như hôm nay",
        "hai đứa mình mãi là bạn thân", "bạn lúc nào cũng thấy nhẹ lòng",
        "có thêm thật nhiều buổi tối bình yên như thế này", "ai cũng có một chiếc chăn thật ấm"
    ]
    static let seeds = [
        "hướng dương", "cúc họa mi", "hoa mười giờ", "bạc hà", "cà chua bi", "đậu biếc",
        "hoa sao nhái", "rau mầm", "cúc vàng", "dưa hấu"
    ]
    static let rides: [(title: String, phrase: String)] = [
        ("Chuyến tàu chiều", "lên một chuyến tàu nhỏ chạy chầm chậm qua những cánh đồng"),
        ("Chuyến đò qua sông", "ngồi trên một chiếc đò nhỏ, nghe mái chèo khua nước"),
        ("Xe buýt màu vàng", "đi một chiếc xe buýt màu vàng chạy vòng quanh thị trấn"),
        ("Khinh khí cầu sọc đỏ", "được bay một vòng trên chiếc khinh khí cầu sọc đỏ trắng"),
        ("Đạp xe dạo phố", "đạp chiếc xe đạp nhỏ đi dạo khắp phố")
    ]
    static let teaTopics = [
        "những chuyến đi xa", "khu vườn nhà mình", "một cuốn sách hay vừa đọc", "một giấc mơ kỳ lạ",
        "bí quyết ngủ trưa thật ngon", "những món ăn yêu thích"
    ]
    static let drawSubjects = [
        "cảnh hoàng hôn", "những đám mây", "một gốc cây già", "mấy chậu hoa", "con đường dẫn về nhà",
        "bạn đang mỉm cười"
    ]

    /// Số khuôn truyện (khuôn "nơi yêu thích của loài" được tính hai lần để xuất hiện thường hơn).
    static let templateCount = 19

    static func story(for day: DayKey, petName: String, species: PetSpecies = .cat) -> AdventureStory {
        let seed = day.string
        func roll(_ salt: String) -> Int { Int(stableHash(seed + "|" + salt) % 1_000_003) }
        func pick<T>(_ list: [T], _ salt: String) -> T { list[roll(salt) % list.count] }
        func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

        let n = petName.isEmpty ? ProfileRecord.defaultPetName : petName
        let sf = flavor(for: Season.of(month: day.month))
        let sp = flavor(for: species)
        let place = pick(places, "place")
        let outdoor = pick(outdoorPlaces, "outdoor")
        let meet = pick(meetings, "meet")
        let friend = pick(friends, "friend")
        let aFriend = "một \(friend.who) \(friend.detail)"
        let keep = pick(keepsakes + sf.keepsakes, "keep")
        let ending = pick(endings, "end")
        let event = pick(events, "event")
        let scene = pick(sf.scenes, "scene")

        func make(_ title: String, _ sentences: [String], _ keepsake: String) -> AdventureStory {
            AdventureStory(title: title, text: sentences.joined(separator: " "), keepsake: keepsake)
        }

        switch roll("tpl") % templateCount {
        case 0: // Chuyến đi quen thuộc
            return make("Chuyến đi tới \(place)", [
                "\(n) ghé \(place), \(meet).", event,
                "Trước khi về, \(n) nhặt được \(keep).", ending
            ], keep)
        case 1: // Đi lạc rồi tìm đường
            return make("Đường về từ \(place)", [
                "\(n) mải chơi ở \(place) nên đi lạc lúc nào không hay.",
                "May sao gặp \(aFriend) chỉ đường tận tình, còn được tặng thêm \(keep).",
                "Hóa ra đường về lại đi qua một lối nhỏ rợp hoa, đẹp hơn cả lối cũ.", ending
            ], keep)
        case 2: // Giúp đỡ ai đó
            return make("Giúp \(friend.who)", [
                "\(n) đang dạo quanh \(place) thì thấy một \(friend.who) \(pick(helpNeeds, "need")).",
                pick(helpActs, "act").replacingOccurrences(of: "{n}", with: n),
                "Để cảm ơn, \(friend.who) tặng \(n) \(keep).", ending
            ], keep)
        case 3: // Kho báu nhỏ
            return make("Kho báu nhỏ ở \(place)", [
                "\(n) tìm thấy một tấm bản đồ vẽ tay ở \(place), trên đó có đánh dấu một ngôi sao nhỏ.", event,
                "Lần theo bản đồ, \(n) thấy kho báu nằm \(pick(treasureSpots, "spot")): \(keep)!",
                "Nhỏ xíu thôi, nhưng với \(n) đó là kho báu quý nhất.", ending
            ], keep)
        case 4: // Lễ hội
            let fest = pick(sf.festivals + commonFestivals, "fest")
            return make(cap(fest), [
                "\(n) lần theo tiếng nhạc và tìm tới \(fest).", scene,
                "\(n) \(pick(festivalActs, "fact")), rồi còn được tặng \(keep).", ending
            ], keep)
        case 5: // Ngày mưa
            return make("Ngày mưa ở \(place)", [
                "\(n) đang chơi ở \(place) thì \(sf.rain) kéo tới.",
                "\(n) \(sp.rain).",
                "Gần đó có \(aFriend) cũng đang ngắm mưa, thế là cả hai trò chuyện rôm rả.",
                "Tạnh mưa, \(n) thấy \(keep) nằm ngay cạnh một vũng nước.", ending
            ], keep)
        case 6: // Nấu ăn
            let dish = pick(dishes + [sf.dish], "dish")
            return make("Món \(dish)", [
                "\(n) theo \(pick(cooks, "cook")) vào bếp học làm \(dish).",
                pick(cookMoments, "moment"),
                "Lúc về, \(n) được tặng \(keep) cùng một phần \(dish) để dành cho bạn.", ending
            ], keep)
        case 7: // Thi tài
            let contest = pick(contests, "contest")
            return make("Hội thi \(contest)", [
                "\(n) ghé \(outdoor) đúng lúc đang có hội thi \(contest), thế là xin vào chơi cùng.",
                "\(n) \(pick(contestMoments, "cmoment")).",
                "Ban giám khảo là \(aFriend), trao cho \(n) giải “\(pick(awards, "award"))” kèm \(keep).", ending
            ], keep)
        case 8: // Viết thư
            return make("Lá thư từ \(place)", [
                "\(n) ngồi ở \(place) viết một lá thư nhỏ gửi bạn.",
                "Trong thư kể rằng hôm nay \(n) đã \(meet).",
                "Cuối thư còn vẽ \(pick(drawings, "draw")) và kẹp theo \(keep).",
                pick(letterClosings, "close")
            ], keep)
        case 9, 18: // Nơi yêu thích của loài
            return make(sp.title, [
                "\(n) dậy thật sớm để tới \(sp.place), nơi \(n) thích nhất.",
                "\(n) \(sp.loves).", scene,
                "Lúc về, \(n) mang theo \(sp.keepsake).", ending
            ], sp.keepsake)
        case 10: // Ngắm sao
            let spot = pick(nightPlaces, "night")
            return make("Đếm sao trên \(spot)", [
                "\(n) ra \(spot) ngắm sao khi trời vừa tối.",
                "\(n) đếm được \(20 + roll("stars") % 80) ngôi sao thì quên mất mình đang đếm tới đâu.",
                "Bỗng một ngôi sao băng vụt qua, \(n) vội ước \(pick(wishes, "wish")).",
                "Trên đường về, \(n) nhặt được \(keep) dưới ánh trăng.", ending
            ], keep)
        case 11: // Dã ngoại
            return make("Dã ngoại ở \(outdoor)", [
                "\(n) mang theo \(sp.snack) đi dã ngoại ở \(outdoor).",
                "Trải tấm khăn ca rô ra xong, \(n) \(meet).",
                "Có \(aFriend) ghé qua, thế là cả hai chia nhau đồ ăn ngon lành.",
                "Lúc dọn đồ, \(n) tìm thấy \(keep) nằm trong đám cỏ.", ending
            ], keep)
        case 12: // Gieo hạt
            let seedName = pick(seeds, "seed")
            return make("Gieo hạt \(seedName)", [
                "\(n) mang một túi hạt \(seedName) tới \(outdoor).",
                "\(n) cẩn thận gieo từng hạt, tưới nước rồi thì thầm: “Lớn nhanh nhé!”", event,
                "Trước khi về, \(n) cắm một que nhỏ để đánh dấu, rồi nhặt \(keep) làm kỷ niệm.", ending
            ], keep)
        case 13: // Đi tàu, đi đò, đi xe
            let ride = pick(rides, "ride")
            return make(ride.title, [
                "\(n) \(ride.phrase).", roll("mid") % 2 == 0 ? event : scene,
                "Điểm dừng cuối là \(place), nơi \(n) \(meet).",
                "\(n) giữ lại \(keep) làm kỷ niệm cho chuyến đi.", ending
            ], keep)
        case 14: // Dạo chơi theo mùa
            let seasonKeep = pick(sf.keepsakes, "skeep")
            return make(pick(sf.titles, "stitle"), [
                "\(n) đi dạo quanh \(place).", scene,
                "\(n) \(pick(sf.acts, "sact")), thấy lòng nhẹ tênh.",
                "Trên đường về, \(n) nhặt được \(seasonKeep).", ending
            ], seasonKeep)
        case 15: // Trà chiều
            return make("Trà chiều với \(friend.who)", [
                "\(n) được \(aFriend) mời uống trà chiều ở \(place).",
                "Trên bàn có trà hoa cúc, bánh quy và cả \(sp.snack) dành riêng cho \(n).",
                "\(cap(friend.who)) kể chuyện \(pick(teaTopics, "topic")), còn \(n) kể về bạn.",
                "Lúc chia tay, \(n) được tặng \(keep).", ending
            ], keep)
        case 16: // Rủ bạn tới nơi yêu thích
            return make("Rủ \(friend.who) đi chơi", [
                "\(n) rủ \(aFriend) cùng tới \(sp.place).",
                "\(n) \(sp.loves), còn \(friend.who) ngồi bên cạnh vỗ tay.", event,
                "Lúc chia tay, \(friend.who) tặng \(n) \(keep).", ending
            ], keep)
        default: // 17 — Vẽ tranh
            return make("Bức tranh ở \(place)", [
                "\(n) mang giấy bút tới \(place) để vẽ \(pick(drawSubjects, "subject")).",
                "Vẽ mãi mới xong, tranh hơi lem một chút nhưng rất có hồn.",
                "\(cap(aFriend)) đi ngang qua khen mãi, còn tặng \(n) \(keep).", ending
            ], keep)
        }
    }

    /// FNV-1a 64-bit: ổn định giữa các lần chạy (không như `hashValue`).
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in s.utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01B3
        }
        return h
    }
}
