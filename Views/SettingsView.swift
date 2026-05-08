//
//  SettingsView.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

@MainActor
struct SettingsView: View {
    let appearanceMode: AppearanceMode
    let weekdayStart: WeekdayStart
    let statusDateFormat: StatusDateFormat
    let launchAtLoginEnabled: Bool
    let canManageLaunchAtLogin: Bool
    let launchAtLoginMessage: String?
    let onAppearanceModeChange: (AppearanceMode) -> Void
    let onWeekdayStartChange: (WeekdayStart) -> Void
    let onStatusDateFormatChange: (StatusDateFormat) -> Void
    let onLaunchAtLoginChange: (Bool) -> Void
    let onQuit: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: onClose) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(minWidth: 64, minHeight: 32, alignment: .leading)
                    .contentShape(Rectangle())
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

            settingCard(title: "菜单栏日期") {
                Picker("菜单栏日期", selection: statusDateFormatBinding) {
                    ForEach(StatusDateFormat.allCases) { format in
                        Text("\(format.title) · \(format.previewText(for: Date()))").tag(format)
                    }
                }

                Text("当前预览：\(statusDateFormat.previewText(for: Date()))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            settingCard(title: "开机启动") {
                Toggle("登录 macOS 时自动打开今历", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
                    .disabled(!canManageLaunchAtLogin)

                if let launchAtLoginMessage {
                    Text(launchAtLoginMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onQuit) {
                Text("退出应用")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Spacer()
        }
        .padding(14)
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(get: { appearanceMode }, set: { onAppearanceModeChange($0) })
    }

    private var weekdayBinding: Binding<WeekdayStart> {
        Binding(get: { weekdayStart }, set: { onWeekdayStartChange($0) })
    }

    private var statusDateFormatBinding: Binding<StatusDateFormat> {
        Binding(get: { statusDateFormat }, set: { onStatusDateFormatChange($0) })
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(get: { launchAtLoginEnabled }, set: { onLaunchAtLoginChange($0) })
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
