import SwiftUI
import AppKit

class PreferencesManager {
    static func openPreferencesWindow(preferencesWindow: inout NSWindow?) {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        let window = NSWindow(contentViewController: hostingController)
        window.setFrameAutosaveName("Preferences")
        window.title = "Preferences"
        window.makeKeyAndOrderFront(nil)
        preferencesWindow = window
        
        NSApp.activate(ignoringOtherApps: true)
        
        window.isReleasedWhenClosed = false
        window.delegate = AppDelegate() as NSWindowDelegate
    }
}
