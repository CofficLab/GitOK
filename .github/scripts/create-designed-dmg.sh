#!/bin/bash
set -euo pipefail

# Create a Finder-style DMG with the GitOK branded background and layout.
#
# The Finder layout is applied through AppleScript, which is unreliable on CI
# runners: the Finder may fail the Apple Event with -10006 (errAEEventFailed)
# when it cannot service the request in time. Because the layout is purely
# cosmetic, a failure must never abort the release pipeline. We therefore
# degrade in three levels:
#
#   Level 1  branded layout (background picture + window/icon placement)
#   Level 2  window/icon placement without the background picture
#   Level 3  no Finder automation at all (plain but functional DMG)
#
# Usage: create-designed-dmg.sh APP_PATH OUTPUT_PATH [VOLUME_NAME] [BACKGROUND_PATH]

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "Usage: $0 APP_PATH OUTPUT_PATH [VOLUME_NAME] [BACKGROUND_PATH]" >&2
  exit 2
fi

APP_PATH="$1"
OUTPUT_PATH="$2"
VOLUME_NAME="${3:-GitOK}"
BACKGROUND_PATH="${4:-.github/dmg/GitOK-dmg-background.png}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "$BACKGROUND_PATH" != /* ]]; then
  BACKGROUND_PATH="$ROOT_DIR/$BACKGROUND_PATH"
fi

[[ -d "$APP_PATH" ]] || { echo "App not found: $APP_PATH" >&2; exit 1; }
[[ -f "$BACKGROUND_PATH" ]] || { echo "Background not found: $BACKGROUND_PATH" >&2; exit 1; }

OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
mkdir -p "$OUTPUT_DIR"

TEMP_ROOT="${RUNNER_TEMP:-/tmp}"
WORK_DIR="$(mktemp -d "$TEMP_ROOT/gitok-dmg.XXXXXX")"
STAGING_DIR="$WORK_DIR/staging"
READ_WRITE_DMG="$WORK_DIR/$VOLUME_NAME-rw.dmg"
MOUNT_POINT=""

