//
//  MenuBarCalendarApp.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

@main
struct MenuBarCalendarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
