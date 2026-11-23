#!/bin/bash
#
# calculate-version.sh - 计算下一个语义化版本号
#
# 基于 bump-version.sh 确定的递增类型（major/minor/patch）计算新版本。
# 同时兼顾 xcconfig 中手动设置的版本号：当它高于最新 tag 时保留原值，
# 避免手动 bump major/minor 后被 CI 再叠加一次。
#
# Usage: ./calculate-version.sh
# Output: <version> (e.g., 4.0.68)
# Stderr: 诊断信息（tag 版本、xcconfig 版本等）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION_FILE="${GITOK_VERSION_FILE:-${ROOT_DIR}/GitOKApp/GitOK.xcconfig}"

# 获取最近的 v* tag（main 分支用 v 前缀；pre 分支的 p* tag 不参与语义化版本计算）
# 使用 sort -V 确保按版本号大小排序
LAST_TAG=$(git tag -l "v*" | sort -V | tail -n 1 2>/dev/null || echo "v0.0.0")
LAST_TAG="${LAST_TAG#v}"

# 从 xcconfig 读取当前 MARKETING_VERSION
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ 未找到版本配置文件: $VERSION_FILE" >&2
  exit 1
fi

XCODE_VERSION=$(awk '/^[[:space:]]*MARKETING_VERSION[[:space:]]*=/ {
  value = $2
  gsub(/^[[:space:]]+/, "", value)
  gsub(/[[:space:];"]+$/, "", value)
  print value
  exit
}' FS='=' "$VERSION_FILE")
XCODE_VERSION="${XCODE_VERSION:-0.0.0}"

# 取 tag 版本与 xcconfig 版本中较高的作为基准
# sort -V 做版本号感知的排序（如 1.10 > 1.9）
BASE_VERSION=$(printf '%s\n' "${LAST_TAG}" "${XCODE_VERSION}" | sort -V | tail -n 1)

echo "Git tag version: ${LAST_TAG}" >&2
echo "Xcode version: ${XCODE_VERSION}" >&2

# 当 xcconfig 中的版本高于最新 tag 时，说明是手动设定的新版本，直接使用
# 避免手动 bump major/minor 后被 CI 再叠加一次递增
if [[ "${XCODE_VERSION}" != "${LAST_TAG}" && "${BASE_VERSION}" == "${XCODE_VERSION}" ]]; then
  echo "Using repository version: ${XCODE_VERSION}" >&2
  echo "${XCODE_VERSION}"
  exit 0
fi

echo "Using base version: ${BASE_VERSION}" >&2

# 获取递增类型（major / minor / patch）
INCREMENT_TYPE=$("${SCRIPT_DIR}/bump-version.sh")
echo "Increment type: ${INCREMENT_TYPE}" >&2

# 基于基准版本计算新版本
LAST_TAG="${BASE_VERSION}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$LAST_TAG"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

case $INCREMENT_TYPE in
  major)
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  minor)
    NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
    ;;
  patch)
    NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
    ;;
  *)
    echo "❌ 未知的递增类型: '$INCREMENT_TYPE'" >&2
    exit 1
    ;;
esac

echo "$NEW_VERSION"
