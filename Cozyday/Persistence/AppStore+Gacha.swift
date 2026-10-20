import Foundation

extension AppStore {
    static let unseenGachaKey = "gacha.unseenBatch"

    /// Quay máy gacha `count` lượt (1 hoặc 10) bằng xu hoặc vé. Trong MỘT lần lưu: trừ xu/vé, ghi từng lượt
    /// (kết quả + bộ đếm bảo đảm nằm trong sổ cái), thêm món mới vào kho; món trùng đổi thành xu.
    /// Kết quả được lưu TRƯỚC khi chạy hoạt ảnh, và đánh dấu "chưa xem" để mở lại app vẫn xem lại đúng kết quả đó.
    @discardableResult
    func pullGacha(count: Int, payment: GachaPayment = .coins) throws -> [GachaPull] {
        var rng = SystemRandomNumberGenerator()
        var pulls: [GachaPull] = []
        try commit {
            // Quyết định bên trong lần ghi: bấm nhanh hai lần thì lần sau thấy số dư đã trừ.
            do {
                // Dữ liệu thử nghiệm coi mọi món là "đã có": máy vẫn dùng kho THẬT để thử được luồng nhận món mới.
                pulls = try GachaPolicy.pull(count: count, ledger: self.ledger, owned: self.realOwnedIDs, now: self.now,
                                             payment: payment, rng: &rng)
            } catch let error as GachaError {
                throw StoreError.invalid(error.errorDescription ?? "Không quay được.")
            }
            for p in pulls {
                self.insertLedger(p.entry)
                guard !p.isDuplicate, !Catalog.isOwned(p.itemID, owned: self.realOwnedIDs) else { continue }
                let record = OwnedItemRecord(itemID: p.itemID, acquiredAt: self.now, transactionID: p.entry.id)
                self.context.insert(OwnedItemModel(record: record))
                self.owned.append(record)
            }
        }
        markGachaUnseen(pulls.map(\.entry.id))
        return pulls
    }

    var gachaPity: (sinceEpic: Int, sinceSecret: Int) { GachaPolicy.pityCounters(ledger: ledger) }

    // MARK: Kết quả chưa xem

    /// Lượt quay đã lưu nhưng chưa xem hết màn kết quả (app bị đóng / bỏ qua giữa chừng).
    /// Đọc lại từ sổ cái, không quay lại.
    var unseenGachaPulls: [GachaPull] {
        guard let raw = defaults.array(forKey: Self.unseenGachaKey) as? [String] else { return [] }
        let ids = Set(raw.compactMap(UUID.init(uuidString:)))
        guard !ids.isEmpty else { return [] }
        return ledger.filter { $0.kind == .gacha && ids.contains($0.id) }.compactMap { e in
            guard let itemID = e.refID, let item = Catalog.item(itemID) else { return nil }
            // Dòng gacha ghi "(trùng, +N xu)" khi món trùng: đọc lại đúng như lúc quay.
            let duplicate = e.memo.contains("(trùng")
            return GachaPull(itemID: itemID, tier: item.tier, isDuplicate: duplicate,
                             refund: duplicate ? GachaConfig.duplicateRefund(item.tier) : 0, entry: e)
        }
    }

    func markGachaUnseen(_ ids: [UUID]) {
        defaults.set(ids.map(\.uuidString), forKey: Self.unseenGachaKey)
    }

    func markGachaSeen() {
        defaults.removeObject(forKey: Self.unseenGachaKey)
    }
}
