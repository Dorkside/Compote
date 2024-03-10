tell application "Notes"
    tell account "iCloud"
        tell folder "Notes"
            set noteDetails to {}
            set noteList to every note
            repeat with aNote in noteList
                set targetDate to current date
                set day of targetDate to /*TARGET_DAY*/
                set month of targetDate to /*TARGET_MONTH*/
                set year of targetDate to /*TARGET_YEAR*/
                set hours of targetDate to 0
                set minutes of targetDate to 0
                set seconds of targetDate to 0
                if (modification date of aNote) > targetDate then
                    set currentCreationDate to creation date of aNote
                    set creationDateString to (year of currentCreationDate as string) & "-" & ((month of currentCreationDate as integer) as string) & "-" & (day of currentCreationDate as string) & "T" & (hours of currentCreationDate as string) & ":" & (minutes of currentCreationDate as string) & ":" & (seconds of currentCreationDate as string) & "Z"
                    
                    set currentModificationDate to modification date of aNote
                    set modificationDateString to (year of currentModificationDate as string) & "-" & ((month of currentModificationDate as integer) as string) & "-" & (day of currentModificationDate as string) & "T" & (hours of currentModificationDate as string) & ":" & (minutes of currentModificationDate as string) & ":" & (seconds of currentModificationDate as string) & "Z"
                    
                    set end of noteDetails to {id:id of aNote, name:name of aNote, body:body of aNote, creationDate:creationDateString, modificationDate:modificationDateString}
                end if
            end repeat
        end tell
    end tell
end tell
return noteDetails

