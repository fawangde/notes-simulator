import Foundation

enum ActivationErrorMapper {
    static func message(for error: Error) -> String {
        if let activation = error as? ActivationError {
            return activation.errorDescription ?? "激活失败，请稍后重试"
        }

        let ns = error as NSError
        let lower = ns.localizedDescription.lowercased()

        if ns.domain == "com.firebase" {
            if lower.contains("permission") || lower.contains("denied") {
                return "Realtime Database 权限不足，请确认 database.rules 已发布"
            }
            if lower.contains("network") || lower.contains("offline") || lower.contains("disconnected") {
                return "无法连接 Realtime Database，请检查 Wi-Fi 或蜂窝网络"
            }
        }

        if lower.contains("network")
            || lower.contains("internet")
            || lower.contains("offline")
            || lower.contains("connection") {
            return "无法连接 Realtime Database，请检查网络后重试"
        }
        if lower.contains("permission") || lower.contains("denied") {
            return "服务器拒绝访问，请检查 Realtime Database 规则是否已发布"
        }

        return "激活失败，请稍后重试"
    }
}

enum RTDBValue {
    static func bool(from value: Any?) -> Bool? {
        switch value {
        case let flag as Bool:
            return flag
        case let number as NSNumber:
            return number.boolValue
        case let number as Int:
            return number != 0
        default:
            return nil
        }
    }

    static func int(from value: Any?) -> Int? {
        switch value {
        case let number as Int:
            return number
        case let number as Int64:
            return Int(number)
        case let number as Double:
            return Int(number)
        case let number as NSNumber:
            return number.intValue
        default:
            return nil
        }
    }

    static func double(from value: Any?) -> Double? {
        switch value {
        case let number as Double:
            return number
        case let number as Int:
            return Double(number)
        case let number as Int64:
            return Double(number)
        case let number as NSNumber:
            return number.doubleValue
        default:
            return nil
        }
    }
}
