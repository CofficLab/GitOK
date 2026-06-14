#!/bin/bash
# Local smoke tests for release.yaml appcast/changelog logic.
# Usage: bash .github/scripts/test-release-workflow.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

pass() { echo "✅ $1"; }
fail() { echo "❌ $1" >&2; exit 1; }

echo "=== 1. install-sparkle-tools.sh ==="
chmod +x "${ROOT}/.github/scripts/install-sparkle-tools.sh"
SPARKLE_BIN="$(
  SPARKLE_VERSION=2.8.1 RUNNER_TEMP="${WORK}" \
    "${ROOT}/.github/scripts/install-sparkle-tools.sh"
)"
[[ "${SPARKLE_BIN}" == *$'\n'* ]] && fail "install script stdout must be a single line"
[ -x "${SPARKLE_BIN}/generate_appcast" ] || fail "generate_appcast missing"
"${SPARKLE_BIN}/generate_appcast" --help >/dev/null
pass "Sparkle tools install"

echo "=== 2. tag + changelog logic ==="
cd "${ROOT}"
tag=$(git describe --tags --abbrev=0)
if [[ $tag == p* ]]; then
  previous_tag=$(git tag -l "p[0-9]*" | sort -V | grep -Fxv "$tag" | tail -n 1)
  [ -z "$previous_tag" ] && previous_tag=$(git tag -l "v*" | sort -V | tail -n 1)
else
  previous_tag=$(git tag -l "v*" | sort -V | grep -Fxv "$tag" | tail -n 1)
fi
[ -n "$tag" ] || fail "no tag found"
if [ -n "$previous_tag" ]; then
  CHANGES=$(git log "${previous_tag}"..HEAD --no-merges --pretty=format:'- %s' \
    | grep -Ev '^- (ci|chore|build|style|test)(\(|:)' \
    | grep -Ev '^- 👷 CI:' \
    | sort -u \
    | head -20 || true)
  [ -n "$CHANGES" ] || CHANGES="- Maintenance and stability improvements"
  printf '%s\n' "$CHANGES" | head -3
fi
pass "tag=${tag} previous=${previous_tag:-none}"

echo "=== 3. perl appcast post-process ==="
cat > "${WORK}/appcast-arm64.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <item>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="file://local/old.dmg" sparkle:edSignature="abc" length="123" type="application/octet-stream"/>
        </item>
    </channel>
</rss>
EOF
cd "${WORK}"
export u="https://github.com/CofficLab/GitOK/releases/latest/download/GitOK-arm64-test.dmg"
export RELEASE_NOTES_HTML="<p>test</p>"
export RELEASE_NOTES_LINK="https://github.com/CofficLab/GitOK/releases/latest"
perl -i -pe 'if (!$done) { s/(enclosure url=")[^"]*/$1.$ENV{u}/e && ($done=1) }' appcast-arm64.xml
perl -i -0777 -pe '
  if (!$done++) {
    my $notes = $ENV{RELEASE_NOTES_HTML} // "";
    my $link = $ENV{RELEASE_NOTES_LINK} // "";
    my $insert = qq{\n            <description><![CDATA[$notes]]></description>\n            <sparkle:fullReleaseNotesLink>$link</sparkle:fullReleaseNotesLink>};
    s/(<sparkle:minimumSystemVersion>[^<]+<\/sparkle:minimumSystemVersion>)(?!\s*<description)/$1$insert/s;
  }
' appcast-arm64.xml
grep -q 'releases/latest/download/GitOK-arm64-test.dmg' appcast-arm64.xml || fail "url rewrite failed"
grep -q 'fullReleaseNotesLink' appcast-arm64.xml || fail "release notes link missing"
command -v xmllint >/dev/null && xmllint --noout appcast-arm64.xml
pass "perl post-process"

echo "=== 4. generate_appcast with real DMG (optional) ==="
SAMPLE_DMG=""
if [ -f "${ROOT}/temp/GitOK-arm64"*.dmg ]; then
  SAMPLE_DMG=$(ls "${ROOT}"/temp/GitOK-arm64*.dmg | head -n 1)
elif command -v gh >/dev/null; then
  mkdir -p "${WORK}/dmg"
  if gh release download v3.0.13 --repo CofficLab/GitOK --pattern '*arm64*' --dir "${WORK}/dmg" 2>/dev/null; then
    SAMPLE_DMG=$(ls "${WORK}/dmg"/*.dmg | head -n 1)
  fi
fi

if [ -n "$SAMPLE_DMG" ]; then
  mkdir -p "${WORK}/updates" "${WORK}/appcast_input_arm64"
  cp "$SAMPLE_DMG" "${WORK}/updates/"
  cp "${WORK}/updates/"*.dmg "${WORK}/appcast_input_arm64/"
  TEST_KEY=$(openssl rand -base64 32)
  echo "$TEST_KEY" | "${SPARKLE_BIN}/generate_appcast" --ed-key-file - "${WORK}/appcast_input_arm64"
  [ -f "${WORK}/appcast_input_arm64/appcast.xml" ] || fail "expected appcast.xml output"
  cp "${WORK}/appcast_input_arm64/appcast.xml" "${WORK}/appcast-arm64.xml"
  grep -q '<enclosure url=' "${WORK}/appcast-arm64.xml" || fail "missing enclosure"
  grep -q 'length=' "${WORK}/appcast-arm64.xml" || fail "missing enclosure length"
  pass "generate_appcast with real DMG"
else
  echo "⚠️  skipped (no local DMG and gh download unavailable)"
fi

echo
echo "All release workflow smoke tests passed."
