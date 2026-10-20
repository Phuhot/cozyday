import Foundation

extension AppStore {
    /// Quay máy gacha `count` lượt (1 hoặc 10): trừ xu, thêm món mới vào kho, món trùng đổi thành xu. Lưu một lần.
    @discardableResult
    func pullGacha(count: Int) throws -> [GachaPull] {
        var rng = SystemRandomNumberGenerator()
        let pulls: [GachaPull]
        do {
            pulls = try GachaPolicy.pull(count: count, ledger: ledger, owned: ownedIDs, now: now, rng: &rng)
        } catch let error as GachaError {
            throw StoreError.invalid(error.errorDescription ?? "Không quay được.")
        }
        try commit {
            for p in pulls {
                self.insertLedger(p.entry)
                guard !p.isDuplicate, !Catalog.isOwned(p.itemID, owned: self.ownedIDs) else { continue }
                let record = OwnedItemRecord(itemID: p.itemID, acquiredAt: self.now, transactionID: p.entry.id)
                self.context.insert(OwnedItemModel(record: record))
                self.owned.append(record)
            }
        }
        return pulls
    }

    var gachaPity: (sinceEpic: Int, sinceSecret: Int) { GachaPolicy.pityCounters(ledger: ledger) }

    /// Nhập mã quà. Trả về số xu nhận được.
    @discardableResult
    func redeemGiftCode(_ code: String) throws -> Int {
        guard let entry = GiftCodes.entry(code: code, now: now) else { throw StoreError.invalid("Mã không đúng.") }
        try commit { self.insertLedger(entry) }
        return entry.coins
    }
}
