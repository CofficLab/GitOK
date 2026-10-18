#!/usr/bin/env bash
# Runs `swift test --enable-code-coverage` for a package, prints JSON line with source-only coverage.
set -uo pipefail

pkg="${1:?package dir required}"
pkgname="$(basename "$(cd "$pkg" && pwd)")"

if [ ! -f "$pkg/Package.swift" ]; then
  echo "{\"package\":\"$pkgname\",\"status\":\"skip_no_manifest\"}"
  exit 0
fi

log="/tmp/gitok-cov/logs/$pkgname.log"
mkdir -p /tmp/gitok-cov/logs
( cd "$pkg" && swift test --enable-code-coverage ) > "$log" 2>&1
rc=$?

codecov_dir=$(find "$pkg/.build" -type d -name codecov 2>/dev/null | head -1)
test_bin=$(find "$pkg/.build" -path "*.xctest/Contents/MacOS/*" -type f ! -path "*dSYM*" ! -name "*.plist" 2>/dev/null | head -1)

if [ -z "$codecov_dir" ] || [ -z "$test_bin" ]; then
  if [ $rc -ne 0 ]; then
    echo "{\"package\":\"$pkgname\",\"status\":\"build_or_test_failed\",\"rc\":$rc}"
  else
    echo "{\"package\":\"$pkgname\",\"status\":\"no_coverage\"}"
  fi
  exit 0
fi

xcrun llvm-cov report -instr-profile="$codecov_dir/default.profdata" "$test_bin" \
  | awk -v pkg="$pkgname" '
      $1 ~ /Sources\// && $1 !~ /\.build\// && ($1 ~ ("^" pkg "/Sources/") || $1 ~ /^Sources\//) {
          lines=$8+0; missed=$9+0; regions=$2+0; mregions=$3+0; fns=$5+0; mfn=$6+0
          printf "FILE\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n", $1, lines, missed, regions, mregions, fns, mfn
      }' > /tmp/gitok-cov/files-$pkgname.tsv

python3 - "$pkgname" "$rc" <<'PY'
import json,sys
pkg, rc = sys.argv[1], int(sys.argv[2])
L=M=R=MR=F=MF=0
files=[]
try:
    for line in open(f"/tmp/gitok-cov/files-{pkg}.tsv"):
        p=line.rstrip("\n").split("\t")
        if p[0]!="FILE": continue
        _,path,lines,missed,regions,mregions,fns,mfn=p
        L+=int(lines);M+=int(missed);R+=int(regions);MR+=int(mregions);F+=int(fns);MF+=int(mfn)
        files.append({"file":path.replace(f"{pkg}/Sources/",""),"lines":int(lines),"missed":int(missed)})
except FileNotFoundError:
    pass
lc = round((L-M)/L*100,1) if L else 0.0
rc_ = round((R-MR)/R*100,1) if R else 0.0
print(json.dumps({"package":pkg,"status":"ok" if rc==0 else "test_failed","rc":rc,
                  "lines":L,"missed":M,"line_cov":lc,"regions":R,"missed_regions":MR,"region_cov":rc_,
                  "files":sorted(files,key=lambda f:-f["missed"])[:8]}))
PY
