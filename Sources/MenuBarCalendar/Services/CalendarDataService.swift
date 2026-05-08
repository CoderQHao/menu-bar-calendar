import Foundation

final class CalendarDataService {
    private let holidayService: HolidayService
    private let lunarService: LunarCalendarService

    init(
        holidayService: HolidayService,
        lunarService: LunarCalendarService
    ) {
        self.holidayService = holidayService
        self.lunarService = lunarService
    }

    func makeMonthDays(displayedMonth: Date, selectedDate: Date?, firstWeekday: Int) -> [DayModel] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current

        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        let monthStart = monthInterval.start
        let visibleStart = monthFirstWeek.start
        let today = calendar.startOfDay(for: Date())

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: visibleStart) else {
                return nil
            }

            let holidayInfo = holidayService.holidayInfo(for: date)
            let holidayName = holidayInfo?.name
            let secondaryText = lunarService.secondaryText(for: date, holidayName: holidayName)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isSelected = selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false
            let isInCurrentMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7

            return DayModel(
                date: date,
                solarDay: calendar.component(.day, from: date),
                secondaryText: secondaryText,
                isInCurrentMonth: isInCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                isWeekend: isWeekend && holidayInfo?.isWorkdayOverride != true,
                isHoliday: holidayInfo?.isHoliday == true,
                isWorkdayOverride: holidayInfo?.isWorkdayOverride == true,
                holidayName: holidayName
            )
        }
    }
}
