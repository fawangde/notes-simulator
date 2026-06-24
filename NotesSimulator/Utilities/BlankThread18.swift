import Foundation
import UIKit

/// iOS 18 信息页：两套独立空白会话（互不影响随机池，与 26 分池）
enum BlankThread18 {
    /// 标准空白：第 2 行固定 + 随机 50（合计 51）
    enum Standard {
        static let consoleTag = "BlankThread18"
        static let fixedLineIndex = 1
        static let randomBlankCount = 50
        static let seedSalt: UInt64 = 0x517C_C1B7_2722_0A95
    }

    /// 绿色 SMS 空白：第 1 行固定 + 随机 60（合计 61），撰写页 UI 不同
    enum GreenSMS {
        static let consoleTag = "BlankThread18Green"
        static let fixedLineIndex = 0
        static let randomBlankCount = 60
        static let seedSalt: UInt64 = 0x85EB_CA6B_EA12_7F3D
    }

    static func standardBlankLineIndices(lineCount: Int, noteBody: String) -> Set<Int> {
        blankLineIndices(
            lineCount: lineCount,
            noteBody: noteBody,
            fixedLineIndex: Standard.fixedLineIndex,
            randomBlankCount: Standard.randomBlankCount,
            seed: stableSeed(noteBody) ^ Standard.seedSalt
        )
    }

    static func greenSMSBlankLineIndices(lineCount: Int, noteBody: String) -> Set<Int> {
        blankLineIndices(
            lineCount: lineCount,
            noteBody: noteBody,
            fixedLineIndex: GreenSMS.fixedLineIndex,
            randomBlankCount: GreenSMS.randomBlankCount,
            seed: stableSeed(noteBody) ^ GreenSMS.seedSalt
        )
    }

    static func logAssignments(lines: [String], noteBody: String) {
        log(
            tag: Standard.consoleTag,
            title: "标准空白（固定第2行+随机50）",
            indices: standardBlankLineIndices(lineCount: lines.count, noteBody: noteBody),
            lines: lines
        )
        log(
            tag: GreenSMS.consoleTag,
            title: "绿色SMS空白（固定第1行+随机60）",
            indices: greenSMSBlankLineIndices(lineCount: lines.count, noteBody: noteBody),
            lines: lines
        )
    }

    private static func blankLineIndices(
        lineCount: Int,
        noteBody: String,
        fixedLineIndex: Int,
        randomBlankCount: Int,
        seed: UInt64
    ) -> Set<Int> {
        guard lineCount > 0 else { return [] }

        var indices = Set<Int>()
        if fixedLineIndex < lineCount {
            indices.insert(fixedLineIndex)
        }

        let pool = (0..<lineCount).filter { $0 != fixedLineIndex }
        var generator = BlankThread18SeededRNG(seed: seed)
        let picks = pool.shuffled(using: &generator).prefix(min(randomBlankCount, pool.count))
        indices.formUnion(picks)
        return indices
    }

    private static func log(tag: String, title: String, indices: Set<Int>, lines: [String]) {
        let sorted = indices.sorted()
        let human = sorted.map { ordinal in
            let lineNo = ordinal + 1
            let preview = lines.indices.contains(ordinal) ? lines[ordinal] : "?"
            return "第\(lineNo)行(\(preview))"
        }
        print("[\(tag)] 备忘录 \(lines.count) 行 → \(title) \(sorted.count) 个")
        print("[\(tag)] \(human.joined(separator: "、"))")
    }

    private static func stableSeed(_ text: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in text.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return hash
    }
}

enum IOS18ComposeChromeStyle: Equatable {
    case standard
    case greenSMS
}

private struct BlankThread18SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
