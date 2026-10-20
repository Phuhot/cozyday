import Foundation

/// Kỷ vật mang về từ chuyến đi, trưng bày được trong phòng.
/// Nội dung kỷ niệm (tên thú cưng, loài, câu chuyện, ngày) được CHỤP LẠI lúc nhận và không đổi về sau,
/// kể cả khi bạn đổi tên hay đổi loài thú cưng.
struct KeepsakeRecord: Codable, Equatable, Identifiable {
    var id: UUID
    /// Nguồn duy nhất (ví dụ "adventure:2026-10-20"): mỗi chuyến đi cho tối đa một kỷ vật.
    var sourceKey: String
    /// Mã hình vẽ kỷ vật (xem `KeepsakeArt`).
    var artID: String
    var title: String
    var story: String
    var day: DayKey
    var petName: String
    var species: String
    var createdAt: Date
    /// Phòng đang trưng bày (RoomKind.rawValue), nil = cất trong hộp.
    var placedRoom: String?
}
