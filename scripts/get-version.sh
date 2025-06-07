#!/bin/bash

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
        "version:📝 版本管理:查看或更新应用版本号"
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

# 用法: bash scripts/get-version.sh [pbxproj路径]
projectFile=${1:-$(find $(pwd) -maxdepth 2 ! -path "*Resources*" ! -path "*temp*" -type f -name "*.pbxproj" | head -n 1)}
if [ -z "$projectFile" ]; then
  echo "❌ 未找到 .pbxproj 配置文件！" >&2
  exit 1
fi
version=$(grep "MARKETING_VERSION" "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
if [ -z "$version" ]; then
  echo "❌ 未找到 MARKETING_VERSION！" >&2
  exit 2
fi
echo "当前版本号: $version"

# 显示开发路线图
show_development_roadmap "version"