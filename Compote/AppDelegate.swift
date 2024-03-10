import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        if let statusBarButton = statusBarItem.button {
            statusBarButton.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Notes")
        }
        
        let statusBarMenu = NSMenu(title: "Status Bar Menu")
        statusBarItem.menu = statusBarMenu
        
        statusBarMenu.addItem(
            withTitle: "Open Preferences...",
            action: #selector(AppDelegate.openPreferences),
            keyEquivalent: "")
        
        statusBarMenu.addItem(
            NSMenuItem.separator())
        
        statusBarMenu.addItem(
            withTitle: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
    }
    
    @objc func openPreferences() {
        // Check if we already have a preferences window and bring it to front
        if let preferencesWindow = preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create the preferences window and content
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 200))
        window.center()
        window.setFrameAutosaveName("Preferences")
        window.title = "Preferences"
        window.makeKeyAndOrderFront(nil)
        self.preferencesWindow = window
        
        // Ensure the preferences window is brought to the front and activate the app
        NSApp.activate(ignoringOtherApps: true)
        
        // Optional: Clean up when the window is closed
        window.isReleasedWhenClosed = false
        window.delegate = self
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clear the reference to the preferences window when it's closed
        preferencesWindow = nil
    }
}
