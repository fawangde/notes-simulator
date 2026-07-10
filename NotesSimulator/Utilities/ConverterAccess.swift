import Foundation

enum ConverterAccess {
    /// 次数码激活时的初始次数 → 超级转换器可用时长（从备忘录激活时刻起算）
    static func duration(forInitialClickCount count: Int) -> TimeInterval {
        switch count {
        case 1 ... 5:
            return 3 * 86_400
        case 6 ... 10:
            return 7 * 86_400
        default:
            return 30 * 86_400
        }
    }

    static func converterExpiry(
        mode: ActivationMode,
        memoExpiresAt: Date?,
        initialClickCount: Int?,
        activatedAt: Date
    ) -> Date? {
        switch mode {
        case .time:
            return memoExpiresAt
        case .clicks:
            guard let initialClickCount, initialClickCount > 0 else { return nil }
            return activatedAt.addingTimeInterval(duration(forInitialClickCount: initialClickCount))
        }
    }

    static func remainingTimeText(until expiresAt: Date, now: Date = Date()) -> String {
        ActivationFormatting.remainingTimeText(until: expiresAt, now: now)
    }

    static let expiredWhileClicksRemainMessage = """
    超级转换器已到期。请先使用剩余的备忘录模拟次数；次数用完后，可重新购买激活以继续使用转换器。
    """

    static let notActivatedMessage = "请先激活 App"
}
