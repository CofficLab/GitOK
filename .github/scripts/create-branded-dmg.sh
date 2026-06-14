#!/bin/bash
# Build a branded GitOK DMG with gift-box background for release distribution.
#
# Usage:
#   create-branded-dmg.sh <app-path> <arch> <output-dir>
#
# Example:
#   create-branded-dmg.sh ./temp/arm64/Build/Products/Release/GitOK.app arm64 ./temp
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <app-path> <arch> <output-dir>" >&2
    exit 1
fi

APP_PATH="$1"
ARCH="$2"
OUTPUT_DIR="$3"

SCHEME="${SCHEME:-GitOK}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKGROUND="${DMG_BACKGROUND:-${ROOT}/.github/dmg/background.png}"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found: $APP_PATH" >&2
    exit 1
fi

if [ ! -f "$BACKGROUND" ]; then
    echo "❌ DMG background not found: $BACKGROUND" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
VERSION_DMG="${VERSION//./_}"
DMG_NAME="${SCHEME}-${ARCH}-${VERSION_DMG}.dmg"
OUTPUT_DMG="${OUTPUT_DIR}/${DMG_NAME}"

CREATE_DMG="$(CREATE_DMG_VERSION="${CREATE_DMG_VERSION:-1.2.3}" "${ROOT}/.github/scripts/install-create-dmg.sh")"
if [ ! -x "$CREATE_DMG" ]; then
    echo "❌ create-dmg not found at $CREATE_DMG" >&2
    exit 1
fi

STAGING="${OUTPUT_DIR}/dmg_staging_${ARCH}"
VOL_NAME="${SCHEME}-${ARCH}"
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto "$APP_PATH" "$STAGING/${SCHEME}.app"

rm -f "$OUTPUT_DMG"

echo "🎁 Creating branded DMG: $DMG_NAME"
"$CREATE_DMG" \
  --volname "$VOL_NAME" \
  --background "$BACKGROUND" \
  --window-size 660 400 \
  --icon-size 128 \
  --text-size 12 \
  --icon "${SCHEME}.app" 150 195 \
  --hide-extension "${SCHEME}.app" \
  --app-drop-link 490 195 \
  --no-internet-enable \
  --hdiutil-retries 6 \
  "$OUTPUT_DMG" \
  "$STAGING"

rm -rf "$STAGING"
echo "✅ Created $OUTPUT_DMG"
