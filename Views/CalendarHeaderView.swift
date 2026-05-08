//
//  CalendarHeaderView.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

struct CalendarHeaderView: View {
    let title: String
    let canReturnToToday: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            monthSwitchGroup
                .frame(width: 70, alignment: .leading)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 8) {
                todayButton
                headerButton(symbol: "gearshape", action: onOpenSettings)
            }
            .frame(width: 78, alignment: .trailing)
        }
    }

    private var monthSwitchGroup: some View {
        HStack(spacing: 6) {
            headerButton(symbol: "chevron.left", action: onPrevious)
            headerButton(symbol: "chevron.right", action: onNext)
        }
    }

    private var todayButton: some View {
        Button(action: onToday) {
            Text("今")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(canReturnToToday ? Color.white : Color.secondary)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(
                    Capsule(style: .continuous)
                        .fill(canReturnToToday ? Color.red : Color.secondary.opacity(0.08))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canReturnToToday)
        .opacity(canReturnToToday ? 1 : 0.7)
    }

    private func headerButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))

                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
