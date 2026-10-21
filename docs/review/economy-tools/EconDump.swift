import Foundation
// Xuất toàn bộ danh mục + bộ phối + đồ ăn + pool gacha ra JSON (đọc thẳng từ code Core).
var items: [[String: Any]] = []
for it in Catalog.items {
    items.append([
        "id": it.id, "slot": it.slot.rawValue, "room": it.slot.roomKind?.rawValue ?? "pet",
        "isFloor": it.slot.isFloor, "isTheme": it.slot.isTheme,
        "name": it.name, "price": it.price, "requiredLevel": it.requiredLevel,
        "rarity": it.rarity.rawValue, "tier": it.tier.rawValue, "gachaOnly": it.gachaOnly,
        "isDefault": it.isDefault, "variantOf": it.variantOf ?? "",
        "inPetItems": Catalog.petItems.contains { $0.id == it.id },
        "inRoomItems": Catalog.roomItems.contains { $0.id == it.id }
    ])
}
var pool: [String: [String]] = [:]
for (k, v) in GachaPolicy.pool() { pool[k.rawValue] = v.map(\.id) }
let looks = PetLooks.all.map { ["id": $0.id, "items": $0.itemIDs, "requiredLevel": $0.requiredLevel, "cost": $0.cost(owned: [])] as [String: Any] }
let foods = FoodCatalog.all.map { ["id": $0.id, "price": $0.price, "fullness": $0.fullness, "happiness": $0.happiness] as [String: Any] }
let rooms = RoomKind.allCases.map { ["id": $0.rawValue, "requiredLevel": $0.requiredLevel] as [String: Any] }
let dup = ItemRarity.allCases.map { [$0.rawValue: GachaConfig.duplicateRefund($0)] }
let out: [String: Any] = ["items": items, "pool": pool, "looks": looks, "foods": foods, "rooms": rooms,
    "gacha": ["single": GachaConfig.singlePrice, "ten": GachaConfig.tenPrice, "epicPity": GachaConfig.epicPity,
              "secretPity": GachaConfig.secretPity, "weights": GachaConfig.weights.map { [$0.0.rawValue: $0.1] }, "dup": dup],
    "reward": ["taskXP": RewardConfig.taskXP, "taskCoins": RewardConfig.taskCoins, "taskPerDay": RewardConfig.taskRewardsPerDay,
               "focus25": [RewardConfig.focusReward(plannedMinutes: 25).xp, RewardConfig.focusReward(plannedMinutes: 25).coins],
               "focus120": [RewardConfig.focusReward(plannedMinutes: 120).xp, RewardConfig.focusReward(plannedMinutes: 120).coins],
               "minigameCap": MinigameConfig.dailyCoinCap, "minigamePerRun": MinigameConfig.maxCoinsPerRun,
               "careCoinCap": CareConfig.dailyCoinCap, "careXPCap": CareConfig.dailyXPCap]]
var exported = out
exported["badges"] = CozyBadge.all.map { ["id": $0.id, "metric": String(describing: $0.metric), "target": $0.target, "coins": $0.coins] as [String: Any] }
exported["events"] = VietnameseEvents.all.map { ["id": $0.id, "start": $0.start.string, "end": $0.end.string, "coins": $0.coins] as [String: Any] }
let data = try! JSONSerialization.data(withJSONObject: exported, options: [.prettyPrinted, .sortedKeys])
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
print("items:", Catalog.items.count)
