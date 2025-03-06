#!/bin/bash

# 脚本：find_dmg.sh
# 功能：查找 DMG 文件并以指定格式返回路径
# 用法：./find_dmg.sh [选项]
# 选项：
#   -d, --directory DIR    指定搜索目录，默认为当前目录
#   -r, --recursive        递归搜索子目录
#   -n, --name PATTERN     指定文件名模式，默认为 "*.dmg"
#   -f, --format FORMAT    指定输出格式：
#                          full: 完整路径（默认）
#                          name: 仅文件名
#                          relative: 相对路径
#   -l, --latest           仅返回最新的文件
#   -h, --help             显示帮助信息

# 显示帮助信息
show_help() {
  echo "用法: $0 [选项]"
  echo "选项:"
  echo "  -d, --directory DIR    指定搜索目录，默认为当前目录"
  echo "  -r, --recursive        递归搜索子目录"
  echo "  -n, --name PATTERN     指定文件名模式，默认为 \"*.dmg\""
  echo "  -f, --format FORMAT    指定输出格式："
  echo "                         full: 完整路径（默认）"
  echo "                         name: 仅文件名"
  echo "                         relative: 相对路径"
  echo "  -l, --latest           仅返回最新的文件"
  echo "  -h, --help             显示帮助信息"
  echo ""
  echo "示例:"
  echo "  $0 -d ./build -r -f name    # 递归搜索 ./build 目录，仅返回文件名"
  echo "  $0 -l                       # 返回当前目录中最新的 DMG 文件的完整路径"
}

# 默认参数
SEARCH_DIR="."
RECURSIVE=false
NAME_PATTERN="*.dmg"
FORMAT="full"
LATEST=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--directory)
      SEARCH_DIR="$2"
      shift 2
      ;;
    -r|--recursive)
      RECURSIVE=true
      shift
      ;;
    -n|--name)
      NAME_PATTERN="$2"
      shift 2
      ;;
    -f|--format)
      FORMAT="$2"
      shift 2
      ;;
    -l|--latest)
      LATEST=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "错误: 未知选项 $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# 检查目录是否存在
if [ ! -d "$SEARCH_DIR" ]; then
  echo "错误: 目录 '$SEARCH_DIR' 不存在" >&2
  exit 1
fi

# 设置查找命令
FIND_CMD="find \"$SEARCH_DIR\""
if [ "$RECURSIVE" = false ]; then
  FIND_CMD="$FIND_CMD -maxdepth 1"
fi
FIND_CMD="$FIND_CMD -type f -name \"$NAME_PATTERN\""

# 执行查找命令
DMG_FILES=$(eval $FIND_CMD 2>/dev/null)

# 检查是否找到文件
if [ -z "$DMG_FILES" ]; then
  echo "错误: 未找到匹配 '$NAME_PATTERN' 的文件" >&2
  exit 1
fi

# 如果需要最新的文件
if [ "$LATEST" = true ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DMG_FILES=$(echo "$DMG_FILES" | xargs ls -t | head -n 1)
  else
    # Linux 和其他系统
    DMG_FILES=$(echo "$DMG_FILES" | xargs ls -t --time=ctime | head -n 1)
  fi
fi

# 处理输出格式
process_output() {
  local path="$1"
  case "$FORMAT" in
    full)
      # 完整路径
      realpath "$path"
      ;;
    name)
      # 仅文件名
      basename "$path"
      ;;
    relative)
      # 相对路径
      realpath --relative-to="$(pwd)" "$path"
      ;;
    *)
      echo "错误: 未知格式 '$FORMAT'" >&2
      exit 1
      ;;
  esac
}

# 输出结果
echo "$DMG_FILES" | while read -r file; do
  process_output "$file"
done

exit 0 