#!/bin/bash
# Silimon - Setup passwordless powermetrics access
# This script creates a sudoers entry for running powermetrics without a password

set -e

SUDOERS_FILE="/etc/sudoers.d/silimon"

echo "Silimon - Setting up passwordless powermetrics access"
echo "======================================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo:"
    echo "  sudo $0"
    exit 1
fi

# Check if already set up
if [[ -f "$SUDOERS_FILE" ]]; then
    echo "Sudoers entry already exists at $SUDOERS_FILE"
    echo "To reinstall, first run: sudo rm $SUDOERS_FILE"
    exit 0
fi

# Create sudoers entry
echo "Creating sudoers entry..."
echo "%admin ALL=(root) NOPASSWD: /usr/bin/powermetrics" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"

# Validate the sudoers file
if visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
    echo "Sudoers entry created successfully!"
else
    echo "Error: Invalid sudoers entry. Removing..."
    rm -f "$SUDOERS_FILE"
    exit 1
fi

echo ""
echo "Setup complete! You can now run 'silimon' without password prompts."
echo ""

# Optional: Enable Touch ID for sudo
echo "Would you like to enable Touch ID for sudo? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    PAM_FILE="/etc/pam.d/sudo"
    if grep -q "pam_tid.so" "$PAM_FILE" 2>/dev/null; then
        echo "Touch ID for sudo is already enabled."
    else
        # Create backup
        cp "$PAM_FILE" "${PAM_FILE}.backup"
        # Add pam_tid.so at the beginning (after the comment header)
        sed -i '' '2i\
auth       sufficient     pam_tid.so
' "$PAM_FILE"
        echo "Touch ID for sudo enabled!"
    fi
fi

echo ""
echo "Done! Run 'silimon' to start monitoring."
