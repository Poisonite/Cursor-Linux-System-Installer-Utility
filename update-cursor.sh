#!/bin/bash
# Update Cursor AppImage

# Get the actual user's home directory, taking sudo into account
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME=$HOME
fi

# Variables
APPDIR=$USER_HOME/Applications/cursor
API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
APPIMAGE_PATH="$APPDIR/cursor.AppImage"
LOGFILE="$APPDIR/update-cursor.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Check for required tools
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log "Error: jq is not installed. Please install it using your package manager."
        zenity --error --text="The 'jq' tool is required but not installed.\nPlease install it using your package manager (e.g., 'sudo apt install jq')" --width=300
        exit 4
    fi
}

# Check and kill any running cursor processes
log "Checking for running Cursor instances..."
if pgrep -f "cursor.AppImage" > /dev/null; then
    log "Found running Cursor instances. Attempting to close them..."
    pkill -f "cursor.AppImage" || true
    sleep 2
    
    # Force kill if still running
    if pgrep -f "cursor.AppImage" > /dev/null; then
        log "Forcing termination of Cursor processes..."
        pkill -9 -f "cursor.AppImage" || true
        sleep 1
    fi
    
    # Check one more time
    if pgrep -f "cursor.AppImage" > /dev/null; then
        log "Unable to terminate all Cursor processes. Please close Cursor manually and run the update again."
        exit 6
    else
        log "Successfully closed all running Cursor instances."
    fi
fi

# Check for network connectivity
log "Checking network connectivity..."
if ! ping -c 1 google.com &> /dev/null; then
    log "No network connection. Please check your connection and try again."
    zenity --error --text="No network connection.\nPlease check your connection and try again." --width=300
    exit 1
fi

log "Network connection successful."

# Get download URL from API
log "Fetching download URL from API..."
API_RESPONSE=$(curl -s "$API_URL")

# Check if we got a valid response with downloadUrl
if echo "$API_RESPONSE" | jq -e .downloadUrl > /dev/null; then
    DOWNLOAD_URL=$(echo "$API_RESPONSE" | jq -r .downloadUrl)
    log "Successfully retrieved download URL: $DOWNLOAD_URL"

    # Download the latest AppImage
    log "Downloading the latest AppImage..."
    TEMP_APPIMAGE="${APPIMAGE_PATH}.download"
    
    # Remove old temp file if it exists
    rm -f "$TEMP_APPIMAGE"
    
    if wget -O "$TEMP_APPIMAGE" "$DOWNLOAD_URL"; then
        log "AppImage downloaded successfully to temporary file."
        
        # Move the temporary file to the final location
        if mv "$TEMP_APPIMAGE" "$APPIMAGE_PATH"; then
            log "AppImage moved to final location."
            
            # Make it executable
            log "Making the AppImage executable..."
            if chmod +x "$APPIMAGE_PATH"; then
                log "Cursor AppImage has been updated and made executable."
                zenity --info --text="Cursor has been successfully updated!" --width=250
                exit 0
            else
                log "Failed to make the AppImage executable."
                zenity --error --text="Failed to make the AppImage executable." --width=300
                exit 3
            fi
        else
            log "Failed to move the AppImage to the final location."
            zenity --error --text="Failed to move the AppImage to the final location." --width=300
            exit 7
        fi
    else
        log "Failed to download the AppImage. Please check your network connection."
        zenity --error --text="Failed to download the AppImage.\nPlease check your network connection." --width=300
        exit 2
    fi
else
    ERROR_MSG=$(echo "$API_RESPONSE" | jq -r '.message // "Unknown error occurred"')
    log "API Error: $ERROR_MSG"
    zenity --error --text="Failed to get download URL:\n$ERROR_MSG" --width=300
    exit 5
fi
