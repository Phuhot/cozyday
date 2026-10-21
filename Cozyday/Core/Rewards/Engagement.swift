import Foundation

struct CozyBadge: Identifiable, Equatable {
    enum Metric { case care, focus, games, collection, adventures, days }
    let id: String
    let title: String
    let metric: Metric
    let target: Int
    let condition: String
    let coins: Int
    static let all: [CozyBadge] = [
        .init(id:"care10",title:"Bàn tay dịu dàng",metric:.care,target:10,condition:"Chăm bạn nhỏ 10 lần",coins:10),
        .init(id:"focus60",title:"Một giờ cho mình",metric:.focus,target:60,condition:"Hoàn thành 60 phút tập trung",coins:15),
        .init(id:"games10",title:"Bạn sân chơi",metric:.games,target:10,condition:"Chơi trọn 10 lượt hợp lệ",coins:10),
        .init(id:"collection10",title:"Chiếc tủ đầu tiên",metric:.collection,target:10,condition:"Sở hữu 10 món ngoài đồ mặc định",coins:10),
        .init(id:"adventures5",title:"Những bước chân nhỏ",metric:.adventures,target:5,condition:"Mang về 5 chuyến đi",coins:15),
        .init(id:"days7",title:"Bảy ngày bên nhau",metric:.days,target:7,condition:"Tương tác có ý nghĩa ở 7 ngày, không cần liên tiếp",coins:15),
        .init(id:"days30",title:"Một tháng kỷ niệm",metric:.days,target:30,condition:"Tương tác có ý nghĩa ở 30 ngày, không cần liên tiếp",coins:25)
    ]
}

/// Vietnamese festival dates, explicitly scheduled per year, never a repeating solar date for lunar holidays.
/// The current edition covers 2025–2027. Windows and claims use Asia/Ho_Chi_Minh regardless of travel.
struct CozyEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let start: DayKey
    let end: DayKey
    let artID: String
    let keepsakeTitle: String
    let quests: [DailyQuest]
    let coins: Int
    func contains(_ day: DayKey) -> Bool { day >= start && day <= end }
}

enum VietnameseEvents {
    static var calendar: Calendar { Calendar.gregorian(timeZone: TimeZone(identifier:"Asia/Ho_Chi_Minh")!) }
    static let supportedYears = 2025...2027
    // Tet / full moon of the eighth lunar month, Gregorian dates in Vietnam.
    static let dates: [(Int, String, String)] = [
        (2025,"2025-01-29","2025-10-06"),
        (2026,"2026-02-17","2026-09-25"),
        (2027,"2027-02-06","2027-09-15")
    ]
    static let all: [CozyEvent] = dates.flatMap { year, tet, moon in
        let themes = [("tet", "Tết bên bạn nhỏ", tet, "envelope", "Bao lì xì hoa mai"),
                      ("midautumn", "Đêm đèn lồng", moon, "lantern", "Đèn trăng kỷ niệm"),
                      ("oct20", "Một lời cảm ơn", "\(year)-10-20", "flower", "Lọ hoa yêu thương")]
        return themes.map { theme in
            let day = DayKey(string:theme.2)!
            return CozyEvent(id:"\(theme.0)-\(year)", title:theme.1,
                start:day.adding(days:-3,calendar:calendar),end:day.adding(days:3,calendar:calendar),
                artID:theme.3,keepsakeTitle:theme.4,
                quests:[DailyQuest(kind:.care,target:2),DailyQuest(kind:.focus,target:10),DailyQuest(kind:.journal,target:1)],coins:15)
        }
    }
    static func active(at date: Date) -> [CozyEvent] { all.filter { $0.contains(DayKey(date,calendar:calendar)) } }
    static func claimable(_ event: CozyEvent, now: Date, activity: DayActivity, keys: Set<String>) -> Bool {
        event.contains(DayKey(now,calendar:calendar)) && event.quests.allSatisfy(activity.isDone)
            && !keys.contains(LedgerKeys.event(event.id,"complete"))
    }
}

extension PetSpecies {
    /// Basic, familiar silhouettes. Only the chosen animal is granted; rare species stay in progression/gacha.
    static let starters: [PetSpecies] = [.cat, .bunny, .hamster, .puppy]
}
