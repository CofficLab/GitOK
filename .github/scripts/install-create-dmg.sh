#!/bin/bash
# Installs create-dmg (with support/) for CI and local DMG packaging.
# Prints the create-dmg executable path to stdout.
set -euo pipefail

CREATE_DMG_VERSION="${CREATE_DMG_VERSION:-1.2.3}"
INSTALL_ROOT="${1:-${RUNNER_TEMP:-/tmp}/create-dmg}"
INSTALL_DIR="${INSTALL_ROOT}/${CREATE_DMG_VERSION}"
CREATE_DMG="${INSTALL_DIR}/create-dmg"

if [ -x "${CREATE_DMG}" ] && [ -d "${INSTALL_DIR}/support" ]; then
    echo "${CREATE_DMG}"
    exit 0
fi

mkdir -p "${INSTALL_ROOT}"
ARCHIVE="${INSTALL_ROOT}/create-dmg-${CREATE_DMG_VERSION}.tar.gz"
URL="https://github.com/create-dmg/create-dmg/archive/refs/tags/v${CREATE_DMG_VERSION}.tar.gz"

echo "⬇️  Downloading create-dmg ${CREATE_DMG_VERSION}..." >&2
curl -fsSL --retry 3 --retry-delay 2 "${URL}" -o "${ARCHIVE}"
tar -xzf "${ARCHIVE}" -C "${INSTALL_ROOT}"
rm -rf "${INSTALL_DIR}"
mv "${INSTALL_ROOT}/create-dmg-${CREATE_DMG_VERSION}" "${INSTALL_DIR}"
chmod +x "${CREATE_DMG}"

if [ ! -d "${INSTALL_DIR}/support" ]; then
    echo "❌ create-dmg support/ directory missing at ${INSTALL_DIR}/support" >&2
    exit 1
fi

echo "${CREATE_DMG}"
