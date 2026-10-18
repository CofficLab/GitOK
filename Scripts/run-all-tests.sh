#!/usr/bin/env bash
# Runs `swift test` for every package under Packages/ that has a Tests dir.
# Logs per package to /tmp/gitok-tests/logs/<pkg>.log, summary to /tmp/gitok-tests/summary.txt
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=/tmp/gitok-tests
LOGS="$OUT/logs"
JOBS="${JOBS:-4}"

mkdir -p "$LOGS"
: > "$OUT/summary.txt"

run_one() {
  local dir="$1"
  local name; name="$(basename "$dir")"
  local log="$LOGS/$name.log"

  if [ ! -f "$dir/Package.swift" ]; then
    echo "SKIP_NO_MANIFEST|$name" >> "$OUT/summary.txt"
    return
  fi

  local start end dur
  start=$(date +%s)
  ( cd "$dir" && swift test ) > "$log" 2>&1
  local rc=$?
  end=$(date +%s)
  dur=$((end-start))

  local status
  if [ $rc -eq 0 ]; then
    status=PASS
  elif grep -qE "error:|✘|Test run with .* failed|fatalError" "$log"; then
    status=FAIL
  else
    status=OTHER
  fi

  echo "$status|$name|${dur}s|rc=$rc" >> "$OUT/summary.txt"
}

export -f run_one
export OUT LOGS

cd "$ROOT/Packages"

# parallel dispatch
for p in */; do
  [ -d "$p/Tests" ] || continue
  printf '%s\n' "$PWD/$p"
done | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {}

echo "--- done ---"
