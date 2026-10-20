import SwiftUI

/// Sàn mua riêng: vẽ trong hệ tọa độ phòng 125×100, chỉ phủ vùng sàn từ `top` (y = 62) xuống đáy.
enum FloorArt {
    static let top: CGFloat = 62

    /// Trả về false nếu `id` không phải sàn.
    static func draw(_ id: String, in ctx: GraphicsContext) -> Bool {
        guard Catalog.item(id)?.slot.isFloor == true else { return false }
        return false
    }
}
