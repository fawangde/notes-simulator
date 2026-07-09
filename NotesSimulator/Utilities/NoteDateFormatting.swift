import Foundation

enum NoteDateFormatting {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    /// 备忘录顶栏：区间开始时间前 2 分钟。
    /// 跨午夜：当前在 00:00 至开始时间前（已过 00:00）→ 前一天；≥ 开始时间 → 当天。
    /// 不跨午夜（00:00–23:59 同日）→ 始终当天。
    static func notesHeaderDate(
        startMinutesFromMidnight: Int,
        on day: Date = Date(),
        timeRange: ThreadTimeRange? = nil
    ) -> Date {
        let calendar = Calendar.current
        var baseDay = calendar.startOfDay(for: day)

        if let timeRange, timeRange.crossesMidnight {
            let currentMinutes =
                calendar.component(.hour, from: day) * 60
                + calendar.component(.minute, from: day)
            if currentMinutes < timeRange.startMinutes {
                baseDay = calendar.date(byAdding: .day, value: -1, to: baseDay) ?? baseDay
            }
        }

        guard let start = calendar.date(byAdding: .minute, value: startMinutesFromMidnight, to: baseDay) else {
            return day
        }
        return calendar.date(byAdding: .minute, value: -2, to: start) ?? start
    }

    /// 撰写页时间戳第二行：「今天 01:53」「昨天 22:58」
    /// 跨午夜区间（如 23:xx-00:xx）：23:xx 段显示昨天，00:xx 段显示今天。
    static func composeThreadDateLabel(from date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return composeThreadDateLabel(minutesFromMidnight: hour * 60 + minute, on: date, timeRange: nil)
    }

    static func composeThreadDateLabel(minutesFromMidnight: Int) -> String {
        composeThreadDateLabel(minutesFromMidnight: minutesFromMidnight, on: Date(), timeRange: nil)
    }

    static func composeThreadDateLabel(minutesFromMidnight: Int, timeRange: ThreadTimeRange?) -> String {
        composeThreadDateLabel(minutesFromMidnight: minutesFromMidnight, on: Date(), timeRange: timeRange)
    }

    static func composeThreadDateLabel(minutesFromMidnight: Int, on day: Date, timeRange: ThreadTimeRange? = nil) -> String {
        let clamped = max(0, min(23 * 60 + 59, minutesFromMidnight))
        let hour = clamped / 60
        let minute = clamped % 60
        let time = String(format: "%02d:%02d", hour, minute)

        if let timeRange, timeRange.crossesMidnight {
            let dayWord = clamped >= timeRange.startMinutes ? "昨天" : "今天"
            return "\(dayWord) \(time)"
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(day) {
            return "今天 \(time)"
        }
        if calendar.isDateInYesterday(day) {
            return "昨天 \(time)"
        }
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "zh_CN")
        dayFormatter.dateFormat = "M月d日"
        return "\(dayFormatter.string(from: day)) \(time)"
    }
}
