#!/bin/bash
# Silimon - Uninstall script
# Cleans up silimon installation

set -e

echo "Silimon - Uninstall"
echo "==================="
echo ""

# Remove any old sudoers entry if it exists (from older versions)
SUDOERS_FILE="/etc/sudoers.d/silimon"
if [[ -f "$SUDOERS_FILE" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "Found old sudoers entry from a previous version."
        echo "Run 'sudo rm $SUDOERS_FILE' to remove it (no longer needed)."
    else
        echo "Removing old sudoers entry (no longer needed)..."
        rm -f "$SUDOERS_FILE"
        echo "Sudoers entry removed."
    fi
fi

# Remove launch agent if present
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.silimon.app.plist"
if [[ -f "$LAUNCH_AGENT" ]]; then
    echo "Removing launch agent..."
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
    rm -f "$LAUNCH_AGENT"
    echo "Launch agent removed."
fi

echo ""
echo "Cleanup complete!"
echo ""
echo "To fully uninstall the binary, run:"
echo "  brew uninstall silimon   # if installed via Homebrew"
echo "  # or"
echo "  rm /usr/local/bin/silimon   # if installed manually"
