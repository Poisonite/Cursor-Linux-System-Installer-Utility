#!/bin/bash
# Check for Cursor updates and return a JSON response

# Get the actual user's home directory, taking sudo into account
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME=$HOME
fi

# Variables
APPDIR="$USER_HOME/Applications/cursor"
API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
APPIMAGE_PATH="$APPDIR/cursor.AppImage"
VERSION_FILE="$APPDIR/cursor-version"
TEMP_APPIMAGE="/tmp/cursor-temp.AppImage"
LOGFILE="$APPDIR/update-cursor.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Function to return JSON response
# Parameters: update_available (true/false), version (string)
return_json() {
    local update_available="$1"
    local version="$2"
    echo "{\"update_available\":$update_available,\"version\":\"$version\"}"
    exit 0
}

# Function to calculate checksum of a file
get_checksum() {
    sha256sum "$1" | cut -d' ' -f1
}

# Check for required tools
if ! command -v jq &> /dev/null; then
    log "Error: jq is not installed. Please install it using your package manager."
    echo "{\"error\":\"jq is not installed. Please install it using your package manager.\"}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log "Error: curl is not installed. Please install it using your package manager."
    echo "{\"error\":\"curl is not installed. Please install it using your package manager.\"}"
    exit 1
fi

# Check if current version file exists, create it if not
if [ ! -f "$VERSION_FILE" ]; then
    echo "none" > "$VERSION_FILE"
    log "Created new version file with 'none' version"
fi

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE")
log "Current version: $CURRENT_VERSION"

# Check for network connectivity
if ! ping -c 1 google.com &> /dev/null; then
    log "No network connection. Cannot check for updates."
    echo "{\"error\":\"No network connection. Cannot check for updates.\"}"
    exit 1
fi

# Get download URL from API
log "Fetching download URL from API..."
API_RESPONSE=$(curl -s "$API_URL")

# Check if we got a valid response with downloadUrl
if ! echo "$API_RESPONSE" | jq -e .downloadUrl > /dev/null; then
    ERROR_MSG=$(echo "$API_RESPONSE" | jq -r '.message // "Unknown error occurred"')
    log "API Error: $ERROR_MSG"
    echo "{\"error\":\"$ERROR_MSG\"}"
    exit 1
fi

# Extract download URL
DOWNLOAD_URL=$(echo "$API_RESPONSE" | jq -r .downloadUrl)
log "Successfully retrieved download URL: $DOWNLOAD_URL"

# Try to parse version from filename
# Expected format example: Cursor-0.46.11-ae378be9dc2f5f1a6a1a220c6e25f9f03c8d4e19.deb.glibc2.25-x86_64.AppImage
FILENAME=$(basename "$DOWNLOAD_URL")
VERSION=$(echo "$FILENAME" | grep -oP 'Cursor-\K[0-9]+\.[0-9]+\.[0-9]+' || echo "")

if [ -n "$VERSION" ]; then
    # Successfully parsed version
    log "Parsed version from download URL: $VERSION"
    
    # Compare with current version
    if [ "$VERSION" != "$CURRENT_VERSION" ]; then
        log "New version available: $VERSION (current: $CURRENT_VERSION)"
        return_json true "$VERSION"
    else
        log "Current version is up to date: $VERSION"
        return_json false "$VERSION"
    fi
else
    # Failed to parse version, download file and compare checksums
    log "Failed to parse version from download URL. Downloading file to compare checksums..."
    
    # Check if current AppImage exists
    if [ ! -f "$APPIMAGE_PATH" ]; then
        log "Current AppImage not found. Cannot compare checksums."
        return_json true "none"
    fi
    
    # Download the file to a temporary location
    if ! wget -q -O "$TEMP_APPIMAGE" "$DOWNLOAD_URL"; then
        log "Failed to download AppImage for comparison"
        echo "{\"error\":\"Failed to download AppImage for comparison\"}"
        exit 1
    fi
    
    # Compare checksums
    CURRENT_CHECKSUM=$(get_checksum "$APPIMAGE_PATH")
    NEW_CHECKSUM=$(get_checksum "$TEMP_APPIMAGE")
    
    # Clean up temporary file
    rm -f "$TEMP_APPIMAGE"
    
    if [ "$CURRENT_CHECKSUM" != "$NEW_CHECKSUM" ]; then
        log "Different checksum detected. Update available."
        return_json true "unknown"
    else
        log "Checksums match. No update available."
        return_json false "unknown"
    fi
fi 