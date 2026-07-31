//
//  IOSSettingsView.swift
//  MenuBarCalendar
//
//  Created by Codex on 2026/5/28.
//

import SwiftUI

struct IOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let weekdayStart: WeekdayStart
    let onWeekdayStartChange: (WeekdayStart) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("日历") {
                    Picker("每周第一天", selection: weekdayBinding) {
                        ForEach(WeekdayStart.allCases) { weekdayStart in
                            Text(weekdayStart.title).tag(weekdayStart)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("版本") {
                    LabeledContent("当前版本", value: Self.currentVersion)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var weekdayBinding: Binding<WeekdayStart> {
        Binding(get: { weekdayStart }, set: { onWeekdayStartChange($0) })
    }

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
}

#Preview {
    IOSSettingsView(weekdayStart: .sunday, onWeekdayStartChange: { _ in })
}
