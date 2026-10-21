import Foundation
import SwiftData

/// Kết quả lưu một lượt Sân chơi.
struct MinigameSave: Equatable {
    var record: MinigameResultRecord
    /// Kỷ lục mới của game này.
    var isNewBest: Bool
    /// false: lượt này đã được lưu từ trước (gọi lại cùng sessionID) — không thưởng thêm.
    var isNew: Bool
}

extension AppStore {
    func minigameResult(_ sessionID: UUID) -> MinigameResultRecord? {
        minigameResults.first { $0.id == sessionID }
    }

    func bestResult(_ kind: MinigameKind) -> MinigameResultRecord? {
        MinigamePolicy.best(kind, results: minigameResults)
    }

    /// Xu Sân chơi đã nhận trong `day` — tính từ sổ cái (nguồn sự thật về tiền, không bị cắt bớt).
    func minigameCoins(on day: DayKey) -> Int {
        ledger.filter { $0.kind == .minigame && DayKey($0.createdAt, calendar: calendar) == day }.reduce(0) { $0 + $1.coins }
    }

    var recentMinigames: [MinigameResultRecord] {
        Array(minigameResults.sorted { $0.finishedAt > $1.finishedAt }.prefix(5))
    }

    private func isNewBest(_ r: MinigameResultRecord) -> Bool {
        !minigameResults.contains { $0.kind == r.kind && $0.id != r.id && $0.score >= r.score && $0.finishedAt <= r.finishedAt }
    }

    /// Lưu kết quả lượt + dòng thưởng `minigame:<sessionID>` trong cùng một lần ghi.
    /// Gọi lại với cùng sessionID (bấm nhận nhiều lần, mở lại màn kết quả, thử lại sau lỗi) không cộng thêm.
    /// Hạn mức tính theo ngày địa phương lúc lượt kết thúc.
    @discardableResult
    func recordMinigame(_ outcome: MinigameOutcome) throws -> MinigameSave {
        if let existing = minigameResult(outcome.sessionID) {
            return MinigameSave(record: existing, isNewBest: isNewBest(existing), isNew: false)
        }
        // Không tin mốc thời gian tương lai từ màn chơi.
        let finished = min(outcome.finishedAt, now)
        let day = DayKey(finished, calendar: calendar)
        let reward = MinigamePolicy.reward(for: outcome, awardedToday: minigameCoins(on: day))
        let record = MinigameResultRecord(
            id: outcome.sessionID, kind: outcome.kind, score: outcome.score, primary: outcome.primary,
            secondary: outcome.secondary, level: outcome.level, activeSeconds: outcome.activeSeconds,
            species: outcome.species, startedAt: min(outcome.startedAt, finished), finishedAt: finished, day: day,
            coins: reward.coins, earned: reward.earned, note: reward.note
        )
        let key = LedgerKeys.minigame(outcome.sessionID)
        let wasBest = isNewBest(record)
        try commit {
            self.context.insert(MinigameResultModel(record: record))
            self.minigameResults.append(record)
            if record.note != .implausible && record.note != .notCompleted {
                self.recordMeaningfulDay(day)
                let marker = "system:game-complete:\(outcome.sessionID.uuidString)"
                if !self.ledgerKeys.contains(marker) {
                    self.insertLedger(LedgerEntry(id: UUID(), key: marker, kind: .system, xp: 0, coins: 0,
                        createdAt: finished, refID: day.string, memo: outcome.kind.name))
                }
            }
            if reward.coins > 0, !self.ledgerKeys.contains(key) {
                self.insertLedger(LedgerEntry(id: UUID(), key: key, kind: .minigame, xp: 0, coins: reward.coins,
                                              createdAt: finished, refID: outcome.sessionID.uuidString.lowercased(),
                                              memo: outcome.kind.name))
            }
            // Cắt bớt lịch sử cũ: giữ 200 lượt mới nhất, mọi lượt 3 ngày gần đây và kỷ lục từng game.
            let keep = MinigamePolicy.retained(self.minigameResults, since: self.now.addingTimeInterval(-3 * 86400))
            if keep.count < self.minigameResults.count {
                for m in try self.context.fetch(FetchDescriptor<MinigameResultModel>()) where !keep.contains(m.id) {
                    self.context.delete(m)
                }
                self.minigameResults.removeAll { !keep.contains($0.id) }
            }
        }
        return MinigameSave(record: record, isNewBest: wasBest, isNew: true)
    }
}
