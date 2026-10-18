import SwiftUI
import UniformTypeIdentifiers

/// Gói dữ liệu sao lưu để lưu ra app Tệp (Files) qua `fileExporter`.
struct BackupFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }

    static func suggestedName(for day: DayKey) -> String {
        "Cozyday-backup-\(day.string)"
    }
}
