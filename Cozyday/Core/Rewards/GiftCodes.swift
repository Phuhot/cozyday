import Foundation

/// Mã quà ẩn trong Cài đặt (dành cho người làm app thử nghiệm). Nhập lại được nhiều lần.
enum GiftCodes {
    static let codes: [String: Int] = ["t3ster": 1000]

    /// Số xu của mã (không phân biệt hoa thường, bỏ khoảng trắng hai đầu), nil nếu mã sai.
    static func coins(for code: String) -> Int? {
        codes[code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }

    static func entry(code: String, now: Date) -> LedgerEntry? {
        guard let coins = coins(for: code) else { return nil }
        let id = UUID()
        return LedgerEntry(id: id, key: LedgerKeys.gift(id), kind: .gift, xp: 0, coins: coins,
                           createdAt: now, refID: nil, memo: "Mã quà")
    }
}
