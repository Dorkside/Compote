import Foundation
import AppKit

class SyncManager {
    static let shared = SyncManager()
    
    func triggerSync() {
        self.fetchNotesContent()
    }
    
    func fetchNotesContent() {
        NotificationCenter.default.post(name: Notification.Name("SyncStarted"), object: nil)
        let lastExecution = UserDefaults.standard.object(forKey: "lastExecution") as? Date
        
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
                    if output.descriptorType != typeNull {
                        guard let listDescriptor = output.coerce(toDescriptorType: typeAEList) else {
                            print("Output is not a list")
                            return
                        }
                        
                        var notesContent: [Note] = []
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
                            notesContent.append(note)
                        }
                        NotificationCenter.default.post(name: Notification.Name("SyncCompleted"), object: nil, userInfo: ["notesContent": notesContent])
                        UserDefaults.standard.set(Date(), forKey: "lastExecution")
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
