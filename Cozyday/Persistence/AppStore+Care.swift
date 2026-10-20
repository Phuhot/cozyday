import Foundation
import SwiftData

extension AppStore {
    // MARK: Nhu cầu

    /// Chỉ số hiện tại (tính suy giảm từ bản đã lưu, không ghi gì).
    var currentNeeds: PetNeeds { petCare.needs.at(now) }

    func foodCount(_ foodID: String) -> Int {
        foodStock.first { $0.foodID == foodID }?.count ?? 0
    }

    var totalFood: Int { foodStock.reduce(0) { $0 + $1.count } }

    func careAction(_ id: UUID) -> CareActionRecord? {
        careActions.first { $0.id == id }
    }

    /// Thưởng chăm sóc đã nhận hôm nay.
    var careTotalsToday: (xp: Int, coins: Int) { CarePolicy.todayTotals(day: today, history: careActions) }

    func rewardedCareCount(_ kind: CareActionKind, on day: DayKey) -> Int {
        careActions.filter { $0.day == day && $0.kind == kind && $0.isRewarded }.count
    }

    /// Chăm sóc một lần: cập nhật nhu cầu, trừ một món ăn (nếu cho ăn), lưu lịch sử và thưởng — trong cùng một lần lưu.
    /// Gọi lại với cùng `actionID` (thử lại, bấm nhanh hai lần) trả về bản ghi cũ, không làm lại.
    @discardableResult
    func performCare(_ kind: CareActionKind, foodID: String? = nil, actionID: UUID) throws -> CareActionRecord {
        if let done = careAction(actionID) { return done }
        if kind == .feed {
            guard let foodID, FoodCatalog.item(foodID) != nil else { throw CareError.unknownFood }
            guard foodCount(foodID) > 0 else { throw CareError.noFood }
        }
        let outcome = try CarePolicy.perform(kind, foodID: foodID, actionID: actionID, stored: petCare.needs, now: now,
                                             day: today, history: careActions, existingKeys: ledgerKeys)
        let cutoff = today.adding(days: -CareConfig.historyDays, calendar: calendar)
        try commit {
            guard let model = try self.fetchPetCareModel() else { throw StoreError.notFound }
            var care = self.petCare
            care.needs = outcome.needs
            model.apply(care)
            self.petCare = care
            if kind == .feed, let foodID {
                try self.changeStock(foodID, by: -1)
            }
            self.context.insert(CareActionModel(record: outcome.record))
            self.careActions.append(outcome.record)
            if let entry = outcome.ledger { self.insertLedger(entry) }
            // Chỉ giữ lịch sử chăm sóc gần đây (thưởng đã nằm trong sổ cái).
            for old in try self.context.fetch(FetchDescriptor<CareActionModel>()) {
                if let day = DayKey(string: old.dayRaw), day < cutoff { self.context.delete(old) }
            }
            self.careActions.removeAll { $0.day < cutoff }
        }
        return outcome.record
    }

    /// Mua đồ ăn: trừ xu (dòng `food-purchase:<transactionID>`) và tăng số lượng trong cùng một lần lưu.
    /// Thử lại với cùng `transactionID` không trừ xu hay tăng số lượng lần hai. Trả về false nếu giao dịch đã có.
    @discardableResult
    func buyFood(_ foodID: String, quantity: Int = 1, transactionID: UUID) throws -> Bool {
        guard let entry = try FoodShopPolicy.purchase(foodID: foodID, quantity: quantity, transactionID: transactionID,
                                                      coins: wallet.coins, stock: foodCount(foodID),
                                                      existingKeys: ledgerKeys, now: now) else { return false }
        try commit {
            self.insertLedger(entry)
            try self.changeStock(foodID, by: quantity)
        }
        return true
    }

    private func changeStock(_ foodID: String, by delta: Int) throws {
        let id = foodID
        let models = try context.fetch(FetchDescriptor<FoodStockModel>(predicate: #Predicate { $0.foodID == id }))
        let current = models.reduce(0) { $0 + $1.count }
        let next = current + delta
        guard next >= 0 else { throw CareError.noFood }
        guard next <= FoodCatalog.maxStock else { throw CareError.stockFull }
        if let first = models.first {
            first.count = next
            models.dropFirst().forEach { context.delete($0) }
        } else {
            context.insert(FoodStockModel(foodID: foodID, count: next))
        }
        foodStock.removeAll { $0.foodID == foodID }
        foodStock.append(FoodStockRecord(foodID: foodID, count: next))
    }
}
