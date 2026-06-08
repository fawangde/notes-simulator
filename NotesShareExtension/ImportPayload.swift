import Foundation

/// 与主 App `NoteImportStore` 保持一致的 App Group 载荷
enum ImportPayload {
    static let appGroupID = "group.com.notesimulator.app"
    static let defaultsKey = "pendingNoteImport.v1"
    static let fileName = "pending-import.json"

    struct Payload: Codable, Equatable {
        var title: String
        var body: String
    }

    static func queue(_ payload: Payload) {
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults(suiteName: appGroupID)?.set(data, forKey: defaultsKey)
            if let fileURL = pendingFileURL() {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    static func parseText(_ text: String, title: String) -> Payload {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let body = lines.joined(separator: "\n")
        return Payload(title: title, body: body)
    }

    private static func pendingFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }
}
