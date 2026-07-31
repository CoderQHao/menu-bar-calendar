//
//  IOSCalendarRootView.swift
//  MenuBarCalendar
//
//  Created by Codex on 2026/5/28.
//

import SwiftUI

struct IOSCalendarRootView: View {
    @StateObject private var viewModel = IOSCalendarViewModel()
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    calendarPanel
                    selectedDayPanel
                    LegendView()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今历")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: viewModel.goToToday) {
                        Image(systemName: "calendar")
                    }
                    .disabled(!viewModel.canReturnToToday)
                    .accessibilityLabel("回到今天")

                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("设置")
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                IOSSettingsView(
                    weekdayStart: viewModel.weekdayStart,
                    onWeekdayStartChange: viewModel.setWeekdayStart
                )
            }
        }
    }

    private var calendarPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button(action: viewModel.goToPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("上个月")

                Text(viewModel.monthTitle)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)

                Button(action: viewModel.goToNextMonth) {
                    Image(systemName: "chevron.right")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("下个月")
            }

            WeekdayHeaderView(weekdayStart: viewModel.weekdayStart)
            MonthGridView(days: viewModel.days, onSelect: viewModel.select(date:))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.selectedDayTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(viewModel.selectedDayStatus)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(selectedStatusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedStatusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(viewModel.selectedDaySubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var selectedStatusColor: Color {
        guard let day = viewModel.selectedDay else {
            return .secondary
        }

        if day.isToday || day.isHoliday {
            return .red
        }

        if day.isWorkdayOverride {
            return .orange
        }

        if day.isWeekend {
            return .blue
        }

        return .secondary
    }
}

#Preview {
    IOSCalendarRootView()
}
