//
//  AppearanceMode.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import AppKit
import SwiftUI

/// App appearance preference, bridged to both AppKit and SwiftUI surfaces.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色"
        case .dark:
            return "深色"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func resolvedColorScheme(using appearance: NSAppearance?) -> ColorScheme? {
        // SwiftUI popover content needs an explicit scheme even when AppKit follows the system.
        switch self {
        case .system:
            let bestMatch = appearance?.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
