#!/bin/bash
set -e

APP="AutoPiP"
REPO="Konradk1995/AutoPiP"
INSTALL_DIR="$HOME/Applications"

echo "Installing $APP..."

# Get latest release URL
ZIP_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep '"browser_download_url"' | head -1 | cut -d'"' -f4)

if [ -z "$ZIP_URL" ]; then
    echo "Error: Could not find latest release."
    exit 1
fi

# Download
curl -sL "$ZIP_URL" -o "/tmp/$APP.zip"

# Quit if running
osascript -e "tell application \"$APP\" to quit" 2>/dev/null || true
sleep 1

# Install
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP.app"
unzip -o -q "/tmp/$APP.zip" -d "$INSTALL_DIR"
rm "/tmp/$APP.zip"

# Register and launch
open "$INSTALL_DIR/$APP.app"

echo ""
echo "Done. Enable the extension in Safari > Settings > Extensions."
