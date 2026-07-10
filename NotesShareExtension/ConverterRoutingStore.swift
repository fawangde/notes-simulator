import Foundation

/// 与主 App `ConverterRoutingStore` 保持一致（Share Extension 副本）
enum ConverterRoutingStore {
    static let appGroupID = "group.com.notesimulator.app"
    static let sessionActiveKey = "converterSessionActive"
    static let pendingImportKey = "pendingConverterImport.v1"
    static let pendingFileName = "pending-converter-import.json"

    struct PendingImport: Codable, Equatable {
        var fileName: String
        var content: String
    }

    static var isConverterSessionActive: Bool {
        get { UserDefaults(suiteName: appGroupID)?.bool(forKey: sessionActiveKey) ?? false }
        set { UserDefaults(suiteName: appGroupID)?.set(newValue, forKey: sessionActiveKey) }
    }

    static func queuePendingImport(_ pending: PendingImport) {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults(suiteName: appGroupID)?.set(data, forKey: pendingImportKey)
        if let fileURL = pendingFileURL() {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    static func consumePendingImport() -> PendingImport? {
        if let fileURL = pendingFileURL(),
           let data = try? Data(contentsOf: fileURL),
           let pending = try? JSONDecoder().decode(PendingImport.self, from: data) {
            try? FileManager.default.removeItem(at: fileURL)
            UserDefaults(suiteName: appGroupID)?.removeObject(forKey: pendingImportKey)
            return pending
        }
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: pendingImportKey),
              let pending = try? JSONDecoder().decode(PendingImport.self, from: data) else {
            return nil
        }
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: pendingImportKey)
        return pending
    }

    private static func pendingFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(pendingFileName)
    }
}
