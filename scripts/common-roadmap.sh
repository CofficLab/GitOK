#!/bin/bash

# ====================================
# 开发分发路线图公共库
# ====================================
#
# 这个脚本提供了开发分发流程的路线图显示功能，用于在各个构建脚本中
# 显示当前步骤和下一步建议，帮助开发者了解整个开发分发流程。
#
# 功能：
# 1. 显示完整的开发分发路线图
# 2. 高亮当前执行步骤
# 3. 提供下一步操作建议

#
# 使用方法：
# 1. 在其他脚本中引入此库：
#    source "$(dirname "$0")/common-roadmap.sh"
#
# 2. 调用路线图显示函数：
#    show_development_roadmap "current_step"
#
# 3. 支持的步骤：
#    - setup: 环境设置
#    - version: 版本管理
#    - build: 构建应用
#    - codesign: 代码签名
#    - package: 打包分发
#    - notarize: 公证验证
#    - distribute: 发布分发
#
# 注意事项：
# - 依赖 common-output.sh 提供颜色变量和输出函数
# - 此脚本不会独立运行，仅作为库文件被其他脚本引用
# ====================================

# 注意：依赖调用脚本已引入 common-output.sh 提供颜色变量

# 显示开发分发路线图
show_development_roadmap() {
    local current_step="$1"
    
    echo
    print_title_box "🗺️  开发分发路线图" "$PURPLE"
    
    # 定义完整路线图步骤
    local steps=(
        "setup:⚙️ 环境设置:配置代码签名环境"
        "version:📝 版本管理:查看或更新应用版本号"
        "build:🔨 构建应用:编译源代码，生成可执行文件"
        "codesign:🔐 代码签名:为应用添加数字签名，确保安全性"
        "package:📦 打包分发:创建 DMG 安装包"
        "notarize:✅ 公证验证:Apple 官方验证（可选）"
        "distribute:🚀 发布分发:上传到分发平台或直接分发"
    )
    
    # 显示当前位置
    printf "${CYAN}📍 当前位置: "
    case "$current_step" in
        "setup") printf "${GREEN}环境设置${NC}\n" ;;
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
        "setup")
            printf "   查看版本信息: ${CYAN}./scripts/get-version.sh${NC}\n"
            printf "   或直接构建应用: ${CYAN}./scripts/build-app.sh${NC}\n"
            ;;
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