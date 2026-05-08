//
//  DayCellView.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

struct DayCellView: View {
    let day: DayModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Text("\(day.solarDay)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(primaryColor)

                Text(day.secondaryText)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(secondaryColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.vertical, 6)
            .background(backgroundShape)

            if let badgeText = day.badgeText {
                Text(badgeText)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(day.isHoliday ? Color.red : Color.orange)
                    .clipShape(Capsule())
                    .offset(x: -2, y: 2)
            }
        }
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if day.isToday {
            return .red
        }
        if day.isSelected {
            return Color.secondary.opacity(0.12)
        }
        return .clear
    }

    private var primaryColor: Color {
        if day.isToday {
            return .white
        }
        if !day.isInCurrentMonth {
            return .secondary.opacity(0.55)
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
            return .white.opacity(0.92)
        }
        if !day.isInCurrentMonth {
            return .secondary.opacity(0.5)
        }
        if day.isHoliday {
            return .red.opacity(0.9)
        }
        return .secondary
    }
}
