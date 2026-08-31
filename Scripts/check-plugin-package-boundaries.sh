#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/GitOKApp"
LEGACY_APP_DIR="$ROOT_DIR/APP"
PLUGIN_PACKAGES_DIR="$ROOT_DIR/Plugins"
COREKIT_DIR="$ROOT_DIR/Packages/KitGitOKCore"
KERNEL_DIR="$ROOT_DIR/Packages/KernelCore"
PROVIDER_DIRS=(
  "$ROOT_DIR/Packages/ProviderProject"
  "$ROOT_DIR/Packages/ProviderGit"
  "$ROOT_DIR/Packages/ProviderTheme"
  "$ROOT_DIR/Packages/ProviderNavigation"
)

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

if [[ ! -f "$KERNEL_DIR/Package.swift" ]]; then
  echo "  kernel package missing: Packages/KernelCore/Package.swift"
  failures=$((failures + 1))
fi

for provider_dir in "${PROVIDER_DIRS[@]}"; do
  if [[ ! -f "$provider_dir/Package.swift" ]]; then
    echo "  provider package missing: ${provider_dir#"$ROOT_DIR"/}"
    failures=$((failures + 1))
  fi
done

if [[ -d "$KERNEL_DIR/Sources" ]] && rg -q '^import (GitOK|.*Plugin)' "$KERNEL_DIR/Sources" 2>/dev/null; then
  echo "  KernelCore must remain independent of GitOK and feature plugins"
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
    # Ignore local build caches left by removed plugin packages. A real plugin
    # directory has either Package.swift or source files and must be checked.
    if [[ ! -f "$dir/Package.swift" && ! -d "$dir/Sources" ]]; then
      continue
    fi
    if [[ ! -f "$dir/Package.swift" ]]; then
      echo "  plugin package missing Package.swift: Plugins/$name"
      failures=$((failures + 1))
    else
      package_name="$(sed -n 's/^[[:space:]]*name:[[:space:]]*"\([^"]*\)"/\1/p' "$dir/Package.swift" | head -1)"
      if [[ "$package_name" != Plugin* ]]; then
        echo "  plugin package must use Plugin prefix: Plugins/$name ($package_name)"
        failures=$((failures + 1))
      fi
    fi
  done < <(find "$PLUGIN_PACKAGES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
else
  echo "  plugin package root is missing: Plugins/"
  failures=$((failures + 1))
fi

if [[ -d "$COREKIT_DIR/Sources" ]]; then
  if rg -q 'import (BannerPlugin|BranchPlugin|GitWorkspacePlugin)' "$COREKIT_DIR/Sources" 2>/dev/null; then
    echo "  KitGitOKCore must not import feature plugin modules"
    failures=$((failures + 1))
  fi
fi

# The application owns one explicit Kernel. Production UI and commands must
# not silently create or retrieve the legacy global RootContainer instance.
if rg -n 'RootContainer\.shared' \
  "$APP_DIR" \
  "$ROOT_DIR/Packages/FactoryCore/Sources/FactoryCore/Commands" \
  "$ROOT_DIR/Packages/FactoryCore/Sources/FactoryCore/Views" \
  "$ROOT_DIR/Packages/FactoryCore/Sources/FactoryCore/Bootstrap" \
  --glob '*.swift' \
  --glob '!RootContainer.swift' 2>/dev/null; then
  echo "  production app/view/command code must receive an explicit Kernel"
  failures=$((failures + 1))
fi

if [[ -d "$PLUGIN_PACKAGES_DIR" ]]; then
  while IFS= read -r file; do
    if rg -q '^import GitOKApp$' "$file" 2>/dev/null; then
      echo "  plugin imports app target: $file"
      failures=$((failures + 1))
    fi
    # Contribution IDs must be stable, plugin-prefixed identifiers — no raw
    # UI copy or throwaway strings. Accepts metadata.id references verbatim.
    if rg -q 'GitOK(RailItem|ListPaneItem|ToolbarItem|StatusBarItem|SettingsPaneItem|OnboardingPaneItem)\(' "$file" 2>/dev/null; then
      while IFS= read -r id_line; do
        id_value="$(printf '%s' "$id_line" | sed -E 's/^[[:space:]]*id:[[:space:]]*//; s/[,[:space:]]*$//')"
        case "$id_value" in
          metadata.id|*\.id|"metadata.id + "*)
            ;;
          *\ *)
            echo "  non-constant contribution id in $file: $id_line"
            failures=$((failures + 1))
            ;;
          \"*\")
            ;;
          *)
            echo "  suspicious contribution id in $file: $id_line"
            failures=$((failures + 1))
            ;;
        esac
      done < <(rg -A2 'GitOK(RailItem|ListPaneItem|ToolbarItem|StatusBarItem|SettingsPaneItem|OnboardingPaneItem)\(' "$file" 2>/dev/null | rg '^\s*[-+]?\s*id:' || true)
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
