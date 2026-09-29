import Foundation

enum DotFormatters {
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func historyDay(_ date: Date) -> String {
        if Calendar.autoupdatingCurrent.isDateInToday(date) {
            return "Today"
        }
        if Calendar.autoupdatingCurrent.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    static func gapDetail(seconds: TimeInterval) -> String {
        let minutes = max(1, Int(ceil(seconds / 60)))
        if minutes < 60 {
            return "Last dose logged · minimum gap has \(minutes) min remaining"
        }
        let hours = Int(ceil(Double(minutes) / 60))
        return "Last dose logged · minimum gap has \(hours) hr remaining"
    }

    static func shortGap(seconds: TimeInterval) -> String {
        let minutes = max(1, Int(ceil(seconds / 60)))
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = Int(ceil(Double(minutes) / 60))
        return "\(hours) hr"
    }
}
