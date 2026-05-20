//
//  HolidayService.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation

/// Reads yearly holiday JSON and exposes fast day lookups for official rest/workday overrides.
final class HolidayService {
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default
    private let calendar = Calendar(identifier: .gregorian)
    private var cachedYears: [Int: [String: HolidayDayPayload]] = [:]

    init() {
        decoder.keyDecodingStrategy = .useDefaultKeys
    }

    func preload(years: [Int]) {
        for year in years {
            if cachedYears[year] == nil {
                cachedYears[year] = loadYear(year: year)
            }
        }
    }

    func holidayInfo(for date: Date) -> HolidayDayPayload? {
        let year = calendar.component(.year, from: date)
        if cachedYears[year] == nil {
            cachedYears[year] = loadYear(year: year)
        }

        let key = Self.storageFormatter.string(from: date)
        return cachedYears[year]?[key]
    }

    private func loadYear(year: Int) -> [String: HolidayDayPayload]? {
        // User-updated data in Application Support wins over the bundled fallback.
        if let cached = loadFromApplicationSupport(year: year) {
            return cached
        }

        return loadBundled(year: year)
    }

    private func loadBundled(year: Int) -> [String: HolidayDayPayload]? {
        guard let url = ResourceBundleProvider.bundle.url(forResource: "\(year)", withExtension: "json") else {
            return nil
        }

        return loadMappedPayload(from: url)
    }

    private func loadFromApplicationSupport(year: Int) -> [String: HolidayDayPayload]? {
        guard let url = applicationSupportDirectory()?.appendingPathComponent("\(year).json") else {
            return nil
        }

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        return loadMappedPayload(from: url)
    }

    private func loadMappedPayload(from url: URL) -> [String: HolidayDayPayload]? {
        guard let payload = try? decoder.decode(HolidayYearPayload.self, from: Data(contentsOf: url)) else {
            return nil
        }

        // Convert the source array into a date-keyed dictionary because calendar cells query per day.
        return Dictionary(uniqueKeysWithValues: payload.days.map { day in
            let info = HolidayDayPayload(
                name: day.name,
                isHoliday: day.isOffDay,
                isWorkdayOverride: !day.isOffDay
            )
            return (day.date, info)
        })
    }

    private func applicationSupportDirectory() -> URL? {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("MenuBarCalendar", isDirectory: true)
    }

    private static let storageFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        // Holiday JSON is keyed by China-local dates, not by the machine's current time zone.
        formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
