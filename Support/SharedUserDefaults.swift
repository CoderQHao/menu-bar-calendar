//
//  SharedUserDefaults.swift
//  MenuBarCalendar
//
//  Created by Codex on 2026/5/28.
//

import Foundation

enum SharedUserDefaults {
    static let appGroupIdentifier = "group.com.example.MenuBarCalendar"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
