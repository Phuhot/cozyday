import XCTest
#if canImport(CozyCore)
@testable import CozyCore
#else
@testable import Cozyday
#endif

final class EngagementTests: XCTestCase {
    func testInvalidGachaBatchCannotDivideByZeroOrBuyUnlimitedPulls() {
        var rng = SeededRNG(seed: 12)
        for count in [-1, 0, 2, 11, Int.max] {
            XCTAssertThrowsError(try GachaPolicy.pull(count: count, ledger: [], owned: [], now: Date(), rng: &rng)) {
                XCTAssertEqual($0 as? GachaError, .invalidCount)
            }
        }
    }

    func testRewardPreviewIsIsolatedAndPreservesSpeciesAndFur() throws {
        let current = PetAppearance(species:.capybara,fur:.cocoa,hat:"hat.beanie",glasses:"glasses.star",
                                    neck:"neck.scarf",outfit:"outfit.sweater",back:"back.balloon",stage:.grown)
        let reward = try XCTUnwrap(Catalog.item("hat.g_teacup"))
        let preview = current.showcasing(reward)
        XCTAssertEqual(preview.species,.capybara)
        XCTAssertEqual(preview.fur,.cocoa)
        XCTAssertEqual(preview.hat,reward.id)
        XCTAssertNil(preview.glasses); XCTAssertNil(preview.neck); XCTAssertNil(preview.outfit); XCTAssertNil(preview.back)
        XCTAssertEqual(current.hat,"hat.beanie")
        XCTAssertEqual(current.back,"back.balloon")
        let species = current.showcasing(try XCTUnwrap(Catalog.item("species.dragon")))
        XCTAssertEqual(species.species,.dragon)
        XCTAssertNil(species.hat)
    }

    func testFestivalDatesVaryByYearAndUseVietnamTime() throws {
        let tet2026 = try XCTUnwrap(VietnameseEvents.all.first { $0.id == "tet-2026" })
        let tet2027 = try XCTUnwrap(VietnameseEvents.all.first { $0.id == "tet-2027" })
        XCTAssertEqual(tet2026.start.string,"2026-02-14")
        XCTAssertEqual(tet2027.start.string,"2027-02-03")
        let utc = Calendar.gregorian(timeZone:TimeZone(secondsFromGMT:0)!)
        let before = utc.date(from:DateComponents(year:2026,month:2,day:13,hour:16,minute:59,second:59))!
        XCTAssertFalse(VietnameseEvents.active(at:before).contains(tet2026))
        XCTAssertTrue(VietnameseEvents.active(at:before.addingTimeInterval(1)).contains(tet2026))
        XCTAssertTrue(VietnameseEvents.active(at:utc.date(from:DateComponents(year:2026,month:9,day:25,hour:12))!).contains { $0.id == "midautumn-2026" })
        XCTAssertTrue(VietnameseEvents.active(at:utc.date(from:DateComponents(year:2040,month:10,day:20))!).isEmpty)
    }

    func testEventClaimRequiresAllGoalsInsideWindowAndIsOnce() throws {
        let event = try XCTUnwrap(VietnameseEvents.all.first)
        let date = event.start.date(atMinute:12*60,in:VietnameseEvents.calendar)
        var activity = DayActivity()
        activity.careActions=2; activity.focusMinutes=10
        XCTAssertFalse(VietnameseEvents.claimable(event,now:date,activity:activity,keys:[]))
        activity.journalWritten=true
        XCTAssertTrue(VietnameseEvents.claimable(event,now:date,activity:activity,keys:[]))
        XCTAssertFalse(VietnameseEvents.claimable(event,now:date,activity:activity,keys:[LedgerKeys.event(event.id,"complete")]))
        XCTAssertFalse(VietnameseEvents.claimable(event,now:date.addingTimeInterval(9*86400),activity:activity,keys:[]))
    }

    func testNewLevelRewardsUnlockRealItemsAndStarterSpeciesExcludeSecrets() {
        for level in [15,21,30] { XCTAssertTrue(Catalog.items.contains { $0.requiredLevel == level && !$0.gachaOnly }) }
        XCTAssertEqual(PetSpecies.starters.count,4)
        for species in PetSpecies.starters {
            XCTAssertNotNil(Catalog.item("species."+species.rawValue))
            XCTAssertFalse(Catalog.item("species."+species.rawValue)!.gachaOnly)
        }
        XCTAssertFalse(PetSpecies.starters.contains(.dragon))
        XCTAssertFalse(PetSpecies.starters.contains(.unicorn))
    }

    func testClockRollbackCannotReorderGachaPityAfterReload() throws {
        var rng = SeededRNG(seed: 42)
        let date = Date(timeIntervalSince1970:1_700_000_000)
        let money = LedgerEntry(id:UUID(),key:"gift:test",kind:.gift,xp:0,coins:10000,createdAt:date,refID:nil,memo:"")
        let first = try GachaPolicy.pull(count:10,ledger:[money],owned:[],now:date,rng:&rng)
        let second = try GachaPolicy.pull(count:1,ledger:[money]+first.map(\.entry),owned:Set(first.map(\.itemID)),now:date.addingTimeInterval(-3600),rng:&rng)
        XCTAssertGreaterThan(second[0].entry.createdAt,first.last!.entry.createdAt)
    }
}
