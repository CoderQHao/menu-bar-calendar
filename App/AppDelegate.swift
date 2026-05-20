//
//  AppDelegate.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import AppKit
import SwiftUI

@MainActor
/// Owns the AppKit shell: menu bar item, popover hosting, and macOS lifecycle notifications.
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let viewModel = CalendarViewModel()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    // A lightweight fallback for missed sleep/wake or calendar-day notifications.
    private var statusRefreshTimer: Timer?
    private var notificationObservers: [NSObjectProtocol] = []
    private lazy var statusMenu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(
            withTitle: "打开日历",
            action: #selector(openCalendarFromMenu(_:)),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "退出",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        menu.items.forEach { $0.target = self }
        return menu
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ensureSingleInstance() else {
            return
        }

        NSApp.setActivationPolicy(.accessory)

        configurePopover()
        configureStatusItem()
        configureDateRefreshNotifications()
        viewModel.start()
        startStatusRefreshTimer()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 360, height: 440)
        popover.contentViewController = NSHostingController(
            rootView: CalendarView(
                viewModel: viewModel,
                onQuit: { [weak self] in
                    self?.quitApp(nil)
                }
            )
        )
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        guard let button = item.button else { return }
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        viewModel.onStatusTitleChange = { [weak self] title in
            self?.updateStatusItemTitle(title)
        }
        viewModel.onAppearanceModeChange = { mode in
            NSApp.appearance = mode.nsAppearance
        }
        updateStatusItemTitle()
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        guard let event = NSApp.currentEvent else { return }
        refreshCurrentDateAndStatusItem()

        if event.type == .rightMouseUp {
            if popover.isShown {
                popover.performClose(sender)
            }
            statusItem?.menu = statusMenu
            button.performClick(nil)
            statusItem?.menu = nil
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            viewModel.refreshVisibleMonth()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc
    private func openCalendarFromMenu(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        refreshCurrentDateAndStatusItem()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func refreshCurrentDateAndStatusItem() {
        viewModel.refreshCurrentDate()
        updateStatusItemTitle()
    }

    private func updateStatusItemTitle(_ title: String? = nil) {
        guard let button = statusItem?.button else { return }

        button.title = title ?? viewModel.statusTitle
        // NSStatusItem can keep an old intrinsic width after sleep/wake, so force a relayout.
        button.invalidateIntrinsicContentSize()
        button.needsLayout = true
        button.needsDisplay = true
        statusItem?.length = NSStatusItem.variableLength
    }

    private func startStatusRefreshTimer() {
        statusRefreshTimer?.invalidate()
        statusRefreshTimer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCurrentDateAndStatusItem()
            }
        }
        RunLoop.main.add(statusRefreshTimer!, forMode: .common)
    }

    private func configureDateRefreshNotifications() {
        // macOS does not guarantee a single notification for every "new visible day" path.
        // Listen to calendar changes, clock edits, wake, screen wake, and unlock/session resume.
        let notificationCenter = NotificationCenter.default
        notificationObservers.append(
            notificationCenter.addObserver(
                forName: .NSCalendarDayChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshCurrentDateAndStatusItem()
                }
            }
        )
        notificationObservers.append(
            notificationCenter.addObserver(
                forName: .NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshCurrentDateAndStatusItem()
                }
            }
        )
        notificationObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshCurrentDateAndStatusItem()
                }
            }
        )
        notificationObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshCurrentDateAndStatusItem()
                }
            }
        )
        notificationObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshCurrentDateAndStatusItem()
                }
            }
        )
    }

    @objc
    private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func ensureSingleInstance() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return true
        }

        // Menu bar apps are especially confusing when duplicated, because only one copy is visible.
        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let otherInstances = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { $0.processIdentifier != currentProcessIdentifier }

        guard let existingInstance = otherInstances.first else {
            return true
        }

        existingInstance.activate()
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
        return false
    }
}
