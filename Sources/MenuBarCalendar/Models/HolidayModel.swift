import Foundation

struct HolidayYearPayload: Codable {
    let year: Int
    let days: [HolidaySourceDay]
}

struct HolidaySourceDay: Codable, Hashable {
    let name: String
    let date: String
    let isOffDay: Bool
}

struct HolidayDayPayload: Codable, Hashable {
    let name: String?
    let isHoliday: Bool
    let isWorkdayOverride: Bool
}
