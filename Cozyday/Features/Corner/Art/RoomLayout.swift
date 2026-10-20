import SwiftUI

/// Vị trí đặt đồ trong từng phòng, theo hệ tọa độ của phòng 125×100 (tường ở trên y = 62).
/// Mỗi món đồ là một ô vuông `size`×`size` (đồ được vẽ trong 100×100 rồi thu nhỏ đều).
enum RoomLayout {
    static let width: CGFloat = 125
    static let aspect: CGFloat = 1.25

    struct Spot {
        let x: CGFloat, y: CGFloat, size: CGFloat
    }

    static func spot(_ slot: ItemSlot) -> Spot? {
        switch slot {
        // Phòng học
        case .wall: return Spot(x: 10, y: 6, size: 32)
        case .lamp: return Spot(x: 90, y: 30, size: 34)
        case .desk: return Spot(x: 62, y: 34, size: 40)
        case .plant: return Spot(x: 2, y: 50, size: 28)
        case .seat: return Spot(x: 22, y: 52, size: 46)
        // Phòng ngủ
        case .closet: return Spot(x: 2, y: 20, size: 42)
        case .bedroomWall: return Spot(x: 72, y: 4, size: 34)
        case .bed: return Spot(x: 64, y: 38, size: 58)
        case .nightstand: return Spot(x: 44, y: 42, size: 26)
        case .bedroomRug: return Spot(x: 20, y: 54, size: 48)
        case .plush: return Spot(x: 4, y: 72, size: 24)
        // Bếp
        case .kitchenWall: return Spot(x: 8, y: 6, size: 32)
        case .fridge: return Spot(x: 80, y: 12, size: 56)
        case .stove: return Spot(x: 54, y: 30, size: 40)
        case .dining: return Spot(x: 4, y: 40, size: 46)
        case .treat: return Spot(x: 16, y: 39, size: 22)
        // Phòng tắm
        case .bathShelf: return Spot(x: 8, y: 6, size: 30)
        case .sink: return Spot(x: 2, y: 26, size: 44)
        case .tub: return Spot(x: 62, y: 30, size: 60)
        case .bathMat: return Spot(x: 28, y: 56, size: 40)
        case .bathToy: return Spot(x: 100, y: 76, size: 20)
        // Vườn
        case .tree: return Spot(x: 0, y: 2, size: 60)
        case .gardenSeat: return Spot(x: 48, y: 28, size: 38)
        case .gardenDeco: return Spot(x: 88, y: 26, size: 38)
        case .flowerBed: return Spot(x: 2, y: 66, size: 32)
        case .pond: return Spot(x: 78, y: 56, size: 46)
        default: return nil
        }
    }

    /// Thứ tự vẽ: đồ ở xa (trên cao) trước, đồ ở gần (đáy thấp hơn) sau.
    static func drawOrder(_ room: RoomKind) -> [ItemSlot] {
        room.slots.filter { !$0.isScene }.sorted {
            guard let a = spot($0), let b = spot($1) else { return false }
            return a.y + a.size < b.y + b.size
        }
    }

    /// Chỗ đứng mặc định của thú cưng (mép trái, tỉ lệ bề rộng phòng; thú cưng rộng 0,30).
    static func petHome(_ room: RoomKind) -> CGFloat {
        switch room {
        case .study: return 0.20
        case .bedroom: return 0.22
        case .kitchen: return 0.42
        case .bath: return 0.26
        case .garden: return 0.34
        }
    }
}
