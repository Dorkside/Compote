import SwiftUI
import AppKit

class PreferencesWindowManager: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowManager()
    private var preferencesWindow: NSWindow?

    func openPreferences() {
        if let preferencesWindow = preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
            return
        }

        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        let window = NSWindow(contentViewController: hostingController)
        window.setFrameAutosaveName("Preferences")
        window.title = "Preferences"
        window.makeKeyAndOrderFront(nil)
        self.preferencesWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.isReleasedWhenClosed = false
        window.delegate = self
    }

    func windowWillClose(_ notification: Notification) {
        preferencesWindow = nil
    }
}
