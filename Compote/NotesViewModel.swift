//
//  NotesViewModel.swift
//  Compote
//
//  Created by James MARTIN on 05.03.2024.
//

import Foundation
import SwiftUI

class NotesViewModel: ObservableObject {
    @Published var notesContent: [String] = []
    
    func fetchNotesContent() {
        let scriptSource = """
            tell application "Notes"
                tell account "iCloud"
                    tell folder "Notes"
                        set noteBodies to {}
                        set noteList to every note
                        repeat with aNote in noteList
                            set end of noteBodies to body of aNote
                        end repeat
                    end tell
                end tell
            end tell
            
            return noteBodies
            """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptSource) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                // Check if the output contains a list of items.
                if output.descriptorType != typeNull {
                    for i in 1...output.numberOfItems {
                        if let item = output.atIndex(i) {
                            // Extracting the raw data of the descriptor as string.
                            let dataString = item.stringValue ?? "Data could not be decoded"
                            self.notesContent.append(dataString)
                        }
                    }
                } else {
                    print("Script execution failed or returned no data")
                }
            } else {
                print("Script execution failed with error: \(String(describing: error))")
            }
        }
    }
}
