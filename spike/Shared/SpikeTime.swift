import Foundation

enum SpikeTime {
    /// Next occurrence of hour:minute strictly after `now` (today or tomorrow).
    static func next(hour: Int, minute: Int = 0, from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfToday)
            ?? now.addingTimeInterval(3600)
        if today > now {
            return today
        }
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
    }

    /// Next 23:00 — the spike's fixed "bedtime".
    static func nextBedtime(from now: Date = Date()) -> Date {
        next(hour: 23, minute: 0, from: now)
    }

    /// hour:minute on the day `dayOffset` days after today.
    static func at(dayOffset: Int, hour: Int, minute: Int = 0, from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) ?? startOfToday
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM HH:mm:ss"
        return formatter
    }()

    private static let hmFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func full(_ date: Date?) -> String {
        guard let date else { return "—" }
        return fullFormatter.string(from: date)
    }

    static func hm(_ date: Date) -> String {
        hmFormatter.string(from: date)
    }
}
