import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var displayedMonth: Date
    @Published private(set) var selectedDate: Date?
    @Published private(set) var days: [DayModel] = []
    @Published var appearanceMode: AppearanceMode
    @Published var weekdayStart: WeekdayStart

    var onStatusTitleChange: ((String) -> Void)?
    var onAppearanceModeChange: ((AppearanceMode) -> Void)?

    private var calendar: Calendar
    private let holidayService: HolidayService
    private let lunarService: LunarCalendarService
    private let dataService: CalendarDataService
    private var dayChangeTimer: Timer?

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.locale = Locale(identifier: "zh_CN")

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
        self.displayedMonth = calendar.startOfDay(for: Date())
        self.selectedDate = calendar.startOfDay(for: Date())
    }

    var statusTitle: String {
        Self.statusFormatter.string(from: Date())
    }

    var monthTitle: String {
        Self.monthFormatter.string(from: displayedMonth)
    }

    var canReturnToToday: Bool {
        !calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    func start() {
        preloadHolidayData()
        refreshVisibleMonth()
        updateStatusTitle()
        applyAppearanceMode()
        scheduleNextDayRefresh()
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
        let today = calendar.startOfDay(for: Date())
        if selectedDate.map({ calendar.isDate($0, inSameDayAs: today) }) == true {
            selectedDate = today
        }
        updateStatusTitle()
        refreshVisibleMonth()
        scheduleNextDayRefresh()
    }

    private static let statusFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let appearanceModeKey = "appearanceMode"
    private static let weekdayStartKey = "weekdayStart"
}
