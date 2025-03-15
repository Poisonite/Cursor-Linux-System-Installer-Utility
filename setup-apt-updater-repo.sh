#!/bin/bash
# Direct approach to making apt recognize Cursor updates - Version 3

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root to modify system configurations."
    echo "Please run with sudo."
    exit 1
fi

# Get the actual user's home directory, even when running with sudo
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
else
    USER_HOME=$HOME
fi

CURSOR_DIR="$USER_HOME/Applications/cursor"
UPDATE_CHECKER="$CURSOR_DIR/check-for-cursor-update.sh"
VERSION_FILE="$CURSOR_DIR/cursor-version"
UPGRADE_SCRIPT="$CURSOR_DIR/upgrade-cursor"
DPKG_STATUS_FILE="/var/lib/dpkg/status"
LOGFILE="$CURSOR_DIR/update-cursor.log"

# Directory where the dummy .deb file will be stored
DEB_DIR="/var/lib/cursor-repo"

echo "=== Direct APT Update Fix (v3) ==="

# Cleanup old configurations
echo "Cleaning up old configurations..."
rm -f "/etc/apt/apt.conf.d/99cursor-upgrade"
rm -f "/etc/apt/apt.conf.d/99cursor-custom-upgrade"
rm -f "/etc/apt/apt.conf.d/99cursor-update-check"

# Step 1: Get current and latest versions
echo "Getting version information..."
UPDATE_INFO=$("$UPDATE_CHECKER")
echo "Update info: $UPDATE_INFO"

CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")
LATEST_VERSION=$(echo "$UPDATE_INFO" | grep -oP '"version":\s*"\K[^"]+' || echo "unknown")

echo "Current version: $CURRENT_VERSION"
echo "Latest version: $LATEST_VERSION"

if [ "$LATEST_VERSION" = "unknown" ] || [ "$CURRENT_VERSION" = "unknown" ]; then
    echo "Error: Unable to determine versions"
    exit 1
fi

if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
    echo "No update available. Latest version ($LATEST_VERSION) is already installed."
    exit 0
fi

# Step 2: Remove old repository files, if any
echo "Cleaning up old repository files..."
rm -rf "$DEB_DIR"
rm -f "/etc/apt/sources.list.d/cursor-editor.list"
rm -rf "/var/lib/apt/lists/_var_lib_cursor-repo_"

# Step 3: Create directory for the dummy .deb file
echo "Creating repository directory..."
mkdir -p "$DEB_DIR"

# Step 4: Create a dummy deb file
echo "Creating dummy package file..."
DUMMY_DEB_DIR="/tmp/cursor-editor-pkg"
mkdir -p "$DUMMY_DEB_DIR/DEBIAN"

cat > "$DUMMY_DEB_DIR/DEBIAN/control" << EOF
Package: cursor-editor
Version: $LATEST_VERSION
Section: editors
Priority: optional
Architecture: amd64
Maintainer: Cursor Team <hi@cursor.com>
Description: Cursor - A modern and powerful text editor
 Cursor is an AI-first code editor.
 This is a dummy package that triggers the real update.
Homepage: https://cursor.com
EOF

# Add a postinst script that will run the real update
cat > "$DUMMY_DEB_DIR/DEBIAN/postinst" << EOF
#!/bin/bash
# Update the version file
echo "$LATEST_VERSION" > "$VERSION_FILE"
# Run the upgrade script
"$UPGRADE_SCRIPT"
EOF
chmod +x "$DUMMY_DEB_DIR/DEBIAN/postinst"

# Build dummy deb
DUMMY_DEB="$DEB_DIR/cursor-editor_${LATEST_VERSION}_amd64.deb"
dpkg-deb --build --root-owner-group "$DUMMY_DEB_DIR" "$DUMMY_DEB"
rm -rf "$DUMMY_DEB_DIR"

# Step 5: Create a local package list - DIRECTLY IN THE REPO DIRECTORY
echo "Creating package list files..."

# Create Packages file directly in the repo directory
cat > "$DEB_DIR/Packages" << EOF
Package: cursor-editor
Version: $LATEST_VERSION
Installed-Size: 250000
Maintainer: Cursor Team <hi@cursor.com>
Architecture: amd64
Filename: cursor-editor_${LATEST_VERSION}_amd64.deb
Size: $(stat -c %s "$DUMMY_DEB")
MD5sum: $(md5sum "$DUMMY_DEB" | cut -d ' ' -f 1)
SHA1: $(sha1sum "$DUMMY_DEB" | cut -d ' ' -f 1)
SHA256: $(sha256sum "$DUMMY_DEB" | cut -d ' ' -f 1)
Section: editors
Priority: optional
Description: Cursor - A modern and powerful text editor
 Cursor is an AI-first code editor.
 It builds on VSCode with powerful AI features.
 .
 This package is managed by a custom update script.
 Updates are checked and applied via apt.
