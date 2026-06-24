import Foundation
import UniformTypeIdentifiers

enum NoteImportService {
    static let appGroupID = "group.com.notesimulator.app"
    static let pendingImportKey = "pendingNoteImport.v1"

    struct Payload: Codable, Equatable {
        var title: String
        var body: String
        var importedAt: Date?
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
        let importedAt = fileImportDate(for: url)
        return Payload(title: title, body: body, importedAt: importedAt)
    }

    static func parsePlainText(_ text: String, suggestedTitle: String = "导入备忘录") -> Payload {
        Payload(
            title: suggestedTitle,
            body: normalizedPhoneBody(from: text),
            importedAt: Date()
        )
    }

    static func queuePendingImport(_ payload: Payload) {
        NoteImportStore.queue(
            NoteImportStore.Payload(
                title: payload.title,
                body: payload.body,
                importedAt: payload.importedAt
            )
        )
    }

    static func consumePendingImport() -> Payload? {
        guard let stored = NoteImportStore.consume() else { return nil }
        return Payload(
            title: stored.title,
            body: stored.body,
            importedAt: stored.importedAt
        )
    }

    private static func fileImportDate(for url: URL) -> Date {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        return values?.contentModificationDate ?? values?.creationDate ?? Date()
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

    /// 导入后在最后一个非空行后追加的空行数
    static let trailingBlankLineCount = 13
    /// UITextView 会吞掉纯换行；用零宽空格占位，视觉上仍是空行
    private static let blankLineMarker = "\u{200B}"

    static func appendTrailingBlankLines(to body: String) -> String {
        var lines = body.components(separatedBy: .newlines)
        while let last = lines.last, isBlankLine(last) {
            lines.removeLast()
        }
        guard !lines.isEmpty else { return body }
        let blanks = Array(repeating: blankLineMarker, count: trailingBlankLineCount)
        return (lines + blanks).joined(separator: "\n")
    }

    private static func isBlankLine(_ line: String) -> Bool {
        line
            .replacingOccurrences(of: blankLineMarker, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    enum ImportError: Error {
        case unreadableEncoding
    }
}
