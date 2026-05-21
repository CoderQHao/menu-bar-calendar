//
//  CalendarViewModel.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
/// Central state holder for the popover calendar, menu-bar title, preferences, and daily refreshes.
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
    @Published private(set) var updateState: UpdateState
    @Published private(set) var updatePrompt: UpdatePrompt?
    let currentAppVersion: String

    var onStatusTitleChange: ((String) -> Void)?
    var onAppearanceModeChange: ((AppearanceMode) -> Void)?

    private var calendar: Calendar
    private let holidayService: HolidayService
    private let lunarService: LunarCalendarService
    private let dataService: CalendarDataService
    private let updateService: UpdateService
    private var dayChangeTimer: Timer?
    private var pendingUpdate: UpdateInfo?
    private var downloadedUpdateURL: URL?
    private var lastAutomaticUpdateCheckDate: Date?
    private var dismissedUpdatePromptVersion: String?
    private var dismissedUpdatePromptDate: Date?
    // Tracks the last day we fully processed so date-dependent UI can roll forward once per day.
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
        self.updateService = UpdateService()
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
        self.updateState = .idle
        self.updatePrompt = nil
        self.currentAppVersion = Self.bundleShortVersion
        self.lastAutomaticUpdateCheckDate = UserDefaults.standard.object(
            forKey: Self.lastAutomaticUpdateCheckDateKey
        ) as? Date
        self.dismissedUpdatePromptVersion = UserDefaults.standard.string(
            forKey: Self.dismissedUpdatePromptVersionKey
        )
        self.dismissedUpdatePromptDate = UserDefaults.standard.object(
            forKey: Self.dismissedUpdatePromptDateKey
        ) as? Date
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

    func handleUpdateButtonPress() {
        switch updateState {
        case .available:
            downloadPendingUpdate()
        case .readyToInstall(let version):
            openDownloadedUpdate(version: version)
        case .checking, .downloading:
            return
        default:
            checkForUpdates()
        }
    }

    func handleCalendarOpened() {
        if showPromptForAvailableUpdateIfNeeded() {
            return
        }

        checkForUpdatesOnCalendarOpen()
    }

    func dismissUpdatePrompt() {
        if let version = updatePrompt?.version {
            let now = Date()
            dismissedUpdatePromptVersion = version
            dismissedUpdatePromptDate = now
            UserDefaults.standard.set(version, forKey: Self.dismissedUpdatePromptVersionKey)
            UserDefaults.standard.set(now, forKey: Self.dismissedUpdatePromptDateKey)
        }

        updatePrompt = nil
    }

    func confirmUpdatePrompt() {
        updatePrompt = nil
        handleUpdateButtonPress()
    }

    func checkForUpdates() {
        guard !updateState.isBusy else {
            return
        }

        pendingUpdate = nil
        downloadedUpdateURL = nil
        updateState = .checking
        recordUpdateCheckDate()

        loadLatestUpdate(shouldPrompt: false, shouldSurfaceFailures: true)
    }

    /// Recomputes all date-sensitive state and reschedules the next midnight refresh.
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

    private func checkForUpdatesOnCalendarOpen() {
        guard !updateState.isBusy,
              shouldRunAutomaticUpdateCheck else {
            return
        }

        recordUpdateCheckDate()
        loadLatestUpdate(shouldPrompt: true, shouldSurfaceFailures: false)
    }

    private func loadLatestUpdate(shouldPrompt: Bool, shouldSurfaceFailures: Bool) {
        Task { [currentAppVersion, updateService] in
            do {
                let update = try await updateService.latestUpdate(currentVersion: currentAppVersion)
                if let update {
                    pendingUpdate = update
                    updateState = .available(version: update.version)
                    if shouldPrompt {
                        showPromptForAvailableUpdateIfNeeded()
                    }
                } else if shouldSurfaceFailures {
                    updateState = .upToDate(currentVersion: currentAppVersion)
                } else if case .checking = updateState {
                    updateState = .idle
                }
            } catch {
                if shouldSurfaceFailures {
                    updateState = .failed(message: error.localizedDescription)
                } else if case .checking = updateState {
                    updateState = .idle
                }
            }
        }
    }

    @discardableResult
    private func showPromptForAvailableUpdateIfNeeded() -> Bool {
        let availableVersion: String

        switch updateState {
        case .available(let version), .readyToInstall(let version):
            availableVersion = version
        default:
            return false
        }

        guard !isUpdatePromptDismissedToday(version: availableVersion),
              updatePrompt?.version != availableVersion else {
            return false
        }

        updatePrompt = UpdatePrompt(version: availableVersion)
        return true
    }

    private func isUpdatePromptDismissedToday(version: String) -> Bool {
        guard dismissedUpdatePromptVersion == version,
              let dismissedUpdatePromptDate else {
            return false
        }

        return calendar.isDate(dismissedUpdatePromptDate, inSameDayAs: Date())
    }

    private func recordUpdateCheckDate() {
        let now = Date()
        lastAutomaticUpdateCheckDate = now
        UserDefaults.standard.set(now, forKey: Self.lastAutomaticUpdateCheckDateKey)
    }

    private func downloadPendingUpdate() {
        guard let pendingUpdate else {
            checkForUpdates()
            return
        }

        updateState = .downloading(version: pendingUpdate.version)

        Task { [pendingUpdate, updateService] in
            do {
                let fileURL = try await updateService.download(pendingUpdate)
                downloadedUpdateURL = fileURL
                openDownloadedUpdate(version: pendingUpdate.version)
            } catch {
                updateState = .failed(message: error.localizedDescription)
            }
        }
    }

    private func openDownloadedUpdate(version: String) {
        guard let downloadedUpdateURL else {
            updateState = .failed(message: "安装包文件不存在，请重新检查更新。")
            return
        }

        if NSWorkspace.shared.open(downloadedUpdateURL) {
            updateState = .readyToInstall(version: version)
        } else {
            updateState = .failed(message: "安装包未能打开，请稍后重试。")
        }
    }

    private func refreshLaunchAtLoginState() {
        canManageLaunchAtLogin = true
        launchAtLoginEnabled = Self.isLaunchAtLoginEnabled
        launchAtLoginMessage = Self.launchAtLoginStatusMessage
    }

    private func scheduleNextDayRefresh() {
        dayChangeTimer?.invalidate()

        let now = Date()
        // Fire slightly after midnight so Foundation date calculations have crossed into the new day.
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
    private static let lastAutomaticUpdateCheckDateKey = "lastAutomaticUpdateCheckDate"
    private static let dismissedUpdatePromptVersionKey = "dismissedUpdatePromptVersion"
    private static let dismissedUpdatePromptDateKey = "dismissedUpdatePromptDate"

    private static var bundleShortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    private var shouldRunAutomaticUpdateCheck: Bool {
        switch updateState {
        case .available, .readyToInstall:
            return false
        default:
            break
        }

        guard let lastAutomaticUpdateCheckDate else {
            return true
        }

        return !calendar.isDate(lastAutomaticUpdateCheckDate, inSameDayAs: Date())
    }

    private static var isLaunchAtLoginEnabled: Bool {
        // .requiresApproval means the helper has been requested and still needs user approval.
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
