#!/bin/bash
#
# bump-version.sh - 根据 Conventional Commits 计算版本递增级别
#
# 分析上次 tag 以来的 commit 消息，按 Semantic Versioning 2.0.0
# 与 Conventional Commits 规范判断版本递增级别。
#
# Usage: ./bump-version.sh
# Output: major|minor|patch
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 获取最近的 v* 或 p* tag（GitOK 的 pre 分支用 p 前缀，main 分支用 v 前缀）
# 使用 sort -V 确保按版本号大小排序，而非 git 历史顺序
LAST_TAG=$(git tag -l "[vp]*" | grep -vE '[\(\)]' | sort -V | tail -n 1 2>/dev/null || echo "v0.0.0")

# 获取上次 tag 以来的所有 commit 完整消息（含 body，用于检测 BREAKING CHANGE:）
COMMITS=$(git log "${LAST_TAG}..HEAD" --pretty=format:%B 2>/dev/null || echo "")

# 无 commit 时默认 patch
if [ -z "$COMMITS" ]; then
  echo "patch"
  exit 0
fi

# 检查破坏性变更
# - commit body 中的 BREAKING CHANGE:
# - commit subject 中的 feat!: / feat(scope)!: / fix!: / refactor!: 等
#   （Conventional Commits 的 ! 标记，scope 可选）
if echo "$COMMITS" | grep -qE "BREAKING CHANGE|^(feat|fix|refactor)(\([^)]*\))?!"; then
  echo "major"
  exit 0
fi

# 检查新功能（feat: 或 feat(scope): 格式）
if echo "$COMMITS" | grep -qE "^feat(\([^)]*\))?!?:"; then
  echo "minor"
  exit 0
fi

# 其他情况（fix / chore / docs / refactor 等）默认 patch
echo "patch"
