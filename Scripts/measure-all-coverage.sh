#!/usr/bin/env bash
# Measures current source-only coverage for every package under Packages/ (parallel).
# Output: /tmp/gitok-cov/current.jsonl  (one JSON per package)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=/tmp/gitok-cov
LOGS="$OUT/logs"
JOBS="${JOBS:-4}"

mkdir -p "$LOGS"
: > "$OUT/current.jsonl"

measure_one() {
  local dir="$1"
  "$ROOT/Scripts/coverage-one.sh" "$dir" >> "$OUT/current.jsonl"
}

export -f measure_one
export ROOT OUT

cd "$ROOT/Packages"
for p in */; do
  [ -f "$p/Package.swift" ] || continue
  printf '%s\n' "$PWD/$p"
done | xargs -P "$JOBS" -I{} bash -c 'measure_one "$@"' _ {}

python3 - <<'PY'
import json
rows=[]
for line in open("/tmp/gitok-cov/current.jsonl"):
    line=line.strip()
    if line: rows.append(json.loads(line))
rows.sort(key=lambda r: r.get("line_cov", 999))
print(f"{'package':42} {'status':16} {'lines%':>7} {'regions%':>9} {'missedLines':>11}")
print("-"*90)
for r in rows:
    if r.get("status")=="ok":
        print(f"{r['package']:42} {r['status']:16} {r['line_cov']:7.1f} {r['region_cov']:9.1f} {r['missed']:11}")
    else:
        print(f"{r['package']:42} {r.get('status'):16} {'-':>7} {'-':>9} {'-':>11}")
PY
echo "--- done -> $OUT/current.jsonl ---"
