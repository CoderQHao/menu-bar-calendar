//
//  DayModel.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation

/// Presentation-ready data for one calendar cell.
struct DayModel: Identifiable, Hashable {
    let date: Date
    let solarDay: Int
    let secondaryText: String
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isWeekend: Bool
    let isHoliday: Bool
    let isWorkdayOverride: Bool
    let holidayName: String?

    var id: String {
        // Stable across refreshes so SwiftUI does not animate a date cell as a different item.
        Self.idFormatter.string(from: date)
    }

    var badgeText: String? {
        if isHoliday {
            return "休"
        }
        if isWorkdayOverride {
            return "班"
        }
        return nil
    }

    private static let idFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
