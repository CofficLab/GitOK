#!/bin/bash
# 用法: bash scripts/get-version.sh [pbxproj路径]
projectFile=${1:-$(find $(pwd) ! -path "*Resources*" -type f -name "*.pbxproj" | head -n 1)}
if [ -z "$projectFile" ]; then
  echo "❌ 未找到 .pbxproj 配置文件！" >&2
  exit 1
fi
version=$(grep -o "MARKETING_VERSION = [^\"']*" "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
if [ -z "$version" ]; then
  echo "❌ 未找到 MARKETING_VERSION！" >&2
  exit 2
fi
echo "$version" 