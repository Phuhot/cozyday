import Foundation

/// Người dùng vừa làm gì với thú cưng (chạm vào khung cảnh căn phòng).
enum PetReaction: CaseIterable, Equatable {
    case petted, pickedUp, dropped
}

/// Câu thú cưng nói khi được chạm vào — chọn theo ngữ cảnh trong ngày, không cần AI.
/// Không bao giờ trách móc hay tạo cảm giác tội lỗi.
enum PetDialogue {
    struct Context: Equatable {
        var minuteOfDay: Int
        var tasksDone: Int
        var tasksTotal: Int
        var wroteJournal: Bool
        var focusRunning: Bool
        var adventureReady: Bool
        var streak: Int
        var userName: String
    }

    static func lines(for c: Context, species: PetSpecies = .cat) -> [String] {
        let name = c.userName.isEmpty ? "bạn" : c.userName
        var lines: [String] = []
        if c.focusRunning {
            return [
                "Suỵt… mình đang tập trung cùng \(name) đó.", "Cố lên, sắp xong rồi!",
                "Mình ngồi đây đọc sách với \(name) nhé.", "Mình giữ yên lặng cho \(name) nè.",
                "Từng chút một thôi, không vội đâu.", "Mình đang canh giờ giúp \(name) đó.",
                "Xong phiên này mình cùng uống nước nha.", "Mình cũng đang chăm chú lắm nè…",
                "Hít một hơi thật sâu rồi làm tiếp nhé."
            ]
        }
        if c.adventureReady {
            lines.append("Mình đủ năng lượng rồi! Kể chuyện đi chơi cho \(name) nghe nhé?")
        }
        switch c.minuteOfDay {
        case 300..<660:
            lines += ["Chào buổi sáng, \(name)!", "Hôm nay mình làm gì trước nhỉ?", "Uống một cốc nước cho tỉnh táo nào.",
                      "Nắng sớm đẹp ghê!", "Mình dậy rồi nè, \(name) dậy chưa?", "Hôm nay cứ nhẹ nhàng thôi nha.",
                      "Vươn vai một cái cho khỏe nào!", "Ăn sáng chưa đó?"]
        case 660..<780:
            lines += ["Trưa rồi, nhớ ăn gì đó nhé.", "Nghỉ một chút cũng được mà.", "Trưa nay ăn món gì ngon thế?",
                      "Chợp mắt mười phút cũng tốt lắm.", "Nắng trưa ấm quá, mình muốn nằm phơi.",
                      "Nửa ngày rồi, \(name) giỏi ghê."]
        case 780..<1080:
            lines += ["Buổi chiều lười biếng ghê…", "Duỗi lưng một cái nào!", "Một việc nhỏ thôi cũng là tiến bộ.",
                      "Làm một ngụm trà không?", "Ngó ra cửa sổ một chút cho mắt nghỉ nào.",
                      "Chiều nay mình ở đây với \(name) nha.", "Đi bộ vài bước cho thoải mái nhé?"]
        case 1080..<1320:
            lines += ["Tối rồi, hôm nay \(name) vất vả rồi.", "Ngồi yên một chút với mình đi.",
                      "Hôm nay có điều gì nhỏ mà vui không?", "Tối nay ăn gì ngon thế?",
                      "Tắt bớt màn hình cho mắt nghỉ nhé.", "Mình pha trà ấm cho \(name) nè."]
        default:
            lines += ["Khuya rồi… đi ngủ sớm nhé.", "Mình buồn ngủ quá… zzz", "Đắp chăn cho ấm nha.",
                      "Việc còn lại để mai tính nhé.", "Mình ngáp rồi nè… \(name) cũng nghỉ thôi.",
                      "Chúc \(name) ngủ ngon, mơ đẹp nhé."]
        }
        if c.tasksTotal > 0 {
            if c.tasksDone == c.tasksTotal {
                lines += ["Xong hết việc hôm nay rồi! Giỏi quá đi!", "Hết việc rồi, giờ là giờ thư giãn!"]
            } else if c.tasksDone > 0 {
                lines += ["Đã xong \(c.tasksDone)/\(c.tasksTotal) việc rồi đó.", "Từng việc một, mình thấy hết đó."]
            } else {
                lines += ["Bắt đầu bằng việc dễ nhất nhé?", "Chưa làm cũng không sao, mình vẫn ở đây."]
            }
        } else {
            lines += ["Hôm nay chưa có kế hoạch gì — thong thả cũng tốt.", "Một ngày trống cũng là một món quà."]
        }
        if c.minuteOfDay >= 1080 {
            if c.wroteJournal {
                lines.append("Viết nhật ký xong rồi, thấy nhẹ lòng hơn chưa?")
            } else {
                lines += ["Hôm nay của \(name) thế nào? Viết vài dòng nhật ký không?",
                          "Kể mình nghe một điều vui hôm nay nhé?"]
            }
        }
        if c.streak >= 7 {
            lines.append("Cả tuần bên nhau rồi, vui ghê!")
        }
        if c.streak >= 3 {
            lines.append("\(c.streak) ngày liền mình gặp nhau rồi đó!")
        }
        lines += speciesChatter(species, name: name)
        lines += ["Rừ rừ…", "Mình thích được xoa đầu lắm.", "Mình thương \(name) nhiều lắm.",
                  "Nghỉ một chút cũng là đang chăm sóc bản thân đó.", "Hôm nay mình nhặt được một chiếc lá xinh lắm.",
                  "Có \(name) ở đây là vui rồi."]
        return lines
    }

