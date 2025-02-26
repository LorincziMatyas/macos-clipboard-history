#!/usr/bin/osascript

-- FILENAME: clipboard_history.applescript
-- AUTHOR: Lorinczi Matyas
-- DESCRIPTION: A simple clipboard history tool for macOS using AppleScript.
-- USAGE: Run with arguments
--   chmod +x clipboard_history.applescript
--   osascript clipboard_history.applescript [start|clear|show|stop]
--   start - to start the clipboard listener
--   clear - to clear the history
--   show - to show the history
--   stop - to stop the listener.

-- Variables
property MAX_HISTORY : 20
property HISTORY_FOLDER : (path to home folder as text) & ".clipboard_history/.history_files"
property PID_FILE : (path to home folder as text) & ".clipboard_history/.listener_pid"

-- Main script execution begins here
on run argv
    -- Create history folder if it doesn't exist
    createHistoryFolder()
    
    -- Process arguments
    if (count of argv) is 0 then
        -- No arguments provided, show usage
        display dialog "Usage: osascript clipboard_history.applescript [start|clear|show|stop]" buttons {"OK"} default button "OK"
    else
        set command to item 1 of argv
        
        if command is "start" then
            startHistory()
        else if command is "clear" then
            clearHistory()
        else if command is "show" then
            showHistory()
        else if command is "stop" then
            stopHistory()
        else
            -- Invalid argument
            display dialog "Usage: osascript clipboard_history.applescript [start|clear|show|stop]" buttons {"OK"} default button "OK"
        end if
    end if
end run

-- Create history folder if it doesn't exist
on createHistoryFolder()
    do shell script "mkdir -p " & quoted form of (POSIX path of HISTORY_FOLDER)
end createHistoryFolder

-- Start clipboard history monitoring
on startHistory()
    -- Check if listener is already running
    try
        set isRunning to false
        set posixPidFile to POSIX path of PID_FILE
        
        set pidFileExists to do shell script "[ -f " & quoted form of posixPidFile & " ] && echo 'yes' || echo 'no'"
        
        if pidFileExists is "yes" then
            set oldPID to do shell script "cat " & quoted form of posixPidFile
            
            -- Check if process is running
            set processRunning to do shell script "ps -p " & oldPID & " > /dev/null 2>&1 && echo 'yes' || echo 'no'"
            
            if processRunning is "yes" then
                set isRunning to true
                display dialog "Clipboard listener is already running (PID: " & oldPID & ")." buttons {"OK"} default button "OK"
            end if
        end if
        
        if not isRunning then
            -- Create a separate shell script for monitoring
            set monitorScript to "#!/bin/bash
HISTORY_FOLDER=\"" & POSIX path of HISTORY_FOLDER & "\"
MAX_HISTORY=" & MAX_HISTORY & "

