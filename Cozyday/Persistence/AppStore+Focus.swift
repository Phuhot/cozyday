import Foundation

extension AppStore {
    var activeFocus: FocusSessionRecord? {
        focusSessions.last { $0.isActive }
    }

    func startFocus(kind: FocusKind, minutes: Int, occurrenceID: UUID?) throws {
        guard FocusPresets.customRange.contains(minutes) else {
            throw StoreError.invalid("Thời lượng cần từ \(FocusPresets.customRange.lowerBound) đến \(FocusPresets.customRange.upperBound) phút.")
        }
        guard activeFocus == nil else { throw StoreError.invalid("Đang có một phiên chạy. Kết thúc phiên đó trước.") }
        let session = FocusSessionRecord.start(kind: kind, minutes: minutes, occurrenceID: occurrenceID, now: now)
        try commit {
            self.context.insert(FocusSessionModel(record: session))
            self.focusSessions.append(session)
        }
    }

    func pauseFocus() throws {
        guard var s = activeFocus else { return }
        if s.reconcile(at: now) { _ = try finish(s); return }
        s.pause(at: now)
        try saveFocus(s)
    }

    func resumeFocus() throws {
        guard var s = activeFocus else { return }
        s.resume(at: now)
        try saveFocus(s)
    }

    /// Kết thúc sớm. Nếu thực ra đã hết giờ thì tính là hoàn thành (và có thưởng).
    @discardableResult
    func endFocusEarly() throws -> LedgerEntry? {
        guard var s = activeFocus else { return nil }
        s.endEarly(at: now)
        return try finish(s)
    }

    /// Chế độ nghiêm: rời app quá lâu thì phiên dừng ở thời điểm vượt giới hạn (không phải lúc mở lại app).
    /// Nếu phiên đã hết giờ trước thời điểm đó thì vẫn tính là hoàn thành.
    @discardableResult
    func breakFocus(at moment: Date) throws -> LedgerEntry? {
        guard var s = activeFocus else { return nil }
        s.endEarly(at: min(max(moment, s.startedAt), now))
        return try finish(s)
    }

    func pomodoroDay(settings: PomodoroSettings) -> PomodoroDay {
        PomodoroDay.compute(sessions: focusSessions, day: today, calendar: calendar, settings: settings)
    }

    /// Gọi khi mở lại app / khi đồng hồ trên màn hình về 0. Kết thúc + thưởng đúng một lần.
    @discardableResult
    func reconcileFocus() throws -> LedgerEntry? {
        guard var s = activeFocus, s.reconcile(at: now) else { return nil }
        return try finish(s)
    }

    private func finish(_ s: FocusSessionRecord) throws -> LedgerEntry? {
        var granted: LedgerEntry?
        try commit {
            try self.focusModel(s.id).apply(s)
            self.replaceFocus(s)
            if s.isRewardEligible,
               let entry = RewardPolicy.forFocus(sessionID: s.id, plannedMinutes: s.plannedMinutes, existingKeys: self.ledgerKeys, now: self.now,
                                                 rewardedMinutesToday: RewardPolicy.focusRewardedMinutesToday(self.ledger, now: self.now, calendar: self.calendar)) {
                self.insertLedger(entry)
                granted = entry
            }
        }
        return granted
    }

    private func saveFocus(_ s: FocusSessionRecord) throws {
        try commit {
            try self.focusModel(s.id).apply(s)
            self.replaceFocus(s)
        }
    }

    private func replaceFocus(_ s: FocusSessionRecord) {
        if let i = focusSessions.firstIndex(where: { $0.id == s.id }) {
            focusSessions[i] = s
        }
    }
}
