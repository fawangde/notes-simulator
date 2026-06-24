import Foundation

/// 主 App 与 Share Extension 共用的待导入载荷（App Group 文件 + UserDefaults 双写）
enum NoteImportStore {
    static let appGroupID = "group.com.notesimulator.app"
    static let defaultsKey = "pendingNoteImport.v1"
    static let fileName = "pending-import.json"

    struct Payload: Codable, Equatable {
        var title: String
        var body: String
        var importedAt: Date?
    }

    static func queue(_ payload: Payload) {
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults(suiteName: appGroupID)?.set(data, forKey: defaultsKey)
            if let fileURL = pendingFileURL() {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    static func consume() -> Payload? {
        if let fileURL = pendingFileURL(),
           let data = try? Data(contentsOf: fileURL),
           let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            try? FileManager.default.removeItem(at: fileURL)
            UserDefaults(suiteName: appGroupID)?.removeObject(forKey: defaultsKey)
            return payload
        }
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: defaultsKey),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: defaultsKey)
        return payload
    }

    private static func pendingFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }
}
