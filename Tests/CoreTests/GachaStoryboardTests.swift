import Foundation
import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class GachaStoryboardTests: XCTestCase {
    func testDurations() {
        XCTAssert((7.0...10.0).contains(GachaStoryboard.duration(.full)), "phim đầy đủ dài 7–10 giây")
        XCTAssertLessThanOrEqual(GachaStoryboard.duration(.short), 2.0)
    }

    func testShotsAreContiguousAndCoverTheFilm() {
        for cut in [GachaStoryboard.Cut.full, .short] {
            let shots = GachaStoryboard.shots(cut)
            XCTAssertEqual(shots.first?.start, 0)
            for (a, b) in zip(shots, shots.dropFirst()) { XCTAssertLessThan(a.start, b.start) }
            XCTAssertLessThan(shots.last!.start, GachaStoryboard.duration(cut))
            XCTAssertEqual(GachaStoryboard.shot(at: GachaStoryboard.duration(cut) - 0.01, cut: cut).shot, shots.last!.shot)
        }
        XCTAssertEqual(GachaStoryboard.shots(.full).map(\.shot), GachaStoryboard.Shot.allCases)
        XCTAssertEqual(GachaStoryboard.shot(at: GachaStoryboard.popTime(.full), cut: .full).shot, .pop)
    }

    func testSoundsSortedInsideFilmAndRevealAtPop() {
        for cut in [GachaStoryboard.Cut.full, .short] {
            for tier in ItemRarity.allCases {
                let cues = GachaStoryboard.sounds(cut, tier: tier)
                XCTAssertEqual(cues.map(\.time), cues.map(\.time).sorted())
                XCTAssert(cues.allSatisfy { $0.time >= 0 && $0.time < GachaStoryboard.duration(cut) })
                XCTAssertEqual(cues.filter { $0.sound == .reveal }.map(\.time), [GachaStoryboard.popTime(cut)])
            }
        }
        // Món càng hiếm, viên nang rung càng lâu.
        XCTAssertGreaterThan(GachaStoryboard.sounds(.full, tier: .epic).filter { $0.sound == .rumble }.count,
                             GachaStoryboard.sounds(.full, tier: .rare).filter { $0.sound == .rumble }.count)
    }
}
