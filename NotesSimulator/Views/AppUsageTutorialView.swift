import SwiftUI

enum AppUsageTutorialContent {
    static func load() -> String {
        guard let url = Bundle.main.url(forResource: "AppUsageTutorial", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "教程加载失败，请重新安装 App。"
        }
        return text
    }
}

struct AppUsageTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                TutorialMarkdownBody(text: AppUsageTutorialContent.load())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("操作教程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct TutorialMarkdownBody: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    private var blocks: [TutorialBlock] {
        TutorialMarkdownParser.parse(text)
    }

    @ViewBuilder
    private func blockView(_ block: TutorialBlock) -> some View {
        switch block.kind {
        case .title:
            Text(block.text)
                .font(.title2.bold())
                .padding(.bottom, 4)
        case .heading2:
            Text(block.text)
                .font(.title3.bold())
                .padding(.top, 6)
        case .heading3:
            Text(block.text)
                .font(.headline)
                .padding(.top, 2)
        case .paragraph:
            inlineText(block.text)
                .font(.body)
                .foregroundStyle(IOSTheme.labelPrimary)
        case .blockquote:
            inlineText(block.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 3)
                }
        case .bullet(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        inlineText(item)
                            .font(.body)
                    }
                }
            }
        case .code(let content):
            Text(content)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(IOSTheme.labelPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        case .table(let rows):
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            inlineText(cell)
                                .font(index == 0 ? .caption.weight(.semibold) : .caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    if index == 0 {
                        Divider()
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        case .divider:
            Divider()
                .padding(.vertical, 4)
        }
    }

    private func inlineText(_ source: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: source,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        }
        return Text(source)
    }
}

private struct TutorialBlock {
    enum Kind {
        case title
        case heading2
        case heading3
        case paragraph
        case blockquote
        case bullet([String])
        case code(String)
        case table([[String]])
        case divider
    }

    let kind: Kind
    let text: String

    init(kind: Kind, text: String = "") {
        self.kind = kind
        self.text = text
    }
}

private enum TutorialMarkdownParser {
    static func parse(_ text: String) -> [TutorialBlock] {
        var blocks: [TutorialBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if trimmed == "---" {
                blocks.append(TutorialBlock(kind: .divider))
                index += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                index += 1
                var codeLines: [String] = []
                while index < lines.count, !lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                blocks.append(TutorialBlock(kind: .code(codeLines.joined(separator: "\n"))))
                if index < lines.count { index += 1 }
                continue
            }

            if trimmed.hasPrefix("# ") {
                blocks.append(TutorialBlock(kind: .title, text: String(trimmed.dropFirst(2))))
                index += 1
                continue
            }

            if trimmed.hasPrefix("## ") {
                blocks.append(TutorialBlock(kind: .heading2, text: String(trimmed.dropFirst(3))))
                index += 1
                continue
            }

            if trimmed.hasPrefix("### ") {
                blocks.append(TutorialBlock(kind: .heading3, text: String(trimmed.dropFirst(4))))
                index += 1
                continue
            }

            if trimmed.hasPrefix("> ") {
                blocks.append(TutorialBlock(kind: .blockquote, text: String(trimmed.dropFirst(2))))
                index += 1
                continue
            }

            if trimmed.hasPrefix("|"), trimmed.hasSuffix("|") {
                var rows: [[String]] = []
                while index < lines.count {
                    let rowLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard rowLine.hasPrefix("|"), rowLine.hasSuffix("|") else { break }
                    if rowLine.contains("---") {
                        index += 1
                        continue
                    }
                    let cells = rowLine
                        .dropFirst()
                        .dropLast()
                        .split(separator: "|", omittingEmptySubsequences: false)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    rows.append(cells)
                    index += 1
                }
                if !rows.isEmpty {
                    blocks.append(TutorialBlock(kind: .table(rows)))
                }
                continue
            }

            if trimmed.hasPrefix("- ") {
                var items: [String] = []
                while index < lines.count {
                    let itemLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard itemLine.hasPrefix("- ") else { break }
                    items.append(String(itemLine.dropFirst(2)))
                    index += 1
                }
                blocks.append(TutorialBlock(kind: .bullet(items)))
                continue
            }

            var paragraphLines: [String] = []
            while index < lines.count {
                let next = lines[index].trimmingCharacters(in: .whitespaces)
                if next.isEmpty || next.hasPrefix("#") || next == "---" || next.hasPrefix("```")
                    || next.hasPrefix("> ") || next.hasPrefix("|") || next.hasPrefix("- ") {
                    break
                }
                paragraphLines.append(next)
                index += 1
            }
            if !paragraphLines.isEmpty {
                blocks.append(TutorialBlock(kind: .paragraph, text: paragraphLines.joined(separator: " ")))
            }
        }

        return blocks
    }
}
