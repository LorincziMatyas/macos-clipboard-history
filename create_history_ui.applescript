# FILENAME: create_history_ui.applescript
# AUTHOR: Lorinczi Matyas
# DESCRIPTION: This script creates a UI for the clipboard history
# USAGE: osascript create_history_ui.applescript "item1" "item2" "item3" "item4" "item5" ...
on run argv
    tell application "System Events"
        activate
    end tell
    
    set itemList to {}
    repeat with i from 1 to count of argv
        set end of itemList to item i of argv
    end repeat
    
    set theResponse to choose from list itemList with prompt "Latest clipboard content on top. \nSelect from the items below:" default items {item 1 of itemList} with title "Clipboard History"
    return theResponse
end run