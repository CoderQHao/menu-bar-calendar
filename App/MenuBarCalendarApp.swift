//
//  MenuBarCalendarApp.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import SwiftUI

@main
struct MenuBarCalendarApp: App {
    // The visible UI is managed from AppKit because this is an accessory menu-bar app.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
