#!/bin/bash

# 确保脚本在错误时退出
set -e

# 检查操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "在 macOS 上生成 EdDSA 密钥..."
  
  # 安装 auto_updater 工具
  flutter pub global activate auto_updater
  
  # 生成密钥
  flutter pub global run auto_updater:generate_keys
  
  echo "密钥已生成并保存在您的钥匙串中。"
  echo "请将生成的 SUPublicEDKey 添加到 macos/Runner/Info.plist 文件中。"
  echo "格式如下:"
  echo ""
  echo "<key>SUPublicEDKey</key>"
  echo "<string>YOUR_PUBLIC_KEY_HERE</string>"
  
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* ]]; then
  echo "在 Windows 上生成 DSA 密钥..."
  
  # 安装 auto_updater 工具
  flutter pub global activate auto_updater
  
  # 生成密钥
  flutter pub global run auto_updater:generate_keys
  
  echo "已生成两个文件:"
  echo "dsa_priv.pem: 您的私钥。请保密并不要共享!"
  echo "dsa_pub.pem: 要包含在应用程序中的公钥。"
  echo ""
  echo "请备份您的私钥并确保其安全!"
  echo "如果您丢失了它，您的用户将无法升级!"
  echo ""
  echo "请将公钥添加到 windows/runner/Runner.rc 文件中，格式如下:"
  echo ""
  echo "DSAPub      DSAPEM      \"../../dsa_pub.pem\""
  
else
  echo "不支持的操作系统: $OSTYPE"
  exit 1
fi 