//
//  CalendarViewModel.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation
import Combine
import ServiceManagement

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var displayedMonth: Date
    @Published private(set) var selectedDate: Date?
    @Published private(set) var days: [DayModel] = []
    @Published var appearanceMode: AppearanceMode
    @Published var weekdayStart: WeekdayStart
    @Published var statusDateFormat: StatusDateFormat
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published private(set) var canManageLaunchAtLogin: Bool
    @Published private(set) var launchAtLoginMessage: String?

    var onStatusTitleChange: ((String) -> Void)?
    var onAppearanceModeChange: ((AppearanceMode) -> Void)?

    private var calendar: Calendar
    private let holidayService: HolidayService
    private let lunarService: LunarCalendarService
    private let dataService: CalendarDataService
    private var dayChangeTimer: Timer?
    private var lastKnownDay: Date

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.locale = Locale(identifier: "zh_CN")
        let today = calendar.startOfDay(for: Date())

        let holidayService = HolidayService()
        let lunarService = LunarCalendarService()
        let weekdayStart = WeekdayStart(
            rawValue: UserDefaults.standard.integer(forKey: Self.weekdayStartKey)
        ) ?? .sunday
        calendar.firstWeekday = weekdayStart.rawValue

        self.calendar = calendar
        self.holidayService = holidayService
        self.lunarService = lunarService
        self.dataService = CalendarDataService(
            holidayService: holidayService,
            lunarService: lunarService
        )
        self.appearanceMode = AppearanceMode(
            rawValue: UserDefaults.standard.string(forKey: Self.appearanceModeKey) ?? ""
        ) ?? .system
        self.weekdayStart = weekdayStart
        self.statusDateFormat = StatusDateFormat(
            rawValue: UserDefaults.standard.string(forKey: Self.statusDateFormatKey) ?? ""
        ) ?? .chinese
        self.displayedMonth = today
        self.selectedDate = today
        self.launchAtLoginEnabled = Self.isLaunchAtLoginEnabled
        self.canManageLaunchAtLogin = true
        self.launchAtLoginMessage = Self.launchAtLoginStatusMessage
        self.lastKnownDay = today
    }

    var statusTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = statusDateFormat.dateFormat
        return formatter.string(from: Date())
    }

    var monthTitle: String {
        Self.monthFormatter.string(from: displayedMonth)
    }

    var canReturnToToday: Bool {
        !calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    func start() {
        preloadHolidayData()
        refreshCurrentDate()
        applyAppearanceMode()
        refreshLaunchAtLoginState()
    }

    func refreshVisibleMonth() {
        calendar.firstWeekday = weekdayStart.rawValue
        days = dataService.makeMonthDays(
            displayedMonth: displayedMonth,
            selectedDate: selectedDate,
            firstWeekday: weekdayStart.rawValue
        )
    }

    func goToPreviousMonth() {
        guard let date = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = date
        refreshVisibleMonth()
    }

    func goToNextMonth() {
        guard let date = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        displayedMonth = date
        refreshVisibleMonth()
    }

    func goToToday() {
        let today = calendar.startOfDay(for: Date())
        displayedMonth = today
        selectedDate = today
        refreshVisibleMonth()
    }

    func select(date: Date) {
        selectedDate = date
        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = date
        }
        refreshVisibleMonth()
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.appearanceModeKey)
        applyAppearanceMode()
    }

    func setWeekdayStart(_ weekdayStart: WeekdayStart) {
        self.weekdayStart = weekdayStart
        calendar.firstWeekday = weekdayStart.rawValue
        UserDefaults.standard.set(weekdayStart.rawValue, forKey: Self.weekdayStartKey)
        refreshVisibleMonth()
    }

    func setStatusDateFormat(_ format: StatusDateFormat) {
        statusDateFormat = format
        UserDefaults.standard.set(format.rawValue, forKey: Self.statusDateFormatKey)
        updateStatusTitle()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLaunchAtLoginState()
        } catch {
            refreshLaunchAtLoginState()
            launchAtLoginMessage = enabled
                ? "未能开启开机启动。请使用已签名应用，或在系统设置中检查登录项权限。"
                : "未能关闭开机启动，请稍后重试。"
        }
    }

    func refreshCurrentDate() {
        let previousDay = lastKnownDay
        let today = calendar.startOfDay(for: Date())
        let dayChanged = !calendar.isDate(previousDay, inSameDayAs: today)

        if dayChanged {
            let selectedWasCurrentDay = selectedDate.map {
                calendar.isDate($0, inSameDayAs: previousDay)
            } ?? false

            lastKnownDay = today

            if selectedWasCurrentDay {
                selectedDate = today
            }

            preloadHolidayData()
        }

        updateStatusTitle()
        refreshVisibleMonth()
        scheduleNextDayRefresh()
    }

    private func preloadHolidayData() {
        let currentYear = calendar.component(.year, from: Date())
        holidayService.preload(years: [currentYear, currentYear + 1])
    }

    private func updateStatusTitle() {
        onStatusTitleChange?(statusTitle)
    }

    private func applyAppearanceMode() {
        onAppearanceModeChange?(appearanceMode)
    }

    private func refreshLaunchAtLoginState() {
        canManageLaunchAtLogin = true
        launchAtLoginEnabled = Self.isLaunchAtLoginEnabled
        launchAtLoginMessage = Self.launchAtLoginStatusMessage
    }

    private func scheduleNextDayRefresh() {
        dayChangeTimer?.invalidate()

        let now = Date()
        guard let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) else {
            return
        }

        dayChangeTimer = Timer(fireAt: nextMidnight, interval: 0, target: self, selector: #selector(handleDayChange), userInfo: nil, repeats: false)
        RunLoop.main.add(dayChangeTimer!, forMode: .common)
    }

    @objc
    private func handleDayChange() {
        refreshCurrentDate()
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let appearanceModeKey = "appearanceMode"
    private static let weekdayStartKey = "weekdayStart"
    private static let statusDateFormatKey = "statusDateFormat"

    private static var isLaunchAtLoginEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    private static var launchAtLoginStatusMessage: String? {
        switch SMAppService.mainApp.status {
        case .requiresApproval:
            return "已添加登录项，请在系统设置 > 通用 > 登录项中允许今历。"
        case .notFound:
            return "当前应用缺少可注册的登录项配置。"
        default:
            return nil
        }
    }
}
