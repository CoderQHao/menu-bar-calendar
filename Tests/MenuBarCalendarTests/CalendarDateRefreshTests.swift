//
//  CalendarDateRefreshTests.swift
//  MenuBarCalendarTests
//
//  Created by DongQing on 2026/10/8.
//

import Foundation
import Testing
@testable import MenuBarCalendar

@MainActor
struct CalendarDateRefreshTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test(arguments: [
        (DateComponents(year: 2026, month: 10, day: 31), DateComponents(year: 2026, month: 11, day: 1)),
        (DateComponents(year: 2026, month: 12, day: 31), DateComponents(year: 2027, month: 1, day: 1)),
        (DateComponents(year: 2028, month: 2, day: 29), DateComponents(year: 2028, month: 3, day: 1)),
        (DateComponents(year: 2026, month: 10, day: 30), DateComponents(year: 2026, month: 11, day: 3)),
        (DateComponents(year: 2026, month: 10, day: 31), DateComponents(year: 2027, month: 1, day: 5))
    ])
    func followsCurrentMonth(previous: DateComponents, current: DateComponents) throws {
        let previousDay = try #require(calendar.date(from: previous))
        let today = try #require(calendar.date(from: current))
        let viewModel = CalendarViewModel(now: previousDay)

        viewModel.refreshCurrentDate(now: today)

        #expect(viewModel.displayedMonth == today)
        #expect(viewModel.selectedDate == today)
    }

    @Test(arguments: [9, 12])
    func preservesBrowsedMonthAndSelectedDate(month: Int) throws {
        let previousDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31)))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let browsedDate = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: 15)))
        let viewModel = CalendarViewModel(now: previousDay)
        viewModel.select(date: browsedDate)

        viewModel.refreshCurrentDate(now: today)

        #expect(viewModel.displayedMonth == browsedDate)
        #expect(viewModel.selectedDate == browsedDate)
    }

    @Test
    func preservesBrowsedMonthWhileSelectionFollowsToday() throws {
        let previousDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31)))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let viewModel = CalendarViewModel(now: previousDay)
        viewModel.goToPreviousMonth()
        let browsedMonth = viewModel.displayedMonth

        viewModel.refreshCurrentDate(now: today)

        #expect(viewModel.displayedMonth == browsedMonth)
        #expect(viewModel.selectedDate == today)
    }

    @Test
    func preservesSelectedDateWithinFollowingMonth() throws {
        let previousDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31)))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let selectedDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 15)))
        let viewModel = CalendarViewModel(now: previousDay)
        viewModel.select(date: selectedDate)

        viewModel.refreshCurrentDate(now: today)

        #expect(viewModel.displayedMonth == today)
        #expect(viewModel.selectedDate == selectedDate)
    }

    @Test
    func preservesMonthAnchorWithinSameMonth() throws {
        let previousDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 8)))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 9)))
        let viewModel = CalendarViewModel(now: previousDay)

        viewModel.refreshCurrentDate(now: today)

        #expect(viewModel.displayedMonth == previousDay)
        #expect(viewModel.selectedDate == today)
    }

    @Test
    func repeatedRefreshContinuesFollowingNextMonth() throws {
        let previousDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31)))
        let november = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let december = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 1)))
        let viewModel = CalendarViewModel(now: previousDay)

        viewModel.refreshCurrentDate(now: november)
        viewModel.refreshCurrentDate(now: november)
        viewModel.refreshCurrentDate(now: december)

        #expect(viewModel.displayedMonth == december)
        #expect(viewModel.selectedDate == december)
    }
}
