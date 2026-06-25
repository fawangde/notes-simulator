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

    /// 备忘录顶栏：当天日期 + 时间小字开始时间前 2 分钟
    static func notesHeaderDate(startMinutesFromMidnight: Int, on day: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        guard let start = calendar.date(byAdding: .minute, value: startMinutesFromMidnight, to: startOfDay) else {
            return day
        }
        return calendar.date(byAdding: .minute, value: -2, to: start) ?? start
    }

    /// 撰写页时间戳第二行：「今天 01:53」「昨天 22:58」
    static func composeThreadDateLabel(from date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return composeThreadDateLabel(minutesFromMidnight: hour * 60 + minute, on: date)
    }

    static func composeThreadDateLabel(minutesFromMidnight: Int) -> String {
        composeThreadDateLabel(minutesFromMidnight: minutesFromMidnight, on: Date())
    }

    static func composeThreadDateLabel(minutesFromMidnight: Int, on day: Date) -> String {
        let clamped = max(0, min(23 * 60 + 59, minutesFromMidnight))
        let hour = clamped / 60
        let minute = clamped % 60
        let time = String(format: "%02d:%02d", hour, minute)
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
