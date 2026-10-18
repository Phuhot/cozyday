import XCTest
import SwiftData
@testable import Cozyday

final class PathCheckTests: XCTestCase {
    func testNoteRoundTripInMemory() throws {
        let schema = Schema([PathCheckNote.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        context.insert(PathCheckNote(text: "xin chào", updatedAt: .now))
        try context.save()
        let notes = try context.fetch(FetchDescriptor<PathCheckNote>())
        XCTAssertEqual(notes.map(\.text), ["xin chào"])
    }
}
