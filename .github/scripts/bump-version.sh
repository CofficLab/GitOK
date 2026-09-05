#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION_FILE="${GITOK_VERSION_FILE:-${ROOT_DIR}/GitOKApp/GitOK.xcconfig}"
DRY_RUN=false

for argument in "$@"; do
  case "$argument" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      echo "❌ 未知参数: $argument" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ 未找到版本配置文件: $VERSION_FILE" >&2
  exit 1
fi

version="$(bash "${SCRIPT_DIR}/get-version.sh" "$VERSION_FILE")"
build="$(bash "${SCRIPT_DIR}/get-version.sh" --build "$VERSION_FILE")"

IFS='.' read -r major minor patch <<< "$version"
new_version="${major}.${minor}.$((patch + 1))"
new_build="$((build + 1))"

echo "📄 配置文件: $VERSION_FILE"
echo "📦 版本号: $version -> $new_version"
echo "🔢 构建号: $build -> $new_build"

if [[ "$DRY_RUN" == true ]]; then
  echo "ℹ️  dry-run：未修改文件"
  exit 0
fi

MARKETING_VERSION="$new_version" CURRENT_PROJECT_VERSION="$new_build" \
  perl -0pi -e '
    my $marketing = $ENV{MARKETING_VERSION};
    my $build = $ENV{CURRENT_PROJECT_VERSION};
    s/^([ \t]*MARKETING_VERSION[ \t]*=[ \t]*)[^\r\n]*/$1$marketing/m;
    s/^([ \t]*CURRENT_PROJECT_VERSION[ \t]*=[ \t]*)[^\r\n]*/$1$build/m;
  ' "$VERSION_FILE"

updated_version="$(bash "${SCRIPT_DIR}/get-version.sh" "$VERSION_FILE")"
updated_build="$(bash "${SCRIPT_DIR}/get-version.sh" --build "$VERSION_FILE")"

if [[ "$updated_version" != "$new_version" || "$updated_build" != "$new_build" ]]; then
  echo "❌ 版本配置写入校验失败" >&2
  exit 3
fi

echo "✅ 已更新版本号: $updated_version"
echo "✅ 已更新构建号: $updated_build"
