#!/usr/bin/env bash
# 本地验证 release workflow 中的 appcast 相关脚本逻辑
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL + 1)); }

assert_contains() {
  local file="$1" pattern="$2" msg="$3"
  if grep -qF "$pattern" "$file"; then pass "$msg"; else fail "$msg"; fi
}

echo "=== 1. bash 语法检查 ==="
for script in .github/scripts/*.sh; do
  [[ "$(basename "$script")" == "verify-release-appcast.sh" ]] && continue
  bash -n "$script" && pass "bash -n $(basename "$script")" || fail "bash -n $(basename "$script")"
done

echo ""
echo "=== 2. perl：URL 仅替换第一条 ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/sample.xml" <<'EOF'
<enclosure url="https://old/first.dmg"/>
<enclosure url="https://old/second.dmg"/>
EOF
export u="https://github.com/CofficLab/GitOK/releases/latest/download/GitOK-arm64-3_0_9.dmg"
perl -i -pe 'if (!$done) { s/(enclosure url=")[^"]*/$1.$ENV{u}/e && ($done=1) }' "$TMP/sample.xml"
assert_contains "$TMP/sample.xml" "GitOK-arm64-3_0_9.dmg" "第一条 URL 已更新"
assert_contains "$TMP/sample.xml" "https://old/second.dmg" "第二条 URL 未改动"

echo ""
echo "=== 3. perl：release notes 仅注入最新一条 ==="
cat > "$TMP/feed.xml" <<'EOF'
<item>
<sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
<enclosure url="file://new.dmg"/>
</item>
<item>
<sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
<description><![CDATA[old]]></description>
</item>
EOF
export RELEASE_NOTES_HTML='<p>new notes</p>'
export RELEASE_NOTES_LINK="https://github.com/CofficLab/GitOK/releases/latest"
perl -i -0777 -pe '
  if (!$done++) {
    my $notes = $ENV{RELEASE_NOTES_HTML} // "";
    my $link = $ENV{RELEASE_NOTES_LINK} // "";
    my $insert = qq{\n<description><![CDATA[$notes]]></description>\n<sparkle:fullReleaseNotesLink>$link</sparkle:fullReleaseNotesLink>};
    s/(<sparkle:minimumSystemVersion>[^<]+<\/sparkle:minimumSystemVersion>)(?!\s*<description)/$1$insert/s;
  }
' "$TMP/feed.xml"
assert_contains "$TMP/feed.xml" "new notes" "最新 item 注入了 release notes"

echo ""
echo "=== 4. 完整流程（真实 generate_appcast + DMG）==="
WORK="$(mktemp -d)"
cp appcast-arm64.xml appcast-x86_64.xml "$WORK/"
mkdir -p "$WORK/updates"
if ls /tmp/gitok-appcast-test/updates/*.dmg >/dev/null 2>&1; then
  cp /tmp/gitok-appcast-test/updates/*.dmg "$WORK/updates/"
elif ! gh release download v3.0.8 -R CofficLab/GitOK -D "$WORK/updates" --pattern "GitOK-*.dmg" >/dev/null 2>&1; then
  fail "无法获取测试 DMG"
  exit 1
fi

SPARKLE_BIN="$(ls -d ~/Library/Developer/Xcode/DerivedData/GitOK*/SourcePackages/artifacts/sparkle/Sparkle/bin | head -n 1)"
RELEASE_BODY=$(gh api repos/CofficLab/GitOK/releases/latest --jq '.body')
RELEASE_NOTES_HTML=$(echo "$RELEASE_BODY" | gh api markdown -F text=@- -f mode=gfm)
export RELEASE_NOTES_HTML RELEASE_NOTES_LINK="https://github.com/CofficLab/GitOK/releases/latest"
feed_name="appcast-arm64.xml"

cd "$WORK"
for arch in arm64 x86_64; do
  input_dir="appcast_input_${arch}"
  appcast_file="appcast-${arch}.xml"
  mkdir -p "$input_dir"
  cp ./updates/*${arch}*.dmg "$input_dir/"
  [ -f "$appcast_file" ] && cp "$appcast_file" "$input_dir/$feed_name"
  ( cd "$input_dir" && "${SPARKLE_BIN}/generate_appcast" . && mv "$feed_name" "../${appcast_file}" )
  dmg_file=$(basename "$(ls "$input_dir"/*.dmg | head -n 1)")
  export u="https://github.com/CofficLab/GitOK/releases/latest/download/$dmg_file"
  perl -i -pe 'if (!$done) { s/(enclosure url=")[^"]*/$1.$ENV{u}/e && ($done=1) }' "$appcast_file"
  perl -i -0777 -pe '
    if (!$done++) {
      my $notes = $ENV{RELEASE_NOTES_HTML} // "";
      my $link = $ENV{RELEASE_NOTES_LINK} // "";
      my $insert = qq{\n            <description><![CDATA[$notes]]></description>\n            <sparkle:fullReleaseNotesLink>$link</sparkle:fullReleaseNotesLink>};
      s/(<sparkle:minimumSystemVersion>[^<]+<\/sparkle:minimumSystemVersion>)(?!\s*<description)/$1$insert/s;
    }
  ' "$appcast_file"
  assert_contains "$appcast_file" "$dmg_file" "${arch}: enclosure 指向正确 DMG"
done
cp appcast-arm64.xml appcast.xml
ARM=$(grep -m1 -o 'GitOK-arm64[^"]*' appcast-arm64.xml)
X86=$(grep -m1 -o 'GitOK-x86_64[^"]*' appcast-x86_64.xml)
[[ "$ARM" == *arm64* && "$X86" == *x86_64* ]] && pass "arm64 / x86_64 feed 架构隔离" || fail "架构隔离失败"

rm -rf "$WORK"

echo ""
echo "=== 5. generate_appcast 可用 ==="
[ -x "${SPARKLE_BIN}/generate_appcast" ] && pass "generate_appcast 可执行" || fail "generate_appcast 不可用"

echo ""
echo "=== 结果: ${PASS} passed, ${FAIL} failed ==="
[ "$FAIL" -eq 0 ]
