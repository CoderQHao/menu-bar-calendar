import SwiftUI

struct CalendarHeaderView: View {
    let title: String
    let canReturnToToday: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                headerButton(symbol: "chevron.left", action: onPrevious)
                Spacer()
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                headerButton(symbol: "gearshape", action: onOpenSettings)
            }

            HStack {
                Spacer()
                Button("回到今天", action: onToday)
                    .buttonStyle(.link)
                    .disabled(!canReturnToToday)
                headerButton(symbol: "chevron.right", action: onNext)
            }
        }
    }

    private func headerButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
