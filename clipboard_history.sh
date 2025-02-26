#!/bin/bash
# FILENAME: clipboard_history.sh
# AUTHOR: Lorinczi Matyas
# DESCRIPTION: A simple clipboard history tool for macOS using shell scripts and AppleScript.
# USAGE: Run the script with 
#   --start to start the clipboard listener
#   --clear to clear the history
#   --show to show the history
#   --stop to stop the listener.
# Running detached in the background so you can close the terminal. 
# nohup /path/to/macos-clipboard-history/clipboard_history.sh --start &

#######################################
############## Variables ##############
#######################################

# Define the path to the PID file
PID_FILE="$HOME/.clipboard_history/.listener_pid"

# Define the path to the history folder
HISTORY_FOLDER="$HOME/.clipboard_history/.history_files"

# Define the path to the AppleScript file, dirname is used to get the script's directory
APPLESCRIPT_FILE="$(dirname "$0")/create_history_ui.applescript"

# Define the maximum number of history files
MAX_HISTORY=20

#######################################
############## Commands ###############
#######################################

# Create necessary directory if it doesn't exist
# -p flag: Create intermediate directories as required.  If this option is not specified, the full path prefix of each operand must already exist.  On the other hand, with this option specified, no error will be reported if a directory given as an operand already exists.  Intermediate directories are created with permission bits of “rwxrwxrwx” (0777) as modified by the current umask, plus write and search permission for the owner.
mkdir -p "$HISTORY_FOLDER"

#######################################
############## Functions ##############
#######################################

# Function to rotate history files
rotate_history() {
    # Get the new content from the first argument
    local new_content="$1"
    
    # Check if content is different from the most recent entry
    # [ -f FILE ]	True if FILE exists and is a regular file.
    if [[ -f "${HISTORY_FOLDER}/1" ]] && [[ "$(cat "${HISTORY_FOLDER}/1")" == "$new_content" ]]; then
        return
    fi
    
    # Rotate files
    for ((i=MAX_HISTORY; i>1; i--)); do
        # Move the file with index i-1 to i
        # Prev stands for the previous index
        prev=$((i-1))

        # Check if the file exists
        if [[ -f "${HISTORY_FOLDER}/${prev}" ]]; then
            # Move the file to the new index
            # Check how to use mv with "man mv" command in the terminal
            mv "${HISTORY_FOLDER}/${prev}" "${HISTORY_FOLDER}/${i}"
        fi
    done
    
    # Save new content to file 1
    # echo prints the content to stdout, and the > operator redirects the output to a file
    echo "$new_content" > "${HISTORY_FOLDER}/1"
}

# Function to start the clipboard listener
# The listener will run in the background and check the clipboard every second
# If the clipboard content is not empty, it will rotate the history files
# and save the new content to the first file
start_history() {
    # Check if listener is already running
    # If the PID file exists and the process is running, exit
    # Otherwise, start the listener
    # [ -f FILE ]	True if FILE exists and is a regular file.
    if [[ -f "$PID_FILE" ]]; then
        # Save the PID from the file
        # cat reads the file and prints the content to stdout
        OLD_PID=$(cat "$PID_FILE")

        # Check if the process is running with ps command
        # The ps utility displays a header line, followed by lines containing information about all of your processes that have controlling terminals.
        # -p flag: Display information about processes which match the specified process IDs.
        if ps -p $OLD_PID > /dev/null 2>&1; then
            # If the process is running, print a message with PID and exit
            echo "Clipboard listener is already running (PID: $OLD_PID)."

            # Exit
            exit 0
        fi
    fi

    # Background listener process
    # Check clipboard every second and rotate history
    (
        while true; do
            # Get the current clipboard content
            current_clipboard=$(pbpaste)

            # If the clipboard content is not empty, rotate history
            # [ -n STRING ] or [ STRING ]	True if the length of "STRING" is non-zero.
            if [[ -n "$current_clipboard" ]]; then
                rotate_history "$current_clipboard"
            fi

            # Sleep for 1 second
            sleep 1
        done
    ) &
    
    # Save the PID of the listener process
    echo $! > "$PID_FILE"

    # Print a message that the listener is started with the PID
    echo "Clipboard listener started (PID: $(cat "$PID_FILE"))"

    # Exit
    exit 0
}

