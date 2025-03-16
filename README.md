# Cursor Editor APT Integration

This repository contains scripts to integrate the Cursor Editor AppImage with APT (Advanced Package Tool) on Debian-based Linux distributions. This allows for automatic updates of Cursor through the system's package manager.

## Terms of Use

This utility is free to use, modify, update, and redistribute, provided that credit is given to the original author. You are welcome to:

- Use this utility for any purpose
- Modify and adapt the code
- Share and redistribute the utility
- Create derivative works

The only requirement is maintaining attribution to the original author.

## Contributing

Improvements and enhancements to this utility are welcome! If you have ideas for new functionality or improvements, please submit them via GitHub. This allows changes to be reviewed and included for all future users to benefit from. Working together, we can make this tool even better.

## Disclaimer

**This is a community-developed tool and is not officially created, endorsed, or maintained by the Cursor development team.**

This utility was created to address the lack of an official repository installation option or .deb package for Linux users. While the Cursor team only provides an AppImage file for Linux installations, this tool integrates that AppImage with your system's package manager for a better install, use, and update experience.

Use at your own risk. While we strive to ensure this tool works correctly, it may break with future updates to Cursor or your operating system.

Note: The built-in "Check for Updates" option in Cursor's Help menu _still_ will not function. Instead, this integration allows Cursor to be updated through your system's package manager (APT). The script checks Cursor's official servers for new versions and handles downloading updates automatically when you run system updates.

## Author

Created by Zac Ingoglia (Poisonite)  
Email: zac@ingoglia.com

## Overview

These scripts set up Cursor Editor to be:

- Installed in the user's Applications directory
- Integrated with the system's APT package manager
- Available in the application menu with a proper desktop entry
- Automatically updated when new versions are released

## Quick Start

To install Cursor Editor with APT integration:

1. **Clone the repository:**

2. **Run the installation script with sudo privileges:**

   ```bash
   sudo ./install-cursor.sh
   ```

   This will:

   - Install Cursor in your ~/Applications/cursor directory
   - Set up APT integration for automatic updates
   - Create desktop entries for easy access
   - Configure necessary permissions

3. **Launch Cursor:**

   - Find Cursor in your system application menu

4. **Updating Cursor:**

   - Updates will be automatically checked during system updates
   - To manually check for updates: `sudo apt update && sudo apt upgrade`
   - The built-in "Check for Updates" feature in Cursor will not work; use APT instead (this isn't a utility limitation, but a Cursor one).

5. **Troubleshooting:**
   - Check the log file at `~/Applications/cursor/update-cursor.log`
   - If you encounter issues, run: `sudo ~/Applications/cursor/check-for-cursor-update.sh` to diagnose update problems

## System Requirements

- Debian-based Linux distribution (Ubuntu, Linux Mint, etc.)
- sudo privileges
- git (for cloning the repository)
- Standard build tools installed (`apt install build-essential`)

## Features

- Seamless integration with APT package manager
- Automatic updates via your system's update mechanism
- Desktop integration (application menu entry, icon, etc.)
- Clean installation in user Applications directory
