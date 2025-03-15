#!/bin/bash
# Script to create a desktop entry for Cursor Editor

# Define colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the actual user's home directory, even when running with sudo
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME=$HOME
fi

# Installation directory
CURSOR_DIR="$USER_HOME/Applications/cursor"
APPIMAGE_PATH="$CURSOR_DIR/cursor.AppImage"
ICON_PATH="$CURSOR_DIR/cursor-icon.png"

# Desktop entry path (user level)
DESKTOP_ENTRY_DIR="$USER_HOME/.local/share/applications"
DESKTOP_ENTRY_PATH="$DESKTOP_ENTRY_DIR/cursor.desktop"

# Desktop entry path (system level, requires sudo)
SYS_DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    # Running as root, install system-wide
    print_message "Running with root privileges, installing desktop entry system-wide..."
    DESKTOP_ENTRY_PATH="$SYS_DESKTOP_ENTRY_PATH"
    # Make sure the system applications directory exists
    mkdir -p /usr/share/applications
else
    # Running as user, install for current user only
    print_message "Running without root privileges, installing desktop entry for current user only..."
    # Make sure the user applications directory exists
    mkdir -p "$DESKTOP_ENTRY_DIR"
fi

# Check if the AppImage exists
if [ ! -f "$APPIMAGE_PATH" ]; then
    print_error "AppImage not found at $APPIMAGE_PATH. Desktop entry creation failed."
    exit 1
fi

# Check if the icon exists
if [ ! -f "$ICON_PATH" ]; then
    print_message "Icon not found at $ICON_PATH. Will use generic icon."
    ICON="cursor-editor"
else
    ICON="$ICON_PATH"
fi

# Make sure the AppImage is executable
chmod +x "$APPIMAGE_PATH"

# Create the desktop entry
print_message "Creating desktop entry at $DESKTOP_ENTRY_PATH..."

cat > "$DESKTOP_ENTRY_PATH" << EOL
[Desktop Entry]
Type=Application
Name=Cursor
GenericName=Text Editor
Comment=AI-first code editor based on VSCode
Exec="$APPIMAGE_PATH"
Icon=$ICON
Terminal=false
Categories=Development;IDE;TextEditor;Programming;
StartupWMClass=Cursor
StartupNotify=true
Keywords=cursor;code;editor;ide;text;programming;ai;
EOL

# Make the desktop entry executable
chmod +x "$DESKTOP_ENTRY_PATH"

# Update the desktop database to reflect changes
if command -v update-desktop-database &> /dev/null; then
    if [ "$EUID" -eq 0 ]; then
        update-desktop-database /usr/share/applications
    else
        update-desktop-database "$DESKTOP_ENTRY_DIR"
    fi
fi

# Check if the desktop entry was created successfully
if [ -f "$DESKTOP_ENTRY_PATH" ]; then
    print_success "Desktop entry created successfully at $DESKTOP_ENTRY_PATH"
    print_message "Cursor should now appear in your application menu."
else
    print_error "Failed to create desktop entry."
    exit 1
fi

exit 0 