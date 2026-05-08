//
//  MonthGridView.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

struct MonthGridView: View {
    let days: [DayModel]
    let onSelect: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days) { day in
                DayCellView(day: day)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(day.date)
                    }
            }
        }
    }
}
