#!/bin/bash
# Build a GitOK DMG using sindresorhus/create-dmg default background.
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

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found: $APP_PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
VERSION_DMG="${VERSION//./_}"
DMG_NAME="${SCHEME}-${ARCH}-${VERSION_DMG}.dmg"
OUTPUT_DMG="${OUTPUT_DIR}/${DMG_NAME}"

CREATE_DMG="$(CREATE_DMG_VERSION="${CREATE_DMG_VERSION:-8.1.0}" "${ROOT}/.github/scripts/install-create-dmg.sh")"
if [ ! -x "$CREATE_DMG" ]; then
    echo "❌ create-dmg not found at $CREATE_DMG" >&2
    exit 1
fi

BUILD_DIR="${OUTPUT_DIR}/dmg_build_${ARCH}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
rm -f "$OUTPUT_DMG"

echo "🎁 Creating DMG: $DMG_NAME"
CREATE_DMG_ARGS=(--overwrite)
if [ -n "${DMG_SIGNING_IDENTITY:-}" ]; then
    CREATE_DMG_ARGS+=(--identity "$DMG_SIGNING_IDENTITY")
fi

set +e
"$CREATE_DMG" "${CREATE_DMG_ARGS[@]}" "$APP_PATH" "$BUILD_DIR"
CREATE_DMG_STATUS=$?
set -e

GENERATED_DMG="$(find "$BUILD_DIR" -maxdepth 1 -name '*.dmg' -type f | head -n 1)"
if [ -z "$GENERATED_DMG" ]; then
    echo "❌ create-dmg did not produce a DMG (exit $CREATE_DMG_STATUS)" >&2
    exit 1
fi

if [ "$CREATE_DMG_STATUS" -eq 2 ]; then
    echo "⚠️  DMG created but code signing reported a warning (exit 2)" >&2
elif [ "$CREATE_DMG_STATUS" -ne 0 ]; then
    echo "❌ create-dmg failed (exit $CREATE_DMG_STATUS)" >&2
    exit "$CREATE_DMG_STATUS"
fi

mv "$GENERATED_DMG" "$OUTPUT_DMG"
rm -rf "$BUILD_DIR"
echo "✅ Created $OUTPUT_DMG"
