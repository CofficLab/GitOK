#!/bin/bash

# 确保脚本在错误时退出
set -e

# 检查参数
if [ $# -lt 1 ]; then
  echo "用法: $0 <dmg_file_path>"
  exit 1
fi

DMG_FILE=$1

# 检查文件是否存在
if [ ! -f "$DMG_FILE" ]; then
  echo "错误: 文件 '$DMG_FILE' 不存在"
  exit 1
fi

# 检查操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "在 macOS 上签名更新..."
  
  # 安装 auto_updater 工具
  flutter pub global activate auto_updater
  
  # 签名更新
  flutter pub global run auto_updater:sign_update "$DMG_FILE"
  
  echo ""
  echo "请将上面的签名添加到 appcast.xml 文件中的 enclosure 节点的 sparkle:edSignature 属性值。"
  
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* ]]; then
  echo "在 Windows 上签名更新..."
  
  # 检查私钥文件
  if [ ! -f "dsa_priv.pem" ]; then
    echo "错误: 私钥文件 'dsa_priv.pem' 不存在"
    echo "请先运行 generate_sparkle_keys.sh 生成密钥"
    exit 1
  fi
  
  # 安装 auto_updater 工具
  flutter pub global activate auto_updater
  
  # 签名更新
  flutter pub global run auto_updater:sign_update "$DMG_FILE"
  
  echo ""
  echo "请将上面的签名添加到 appcast.xml 文件中的 enclosure 节点的 sparkle:dsaSignature 属性值。"
  
else
  echo "不支持的操作系统: $OSTYPE"
  exit 1
fi 