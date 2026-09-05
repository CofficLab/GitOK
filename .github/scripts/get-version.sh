#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION_FILE="${GITOK_VERSION_FILE:-${ROOT_DIR}/GitOKApp/GitOK.xcconfig}"
SETTING="MARKETING_VERSION"

if [[ "${1:-}" == "--build" ]]; then
  SETTING="CURRENT_PROJECT_VERSION"
  shift
fi

if [[ $# -gt 0 ]]; then
  VERSION_FILE="$1"
fi

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ 未找到版本配置文件: $VERSION_FILE" >&2
  exit 1
fi

VALUE="$(awk -v setting="$SETTING" '
  $1 ~ "^[[:space:]]*" setting "[[:space:]]*$" {
    value = $2
    gsub(/^[[:space:]]+/, "", value)
    gsub(/[[:space:];"]+$/, "", value)
    print value
    exit
  }
' FS='=' "$VERSION_FILE")"

if [[ -z "$VALUE" ]]; then
  echo "❌ 未找到 ${SETTING}: $VERSION_FILE" >&2
  exit 2
fi

if [[ "$SETTING" == "MARKETING_VERSION" && ! "$VALUE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ MARKETING_VERSION 格式无效: $VALUE" >&2
  exit 2
fi

if [[ "$SETTING" == "CURRENT_PROJECT_VERSION" && ! "$VALUE" =~ ^[0-9]+$ ]]; then
  echo "❌ CURRENT_PROJECT_VERSION 格式无效: $VALUE" >&2
  exit 2
fi

echo "$VALUE"
