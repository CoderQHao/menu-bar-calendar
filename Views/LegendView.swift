//
//  LegendView.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

struct LegendView: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem("今日", color: .red)
            legendBadge("休", color: .red)
            legendBadge("班", color: .orange)
            legendItem("周末", color: .blue)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func legendItem(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
        }
    }

    private func legendBadge(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(color)
                .clipShape(Capsule())
            Text(title == "休" ? "法定休息日" : "调休上班")
        }
    }
}
