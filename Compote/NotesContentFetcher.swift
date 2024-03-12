import Cocoa

class NotesContentFetcher {
    static var notesContent: [Note] = []

    static func fetchNotesContent(syncItem: NSMenuItem?) {
        self.notesContent.removeAll()
        
        NotificationManager.scheduleNotification(title: "Syncing notes...", body: "", delay: 1)
        syncItem?.title = "Syncing notes..."
        DispatchQueue.main.async {
            syncItem?.isEnabled = false
        }
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
                        
                        for i in 1...listDescriptor.numberOfItems {
                            guard let recordDescriptor = listDescriptor.atIndex(i) else { continue }
                            
                            let noteIdKeyword = FourCharCode("ID  ".fourCharCodeValue)
                            let noteNameKeyword = FourCharCode("pnam".fourCharCodeValue)
                            let noteBodyKeyword = FourCharCode("body".fourCharCodeValue)
                            
                            let noteId = recordDescriptor.paramDescriptor(forKeyword: noteIdKeyword as FourCharCode)?.stringValue ?? ""
                            let noteName = recordDescriptor.paramDescriptor(forKeyword: noteNameKeyword)?.stringValue ?? ""
                            let noteBody = recordDescriptor.paramDescriptor(forKeyword: noteBodyKeyword)?.stringValue ?? ""
                            
                            let note = Note(id: noteId, name: noteName, body: noteBody, creationDate: "", modificationDate: "")
                            self.notesContent.append(note)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            NotificationManager.scheduleNotification(title: "Sync done", body: "Successfully synced \(self.notesContent.count) notes", delay: 1)
                            syncItem?.title = "Sync"
                            DispatchQueue.main.async {
                                syncItem?.isEnabled = true
                            }
                            UserDefaults.standard.set(Date(), forKey: "lastExecution")
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
