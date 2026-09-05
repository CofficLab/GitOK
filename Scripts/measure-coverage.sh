#!/usr/bin/env bash
# Usage: measure-coverage.sh <package-dir>
# Runs `swift test --enable-code-coverage` for a package and prints source-only coverage.
set -euo pipefail

pkg="${1:?package dir required}"
pkgname="$(basename "$(cd "$pkg" && pwd)")"

if [ ! -f "$pkg/Package.swift" ]; then
    echo "SKIP: no Package.swift in $pkg"
    exit 0
fi

echo "=== $pkgname ==="
(cd "$pkg" && swift test --enable-code-coverage) >"/tmp/coverage-$pkgname.log" 2>&1

codecov_dir=$(find "$pkg/.build" -type d -name codecov 2>/dev/null | head -1)
test_bin=$(find "$pkg/.build" -path "*/debug/*PackageTests.xctest/Contents/MacOS/*" -type f ! -path "*dSYM*" 2>/dev/null | head -1)

if [ -z "$codecov_dir" ] || [ -z "$test_bin" ]; then
    echo "WARN: no coverage data or test binary found"; tail -5 "/tmp/coverage-$pkgname.log"; exit 0
fi

xcrun llvm-cov report -instr-profile="$codecov_dir/default.profdata" "$test_bin" \
    | awk -v pkg="$pkgname" '
        BEGIN { src_lines=0; src_missed=0; src_regions=0; src_missed_regions=0 }
        $1 ~ /Sources\// && $1 !~ /\.build\// && ($1 ~ ("^" pkg "/Sources/") || $1 ~ /^Sources\//) {
            # columns: file, regions, missed regions, cover%, funcs, missed funcs, exec, lines, missed lines, cover%, branches...
            lines=$8+0; missed=$9+0; regions=$2+0; mregions=$3+0
            src_lines+=lines; src_missed+=missed; src_regions+=regions; src_missed_regions+=mregions
            total=lines; cov=total>0 ? (total-missed)/total*100 : 0
            printf "  %-62s %6.1f%%  (%d/%d lines)\n", $1, cov, total-missed, total
        }
        END {
            tcov = src_lines>0 ? (src_lines-src_missed)/src_lines*100 : 0
            rcov = src_regions>0 ? (src_regions-src_missed_regions)/src_regions*100 : 0
            printf "  SOURCE TOTAL: %.1f%% lines, %.1f%% regions (%d lines, %d regions)\n", tcov, rcov, src_lines, src_regions
        }'
