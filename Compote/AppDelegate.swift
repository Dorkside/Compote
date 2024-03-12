import SwiftUI
import AppKit

import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusBarItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    var notesContent: [Note] = []
    var syncItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied because: \(error.localizedDescription).")
            }
        }
        
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        if let statusBarButton = statusBarItem.button {
            statusBarButton.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Compote")
        }
        
        let statusBarMenu = NSMenu(title: "Compote Menu")
        statusBarMenu.autoenablesItems = false
        statusBarItem.menu = statusBarMenu
        
        self.syncItem = statusBarMenu.addItem(
            withTitle: "Sync",
            action: #selector(AppDelegate.triggerSync),
            keyEquivalent: "")
        
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
    
    @objc func triggerSync() {
        self.fetchNotesContent()
    }
    
    func scheduleNotification(title: String, body: String, delay: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create a unique identifier for the request.
        let requestIdentifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled!")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Display the notification even when the app is in the foreground
        completionHandler([.sound])
    }
    
    func fetchNotesContent() {
        self.notesContent.removeAll()
        
        self.scheduleNotification(title:"Syncing notes...", body:"", delay:1)
        self.syncItem?.title = "Syncing notes..."
        DispatchQueue.main.async {
            self.syncItem?.isEnabled = false
        }
        let lastExecution = UserDefaults.standard.object(forKey: "lastExecution") as? Date

        // Locate the AppleScript file in the bundle
        guard let scriptFilePath = Bundle.main.path(forResource: "FetchNotes", ofType: "scpt"), let scriptTemplate = try? String(contentsOfFile: scriptFilePath) else {
            print("Unable to find FetchNotes.scpt")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        var dateString = dateFormatter.string(from: lastExecution ?? Date())
        var scriptWithArgument = scriptTemplate.replacingOccurrences(of: "/*TARGET_DAY*/", with: dateString)
        dateFormatter.dateFormat = "MM"
        dateString = dateFormatter.string(from: lastExecution ?? Date())
        scriptWithArgument = scriptWithArgument.replacingOccurrences(of: "/*TARGET_MONTH*/", with: dateString)
        dateFormatter.dateFormat = "yyyy"
        dateString = dateFormatter.string(from: lastExecution ?? Date())
        scriptWithArgument = scriptWithArgument.replacingOccurrences(of: "/*TARGET_YEAR*/", with: dateString)
        
        do {
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: scriptWithArgument) {
                let output = scriptObject.executeAndReturnError(&error)
                if error == nil {
                    // Process the script output as before
                    if output.descriptorType != typeNull {
                        guard let listDescriptor = output.coerce(toDescriptorType: typeAEList) else {
                            print("Output is not a list")
                            return
                        }
                        
                        for i in 1...listDescriptor.numberOfItems {
                            guard let recordDescriptor = listDescriptor.atIndex(i) else { continue }
                            
                            let noteIdKeyword = FourCharCode("ID  ".fourCharCodeValue)
                            let noteNameKeyword = FourCharCode("pnam".fourCharCodeValue)
                            let noteBodyKeyword = FourCharCode("body".fourCharCodeValue)
                            let usrfKeyword = FourCharCode("usrf".fourCharCodeValue)

                            let noteId = recordDescriptor.paramDescriptor(forKeyword: noteIdKeyword as FourCharCode)?.stringValue ?? ""
                            let noteName = recordDescriptor.paramDescriptor(forKeyword: noteNameKeyword)?.stringValue ?? ""
                            let noteBody = recordDescriptor.paramDescriptor(forKeyword: noteBodyKeyword)?.stringValue ?? ""
                            
                            var userData: [String: String] = [:]
                            if let usrfDescriptor = recordDescriptor.paramDescriptor(forKeyword: usrfKeyword) {
                                // Coerce the descriptor to a list type if needed
                                if let usrfList = usrfDescriptor.coerce(toDescriptorType: typeAEList) {
                                    // The list contains key-value pairs in sequence, so iterate through it two items at a time
                                    let itemCount = usrfList.numberOfItems
                                    var index = 1
                                    while index < itemCount {
                                        // Assuming keys and values are both text ('utxt'), extract them as strings
                                        if let keyDescriptor = usrfList.atIndex(index),
                                           let valueDescriptor = usrfList.atIndex(index + 1),
                                           let key = keyDescriptor.stringValue,
                                           let value = valueDescriptor.stringValue {
                                            // Add the key-value pair to the dictionary
                                            userData[key] = value
                                        }
                                        index += 2 // Move to the next key-value pair
                                    }
                                }
                            }

                            let note = Note(id: noteId,
                                            name: noteName,
                                            body: noteBody,
                                            creationDate: userData["creationDate"] ?? "",
                                            modificationDate: userData["modificationDate"] ?? ""
                            )

                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.notesContent.append(note)
                                self.scheduleNotification(title:"Sync done", body:"Successfully synced " + self.notesContent.count.codingKey.stringValue + " notes", delay:1)
                                
                                self.syncItem?.title = "Sync"
                                DispatchQueue.main.async {
                                    self.syncItem?.isEnabled = true
                                }
                                UserDefaults.standard.set(Date(), forKey: "lastExecution")
                            }
                            
                        }
                    } else {
                        print("Script execution failed or returned no data")
                    }
                } else {
                    print("Script execution failed with error: \(String(describing: error))")
                }
            }
        } catch {
            print("Failed to load AppleScript from file with error: \(error)")
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clear the reference to the preferences window when it's closed
        preferencesWindow = nil
    }
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}

struct Note {
    var id: String
    var name: String
    var body: String
    var creationDate: String
    var modificationDate: String
}
