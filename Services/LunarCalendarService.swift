//
//  LunarCalendarService.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation

final class LunarCalendarService {
    private let lunarCalendar = Calendar(identifier: .chinese)
    private let gregorianCalendar = Calendar(identifier: .gregorian)

    func secondaryText(for date: Date, holidayName: String?) -> String {
        if let holidayName, !holidayName.isEmpty {
            return holidayName
        }

        if let festival = traditionalFestival(for: date) {
            return festival
        }

        if let solarTerm = solarTerm(for: date) {
            return solarTerm
        }

        return lunarLabel(for: date)
    }

    private func lunarLabel(for date: Date) -> String {
        let components = lunarCalendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return ""
        }

        if day == 1 {
            return Self.lunarMonths[normalized(month) - 1]
        }

        return Self.lunarDays[day - 1]
    }

    private func traditionalFestival(for date: Date) -> String? {
        let components = lunarCalendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return nil
        }

        return Self.traditionalFestivals["\(normalized(month))-\(day)"]
    }

    private func solarTerm(for date: Date) -> String? {
        let components = gregorianCalendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return nil
        }

        return Self.solarTerms["\(month)-\(day)"]
    }

    private func normalized(_ lunarMonth: Int) -> Int {
        abs(lunarMonth)
    }

    private static let lunarMonths = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月"
    ]

    private static let lunarDays = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    private static let traditionalFestivals: [String: String] = [
        "1-1": "春节",
        "1-15": "元宵节",
        "5-5": "端午节",
        "7-7": "七夕",
        "8-15": "中秋节",
        "9-9": "重阳节",
        "12-8": "腊八节",
        "12-23": "小年"
    ]

    // MVP 先用静态表覆盖常见节气展示，后续可替换为高精度算法。
    private static let solarTerms: [String: String] = [
        "2-4": "立春", "2-19": "雨水",
        "3-5": "惊蛰", "3-20": "春分",
        "4-4": "清明", "4-20": "谷雨",
        "5-5": "立夏", "5-21": "小满",
        "6-5": "芒种", "6-21": "夏至",
        "7-7": "小暑", "7-22": "大暑",
        "8-7": "立秋", "8-23": "处暑",
        "9-7": "白露", "9-23": "秋分",
        "10-8": "寒露", "10-23": "霜降",
        "11-7": "立冬", "11-22": "小雪",
        "12-7": "大雪", "12-21": "冬至",
        "1-5": "小寒", "1-20": "大寒"
    ]
}
