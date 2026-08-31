#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "error: xcodegen is required to generate GitOK.xcodeproj" >&2
    exit 1
fi

exec xcodegen generate \
    --spec "$repo_root/project.yml" \
    --project-root "$repo_root" \
    --project "$repo_root"
