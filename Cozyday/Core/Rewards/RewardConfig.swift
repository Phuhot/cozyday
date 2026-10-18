import Foundation

/// Mọi con số về thưởng tập trung ở đây.
enum RewardConfig {
    /// Hoàn thành một lần việc (lần đầu tiên).
    static let taskXP = 10
    static let taskCoins = 5

    /// Phiên tập trung hoàn thành đủ thời lượng: thưởng theo số phút đã đặt.
    static let focusMinMinutesForReward = 10
    static let focusXPPerFiveMinutes = 2
    static let focusCoinsPerFiveMinutes = 1
    static let focusMaxRewardMinutes = 120

    /// Viết nhật ký: một lần mỗi ngày.
    static let journalXP = 5
    static let journalCoins = 2

    /// Bài thở: một lần mỗi ngày.
    static let breathingXP = 3
    static let breathingCoins = 1

    /// Nghe thú cưng kể chuyến phiêu lưu (khi đủ năng lượng): một lần mỗi ngày.
    static let adventureXP = 5
    static let adventureCoins = 3

    /// XP cho mỗi cấp của mèo.
    static let xpPerLevel = 100

    static func focusReward(plannedMinutes: Int) -> (xp: Int, coins: Int) {
        guard plannedMinutes >= focusMinMinutesForReward else { return (0, 0) }
        let blocks = min(plannedMinutes, focusMaxRewardMinutes) / 5
        return (blocks * focusXPPerFiveMinutes, blocks * focusCoinsPerFiveMinutes)
    }

    /// Quy tắc hiển thị trong app (Cài đặt → Quy tắc phần thưởng).
    static let rulesText: [String] = [
        "Hoàn thành một việc lần đầu: +\(taskXP) XP, +\(taskCoins) xu.",
        "Bỏ đánh dấu hoàn thành hoặc xóa việc không thu hồi phần thưởng đã nhận.",
        "Hoàn thành lại chính lần việc đó không nhận thêm thưởng.",
        "Phiên tập trung từ \(focusMinMinutesForReward) phút trở lên, chạy hết giờ: +\(focusXPPerFiveMinutes) XP và +\(focusCoinsPerFiveMinutes) xu cho mỗi 5 phút (tối đa \(focusMaxRewardMinutes) phút).",
        "Kết thúc sớm: không có thưởng, nhưng số phút đã tập trung vẫn được tính vào thống kê. Thời gian tạm dừng không được tính.",
        "Viết nhật ký: +\(journalXP) XP, +\(journalCoins) xu, một lần mỗi ngày.",
        "Làm bài thở: +\(breathingXP) XP, +\(breathingCoins) xu, một lần mỗi ngày.",
        "Mỗi việc xong, phiên tập trung, nhật ký hoặc bài thở trong ngày nạp \(Adventure.energyPerActivity)% năng lượng. Đủ 100%, thú cưng đi chơi và về kể chuyện: +\(adventureXP) XP, +\(adventureCoins) xu, một lần mỗi ngày.",
        "Một số hình dạng và trang phục mở khóa theo cấp. Cấp không bao giờ bị giảm.",
        "Mèo không bao giờ ốm, buồn bỏ đi hay mất đồ khi bạn nghỉ vài ngày."
    ]
}
