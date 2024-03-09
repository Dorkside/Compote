tell application "Notes"
    tell account "iCloud"
        tell folder "Notes"
            set noteDetails to {}
            set noteList to every note
            repeat with aNote in noteList
                set end of noteDetails to {id:id of aNote, name:name of aNote, body:body of aNote, creationDate:creation date of aNote, modificationDate:modification date of aNote}
            end repeat
        end tell
    end tell
end tell

return noteDetails
