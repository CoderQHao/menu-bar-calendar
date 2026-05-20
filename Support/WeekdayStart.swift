//
//  WeekdayStart.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation

/// User preference for the first column in the calendar grid.
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

/// Menu-bar date formats shown in Settings and used by the status item title.
enum StatusDateFormat: String, CaseIterable, Identifiable {
    case chinese
    case slash
    case weekdayFirst
    case dotted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chinese:
            return "中文日期"
        case .slash:
            return "斜杠日期"
        case .weekdayFirst:
            return "星期优先"
        case .dotted:
            return "点分日期"
        }
    }

    var dateFormat: String {
        switch self {
        case .chinese:
            return "M月d日 EEE"
        case .slash:
            return "MM/dd EEE"
        case .weekdayFirst:
            return "EEE M/d"
        case .dotted:
            return "MM.dd EEE"
        }
    }

    func previewText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
}
