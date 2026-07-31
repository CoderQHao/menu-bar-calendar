//
//  IOSCalendarViewModel.swift
//  MenuBarCalendar
//
//  Created by Codex on 2026/5/28.
//

import Combine
import Foundation
import WidgetKit

@MainActor
final class IOSCalendarViewModel: ObservableObject {
    @Published private(set) var displayedMonth: Date
    @Published private(set) var selectedDate: Date
    @Published private(set) var days: [DayModel] = []
    @Published var weekdayStart: WeekdayStart

    private var calendar: Calendar
    private let holidayService: HolidayService
    private let dataService: CalendarDataService

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")

        let weekdayStart = WeekdayStart(
            rawValue: SharedUserDefaults.defaults.integer(forKey: Self.weekdayStartKey)
        ) ?? .sunday
        calendar.firstWeekday = weekdayStart.rawValue

        let today = calendar.startOfDay(for: Date())
        let holidayService = HolidayService()

        self.calendar = calendar
        self.holidayService = holidayService
        self.dataService = CalendarDataService(
            holidayService: holidayService,
            lunarService: LunarCalendarService()
        )
        self.displayedMonth = today
        self.selectedDate = today
        self.weekdayStart = weekdayStart

        preloadHolidayData(around: today)
        refreshVisibleMonth()
    }

    var monthTitle: String {
        Self.monthFormatter.string(from: displayedMonth)
    }

    var selectedDay: DayModel? {
        days.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var selectedDayTitle: String {
        Self.dayFormatter.string(from: selectedDate)
    }

    var selectedDaySubtitle: String {
        guard let selectedDay else {
            return ""
        }

        if let holidayName = selectedDay.holidayName {
            return "\(selectedDay.secondaryText) · \(holidayName)"
        }

        return selectedDay.secondaryText
    }

    var selectedDayStatus: String {
        guard let selectedDay else {
            return "普通日期"
        }

        if selectedDay.isToday {
            return "今天"
        }

        if selectedDay.isHoliday {
            return "法定休息日"
        }

        if selectedDay.isWorkdayOverride {
            return "调休上班"
        }

        if selectedDay.isWeekend {
            return "周末"
        }

        return "普通日期"
    }

    var canReturnToToday: Bool {
        !calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
            || !calendar.isDate(selectedDate, inSameDayAs: Date())
    }

    func goToPreviousMonth() {
        guard let date = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = date
        preloadHolidayData(around: date)
        refreshVisibleMonth()
    }

    func goToNextMonth() {
        guard let date = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = date
        preloadHolidayData(around: date)
        refreshVisibleMonth()
    }

    func goToToday() {
        let today = calendar.startOfDay(for: Date())
        displayedMonth = today
        selectedDate = today
        preloadHolidayData(around: today)
        refreshVisibleMonth()
    }

    func select(date: Date) {
        selectedDate = calendar.startOfDay(for: date)

        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = date
            preloadHolidayData(around: date)
        }

        refreshVisibleMonth()
    }

    func setWeekdayStart(_ weekdayStart: WeekdayStart) {
        self.weekdayStart = weekdayStart
        calendar.firstWeekday = weekdayStart.rawValue
        SharedUserDefaults.defaults.set(weekdayStart.rawValue, forKey: Self.weekdayStartKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "MonthCalendarWidget")
        refreshVisibleMonth()
    }

    private func refreshVisibleMonth() {
        calendar.firstWeekday = weekdayStart.rawValue
        days = dataService.makeMonthDays(
            displayedMonth: displayedMonth,
            selectedDate: selectedDate,
            firstWeekday: weekdayStart.rawValue
        )
    }

    private func preloadHolidayData(around date: Date) {
        let year = calendar.component(.year, from: date)
        holidayService.preload(years: [year - 1, year, year + 1])
    }

    private static let weekdayStartKey = "weekdayStart"

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }()
}
