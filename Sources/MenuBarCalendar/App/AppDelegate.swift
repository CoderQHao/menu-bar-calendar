import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let viewModel = CalendarViewModel()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
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
        viewModel.start()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 320, height: 372)
        popover.contentViewController = NSHostingController(
            rootView: CalendarView(viewModel: viewModel)
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
            self?.statusItem?.button?.title = title
        }
        viewModel.onAppearanceModeChange = { mode in
            NSApp.appearance = mode.nsAppearance
        }
        button.title = viewModel.statusTitle
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        guard let event = NSApp.currentEvent else { return }

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
        viewModel.refreshVisibleMonth()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    @objc
    private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func ensureSingleInstance() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return true
        }

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
