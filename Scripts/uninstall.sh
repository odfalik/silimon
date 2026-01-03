#!/bin/bash
# Silimon - Uninstall script
# Removes sudoers entry and cleans up

set -e

SUDOERS_FILE="/etc/sudoers.d/silimon"

echo "Silimon - Uninstall"
echo "==================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo:"
    echo "  sudo $0"
    exit 1
fi

# Remove sudoers entry
if [[ -f "$SUDOERS_FILE" ]]; then
    echo "Removing sudoers entry..."
    rm -f "$SUDOERS_FILE"
    echo "Sudoers entry removed."
else
    echo "No sudoers entry found."
fi

# Clean up temp files
echo "Cleaning up temp files..."
rm -f /tmp/silimon_metrics_*

echo ""
echo "Uninstall complete!"
echo ""
echo "Note: This script does not remove the silimon binary."
echo "To fully uninstall, also run:"
echo "  brew uninstall silimon   # if installed via Homebrew"
echo "  # or"
echo "  rm /usr/local/bin/silimon   # if installed manually"
