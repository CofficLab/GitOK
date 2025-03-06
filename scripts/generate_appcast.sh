#!/bin/bash

# 确保脚本在错误时退出
set -e

# 检查参数
if [ $# -lt 3 ]; then
  echo "用法: $0 <dmg_file_path> <version> <signature>"
  exit 1
fi

DMG_FILE=$1
VERSION=$2
SIGNATURE=$3

# 检查文件是否存在
if [ ! -f "$DMG_FILE" ]; then
  echo "错误: 文件 '$DMG_FILE' 不存在"
  exit 1
fi

# 检查模板文件是否存在
TEMPLATE_FILE="scripts/appcast.xml.template"
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "错误: 模板文件 '$TEMPLATE_FILE' 不存在"
  exit 1
fi

# 获取文件大小
FILE_SIZE=$(stat -f%z "$DMG_FILE")

# 获取文件名
DMG_FILENAME=$(basename "$DMG_FILE")

# 获取当前日期
PUB_DATE=$(date -R)

# 版本号（去除点号）
VERSION_NUMBER=$(echo $VERSION | tr -d '.')

# 创建 appcast.xml 文件
cat "$TEMPLATE_FILE" | \
  sed "s/VERSION/$VERSION/g" | \
  sed "s/VERSION_NUMBER/$VERSION_NUMBER/g" | \
  sed "s/PUB_DATE/$PUB_DATE/g" | \
  sed "s/DMG_FILENAME/$DMG_FILENAME/g" | \
  sed "s/ED_SIGNATURE/$SIGNATURE/g" | \
  sed "s/FILE_SIZE/$FILE_SIZE/g" > appcast.xml

echo "已生成 appcast.xml 文件" 