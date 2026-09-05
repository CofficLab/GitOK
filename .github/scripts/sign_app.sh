#!/bin/bash

set -euo pipefail

APP_PATH="${1:-}"
IDENTITY="${2:-}"
ENTITLEMENTS="${3:-}"
CODESIGN_RETRIES="${CODESIGN_RETRIES:-5}"
CODESIGN_RETRY_DELAY="${CODESIGN_RETRY_DELAY:-5}"

if [[ -z "$APP_PATH" || -z "$IDENTITY" ]]; then
    echo "Usage: sign_app.sh <App Path> <Identity> [Entitlements Path]" >&2
    exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "App not found: $APP_PATH" >&2
    exit 1
fi

echo "📦 Signing App: $APP_PATH"
echo "🆔 Identity: $IDENTITY"

xattr -cr "$APP_PATH"

timestamp_options=(--timestamp)
if [[ -n "${CODESIGN_TIMESTAMP_URL:-}" ]]; then
    timestamp_options+=("--timestamp=${CODESIGN_TIMESTAMP_URL}")
fi

codesign_with_timestamp_retry() {
    local attempt=1
    local output

    while true; do
        if output="$(codesign "$@" 2>&1)"; then
            printf '%s\n' "$output"
            return 0
        fi

        printf '%s\n' "$output" >&2
        if ! grep -qi 'timestamp' <<< "$output" || (( attempt >= CODESIGN_RETRIES )); then
            return 1
        fi

        local delay=$((CODESIGN_RETRY_DELAY * attempt))
        echo "⏳ Timestamp service failed; retrying codesign in ${delay}s (${attempt}/${CODESIGN_RETRIES})..." >&2
        sleep "$delay"
        ((attempt++))
    done
}

sign_nested_item() {
    local item="$1"
    local entitlements_file
    entitlements_file="$(mktemp "${TMPDIR:-/tmp}/gitok-entitlements.XXXXXX.plist")"

    local options=(
        --force
        "${timestamp_options[@]}"
        --sign "$IDENTITY"
        --options runtime
        --preserve-metadata=identifier,entitlements,flags
    )

    if codesign -d --entitlements - --xml "$item" > "$entitlements_file" 2>/dev/null && [[ -s "$entitlements_file" ]]; then
        options+=(--entitlements "$entitlements_file")
    fi

    codesign_with_timestamp_retry "${options[@]}" "$item"
    rm -f "$entitlements_file"
}

echo "🔍 Signing nested bundles and frameworks..."
while IFS= read -r -d '' item; do
    sign_nested_item "$item"
done < <(
    find "$APP_PATH" -depth -print0 \
        | while IFS= read -r -d '' path; do
            if [[ "$path" != "$APP_PATH" && ( "$path" == *.framework || "$path" == *.app || "$path" == *.xpc || "$path" == *.bundle || "$path" == *.appex || "$path" == *.systemextension || "$path" == *.dylib || "$path" == *.so || "$path" == */Autoupdate ) && "$path" != */Contents/Resources/*.bundle ]]; then
                printf '%s\0' "$path"
            fi
        done
)

HELPERS_DIR="$APP_PATH/Contents/Helpers"
if [[ -d "$HELPERS_DIR" ]]; then
    echo "🔍 Signing helper executables..."
    while IFS= read -r -d '' helper; do
        [[ -x "$helper" ]] || continue
        codesign_with_timestamp_retry \
            --force "${timestamp_options[@]}" --sign "$IDENTITY" --options runtime "$helper"
    done < <(find "$HELPERS_DIR" -type f ! -type l -print0)
fi

echo "✍️  Signing main app..."
main_options=(--force "${timestamp_options[@]}" --sign "$IDENTITY" --options runtime)
if [[ -n "$ENTITLEMENTS" ]]; then
    [[ -f "$ENTITLEMENTS" ]] || { echo "Entitlements not found: $ENTITLEMENTS" >&2; exit 1; }
    main_options+=(--entitlements "$ENTITLEMENTS")
fi
codesign_with_timestamp_retry "${main_options[@]}" "$APP_PATH"

echo "✅ Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv "$APP_PATH" 2>&1 | sed 's/^/   /' | head -20