Homepage: https://cursor.com
EOF

# Compress the Packages file
gzip -9c "$DEB_DIR/Packages" > "$DEB_DIR/Packages.gz"

# Calculate hashes for the Release file
PACKAGES_MD5=$(md5sum "$DEB_DIR/Packages" | cut -d ' ' -f 1)
PACKAGES_SIZE=$(stat -c %s "$DEB_DIR/Packages")
PACKAGES_SHA256=$(sha256sum "$DEB_DIR/Packages" | cut -d ' ' -f 1)

PACKAGES_GZ_MD5=$(md5sum "$DEB_DIR/Packages.gz" | cut -d ' ' -f 1)
PACKAGES_GZ_SIZE=$(stat -c %s "$DEB_DIR/Packages.gz")
PACKAGES_GZ_SHA256=$(sha256sum "$DEB_DIR/Packages.gz" | cut -d ' ' -f 1)

# Create a properly formatted Release file with strong hashes
# Using date format that matches official Ubuntu repositories (RFC 822 format)
cat > "$DEB_DIR/Release" << EOF
Origin: Cursor
Label: Cursor Editor
Suite: ./
Codename: ./
Date: $(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S UTC")
Architectures: amd64
Components: main
Description: Cursor Editor Repository
MD5Sum:
 $PACKAGES_MD5 $PACKAGES_SIZE Packages
 $PACKAGES_GZ_MD5 $PACKAGES_GZ_SIZE Packages.gz
SHA256:
 $PACKAGES_SHA256 $PACKAGES_SIZE Packages
 $PACKAGES_GZ_SHA256 $PACKAGES_GZ_SIZE Packages.gz
EOF

# Handle the apt lists directory properly
echo "Setting up apt lists directory..."
LISTS_DIR="/var/lib/apt/lists"
mkdir -p "$LISTS_DIR"

# Use a proper filename that won't be mistaken for a directory
LISTS_FILE="${LISTS_DIR}/var_lib_cursor-repo__Packages"
cp "$DEB_DIR/Packages" "$LISTS_FILE"
gzip -9c "$DEB_DIR/Packages" > "${LISTS_FILE}.gz"

# Copy the Release file too
cp "$DEB_DIR/Release" "${LISTS_DIR}/var_lib_cursor-repo__Release"

# Step 6: Update dpkg status to have current version
echo "Updating dpkg status for cursor-editor..."
if ! grep -q "Package: cursor-editor" "$DPKG_STATUS_FILE"; then
    echo "Adding cursor-editor to dpkg status file..."
    cat >> "$DPKG_STATUS_FILE" << EOF

Package: cursor-editor
Status: install ok installed
Priority: optional
Section: editors
Installed-Size: 250000
Maintainer: Cursor Team <hi@cursor.com>
Architecture: amd64
Version: $CURRENT_VERSION
Provides: editor
Description: Cursor - A modern and powerful text editor
 Cursor is an AI-first code editor.
 It builds on VSCode with powerful AI features.
 .
 This package is managed by a custom update script.
 Updates are checked and applied via apt.
Homepage: https://cursor.com
EOF
else
    echo "Updating cursor-editor in dpkg status file..."
    TEMP_FILE=$(mktemp)
    sed -E "/Package: cursor-editor/,/^$/ {
        s/Version: .*/Version: $CURRENT_VERSION/
    }" "$DPKG_STATUS_FILE" > "$TEMP_FILE"
    cp "$TEMP_FILE" "$DPKG_STATUS_FILE"
    rm -f "$TEMP_FILE"
fi

# Step 7: Create sources.list file with the correct path
SOURCES_FILE="/etc/apt/sources.list.d/cursor-editor.list"
echo "Creating sources list file at $SOURCES_FILE"

cat > "$SOURCES_FILE" << EOF
# Cursor Editor Repository
deb [trusted=yes allow-insecure=yes] file:///var/lib/cursor-repo ./
EOF

# Create the upgrade marker file that the upgrade-cursor script looks for
echo "Creating upgrade marker file..."
UPGRADE_MARKER="/var/lib/apt/lists/cursor-editor.update"
cat > "$UPGRADE_MARKER" << EOF
Package: cursor-editor
Version: $LATEST_VERSION
Status: install ok available
EOF

# Step 8: Update apt cache with only our repository
echo "Updating apt cache..."
apt-get update -o Dir::Etc::sourcelist="sources.list.d/cursor-editor.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

echo "=== Fix Complete ==="
echo ""
echo "Now you can verify the update is available with:"
echo "  apt list --upgradable"
echo ""
echo "And install it with:"
echo "  sudo apt install cursor-editor"
echo ""
echo "If you encounter issues, try running 'sudo apt update' first." 