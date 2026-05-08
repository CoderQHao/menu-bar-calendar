import SwiftUI

struct SettingsView: View {
    let appearanceMode: AppearanceMode
    let weekdayStart: WeekdayStart
    let onAppearanceModeChange: (AppearanceMode) -> Void
    let onWeekdayStartChange: (WeekdayStart) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: onClose) {
                    Label("返回", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text("设置")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Color.clear
                    .frame(width: 44, height: 28)
            }

            settingCard(title: "显示模式") {
                Picker("显示模式", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            settingCard(title: "每周第一天") {
                Picker("每周第一天", selection: weekdayBinding) {
                    ForEach(WeekdayStart.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Spacer()
        }
        .padding(14)
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { appearanceMode }, set: onAppearanceModeChange)
    }

    private var weekdayBinding: Binding<WeekdayStart> {
        Binding(get: { weekdayStart }, set: onWeekdayStartChange)
    }

    private func settingCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
