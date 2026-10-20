import Foundation

/// Mã nhập trong phần ẩn của Cài đặt. Đây chỉ là tiện ích cho chủ dự án thử app trên máy của mình,
/// KHÔNG phải cơ chế xác thực: ai biết mã đều nhập được (mã nằm ngay trong app).
enum GiftCodes {
    /// Mã quà: 10.000 xu, mỗi bộ dữ liệu nhận một lần (khóa cố định `gift:t3ster`).
    static let t3ster = "t3ster"
    static let t3sterCoins = 10_000
    /// Bản trước phiên 9: mỗi lần nhập t3ster ghi một dòng `gift:<uuid>`, 1.000 xu, ghi chú "Mã quà".
    /// Không có mã quà nào khác từng tồn tại, nên dòng gift mang đúng dấu vết đó là một lần đổi t3ster cũ.
    static let legacyT3sterCoins = 1_000
    static let legacyMemo = "Mã quà"

    /// Mã bật chế độ "Dữ liệu thử nghiệm" (mở khóa toàn bộ nội dung để kiểm tra).
    static let tester = "phuhotdz"

    enum Kind: Equatable {
        case coins
        case testerMode
    }

    static func normalize(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func kind(of code: String) -> Kind? {
        switch normalize(code) {
        case t3ster: return .coins
        case tester: return .testerMode
        default: return nil
        }
    }

    /// Tổng xu đã nhận từ các lần đổi t3ster theo cách cũ (dựa trên dấu vết trong sổ cái, không đoán từ số dư).
    static func legacyT3sterReceived<S: Sequence>(_ ledger: S) -> Int where S.Element == LedgerEntry {
        ledger.reduce(0) { sum, e in
            e.kind == .gift && e.key != LedgerKeys.giftT3ster && e.key.hasPrefix("gift:")
                && e.memo == legacyMemo && e.coins == legacyT3sterCoins ? sum + e.coins : sum
        }
    }

    /// Dòng nhận/bù t3ster: tổng quyền lợi của mã là 10.000 xu cho mỗi bộ dữ liệu.
    /// - Chưa từng đổi: 10.000 xu.
    /// - Đã đổi bản cũ (mỗi lần 1.000 xu): bù phần còn thiếu, ví dụ đổi một lần → 9.000 xu.
    /// - Đã nhận đủ hoặc hơn ở bản cũ (nhập lại nhiều lần): ghi dòng 0 xu để khóa mã, không thu hồi.
    /// nil khi khóa `gift:t3ster` đã có (đã nhận/bù rồi).
    static func t3sterEntry<S: Sequence>(ledger: S, existingKeys: Set<String>, now: Date, isTopUp: Bool) -> LedgerEntry?
    where S.Element == LedgerEntry {
        guard !existingKeys.contains(LedgerKeys.giftT3ster) else { return nil }
        let received = legacyT3sterReceived(ledger)
        let coins = max(0, t3sterCoins - received)
        let memo = isTopUp
            ? "Bù mã t3ster (bản cũ đã nhận \(received) xu, tổng \(t3sterCoins) xu)"
            : (received > 0 ? "Mã t3ster (đã nhận \(received) xu ở bản cũ)" : "Mã t3ster")
        return LedgerEntry(id: UUID(), key: LedgerKeys.giftT3ster, kind: .gift, xp: 0, coins: coins,
                           createdAt: now, refID: t3ster, memo: memo)
    }
}