    /// `tap` tăng dần mỗi lần chạm → lần lượt đổi câu, không ngẫu nhiên khó đoán.
    static func line(for c: Context, tap: Int, species: PetSpecies = .cat) -> String {
        let all = lines(for: c, species: species)
        return all[((tap % all.count) + all.count) % all.count]
    }

    static func speciesChatter(_ species: PetSpecies, name: String) -> [String] {
        switch species {
        case .cat: return ["Meo~ gãi cằm cho mình đi.", "Mình vừa ngủ một giấc trong nắng đó."]
        case .bunny: return ["Tai mình vểnh lên vì vui nè!", "Mình mơ thấy cả một vườn cà rốt."]
        case .hamster: return ["Má mình đang giấu hạt đó, suỵt!", "Chạy một vòng cho khỏe nào!"]
        case .bear: return ["Ước gì có một thìa mật ong…", "Ôm một cái thật to nào!"]
        case .fox: return ["Đuôi mình xù chưa nè?", "Mình vừa tìm được một chiếc lá đỏ xinh lắm."]
        case .puppy: return ["Gâu! Đi dạo không, đi dạo không?", "Đuôi mình vẫy không ngừng được nè!"]
        case .duck: return ["Quạc quạc! Hôm nay có mưa không nhỉ?", "Mình muốn đi bơi một vòng ghê."]
        case .frog: return ["Ộp ộp! Lá súng hôm nay mát lắm.", "Mình tập nhảy xa hơn rồi đó!"]
        case .capybara: return ["Thong thả thôi, không vội gì đâu.", "Ước gì được ngâm suối nước nóng…"]
        case .panda: return ["Măng hôm nay giòn ghê.", "Mình lăn một vòng cho \(name) xem nè!"]
        case .penguin: return ["Lạch bạch… mình đến đây!", "Mình để dành một viên sỏi đẹp tặng \(name)."]
        }
    }

    // MARK: Phản ứng khi được vuốt ve, nhấc lên, thả xuống

    /// Câu ngắn khi người dùng chạm vào thú cưng. `seed` tăng dần → lần lượt đổi câu (tất định).
    static func reaction(_ reaction: PetReaction, petName: String, species: PetSpecies = .cat, seed: Int) -> String {
        let pool = reactionLines(reaction, petName: petName, species: species)
        return pool[((seed % pool.count) + pool.count) % pool.count]
    }

    /// Toàn bộ câu cho một loại phản ứng; câu riêng của loài được xen vào giữa để sớm xuất hiện.
    static func reactionLines(_ reaction: PetReaction, petName: String, species: PetSpecies = .cat) -> [String] {
        let pet = petName.isEmpty ? ProfileRecord.defaultPetName : petName
        let common: [String]
        switch reaction {
        case .petted:
            common = [
                "Hihi, nhột quá!", "Xoa nữa đi, xoa nữa đi!", "Ui, dễ chịu ghê…", "Thêm chút nữa thôi mà~",
                "Mình thích thế này lắm!", "Ấm áp quá đi…", "Chỗ đó đó, đúng chỗ đó!", "Lim dim luôn rồi nè…",
                "\(pet) vui lắm luôn!", "Hehe, thương bạn ghê!", "Cả ngày chỉ cần vậy thôi.",
                "Tay bạn ấm quá à.", "Ư… buồn ngủ mất thôi.", "Nữa nè, bên tai này nữa!"
            ]
        case .pickedUp:
            common = [
                "Ơ, bay lên rồi!", "Ui, cao quá ta!", "Mình bay nè, vù vù!", "Đi đâu thế, đi đâu thế?",
                "Ôm chặt mình nha!", "Nhìn từ trên này đẹp ghê!", "Hì, nhẹ tay nha bạn.",
                "Wow, thấy cả căn phòng luôn!", "Lơ lửng như đám mây vậy!", "\(pet) là phi công nhỏ nè!",
                "Đung đưa vui quá đi!", "Bế mình đi chơi hả?", "Ơ kìa, chân không chạm đất!"
            ]
        case .dropped:
            common = [
                "Chỗ này cũng xinh nè!", "Hạ cánh an toàn!", "Ồ, chỗ mới nè!", "Ở đây ngắm cảnh đẹp ghê.",
                "Mình ngồi đây được không?", "Phịch! Êm ghê.", "Chỗ này nắng ấm quá.",
                "Để mình đi khám phá chút.", "Từ giờ đây là góc của \(pet)!", "Ồ, mình chưa ngồi đây bao giờ.",
                "Cảm ơn bạn nha!", "Chỗ này hợp ngủ trưa ghê.", "Xem nào, có gì vui ở đây?"
            ]
        }
        let special = speciesReactions(reaction, species: species)
        // Xen kẽ: cứ 3 câu chung lại có 1 câu riêng của loài.
        var out: [String] = []
        var s = special.makeIterator()
        for (i, line) in common.enumerated() {
            if i % 3 == 0, let extra = s.next() { out.append(extra) }
            out.append(line)
        }
        while let extra = s.next() { out.append(extra) }
        return out
    }