cleanup() {
  if [[ -n "$MOUNT_POINT" && -d "$MOUNT_POINT" ]]; then
    hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$STAGING_DIR/.background"
ditto "$APP_PATH" "$STAGING_DIR/GitOK.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$BACKGROUND_PATH" "$STAGING_DIR/.background/background.png"
chflags hidden "$STAGING_DIR/.background"

mdutil -i off "$STAGING_DIR" >/dev/null 2>&1 || true
sync

hdiutil detach "/Volumes/$VOLUME_NAME" -force >/dev/null 2>&1 || true

create_read_write_image() {
  rm -f "$READ_WRITE_DMG"
  hdiutil create \
    -size 200m \
    -fs HFS+ \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDRW \
    "$READ_WRITE_DMG" >/dev/null
}

attempt=0
until create_read_write_image; do
  attempt=$((attempt + 1))
  if [[ "$attempt" -ge 6 ]]; then
    echo "Unable to create DMG after 6 attempts: $VOLUME_NAME" >&2
    exit 1
  fi
  echo "Retrying DMG creation ($attempt/5): $VOLUME_NAME" >&2
  sleep $((attempt * 2))
done

ATTACH_OUTPUT="$(hdiutil attach "$READ_WRITE_DMG" -readwrite -noverify -noautoopen)"
MOUNT_POINT="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/\/Volumes\// {print substr($0, index($0, "/Volumes/")); exit}')"

if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  echo "Unable to locate mounted DMG for $VOLUME_NAME" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AppleScript layout helpers
# ---------------------------------------------------------------------------

# Layout script used for both level 1 and level 2. The background picture is
# only applied when USE_BACKGROUND is "true". The very last `set bounds` is
# wrapped in a `try` block on purpose: it merely re-asserts the window size
# after the window has been closed and reopened so that Finder persists it in
# the volume. Losing it only costs the window size, not the overall layout.
write_layout_script() {
  cat > "$1" <<'APPLESCRIPT'
on run argv
  set volumeName to item 1 of argv
  set useBackground to item 2 of argv
  with timeout of 30 seconds
    tell application "Finder"
      tell disk volumeName
        open
        delay 1
        set containerWindow to container window
        set current view of containerWindow to icon view
        set toolbar visible of containerWindow to false
        set statusbar visible of containerWindow to false
        set sidebar width of containerWindow to 0
        set bounds of containerWindow to {120, 120, 840, 660}
        set iconViewOptions to icon view options of containerWindow
        set icon size of iconViewOptions to 112
        set text size of iconViewOptions to 12
        set arrangement of iconViewOptions to not arranged
        if useBackground = "true" then
          set background picture of iconViewOptions to file ".background:background.png"
        end if
        set position of item "GitOK.app" to {220, 300}
        set position of item "Applications" to {500, 300}
        close containerWindow
        open
        delay 1
        try
          set bounds of container window to {120, 120, 840, 660}
        end try
      end tell
    end tell
  end timeout
end run
APPLESCRIPT
}

# Run an AppleScript with a wall-clock watchdog. `with timeout` inside
# AppleScript only bounds individual Apple Events; it does not stop a wedged
# osascript process, so we additionally kill the process ourselves.
run_osascript_with_watchdog() {
  local timeout_seconds="$1"
  local script_file="$2"
  shift 2
  local start_seconds pid exit_code

  start_seconds=$SECONDS
  osascript "$script_file" "$@" &
  pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    if (( SECONDS - start_seconds >= timeout_seconds )); then
      kill -9 "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      echo "   ⏱️  osascript 超时（${timeout_seconds}s），已终止" >&2
      return 124
    fi
    sleep 0.5
  done

  set +e
  wait "$pid"
  exit_code=$?
  set -e
  return "$exit_code"
}

# Try one layout level a number of times. Returns 0 as soon as an attempt
# succeeds, 1 if every attempt failed.
apply_layout_with_retries() {
  local script_file="$1"
  local use_background="$2"
  local max_attempts="$3"
  local attempt exit_code

  for (( attempt = 1; attempt <= max_attempts; attempt++ )); do
    echo "   🎨 应用 DMG 排版（背景=${use_background}，尝试 ${attempt}/${max_attempts}）" >&2
    set +e
    run_osascript_with_watchdog 120 "$script_file" "$VOLUME_NAME" "$use_background"
    exit_code=$?
    set -e
    if [[ "$exit_code" -eq 0 ]]; then
      return 0
    fi
    echo "   ⚠️  排版失败（退出码 ${exit_code}）" >&2
    sleep $(( attempt * 2 ))
  done

  return 1
}

LAYOUT_SCRIPT="$WORK_DIR/layout.applescript"
write_layout_script "$LAYOUT_SCRIPT"

LAYOUT_APPLIED=0
if apply_layout_with_retries "$LAYOUT_SCRIPT" "true" 3; then
  LAYOUT_APPLIED=1
  echo "   ✅ 已应用品牌 DMG 排版" >&2
else
  echo "   ⚠️  品牌排版失败，降级为不含背景图的布局" >&2
  echo "::warning::Finder 无法应用品牌 DMG 排版（Apple Event 超时/错误），已降级为不含背景图的布局。DMG 功能与公证不受影响。" >&2
  if apply_layout_with_retries "$LAYOUT_SCRIPT" "false" 2; then
    LAYOUT_APPLIED=2
    echo "   ✅ 已应用无背景图排版" >&2
  else
    echo "   ⚠️  Finder 排版不可用，降级为朴素 DMG（不影响功能与公证）" >&2
    echo "::warning::Finder 排版完全不可用，已降级为朴素 DMG（无自定义窗口布局与背景图）。DMG 功能与公证不受影响。" >&2
  fi
fi

sync
hdiutil detach "$MOUNT_POINT" >/dev/null
MOUNT_POINT=""

rm -f "$OUTPUT_PATH"
hdiutil convert "$READ_WRITE_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$OUTPUT_PATH" >/dev/null

# Verify the produced image actually carries the payload. This guards against
# a degraded layout leaving an empty or partially staged volume behind.
# Mounting is retried because attach itself can transiently fail on CI.
VERIFY_MOUNT="$WORK_DIR/verify"
mkdir -p "$VERIFY_MOUNT"
VERIFY_OK=0
for verify_attempt in 1 2 3; do
  if hdiutil attach "$OUTPUT_PATH" -nobrowse -noautoopen -readonly -mountpoint "$VERIFY_MOUNT" >/dev/null 2>&1; then
    VERIFY_OK=1
    [[ -d "$VERIFY_MOUNT/GitOK.app" ]] || VERIFY_OK=0
    [[ -L "$VERIFY_MOUNT/Applications" ]] || VERIFY_OK=0
    hdiutil detach "$VERIFY_MOUNT" -force >/dev/null 2>&1 || true
    break
  fi
  echo "   ⚠️  校验挂载失败（尝试 ${verify_attempt}/3）" >&2
  sleep $(( verify_attempt * 2 ))
done

if [[ "$VERIFY_OK" -ne 1 ]]; then
  echo "❌ DMG 内容校验失败（缺少 GitOK.app 或 Applications 链接，或无法挂载）" >&2
  exit 1
fi

if [[ "$LAYOUT_APPLIED" -eq 1 ]]; then
  echo "Created $OUTPUT_PATH (branded layout)"
elif [[ "$LAYOUT_APPLIED" -eq 2 ]]; then
  echo "Created $OUTPUT_PATH (layout without background picture)"
else
  echo "Created $OUTPUT_PATH (plain layout)"
fi
