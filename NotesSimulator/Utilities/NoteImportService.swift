import Foundation
import UniformTypeIdentifiers

enum NoteImportService {
    static let appGroupID = "group.com.notesimulator.app"
    static let pendingImportKey = "pendingNoteImport.v1"

    struct Payload: Codable, Equatable {
        var title: String
        var body: String
    }

    /// 从 txt 文件名取标题、正文取每行号码
    static func parseTextFile(url: URL) throws -> Payload {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .unicode)
            ?? String(data: data, encoding: .ascii) else {
            throw ImportError.unreadableEncoding
        }

        let title = url.deletingPathExtension().lastPathComponent
        let body = normalizedPhoneBody(from: text)
        return Payload(title: title, body: body)
    }

    static func parsePlainText(_ text: String, suggestedTitle: String = "导入备忘录") -> Payload {
        Payload(title: suggestedTitle, body: normalizedPhoneBody(from: text))
    }

    static func queuePendingImport(_ payload: Payload) {
        NoteImportStore.queue(NoteImportStore.Payload(title: payload.title, body: payload.body))
    }

    static func consumePendingImport() -> Payload? {
        guard let stored = NoteImportStore.consume() else { return nil }
        return Payload(title: stored.title, body: stored.body)
    }

    static func accepts(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ext == "txt" || ext == "text" { return true }
        if let type = UTType(filenameExtension: ext) {
            return type.conforms(to: .plainText) || type.conforms(to: .text)
        }
        return false
    }

    private static func normalizedPhoneBody(from text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return "" }

        let phones = lines.map { line -> String in
            if let match = line.firstMatch(of: PhoneUtilities.phonePattern) {
                return String(match.output)
            }
            return line.filter { $0.isNumber || $0 == "+" || $0 == " " }.trimmingCharacters(in: .whitespaces)
        }
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

        return phones.joined(separator: "\n")
    }

    enum ImportError: Error {
        case unreadableEncoding
    }
}
