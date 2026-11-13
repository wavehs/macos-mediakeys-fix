#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

APP_NAME="MediaKeysFix"
APP_BUNDLE="${APP_NAME}.app"
TARGET_DIR="/Applications"

echo -e "${BLUE}${BOLD}=== ${APP_NAME} Installer ===${NC}"
echo -e "Setting up hardware-level media keys fix for physical F7, F8, F9...\n"

# Check dependencies
if ! command -v swiftc >/dev/null 2>&1; then
    echo -e "${YELLOW}Error: swiftc not found.${NC}"
    echo "Please install Xcode Command Line Tools by running:"
    echo "  xcode-select --install"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# 1. Compile binary
echo -e "🔨 ${BOLD}Compiling ${APP_NAME}...${NC}"
swiftc -O src/*.swift -o "${APP_NAME}"

# 2. Assemble .app bundle
echo -e "📦 ${BOLD}Building ${APP_BUNDLE}...${NC}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp src/Info.plist "${APP_BUNDLE}/Contents/Info.plist"

if [ -f "resources/AppIcon.icns" ]; then
    cp resources/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# 3. Ad-hoc codesign
echo -e "🔏 ${BOLD}Code signing bundle...${NC}"
codesign --force --deep --sign - "${APP_BUNDLE}" >/dev/null 2>&1 || true

# 4. Install destination
if [ ! -w "${TARGET_DIR}" ]; then
    TARGET_DIR="${HOME}/Applications"
    mkdir -p "${TARGET_DIR}"
fi

echo -e "📂 ${BOLD}Installing to ${TARGET_DIR}/${APP_BUNDLE}...${NC}"

# Kill any existing instance
pkill -x "${APP_NAME}" >/dev/null 2>&1 || true
sleep 0.5

rm -rf "${TARGET_DIR}/${APP_BUNDLE}"
cp -R "${APP_BUNDLE}" "${TARGET_DIR}/${APP_BUNDLE}"

# 5. Handle Start at Login
AUTOSTART=true
for arg in "$@"; do
    if [ "$arg" == "--no-autostart" ]; then
        AUTOSTART=false
    elif [ "$arg" == "--autostart" ] || [ "$arg" == "-y" ]; then
        AUTOSTART=true
    fi
done

if [ "$AUTOSTART" = true ]; then
    echo -e "🚀 ${BOLD}Enabling Launch at Login (start on computer boot)...${NC}"
    "${TARGET_DIR}/${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" --enable-login >/dev/null 2>&1 || true
fi

# 6. Launch the App
echo -e "✨ ${BOLD}Launching ${APP_NAME}...${NC}"
sleep 0.5
open "${TARGET_DIR}/${APP_BUNDLE}" >/dev/null 2>&1 || true

echo -e "\n${GREEN}${BOLD}✓ Installation complete!${NC}"
echo -e "• App is running in your Menu Bar (look for the ⏯ icon)."
echo -e "• Start at Login is ${BOLD}$( [ "$AUTOSTART" = true ] && echo "ENABLED" || echo "DISABLED" )${NC} (you can toggle it anytime from the menu bar icon)."
echo -e "• Physical F7 (Prev), F8 (Play/Pause), and F9 (Next) are now active."
echo -e "• Fn + F7/F8/F9 will continue to pass through as standard F-keys to your active app."
