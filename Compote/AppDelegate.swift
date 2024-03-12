import SwiftUI
import AppKit
import UserNotifications
import PreferencesManager
import NotificationManager
import NotesContentFetcher

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusBarItem: NSStatusItem!
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
            statusBarButton.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Notes")
        }
        
        let statusBarMenu = NSMenu(title: "Status Bar Menu")
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
        PreferencesManager.openPreferencesWindow()
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
