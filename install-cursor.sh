#!/bin/bash
# Comprehensive Cursor Installer Script

# Define colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get username of the user who invoked sudo
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    # Get the real user's home directory
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    REAL_USER="$(whoami)"
    USER_HOME="$HOME"
fi

# Target installation directory
INSTALL_DIR="$USER_HOME/Applications/cursor"

# Check if running as root (needed for APT integration)
if [ "$EUID" -ne 0 ]; then
    print_warning "This script needs to run with sudo privileges for full functionality."
    print_warning "Please run: sudo $0"
    exit 1
fi

print_message "Starting Cursor installation for user: $REAL_USER"
print_message "Installation directory: $INSTALL_DIR"

# Create installation directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    print_message "Creating installation directory at $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Failed to create installation directory. Aborting."
        exit 1
    fi
fi

# Copy required files
print_message "Copying Cursor files to $INSTALL_DIR..."
cp "$SCRIPT_DIR/cursor.AppImage" "$INSTALL_DIR/" 2>/dev/null || print_warning "AppImage not found in source directory, will be downloaded during setup"
cp "$SCRIPT_DIR/cursor-icon.png" "$INSTALL_DIR/" || print_warning "Icon not found in source directory"
cp "$SCRIPT_DIR/update-cursor.sh" "$INSTALL_DIR/" || { print_error "Required script not found: update-cursor.sh"; exit 1; }
cp "$SCRIPT_DIR/upgrade-cursor" "$INSTALL_DIR/" || { print_error "Required script not found: upgrade-cursor"; exit 1; }
cp "$SCRIPT_DIR/check-for-cursor-update.sh" "$INSTALL_DIR/" || { print_error "Required script not found: check-for-cursor-update.sh"; exit 1; }
cp "$SCRIPT_DIR/setup-apt-updater-repo.sh" "$INSTALL_DIR/" || { print_error "Required script not found: setup-apt-updater-repo.sh"; exit 1; }
cp "$SCRIPT_DIR/create-desktop-entry.sh" "$INSTALL_DIR/" || { print_error "Required script not found: create-desktop-entry.sh"; exit 1; }

# Make sure the log file exists
touch "$INSTALL_DIR/update-cursor.log"

# Ensure correct permissions
print_message "Setting correct permissions..."
chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR/upgrade-cursor" 2>/dev/null
if [ -f "$INSTALL_DIR/cursor.AppImage" ]; then
    chmod +x "$INSTALL_DIR/cursor.AppImage"
fi

# Fix ownership to ensure the real user can access the files
chown -R "$REAL_USER:$(id -gn $REAL_USER)" "$INSTALL_DIR"

# Step 1: Set up APT integration
print_message "Setting up APT integration for automatic updates..."
"$INSTALL_DIR/setup-apt-updater-repo.sh" || { print_error "Failed to set up APT integration"; exit 1; }

# Step 2: Create desktop entry
print_message "Creating desktop entry for Cursor..."
# Run as the real user to create user-specific desktop entry
if [ "$REAL_USER" != "root" ]; then
    # Create desktop entry for the real user
    sudo -u "$REAL_USER" "$INSTALL_DIR/create-desktop-entry.sh" || print_warning "Failed to create user desktop entry"
    
    # Also create system-wide desktop entry
    "$INSTALL_DIR/create-desktop-entry.sh" || print_warning "Failed to create system desktop entry"
else
    # Just create system-wide entry if SUDO_USER is not set
    "$INSTALL_DIR/create-desktop-entry.sh" || print_warning "Failed to create desktop entry"
fi

print_success "Cursor has been successfully installed!"
print_message "You can now find Cursor in your application menu or run it from: $INSTALL_DIR/cursor.AppImage"
print_message "Updates will be managed automatically through APT."

exit 0 