import Foundation

extension AppStore {
    static let unseenGachaKey = "gacha.unseenBatch" // compatibility with the unpublished V9 draft
    private static func pendingKey(_ id: UUID) -> String { "system:gacha-pending:\(id.uuidString)" }
    private static func seenKey(_ id: UUID) -> String { "system:gacha-seen:\(id.uuidString)" }

    /// Payment, result, inventory, pity and the recovery marker share one SwiftData save.
    @discardableResult
    func pullGacha(count: Int, payment: GachaPayment = .coins) throws -> [GachaPull] {
        var rng = SystemRandomNumberGenerator()
        var pulls: [GachaPull] = []
        try commit {
            guard self.unseenGachaPulls.isEmpty else {
                throw StoreError.invalid("Hãy xem kết quả đã lưu trước khi quay tiếp.")
            }
            do {
                pulls = try GachaPolicy.pull(count: count, ledger: self.ledger, owned: self.realOwnedIDs,
                                             now: self.now, payment: payment, rng: &rng)
            } catch let error as GachaError {
                throw StoreError.invalid(error.errorDescription ?? "Không quay được.")
            }
            for p in pulls {
                self.insertLedger(p.entry)
                self.insertLedger(LedgerEntry(id: UUID(), key: Self.pendingKey(p.entry.id), kind: .system,
                    xp: 0, coins: 0, createdAt: self.now, refID: p.entry.id.uuidString, memo: "Kết quả chưa xem"))
                if !p.isDuplicate, !Catalog.isOwned(p.itemID, owned: self.realOwnedIDs) {
                    let record = OwnedItemRecord(itemID: p.itemID, acquiredAt: self.now, transactionID: p.entry.id)
                    self.context.insert(OwnedItemModel(record: record))
                    self.owned.append(record)
                }
            }
        }
        return pulls
    }

    var gachaPity: (sinceEpic: Int, sinceSecret: Int) { GachaPolicy.pityCounters(ledger: ledger) }

    var unseenGachaPulls: [GachaPull] {
        let legacy = Set((defaults.array(forKey: Self.unseenGachaKey) as? [String] ?? []).compactMap(UUID.init(uuidString:)))
        let keys = ledgerKeys
        return ledger.filter {
            $0.kind == .gacha && (keys.contains(Self.pendingKey($0.id)) || legacy.contains($0.id))
                && !keys.contains(Self.seenKey($0.id))
        }.compactMap { e in
            guard let itemID = e.refID, let item = Catalog.item(itemID) else { return nil }
            let duplicate = e.memo.contains("(trùng")
            return GachaPull(itemID: itemID, tier: item.tier, isDuplicate: duplicate,
                             refund: duplicate ? GachaConfig.duplicateRefund(item.tier) : 0, entry: e)
        }
    }

    /// Acknowledgement is backed up with the ledger. A failed save leaves the result recoverable.
    func markGachaSeen() throws {
        let pending = unseenGachaPulls
        guard !pending.isEmpty else { return }
        try commit {
            for p in pending {
                self.insertLedger(LedgerEntry(id: UUID(), key: Self.seenKey(p.entry.id), kind: .system,
                    xp: 0, coins: 0, createdAt: self.now, refID: p.entry.id.uuidString, memo: "Đã xem kết quả"))
            }
        }
        defaults.removeObject(forKey: Self.unseenGachaKey)
    }
}
