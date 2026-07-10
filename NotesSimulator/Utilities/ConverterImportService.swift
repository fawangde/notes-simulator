import Foundation

enum ConverterImportService {
    @discardableResult
    static func consumePendingImportToTXTFiles() -> String? {
        guard let pending = ConverterRoutingStore.consumePendingImport() else { return nil }
        let saved = ZGFileHelper.shared.saveImportedText(
            fileName: pending.fileName,
            content: pending.content
        )
        return saved ? sanitizedFileName(pending.fileName) : nil
    }

    @discardableResult
    static func importFileURLToTXTFiles(_ url: URL) -> String? {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .unicode) else {
            return nil
        }
        let fileName = url.deletingPathExtension().lastPathComponent
        let saved = ZGFileHelper.shared.saveImportedText(fileName: fileName, content: text)
        return saved ? sanitizedFileName(fileName) : nil
    }

    private static func sanitizedFileName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasSuffix(".txt") { return trimmed }
        return trimmed + ".txt"
    }
}
