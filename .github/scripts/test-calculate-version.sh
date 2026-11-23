#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gitok-calculate-version-test.XXXXXX")"
trap 'rm -rf "${TEST_ROOT}"' EXIT

setup_repository() {
  local version="$1"
  local build="$2"
  local tag="$3"

  mkdir -p "${TEST_ROOT}/repository/.github/scripts" "${TEST_ROOT}/repository/GitOKApp"
  cp "${REPO_ROOT}/.github/scripts/bump-version.sh" "${TEST_ROOT}/repository/.github/scripts/"
  cp "${REPO_ROOT}/.github/scripts/calculate-version.sh" "${TEST_ROOT}/repository/.github/scripts/"
  cat > "${TEST_ROOT}/repository/GitOKApp/GitOK.xcconfig" <<EOF
// 版本号
MARKETING_VERSION = ${version}
CURRENT_PROJECT_VERSION = ${build}
EOF

  git -C "${TEST_ROOT}/repository" init -q
  git -C "${TEST_ROOT}/repository" config user.email "test@example.com"
  git -C "${TEST_ROOT}/repository" config user.name "Version Test"
  git -C "${TEST_ROOT}/repository" add .
  git -C "${TEST_ROOT}/repository" commit -q -m "chore: initialize test repository"
  git -C "${TEST_ROOT}/repository" tag "${tag}"
}

add_commit() {
  local message="$1"
  printf '%s\n' "${message}" >> "${TEST_ROOT}/repository/change.txt"
  git -C "${TEST_ROOT}/repository" add change.txt
  git -C "${TEST_ROOT}/repository" commit -q -m "${message}"
}

assert_version() {
  local expected="$1"
  local actual
  actual="$(cd "${TEST_ROOT}/repository" && bash .github/scripts/calculate-version.sh 2>/dev/null)"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "FAIL: expected ${expected}, got ${actual}" >&2
    exit 1
  fi
}

# 场景 1：xcconfig 版本高于 tag → 保留 xcconfig 版本（手动 bump 优先）
rm -rf "${TEST_ROOT}/repository"
setup_repository "5.0.0" "500" "v4.0.67"
add_commit "feat: add a release feature"
assert_version "5.0.0"

# 场景 2：tag 版本等于 xcconfig，fix commit → patch +1
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "fix: repair a bug"
assert_version "4.0.68"

# 场景 3：tag 版本等于 xcconfig，feat commit → minor +1
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "feat: add new feature"
assert_version "4.1.0"

# 场景 4：tag 版本等于 xcconfig，breaking change → major +1
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "feat!: breaking change"
assert_version "5.0.0"

# 场景 5：chore commit → patch +1
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "chore: update dependencies"
assert_version "4.0.68"

# 场景 6：多个 commit，取最高级别（feat > fix）
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "fix: bug fix"
add_commit "feat: new feature"
assert_version "4.1.0"

# 场景 7：BREAKING CHANGE 在 body 中 → major
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
printf 'change\n' >> "${TEST_ROOT}/repository/change.txt"
git -C "${TEST_ROOT}/repository" add change.txt
git -C "${TEST_ROOT}/repository" commit -q -m "refactor: rewrite core" -m "BREAKING CHANGE: API changed"
assert_version "5.0.0"

# 场景 8：feat(scope): 格式 → minor
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "feat(Sidebar): add project search bar"
assert_version "4.1.0"

# 场景 9：refactor(scope)!: 格式 → major
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "refactor(core)!: remove deprecated API"
assert_version "5.0.0"

# 场景 10：fix(git): 格式 → patch
rm -rf "${TEST_ROOT}/repository"
setup_repository "4.0.67" "467" "v4.0.67"
add_commit "fix(git): decode non-UTF-8 diff output"
assert_version "4.0.68"

echo "✅ calculate-version tests passed"
