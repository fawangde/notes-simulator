import Foundation

enum ActivationFormatting {
    /// 剩余时间：≥1 天显示天；<1 天显示小时；<1 小时显示分钟（不显示秒）
    static func remainingTimeText(until expiresAt: Date, now: Date = Date()) -> String {
        let interval = max(0, expiresAt.timeIntervalSince(now))
        guard interval > 0 else { return "已过期" }

        let days = Int(interval / 86_400)
        if days >= 1 {
            return "剩余 \(days) 天"
        }

        let hours = Int(interval / 3_600)
        if hours >= 1 {
            return "剩余 \(hours) 小时"
        }

        let minutes = max(1, Int(ceil(interval / 60)))
        return "剩余 \(minutes) 分钟"
    }

    static func remainingClicksText(_ count: Int) -> String {
        max(0, count) > 0 ? "剩余 \(max(0, count)) 次模拟" : "已用完"
    }

    /// 去掉首尾空白并统一大写，便于字母码匹配 Realtime Database 节点
    static func normalizedCode(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// 5～8 位，仅 ASCII 英文字母或数字（纯数字 / 纯英文 / 组合均可）
    static func isValidFormat(_ code: String) -> Bool {
        guard (5 ... 8).contains(code.count) else { return false }
        return code.allSatisfy(isAllowedCharacter)
    }

    static func duration(for code: String) -> TimeInterval? {
        guard isValidFormat(code) else { return nil }
        switch code.count {
        case 5: return 86_400
        case 6: return 3 * 86_400
        case 7: return 30 * 86_400
        default: return nil
        }
    }

    static func inferredMode(for code: String) -> ActivationMode? {
        guard isValidFormat(code) else { return nil }
        switch code.count {
        case 5, 6, 7: return .time
        case 8: return .clicks
        default: return nil
        }
    }

    private static func isAllowedCharacter(_ character: Character) -> Bool {
        guard character.isASCII, let scalar = character.unicodeScalars.first else { return false }
        return CharacterSet.alphanumerics.contains(scalar)
    }
}