    static func speciesReactions(_ reaction: PetReaction, species: PetSpecies) -> [String] {
        switch (reaction, species) {
        case (.petted, .cat): return ["Gừ gừ… sướng quá!", "Meo~ gãi cằm nữa đi.", "Gừ gừ gừ…"]
        case (.petted, .bunny): return ["Tai mình mềm lắm đúng không?", "Mũi mình nhúc nhích vì vui nè!"]
        case (.petted, .hamster): return ["Chít chít! Vui quá!", "Má mình phồng lên vì sướng nè!"]
        case (.petted, .bear): return ["Ư hừm… như được ôm vậy.", "Gãi lưng giùm mình với!"]
        case (.petted, .fox): return ["Đuôi mình vẫy vẫy nè!", "Hì, cáo cũng thích được nựng."]
        case (.petted, .puppy): return ["Gâu! Đuôi vẫy tít luôn!", "Gãi bụng đi, gãi bụng đi!"]
        case (.petted, .duck): return ["Quạc quạc! Vui ghê!", "Lông mình mượt chưa nè?"]
        case (.petted, .frog): return ["Ộp ộp! Mát tay ghê!", "Ộp… dễ chịu quá trời."]
        case (.petted, .capybara): return ["Thư thái quá…", "Cứ chậm rãi vậy là sướng nhất."]
        case (.petted, .panda): return ["Hihi, mình lăn một vòng nè!", "Ấm như ổ tre luôn…"]
        case (.petted, .penguin): return ["Mình vỗ cánh vì vui đó!", "Ê, nhột bụng mình!"]

        case (.pickedUp, .cat): return ["Meo? Mình lơ lửng nè!", "Đuôi mình đung đưa nè."]
        case (.pickedUp, .bunny): return ["Hai tai bay phấp phới!", "Thỏ nhảy cao chưa nè?"]
        case (.pickedUp, .hamster): return ["Chít! Cao quá đi!", "Nắm chặt hạt hướng dương nào!"]
        case (.pickedUp, .bear): return ["Gấu nhỏ bay lên nè!", "Ôm như ôm gấu bông nha!"]
        case (.pickedUp, .fox): return ["Đuôi xù đung đưa nè!", "Từ trên này thấy rõ ghê!"]
        case (.pickedUp, .puppy): return ["Gâu gâu! Chơi tiếp nào!", "Chân mình vẫn đang chạy nè!"]
        case (.pickedUp, .duck): return ["Quạc! Mình biết bay rồi!", "Quạc quạc, cao ghê!"]
        case (.pickedUp, .frog): return ["Ộp! Nhảy cao thế này á?", "Ộp ộp, bay như chuồn chuồn!"]
        case (.pickedUp, .capybara): return ["Ừm… lên cao cũng thong thả.", "Bay chậm chậm thôi nha."]
        case (.pickedUp, .panda): return ["Ôm mình như ôm gấu bông!", "Ui, gấu trúc biết bay!"]
        case (.pickedUp, .penguin): return ["Cuối cùng mình cũng bay!", "Vỗ cánh, vỗ cánh nào!"]

        case (.dropped, .cat): return ["Meo, chỗ này để phơi nắng!", "Có cái hộp nào ở đây không?"]
        case (.dropped, .bunny): return ["Nhảy tưng tưng chỗ mới nè!", "Có cà rốt ở đây không ta?"]
        case (.dropped, .hamster): return ["Chỗ này giấu hạt được nè!", "Chít chít, đào ổ ở đây!"]
        case (.dropped, .bear): return ["Chỗ này êm như ổ lá.", "Ngồi đây ngủ đông được nè."]
        case (.dropped, .fox): return ["Hít hít… chỗ mới thơm ghê.", "Đuôi xù cuộn tròn ở đây nhé."]
        case (.dropped, .puppy): return ["Gâu! Chạy một vòng xem nào!", "Đánh hơi chỗ mới nào!"]
        case (.dropped, .duck): return ["Quạc quạc, có ao ở đây không?", "Lạch bạch đi xem nào!"]
        case (.dropped, .frog): return ["Ộp! Đáp xuống như lá súng!", "Ộp ộp, chỗ này mát ghê."]
        case (.dropped, .capybara): return ["Ở đâu cũng thong thả được.", "Chỗ này hợp ngâm mình ghê."]
        case (.dropped, .panda): return ["Có tre ở đây không nhỉ?", "Lăn một vòng chỗ mới nào!"]
        case (.dropped, .penguin): return ["Lạch bạch đi xem chỗ mới!", "Chỗ này trượt bụng được nè!"]
        }
    }
}
