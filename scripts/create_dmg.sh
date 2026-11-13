#!/usr/bin/env bash
set -e

APP_NAME="MediaKeysFix"
APP_BUNDLE="${APP_NAME}.app"
VOL_NAME="MediaKeysFix"
DMG_FINAL="${APP_NAME}.dmg"
STAGING_DIR="build/dmg_staging"

echo "==> Packaging ${APP_NAME} for Release..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SCRIPT_DIR}"

# 1. Ensure clean app build
make app

# 2. Prepare staging directory
rm -rf build/dmg_staging "${DMG_FINAL}" "${APP_NAME}.zip"
mkdir -p "${STAGING_DIR}"

cp -R "${APP_BUNDLE}" "${STAGING_DIR}/${APP_BUNDLE}"
ln -s /Applications "${STAGING_DIR}/Applications"

# 3. Create compressed DMG
echo "==> Creating ${DMG_FINAL}..."
hdiutil create -srcfolder "${STAGING_DIR}" -volname "${VOL_NAME}" -ov -format UDZO "${DMG_FINAL}" >/dev/null
rm -rf build/dmg_staging

# 4. Create .zip archive
echo "==> Creating ${APP_NAME}.zip..."
ditto -c -k --keepParent "${APP_BUNDLE}" "${APP_NAME}.zip"

echo ""
echo "=========================================================="
echo "✓ Release artifacts created successfully:"
echo "  • DMG Installer : ${PWD}/${DMG_FINAL}"
echo "  • ZIP Archive   : ${PWD}/${APP_NAME}.zip"
echo "=========================================================="
