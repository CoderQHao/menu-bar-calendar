import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 12) {
            if isShowingSettings {
                SettingsView(
                    appearanceMode: viewModel.appearanceMode,
                    weekdayStart: viewModel.weekdayStart,
                    onAppearanceModeChange: viewModel.setAppearanceMode,
                    onWeekdayStartChange: viewModel.setWeekdayStart,
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
        .preferredColorScheme(viewModel.appearanceMode.colorScheme)
    }
}
