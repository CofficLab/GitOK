#!/bin/bash

# ====================================
# macOS 应用版本号自动递增脚本
# ====================================
#
# 功能说明:
#   自动读取 Xcode 项目文件中的 MARKETING_VERSION，
#   将版本号的最后一位数字递增 1，并更新到项目文件中。
#
# 使用方法:
#   bash scripts/bump-version.sh
#
# 版本号格式:
#   支持标准的三位版本号格式：主版本.次版本.修订版本 (例如: 1.4.6)
#   脚本会自动递增修订版本号 (最后一位数字)
#
# 依赖条件:
#   - 项目根目录下存在 .pbxproj 文件
#   - 项目文件中包含 MARKETING_VERSION 配置
#   - 版本号格式符合 x.y.z 的标准格式
#
# 输出结果:
#   - 显示当前版本号和新版本号
#   - 更新项目文件中的版本号
#   - 显示 Git 状态变更
#   - 展示开发分发路线图
#
# 示例:
#   当前版本: 1.4.6 → 更新后版本: 1.4.7
#
# 注意事项:
#   - 脚本会直接修改项目文件，建议在版本控制环境下使用
#   - 执行后需要手动提交 Git 变更
#   - 仅递增修订版本号，如需更新主版本或次版本请手动修改
# ====================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示开发路线图
show_development_roadmap() {
    local current_step="$1"
    
    echo
    printf "${PURPLE}===========================================${NC}\n"
    printf "${PURPLE}         🗺️  开发分发路线图                ${NC}\n"
    printf "${PURPLE}===========================================${NC}\n"
    echo
    
    # 定义路线图步骤（包含版本管理）
    local steps=(
        "version:📝 版本管理:更新应用版本号"
        "build:🔨 构建应用:编译源代码，生成可执行文件"
        "codesign:🔐 代码签名:为应用添加数字签名，确保安全性"
        "package:📦 打包分发:创建 DMG 安装包"
        "notarize:✅ 公证验证:Apple 官方验证（可选）"
        "distribute:🚀 发布分发:上传到分发平台或直接分发"
    )
    
    printf "${CYAN}📍 当前位置: "
    case "$current_step" in
        "version") printf "${GREEN}版本管理${NC}\n" ;;
        "build") printf "${GREEN}构建应用${NC}\n" ;;
        "codesign") printf "${GREEN}代码签名${NC}\n" ;;
        "package") printf "${GREEN}打包分发${NC}\n" ;;
        "notarize") printf "${GREEN}公证验证${NC}\n" ;;
        "distribute") printf "${GREEN}发布分发${NC}\n" ;;
        *) printf "${YELLOW}未知步骤${NC}\n" ;;
    esac
    echo
    
    # 显示路线图
    for step in "${steps[@]}"; do
        local step_id=$(echo "$step" | cut -d':' -f1)
        local step_icon=$(echo "$step" | cut -d':' -f2)
        local step_desc=$(echo "$step" | cut -d':' -f3)
        
        if [ "$step_id" = "$current_step" ]; then
            printf "${GREEN}▶ %s %s${NC}\n" "$step_icon" "$step_desc"
        else
            printf "  %s %s\n" "$step_icon" "$step_desc"
        fi
    done
    
    echo
    printf "${YELLOW}💡 下一步建议:${NC}\n"
    case "$current_step" in
        "version")
            printf "   构建应用: ${CYAN}./scripts/build-app.sh${NC}\n"
            ;;
        "build")
            printf "   运行代码签名: ${CYAN}./scripts/codesign-app.sh${NC}\n"
            ;;
        "codesign")
            printf "   创建安装包: ${CYAN}./scripts/create-dmg.sh${NC}\n"
            ;;
        "package")
            printf "   进行公证验证或直接分发应用\n"
            ;;
        "notarize")
            printf "   发布到分发平台或提供下载链接\n"
            ;;
        "distribute")
            printf "   🎉 开发分发流程已完成！\n"
            ;;
    esac
    
    echo
    printf "${PURPLE}===========================================${NC}\n"
}

printf "${BLUE}===========================================${NC}\n"
printf "${BLUE}         版本管理环境信息                ${NC}\n"
printf "${BLUE}===========================================${NC}\n"
echo

# 系统信息
printf "${GREEN}📱 系统信息:${NC}\n"
echo "   操作系统: $(uname -s) $(uname -r)"
echo "   系统架构: $(uname -m)"
echo "   主机名称: $(hostname)"
echo

# Xcode 信息
printf "${GREEN}🔨 Xcode 开发环境:${NC}\n"
if command -v xcodebuild &> /dev/null; then
    echo "   Xcode 版本: $(xcodebuild -version | head -n 1)"
    echo "   构建版本: $(xcodebuild -version | tail -n 1)"
else
    printf "   ${RED}❌ 未找到 Xcode${NC}\n"
fi
echo

# Swift 信息
printf "${GREEN}🚀 Swift 编译器:${NC}\n"
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version 2>/dev/null | grep -o 'Swift version [0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d' ' -f3)
    echo "   Swift 版本: ${SWIFT_VERSION}"
else
    printf "   ${RED}❌ 未找到 Swift${NC}\n"
fi
echo

# Git 信息
printf "${GREEN}📝 Git 版本控制:${NC}\n"
if command -v git &> /dev/null; then
    echo "   Git 版本: $(git --version)"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "   当前分支: $(git branch --show-current)"
        echo "   最新提交: $(git log -1 --pretty=format:'%h - %s (%an, %ar)')"
    fi
else
    printf "   ${RED}❌ 未找到 Git${NC}\n"
fi
echo

printf "${BLUE}===========================================${NC}\n"
printf "${BLUE}         开始版本号更新流程                ${NC}\n"
printf "${BLUE}===========================================${NC}\n"
echo

# 读取配置文件路径
projectFile=$(find $(pwd) -maxdepth 2 ! -path "*Resources*" ! -path "*temp*" -type f -name "*.pbxproj" | head -n 1)

if [ -z "$projectFile" ]; then
  echo "❌ 未找到 .pbxproj 配置文件！"
  exit 1
fi

echo "🔍 配置文件路径: $projectFile"

# 读取文件中的版本号
version=$(grep -o "MARKETING_VERSION = [^\"']*" "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')

if [ -z "$version" ]; then
  echo "❌ 未找到 MARKETING_VERSION！"
  exit 1
fi

echo "📦 当前版本号: $version"

# 将版本号拆分为数组
IFS='.' read -r -a versionArray <<< "$version"

# 递增最后一位数字
((versionArray[2]++))

# 重新组合版本号
newVersion="${versionArray[0]}.${versionArray[1]}.${versionArray[2]}"

echo "⬆️  新版本号: $newVersion"

echo "📝 正在写入新版本号到文件..."

# 新版本号写入文件
sed -i '' "s/MARKETING_VERSION = $version/MARKETING_VERSION = $newVersion/" "$projectFile"

updatedVersion=$(grep -o "MARKETING_VERSION = [^\"']*" "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')

echo "✅ 更新后的版本号: $updatedVersion"

git status

# 显示开发路线图
show_development_roadmap "version"