import SwiftUI

struct WeekdayHeaderView: View {
    let weekdayStart: WeekdayStart

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdayStart.orderedWeekdays.enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(weekday == "六" || weekday == "日" ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
