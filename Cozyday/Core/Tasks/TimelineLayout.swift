import Foundation

/// Bố trí các khối việc trên timeline dọc.
///
/// Quy ước: khối hiển thị cao tối thiểu `minDisplayMinutes` (để chữ luôn đọc được). Hai việc có
/// khoảng *hiển thị* chồng nhau được xếp vào các cột (lane) cạnh nhau, không bao giờ vẽ đè.
/// `overlapsRealTime` cho biết việc có trùng giờ thật với việc khác hay không (để hiện cảnh báo).
enum TimelineLayout {
    struct Item: Equatable {
        var id: UUID
        var start: Int
        var duration: Int
    }

    struct Placement: Equatable {
        var id: UUID
        var displayStart: Int
        var displayEnd: Int
        var lane: Int
        var laneCount: Int
        /// Thời lượng thật ngắn hơn chiều cao tối thiểu → khối được kéo dài khi vẽ.
        var isStretched: Bool
        var overlapsRealTime: Bool
    }

    static func layout(_ items: [Item], minDisplayMinutes: Int) -> [Placement] {
        let sorted = items.sorted {
            if $0.start != $1.start { return $0.start < $1.start }
            if $0.duration != $1.duration { return $0.duration > $1.duration }
            return $0.id.uuidString < $1.id.uuidString
        }

        var placements: [Placement] = []
        var cluster: [Placement] = []
        var clusterEnd = Int.min
        var laneEnds: [Int] = []

        func flush() {
            let count = max(1, laneEnds.count)
            for var p in cluster {
                p.laneCount = count
                placements.append(p)
            }
            cluster.removeAll()
            laneEnds.removeAll()
        }

        for item in sorted {
            let displayEnd = item.start + max(item.duration, minDisplayMinutes)
            if item.start >= clusterEnd, !cluster.isEmpty {
                flush()
            }
            let lane: Int
            if let free = laneEnds.firstIndex(where: { $0 <= item.start }) {
                lane = free
                laneEnds[free] = displayEnd
            } else {
                lane = laneEnds.count
                laneEnds.append(displayEnd)
            }
            clusterEnd = cluster.isEmpty ? displayEnd : max(clusterEnd, displayEnd)
            cluster.append(Placement(
                id: item.id,
                displayStart: item.start,
                displayEnd: displayEnd,
                lane: lane,
                laneCount: 1,
                isStretched: item.duration < minDisplayMinutes,
                overlapsRealTime: false
            ))
        }
        flush()

        // Đánh dấu trùng giờ thật (khoảng [start, start+duration) giao nhau).
        let real = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        for i in placements.indices {
            guard let a = real[placements[i].id] else { continue }
            placements[i].overlapsRealTime = items.contains { b in
                b.id != a.id && a.start < b.start + b.duration && b.start < a.start + a.duration
            }
        }
        return placements
    }
}
