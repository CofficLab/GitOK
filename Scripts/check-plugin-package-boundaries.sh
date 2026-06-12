#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/GitOKApp"
LEGACY_APP_DIR="$ROOT_DIR/APP"
PLUGIN_PACKAGES_DIR="$ROOT_DIR/Plugins"
COREKIT_DIR="$ROOT_DIR/Packages/GitOKCoreKit"

mode="${1:-strict}"
if [[ "$mode" != "strict" && "$mode" != "--allow-legacy" ]]; then
  echo "usage: $0 [strict|--allow-legacy]" >&2
  exit 2
fi

failures=0

echo "Checking GitOK plugin package boundaries..."

if [[ -e "$LEGACY_APP_DIR" ]]; then
  echo "  legacy app directory still exists: APP/"
  failures=$((failures + 1))
fi

if [[ ! -d "$APP_DIR" ]]; then
  echo "  app shell directory missing: GitOKApp/"
  failures=$((failures + 1))
fi

if [[ -d "$ROOT_DIR/Packages" ]]; then
  while IFS= read -r -d '' dir; do
    name="$(basename "$dir")"
    echo "  stale plugin mirror under Packages/: Packages/$name (use Plugins/ only)"
    failures=$((failures + 1))
  done < <(find "$ROOT_DIR/Packages" -mindepth 1 -maxdepth 1 -type d -name 'Plugin*' -print0 2>/dev/null | sort -z)
fi

if [[ -d "$PLUGIN_PACKAGES_DIR" ]]; then
  while IFS= read -r -d '' dir; do
    name="$(basename "$dir")"
    if [[ ! -f "$dir/Package.swift" ]]; then
      echo "  plugin package missing Package.swift: Plugins/$name"
      failures=$((failures + 1))
    fi
  done < <(find "$PLUGIN_PACKAGES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
else
  echo "  plugin package root is missing: Plugins/"
  failures=$((failures + 1))
fi

if [[ -d "$COREKIT_DIR/Sources" ]]; then
  if rg -q 'import (BannerPlugin|BranchPlugin|GitWorkspacePlugin)' "$COREKIT_DIR/Sources" 2>/dev/null; then
    echo "  GitOKCoreKit must not import feature plugin modules"
    failures=$((failures + 1))
  fi
fi

if [[ -d "$PLUGIN_PACKAGES_DIR" ]]; then
  while IFS= read -r file; do
    if rg -q '^import GitOKApp$' "$file" 2>/dev/null; then
      echo "  plugin imports app target: $file"
      failures=$((failures + 1))
    fi
  done < <(find "$PLUGIN_PACKAGES_DIR" -name '*.swift' -not -path '*/.build/*' 2>/dev/null)
fi

if [[ "$failures" -eq 0 ]]; then
  echo "OK: GitOK plugin boundaries satisfied."
  exit 0
fi

echo
echo "Found $failures plugin boundary issue(s)."
if [[ "$mode" == "--allow-legacy" ]]; then
  exit 0
fi

exit 1
