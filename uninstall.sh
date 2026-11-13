#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

APP_NAME="MediaKeysFix"
LAUNCH_DIR="${HOME}/Library/LaunchAgents"

echo -e "${BLUE}${BOLD}=== ${APP_NAME} Uninstaller ===${NC}"

# 1. Terminate application process
echo -e "🛑 Stopping ${APP_NAME} process..."
pkill -x "${APP_NAME}" >/dev/null 2>&1 || true
pkill -x "mediakeyd" >/dev/null 2>&1 || true

# 2. Unload & remove LaunchAgents
echo -e "🗑️  Removing LaunchAgents..."
launchctl unload "${LAUNCH_DIR}/com.user.mediakeysfix.plist" >/dev/null 2>&1 || true
launchctl unload "${LAUNCH_DIR}/com.user.mediakeyd.plist" >/dev/null 2>&1 || true
launchctl unload "${LAUNCH_DIR}/com.user.hidutilKeyMapping.plist" >/dev/null 2>&1 || true

rm -f "${LAUNCH_DIR}/com.user.mediakeysfix.plist"
rm -f "${LAUNCH_DIR}/com.user.mediakeyd.plist"
rm -f "${LAUNCH_DIR}/com.user.hidutilKeyMapping.plist"

# 3. Remove application bundles
echo -e "🗑️  Removing application bundles..."
rm -rf "/Applications/${APP_NAME}.app"
rm -rf "${HOME}/Applications/${APP_NAME}.app"
rm -rf "${APP_NAME}.app"
rm -f "${APP_NAME}"
rm -f "/opt/homebrew/bin/mediakeyd"

# 4. Reset HID key mapping
echo -e "⌨️  Restoring default macOS keyboard mappings..."
hidutil property --set '{"UserKeyMapping":[]}' >/dev/null 2>&1 || true

# 5. Clean logs
rm -f "/tmp/mediakeyd.log" "/tmp/mediakeyd.err" "/tmp/mediakeyd.out"

echo -e "\n${GREEN}${BOLD}✓ Uninstallation complete!${NC}"
echo "All keymappings have been reset to macOS factory defaults."
