//
//  CalendarView.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let onQuit: () -> Void
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 12) {
            if isShowingSettings {
                SettingsView(
                    appearanceMode: viewModel.appearanceMode,
                    weekdayStart: viewModel.weekdayStart,
                    statusDateFormat: viewModel.statusDateFormat,
                    launchAtLoginEnabled: viewModel.launchAtLoginEnabled,
                    canManageLaunchAtLogin: viewModel.canManageLaunchAtLogin,
                    launchAtLoginMessage: viewModel.launchAtLoginMessage,
                    onAppearanceModeChange: viewModel.setAppearanceMode,
                    onWeekdayStartChange: viewModel.setWeekdayStart,
                    onStatusDateFormatChange: viewModel.setStatusDateFormat,
                    onLaunchAtLoginChange: viewModel.setLaunchAtLogin,
                    onQuit: onQuit,
                    onClose: { isShowingSettings = false }
                )
            } else {
                CalendarHeaderView(
                    title: viewModel.monthTitle,
                    canReturnToToday: viewModel.canReturnToToday,
                    onPrevious: viewModel.goToPreviousMonth,
                    onNext: viewModel.goToNextMonth,
                    onToday: viewModel.goToToday,
                    onOpenSettings: { isShowingSettings = true }
                )

                WeekdayHeaderView(weekdayStart: viewModel.weekdayStart)
                MonthGridView(days: viewModel.days, onSelect: viewModel.select(date:))
                LegendView()
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(viewModel.appearanceMode.resolvedColorScheme(using: NSApp.effectiveAppearance))
    }
}
