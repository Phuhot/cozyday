import Foundation
import SwiftData

enum PersistenceError: Error, LocalizedError {
    case cannotOpen(String)

    var errorDescription: String? {
        switch self {
        case .cannotOpen(let detail): return detail
        }
    }
}

/// Tạo ModelContainer. CloudKit tắt tường minh; dữ liệu chỉ nằm trên máy.
/// Nếu mở store thất bại (ví dụ migration lỗi) thì báo lỗi — KHÔNG xóa file dữ liệu để "khởi tạo lại".
enum PersistenceController {
    static let storeFileName = "Cozyday.store"

    static func storeURL() throws -> URL {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        return folder.appendingPathComponent(storeFileName)
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CozySchemaV1.self)
        let configuration: ModelConfiguration
        if inMemory {
            // Tên riêng cho mỗi container trong bộ nhớ (dùng trong test) để không dùng chung dữ liệu.
            configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, url: try storeURL(), cloudKitDatabase: .none)
        }
        do {
            return try ModelContainer(for: schema, migrationPlan: CozyMigrationPlan.self, configurations: [configuration])
        } catch {
            throw PersistenceError.cannotOpen(String(describing: error))
        }
    }
}
