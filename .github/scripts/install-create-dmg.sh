#!/bin/bash
# Installs sindresorhus/create-dmg (npm) for CI and local DMG packaging.
# Prints the create-dmg executable path to stdout.
set -euo pipefail

CREATE_DMG_VERSION="${CREATE_DMG_VERSION:-8.1.0}"
INSTALL_ROOT="${1:-${RUNNER_TEMP:-/tmp}/create-dmg-npm}"
BIN_DIR="${INSTALL_ROOT}/bin"
CREATE_DMG="${BIN_DIR}/create-dmg"

if [ -x "${CREATE_DMG}" ]; then
    echo "${CREATE_DMG}"
    exit 0
fi

mkdir -p "${INSTALL_ROOT}"
npm install --global "create-dmg@${CREATE_DMG_VERSION}" --prefix "${INSTALL_ROOT}" >&2

if [ ! -x "${CREATE_DMG}" ]; then
    echo "❌ create-dmg not found at ${CREATE_DMG}" >&2
    exit 1
fi

echo "${CREATE_DMG}"
