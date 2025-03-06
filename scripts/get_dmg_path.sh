#!/bin/bash

# 脚本：get_dmg_path.sh
# 功能：自动寻找 DMG 文件并返回其路径
# 用法：./get_dmg_path.sh [搜索目录]
# 返回：找到的第一个 DMG 文件的绝对路径

# 确保脚本在错误时退出
set -e

# 默认搜索当前目录
SEARCH_DIR="."

# 如果提供了参数，则使用参数作为搜索目录
if [ $# -ge 1 ]; then
  SEARCH_DIR="$1"
fi

# 检查目录是否存在
if [ ! -d "$SEARCH_DIR" ]; then
  echo "错误: 目录 '$SEARCH_DIR' 不存在" >&2
  exit 1
fi

# 查找 DMG 文件
DMG_FILES=$(find "$SEARCH_DIR" -maxdepth 1 -type f -name "*.dmg" 2>/dev/null)

# 检查是否找到 DMG 文件
if [ -z "$DMG_FILES" ]; then
  echo "错误: 在 '$SEARCH_DIR' 中未找到 DMG 文件" >&2
  exit 1
fi

# 获取第一个 DMG 文件的路径
DMG_PATH=$(echo "$DMG_FILES" | head -n 1)

# 获取绝对路径
ABSOLUTE_PATH=$(realpath "$DMG_PATH")

# 输出 DMG 文件的绝对路径
echo "$ABSOLUTE_PATH"

# 脚本执行成功
exit 0 