# Function to rotate history files
rotate_history() {
    local new_content=\"$1\"
    
    # Check if content is different from the most recent entry
    if [[ -f \"${HISTORY_FOLDER}/1\" ]] && [[ \"$(cat \"${HISTORY_FOLDER}/1\")\" == \"$new_content\" ]]; then
        return
    fi
    
    # Rotate files
    for ((i=MAX_HISTORY; i>1; i--)); do
        prev=$((i-1))
        if [[ -f \"${HISTORY_FOLDER}/${prev}\" ]]; then
            mv \"${HISTORY_FOLDER}/${prev}\" \"${HISTORY_FOLDER}/${i}\"
        fi
    done
    
    # Save new content to file 1
    echo \"$new_content\" > \"${HISTORY_FOLDER}/1\"
}

# Monitor clipboard
LAST_CLIPBOARD=\"\"
while true; do
    CURRENT_CLIPBOARD=$(osascript -e 'try' -e 'the clipboard as text' -e 'on error' -e '\"\"' -e 'end try' 2>/dev/null)
    if [[ -n \"$CURRENT_CLIPBOARD\" && \"$CURRENT_CLIPBOARD\" != \"$LAST_CLIPBOARD\" ]]; then
        rotate_history \"$CURRENT_CLIPBOARD\"
        LAST_CLIPBOARD=\"$CURRENT_CLIPBOARD\"
    fi
    sleep 1
done"

            -- Write monitor script to a temporary file
            set monitorScriptPath to "/tmp/clipboard_monitor.sh"
            do shell script "echo " & quoted form of monitorScript & " > " & monitorScriptPath
            do shell script "chmod +x " & monitorScriptPath
            
            -- Start the monitor script in the background
            set newPID to do shell script monitorScriptPath & " > /dev/null 2>&1 & echo $!"
            
            -- Save PID to file
            do shell script "echo " & newPID & " > " & quoted form of posixPidFile
            
            display dialog "Clipboard listener started (PID: " & newPID & ")" buttons {"OK"} default button "OK"
        end if
    on error errMsg
        display dialog "Error starting clipboard history: " & errMsg buttons {"OK"} default button "OK"
    end try
end startHistory

-- Clear clipboard history
on clearHistory()
    try
        do shell script "rm -rf " & quoted form of (POSIX path of HISTORY_FOLDER)
        createHistoryFolder()
        display dialog "Clipboard history cleared." buttons {"OK"} default button "OK"
    on error errMsg
        display dialog "Error clearing clipboard history: " & errMsg buttons {"OK"} default button "OK"
    end try
end clearHistory

-- Show clipboard history
on showHistory()
    try
        set historyItems to {}
        set itemFiles to {}
        set posixHistoryFolder to POSIX path of HISTORY_FOLDER
        
        -- Build array of items
        repeat with i from 1 to MAX_HISTORY
            set historyFile to posixHistoryFolder & "/" & i
            
            -- Check if file exists
            set fileExists to do shell script "[ -f " & quoted form of historyFile & " ] && echo 'yes' || echo 'no'"
            
            if fileExists is "yes" then
                set fileContent to do shell script "cat " & quoted form of historyFile
                
                -- Truncate content for display
                if length of fileContent > 100 then
                    set preview to text 1 thru 100 of fileContent & "..."
                else
                    set preview to fileContent
                end if
                
                -- Add to lists
                set end of historyItems to preview
                set end of itemFiles to historyFile
            end if
        end repeat
        
        -- If no items found, show message
        if (count of historyItems) is 0 then
            display dialog "No clipboard history found." buttons {"OK"} default button "OK"
            return
        end if
        
        -- Show dialog with history items
        set theChoice to choose from list historyItems with prompt "Latest clipboard content on top. Select from the items below:" default items {item 1 of historyItems} with title "Clipboard History"
        
        -- If user made a selection, copy to clipboard
        if theChoice is not false then
            set selectedIndex to 0
            set selectedItem to item 1 of theChoice
            
            -- Find the index of the selected item
            repeat with i from 1 to (count of historyItems)
                if item i of historyItems is selectedItem then
                    set selectedIndex to i
                    exit repeat
                end if
            end repeat
            
            -- Get the full content from the file
            if selectedIndex > 0 then
                set selectedFile to item selectedIndex of itemFiles
                set fileContent to do shell script "cat " & quoted form of selectedFile
                
                -- Set clipboard using shell command for better compatibility
                do shell script "echo " & quoted form of fileContent & " | pbcopy"
                
                -- Confirm for the user
                display dialog "Copied to clipboard!" buttons {"OK"} default button "OK" with title "Clipboard History"
            end if
        end if
    on error errMsg
        display dialog "Error showing clipboard history: " & errMsg buttons {"OK"} default button "OK"
    end try
end showHistory

-- Stop clipboard history listener
on stopHistory()
    try
        set posixPidFile to POSIX path of PID_FILE
        set pidFileExists to do shell script "[ -f " & quoted form of posixPidFile & " ] && echo 'yes' || echo 'no'"
        
        if pidFileExists is "yes" then
            set pidValue to do shell script "cat " & quoted form of posixPidFile
            
            -- Kill process
            do shell script "kill " & pidValue
            
            -- Remove PID file
            do shell script "rm " & quoted form of posixPidFile
            
            display dialog "Clipboard listener stopped." buttons {"OK"} default button "OK"
        else
            display dialog "No clipboard listener is running." buttons {"OK"} default button "OK"
        end if
    on error errMsg
        display dialog "Error stopping clipboard history: " & errMsg buttons {"OK"} default button "OK"
    end try
end stopHistory
