//
//  MonthCalendarWidget.swift
//  MenuBarCalendar
//
//  Created by Codex on 2026/5/28.
//

import SwiftUI
import WidgetKit

struct MonthCalendarEntry: TimelineEntry {
    let date: Date
    let monthTitle: String
    let weekdayStart: WeekdayStart
    let days: [DayModel]
}

struct MonthCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthCalendarEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthCalendarEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthCalendarEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(for: now)
        let nextRefresh = Self.calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 60 * 60)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry(for date: Date) -> MonthCalendarEntry {
        let weekdayStart = WeekdayStart(
            rawValue: SharedUserDefaults.defaults.integer(forKey: Self.weekdayStartKey)
        ) ?? .sunday
        let holidayService = HolidayService()
        let dataService = CalendarDataService(
            holidayService: holidayService,
            lunarService: LunarCalendarService()
        )
        let year = Self.calendar.component(.year, from: date)
        holidayService.preload(years: [year - 1, year, year + 1])

        return MonthCalendarEntry(
            date: date,
            monthTitle: Self.monthFormatter.string(from: date),
            weekdayStart: weekdayStart,
            days: dataService.makeMonthDays(
                displayedMonth: date,
                selectedDate: date,
                firstWeekday: weekdayStart.rawValue
            )
        )
    }

    private static let weekdayStartKey = "weekdayStart"

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
}

struct MonthCalendarWidget: Widget {
    let kind = "MonthCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthCalendarProvider()) { entry in
            MonthCalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("今历")
        .description("查看本月农历、节假日和调休。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MonthCalendarWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: MonthCalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            header
            weekdayRow
            dayGrid
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(entry.monthTitle)
                .font(headerFont)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            Text(Self.dayFormatter.string(from: entry.date))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(entry.weekdayStart.orderedWeekdays.enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(weekday == "六" || weekday == "日" ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<7, id: \.self) { column in
                        WidgetDayCell(
                            day: entry.days[(row * 7) + column],
                            showsSecondaryText: showsSecondaryText
                        )
                    }
                }
            }
        }
    }

    private var headerFont: Font {
        switch family {
        case .systemSmall:
            return .caption.weight(.semibold)
        default:
            return .headline
        }
    }

    private var verticalSpacing: CGFloat {
        family == .systemSmall ? 4 : 8
    }

    private var gridSpacing: CGFloat {
        family == .systemSmall ? 1 : 3
    }

    private var showsSecondaryText: Bool {
        family != .systemSmall
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "d日"
        return formatter
    }()
}

private struct WidgetDayCell: View {
    let day: DayModel
    let showsSecondaryText: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text("\(day.solarDay)")
                .font(.system(size: showsSecondaryText ? 13 : 11, weight: day.isToday ? .bold : .semibold))
                .foregroundStyle(primaryColor)

            if showsSecondaryText {
                Text(day.secondaryText)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: showsSecondaryText ? 28 : 16)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(backgroundColor)
        )
    }

    private var backgroundColor: Color {
        day.isToday ? .red : .clear
    }

    private var primaryColor: Color {
        if day.isToday {
            return .white
        }

        if !day.isInCurrentMonth {
            return .secondary.opacity(0.5)
        }

        if day.isHoliday {
            return .red
        }

        if day.isWeekend {
            return .blue
        }

        return .primary
    }

    private var secondaryColor: Color {
        if day.isToday {
            return .white.opacity(0.9)
        }

        if day.isHoliday {
            return .red.opacity(0.9)
        }

        return .secondary
    }
}
