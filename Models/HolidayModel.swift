//
//  HolidayModel.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation

/// Raw shape of one bundled or user-provided yearly holiday JSON file.
struct HolidayYearPayload: Codable {
    let year: Int
    let days: [HolidaySourceDay]
}

/// One row from the source JSON. `isOffDay == false` represents an official make-up workday.
struct HolidaySourceDay: Codable, Hashable {
    let name: String
    let date: String
    let isOffDay: Bool
}

/// Normalized value used by the calendar grid after source data has been indexed by date.
struct HolidayDayPayload: Codable, Hashable {
    let name: String?
    let isHoliday: Bool
    let isWorkdayOverride: Bool
}
