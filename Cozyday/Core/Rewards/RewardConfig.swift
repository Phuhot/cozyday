import Foundation

/// Mọi con số về thưởng tập trung ở đây.
enum RewardConfig {
    /// Hoàn thành một lần việc (lần đầu tiên).
    static let taskXP = 10
    static let taskCoins = 8
    /// Số việc được thưởng mỗi ngày (theo ngày hoàn thành). Việc thứ 11 trở đi vẫn ghi nhận nhưng không có XP/xu:
    /// tạo thật nhiều việc rồi tick liên tục không còn là cách "cày" xu.
    static let taskRewardsPerDay = 10

    /// Phiên tập trung hoàn thành đủ thời lượng: thưởng theo số phút đã đặt.
    static let focusMinMinutesForReward = 10
    static let focusXPPerFiveMinutes = 2
    static let focusCoinsPerFiveMinutes = 2
    static let focusMaxRewardMinutes = 120
    /// Tổng số phút tập trung có thưởng mỗi ngày (4 giờ). Tập trung thêm vẫn được ghi vào thống kê.
    static let focusDailyRewardMinutes = 240
    /// Nhật ký chỉ có thưởng khi viết cho hôm nay hoặc hôm qua (viết bù ngày cũ hơn vẫn lưu, không có xu).
    static let journalRewardDaysBack = 1

    /// Viết nhật ký: một lần mỗi ngày.
    static let journalXP = 5
    static let journalCoins = 5

    /// Bài thở: một lần mỗi ngày.
    static let breathingXP = 3
    static let breathingCoins = 3

    /// Nghe thú cưng kể chuyến phiêu lưu (khi đủ năng lượng): một lần mỗi ngày.
    static let adventureXP = 5
    static let adventureCoins = 10

    /// XP cho mỗi cấp của mèo.
    static let xpPerLevel = 100

    static func focusReward(plannedMinutes: Int) -> (xp: Int, coins: Int) {
        guard plannedMinutes >= focusMinMinutesForReward else { return (0, 0) }
        let blocks = min(plannedMinutes, focusMaxRewardMinutes) / 5
        return (blocks * focusXPPerFiveMinutes, blocks * focusCoinsPerFiveMinutes)
    }

    /// Quy tắc hiển thị trong app (Cài đặt → Quy tắc phần thưởng).
    static let rulesText: [String] = [
        "Hoàn thành một việc lần đầu: +\(taskXP) XP, +\(taskCoins) xu. Mỗi ngày tối đa \(taskRewardsPerDay) việc có thưởng; việc xong sau đó vẫn được ghi nhận.",
        "Bỏ đánh dấu hoàn thành hoặc xóa việc không thu hồi phần thưởng đã nhận.",
        "Hoàn thành lại chính lần việc đó không nhận thêm thưởng.",
        "Phiên tập trung từ \(focusMinMinutesForReward) phút trở lên, chạy hết giờ: +\(focusXPPerFiveMinutes) XP và +\(focusCoinsPerFiveMinutes) xu cho mỗi 5 phút (tối đa \(focusMaxRewardMinutes) phút một phiên, \(focusDailyRewardMinutes / 60) giờ có thưởng mỗi ngày).",
        "Kết thúc sớm: không có thưởng, nhưng số phút đã tập trung vẫn được tính vào thống kê. Thời gian tạm dừng không được tính.",
        "Viết nhật ký: +\(journalXP) XP, +\(journalCoins) xu, một lần mỗi ngày (hôm nay hoặc hôm qua; viết bù ngày cũ hơn không có thưởng).",
        "Làm bài thở: +\(breathingXP) XP, +\(breathingCoins) xu, một lần mỗi ngày.",
        "Mỗi việc xong, phiên tập trung, nhật ký hoặc bài thở trong ngày nạp \(Adventure.energyPerActivity)% năng lượng. Đủ 100%, thú cưng đi chơi và về kể chuyện: +\(adventureXP) XP, +\(adventureCoins) xu, một lần mỗi ngày.",
        "Một số hình dạng và trang phục mở khóa theo cấp. Cấp không bao giờ bị giảm.",
        "Thú cưng không bao giờ ốm, bỏ đi, mất cấp hay mất đồ khi bạn nghỉ vài ngày."
    ]
}
