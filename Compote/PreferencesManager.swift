import Cocoa

class PreferencesManager {
    static var preferencesWindow: NSWindow?

    static func openPreferencesWindow() {
        if let preferencesWindow = preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 200))
        window.center()
        window.setFrameAutosaveName("Preferences")
        window.title = "Preferences"
        window.makeKeyAndOrderFront(nil)
        self.preferencesWindow = window
        
        NSApp.activate(ignoringOtherApps: true)
        window.isReleasedWhenClosed = false
        window.delegate = AppDelegate() as? NSWindowDelegate
    }
}
