#!/bin/bash

# 脚本：get_dmg_info.sh
# 功能：查找 DMG 文件并输出相关信息
# 用法：./get_dmg_info.sh [搜索目录]
# 输出：DMG 文件的路径、文件名和大小

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
DMG_FILE=$(find "$SEARCH_DIR" -maxdepth 1 -type f -name "*.dmg" | head -n 1)

# 检查是否找到 DMG 文件
if [ -z "$DMG_FILE" ]; then
  echo "错误: 在 '$SEARCH_DIR' 中未找到 DMG 文件" >&2
  exit 1
fi

# 获取绝对路径
ABSOLUTE_PATH=$(realpath "$DMG_FILE")

# 获取文件名
FILENAME=$(basename "$ABSOLUTE_PATH")

# 获取文件大小
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  FILE_SIZE=$(stat -f%z "$ABSOLUTE_PATH")
else
  # Linux 和其他系统
  FILE_SIZE=$(stat -c%s "$ABSOLUTE_PATH")
fi

# 输出信息（键值对格式，方便解析）
echo "DMG_FILE=$ABSOLUTE_PATH"
echo "DMG_FILENAME=$FILENAME"
echo "FILE_SIZE=$FILE_SIZE"

# 脚本执行成功
exit 0 