clear_history() {
    # Remove all history files with recursive force flags
    # The rm utility attempts to remove the non-directory type files specified on the command line.
    # -r flag: Remove the contents of directories recursively.
    # -f flag: Attempt to remove the files without prompting for confirmation, regardless of the file's permissions.
    rm -rf "$HISTORY_FOLDER"

    # Recreate the history folder
    mkdir -p "$HISTORY_FOLDER"

    # If run in terminal mode, print a message that history is cleared
    echo "Clipboard history cleared."

    # Exit
    exit 0
}

show_history() {
    # Create an array to store all valid items
    # declare: A Bash built-in command used to declare variables and set their attributes
    # -a: A flag that specifies this variable should be treated as an indexed array
    declare -a history_items
    
    # Build the array of items
    for ((i=1; i<=MAX_HISTORY; i++)); do
        # Check if file exists
        if [[ -f "${HISTORY_FOLDER}/${i}" ]]; then
            # Read the file content
            content=$(cat "${HISTORY_FOLDER}/${i}")

            # Truncate content for display and escape quotes
            preview="${content:0:100}"

            # Escape double quotes for AppleScript
            preview="${preview//\"/\\\"}"

            # Truncate content for display
            if [[ ${#content} -gt 100 ]]; then
                preview="${preview}..."
            fi

            # Add the preview to the array
            history_items+=("$preview")
        fi
    done
    
    # If no items found, exit
    if [ ${#history_items[@]} -eq 0 ]; then
        # Print a message that no history was found
        echo "No clipboard history found."

        # Exit
        exit 0
    fi
    
    # Pass the items directly as arguments to the AppleScript
    local selection=$(osascript "$APPLESCRIPT_FILE" "${history_items[@]}")
    
    # If user made a selection, find and copy the corresponding item
    if [[ "$selection" != "false" ]]; then
        # Find the selected item and copy it to clipboard
        for ((i=1; i<=MAX_HISTORY; i++)); do
            # Check if file exists and if the preview matches the selection
            if [[ -f "${HISTORY_FOLDER}/${i}" ]]; then
                # Read the file content
                content=$(cat "${HISTORY_FOLDER}/${i}")

                # Truncate content for display
                preview="${content:0:100}"

                # Truncate content for display
                if [[ ${#content} -gt 100 ]]; then
                    # Add ellipsis if content is longer than 100 characters
                    preview="${preview}..."
                fi

                # If the preview matches the selection, copy the content to clipboard
                if [[ "$selection" == *"$preview"* ]]; then
                    # Copy the content to clipboard
                    echo "$content" | pbcopy
                    break
                fi
            fi
        done
    fi
    exit 0
}

# Function to stop the clipboard listener
stop_history() {
    # Check if the PID file exists
    if [[ -f "$PID_FILE" ]]; then
        # If the PID file exists, kill the process
        # The kill utility sends a signal to the processes specified by the pid operands.
        kill "$(cat "$PID_FILE")"

        # Remove the PID file
        rm "$PID_FILE"

        # Print a message that the listener is stopped
        echo "Clipboard listener stopped."
    else
        echo "No clipboard listener is running."
    fi
    exit 0
}

# Check for aguments and call the appropriate function
# Using case statement for better readability
case "$1" in
    --start)
        start_history
        ;;
    --clear)
        clear_history
        ;;
    --show)
        show_history
        ;;
    --stop)
        stop_history
        ;;
esac


# Show usage if no valid argument is provided
echo "Usage: $0 [--start|--clear|--show|--stop]"

# Exit with error
exit 1