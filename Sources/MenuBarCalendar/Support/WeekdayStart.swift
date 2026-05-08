import Foundation

enum WeekdayStart: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunday:
            return "周日开始"
        case .monday:
            return "周一开始"
        }
    }

    var orderedWeekdays: [String] {
        switch self {
        case .sunday:
            return ["日", "一", "二", "三", "四", "五", "六"]
        case .monday:
            return ["一", "二", "三", "四", "五", "六", "日"]
        }
    }
}
