import Foundation

/// Kịch bản phim mở viên nang: thời lượng, các cảnh quay và mốc âm thanh.
/// Thuần dữ liệu (không vẽ) để kiểm thử được: cảnh nối liền nhau, âm thanh nằm trong phim, tiếng mở viên trùng lúc viên bật.
enum GachaStoryboard {
    enum Cut: Equatable { case full, short }

    enum Shot: String, CaseIterable {
        /// Toàn cảnh phòng đêm, đèn bật, bạn nhỏ nhìn máy rồi lon ton lại gần.
        case establish
        /// Cận máy: bạn nhỏ nhún, bật nhảy, vỗ núm xoay.
        case crank
        /// Góc thấp: viên nang rơi khỏi máng, nảy về phía máy quay, lăn tới chân bạn nhỏ.
        case drop
        /// Cận hai nhân vật: cúi ngửi, khều thử, nghiêng đầu nhìn khán giả, viên nang rung và rỉ sáng.
        case curious
        /// Đẩy máy quay vào viên nang: bật nắp, chớp sáng, tia sáng theo độ hiếm.
        case pop
        /// Lùi ra: bạn nhỏ nhảy mừng, quả cầu sáng và tên độ hiếm, chuyển sang màn nhận món.
        case joy
    }

    enum Sound: Equatable {
        case lampOn, steps, knob, click, drop, bounce, sniff, poke, rumble, reveal, cheer
    }

    static func duration(_ cut: Cut) -> Double { cut == .full ? 8.8 : 2.0 }

    /// Lúc viên nang bật nắp.
    static func popTime(_ cut: Cut) -> Double { cut == .full ? 6.55 : 0.55 }

    /// Các cảnh (bắt đầu, cảnh) theo thứ tự thời gian.
    static func shots(_ cut: Cut) -> [(start: Double, shot: Shot)] {
        switch cut {
        case .full:
            return [(0, .establish), (1.5, .crank), (2.8, .drop), (4.2, .curious), (6.2, .pop), (7.1, .joy)]
        case .short:
            return [(0, .pop), (0.9, .joy)]
        }
    }

    static func shot(at t: Double, cut: Cut) -> (shot: Shot, start: Double, end: Double) {
        let list = shots(cut)
        var i = 0
        while i + 1 < list.count && t >= list[i + 1].start { i += 1 }
        let end = i + 1 < list.count ? list[i + 1].start : duration(cut)
        return (list[i].shot, list[i].start, end)
    }

    /// Mốc âm thanh. Viên càng hiếm, viên rung càng lâu (thêm tiếng rung).
    static func sounds(_ cut: Cut, tier: ItemRarity) -> [(time: Double, sound: Sound)] {
        switch cut {
        case .full:
            var list: [(Double, Sound)] = [
                (0.25, .lampOn), (1.15, .steps), (1.35, .steps), (1.95, .knob), (2.25, .click), (2.45, .click),
                (2.85, .drop), (3.15, .bounce), (3.5, .bounce), (3.8, .bounce),
                (4.65, .sniff), (4.85, .sniff), (5.15, .poke), (5.75, .rumble)
            ]
            if tier >= .epic { list.append((6.0, .rumble)) }
            list += [(popTime(cut), .reveal), (7.25, .cheer)]
            return list
        case .short:
            return [(0.15, .poke), (popTime(cut), .reveal), (1.1, .cheer)]
        }
    }
}
