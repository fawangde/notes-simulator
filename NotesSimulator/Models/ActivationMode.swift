import Foundation

enum ActivationMode: String, Codable, Equatable {
    case time
    case clicks
}

struct ActivationOutcome: Equatable {
    let mode: ActivationMode
    let expiresAt: Date?
    let remainingClicks: Int?
    /// 次数码在 Firebase 中的初始次数（定 ZG 转换器档位）
    let initialClickCount: Int?
    /// 备忘录激活时刻（秒/毫秒均可，由解析方统一）
    let activatedAt: Date?

    init(
        mode: ActivationMode,
        expiresAt: Date?,
        remainingClicks: Int?,
        initialClickCount: Int? = nil,
        activatedAt: Date? = nil
    ) {
        self.mode = mode
        self.expiresAt = expiresAt
        self.remainingClicks = remainingClicks
        self.initialClickCount = initialClickCount
        self.activatedAt = activatedAt
    }
}
