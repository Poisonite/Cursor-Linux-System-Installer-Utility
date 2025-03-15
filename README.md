# Cursor Editor APT Integration

This repository contains scripts to integrate the Cursor Editor AppImage with APT (Advanced Package Tool) on Debian-based Linux distributions. This allows for automatic updates of Cursor through the system's package manager.

## Author

Created by Zac Ingoglia (Poisonite)  
Email: zac@ingoglia.com

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

## Overview

These scripts set up Cursor Editor to be:

- Installed in the user's Applications directory
- Integrated with the system's APT package manager
- Available in the application menu with a proper desktop entry
- Automatically updated when new versions are released

## Quick Start

To install Cursor Editor with APT integration:
