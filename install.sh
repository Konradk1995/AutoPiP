#!/bin/bash
set -e

APP="AutoPiP"
REPO="Konradk1995/AutoPiP"
INSTALL_DIR="$HOME/Applications"

echo "Auto PiP Installer"
echo ""

# Check if user wants userscript or native extension
if [ "${1}" = "--userscript" ] || [ "${1}" = "-u" ]; then
    echo "Installing userscript..."
    SCRIPT_URL="https://raw.githubusercontent.com/$REPO/main/autopip.user.js"
    DEST="$HOME/Downloads/autopip.user.js"
    curl -sL "$SCRIPT_URL" -o "$DEST"
    echo ""
    echo "Downloaded to $DEST"
    echo "Open it with your userscript manager (Userscripts, Tampermonkey, etc.)"
    echo ""
    echo "No userscript manager? Get one:"
    echo "  Safari:       https://apps.apple.com/app/userscripts/id1463298887 (free)"
    echo "  Chrome/Edge:  https://www.tampermonkey.net/"
    echo "  Firefox:      https://www.tampermonkey.net/"
    open "$DEST"
    exit 0
fi

echo "Installing native Safari extension..."
echo ""

# Get latest release URL
ZIP_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep '"browser_download_url"' | grep '\.zip"' | head -1 | cut -d'"' -f4)

if [ -z "$ZIP_URL" ]; then
    echo "Error: Could not find latest release."
    echo ""
    echo "Try the userscript instead:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh)\" -- --userscript"
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
echo ""
echo "Note: The native extension requires 'Allow Unsigned Extensions' in"
echo "Safari's Develop menu, which resets on every restart. For a permanent"
echo "solution, use the userscript instead:"
echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh)\" -- --userscript"
