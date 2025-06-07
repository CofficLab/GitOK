#!/bin/bash

# ====================================
# macOS 应用代码签名脚本
# ====================================
#
# 这个脚本用于对 macOS 应用程序进行代码签名，包括 Sparkle 框架的各个组件。
# 脚本会显示详细的签名环境信息，帮助开发者了解当前的签名状态，便于调试和问题排查。
#
# 功能：
# 1. 显示系统环境信息（操作系统、架构、主机名等）
# 2. 显示代码签名环境信息（证书、身份等）
# 3. 显示应用程序信息（路径、版本等）
# 4. 对 Sparkle 框架组件进行代码签名
# 5. 对主应用程序进行代码签名
# 6. 验证代码签名结果
# 7. 显示签名结果和状态
#
# 使用方法：
# 1. 设置必要的环境变量：
#    export SCHEME="YourAppScheme"             # 应用方案名称
#    export SIGNING_IDENTITY="Developer ID"   # 代码签名身份
#    export BuildPath="/path/to/build"        # 构建输出路径（可选，默认为 ./temp）
#    export VERBOSE="true"                    # 可选：显示详细签名日志
#
# 2. 在项目根目录运行脚本：
#    ./scripts/codesign-app.sh
#
# 3. 启用详细日志模式：
#    VERBOSE=true ./scripts/codesign-app.sh
#
# 注意事项：
# - 需要有效的 Apple 开发者证书
# - 需要在 macOS 系统上运行
# - 确保 SCHEME 和 SIGNING_IDENTITY 环境变量已正确设置
# - 应用程序必须已经构建完成
# - 脚本会对 Sparkle 框架的所有组件进行签名
#
# 输出：
# - 详细的环境信息报告
# - 代码签名过程的实时输出
# - 签名验证结果
# - 如果签名失败，脚本会以非零状态码退出
# ====================================

# 设置错误处理
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印成功信息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 打印错误信息
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 打印警告信息
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 打印信息
print_info() {
    echo -e "${BLUE}ℹ️  $1: $2${NC}"
}

# 打印分隔线
print_separator() {
    echo -e "${BLUE}===========================================${NC}"
}

# 打印标题
print_title() {
    echo -e "${PURPLE}$1${NC}"
}

# 执行命令并显示结果
execute_command() {
    local cmd="$1"
    local description="$2"
    
    echo -e "${PURPLE}🔧 $description${NC}"
    
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${BLUE}执行命令: $cmd${NC}"
    fi
    
    if eval "$cmd"; then
        print_success "$description 完成"
    else
        print_error "$description 失败"
        exit 1
    fi
    echo
}

# 检查环境变量并提供建议的函数
check_and_suggest() {
    local missing_vars=""
    
    # 检查 SCHEME
    if [ -z "$SCHEME" ]; then
        missing_vars="${missing_vars}SCHEME "
    fi
    
    # 检查 SIGNING_IDENTITY
    if [ -z "$SIGNING_IDENTITY" ]; then
        missing_vars="${missing_vars}SIGNING_IDENTITY "
    fi
    
    # 如果有缺失的环境变量，提供完整建议
    if [ -n "$missing_vars" ]; then
        echo "❌ 错误: 以下环境变量未设置: $missing_vars"
        echo "正在自动检测可用的配置..."
        echo
        
        # 查找项目文件
        if ls *.xcworkspace 1> /dev/null 2>&1; then
            PROJECT_FILE=$(ls -d *.xcworkspace | head -1)
            PROJECT_TYPE="-workspace"
        elif ls *.xcodeproj 1> /dev/null 2>&1; then
            PROJECT_FILE=$(ls -d *.xcodeproj | head -1)
            PROJECT_TYPE="-project"
        else
            echo "❌ 未找到 Xcode 项目文件"
            exit 1
        fi
        
        # 获取可用的 schemes
        echo "📋 检测到的可用 Scheme:"
        AVAILABLE_SCHEMES=$(xcodebuild $PROJECT_TYPE "$PROJECT_FILE" -list 2>/dev/null | sed -n '/Schemes:/,/^$/p' | grep -v 'Schemes:' | grep -v '^$' | sed 's/^[[:space:]]*//' | sort -u)
        
        if [ -n "$AVAILABLE_SCHEMES" ]; then
            echo "$AVAILABLE_SCHEMES" | while read -r scheme; do
                [ -n "$scheme" ] && echo "  - $scheme"
            done
        else
            echo "   未检测到可用的 Scheme"
            exit 1
        fi
        
        echo
        
        # 获取可用的代码签名证书
        echo "📋 检测到的可用代码签名证书:"
        AVAILABLE_IDENTITIES=$(security find-identity -v -p codesigning | grep -E "(Developer ID Application|Apple Development|iPhone Developer|Mac Developer)" | head -5)
        
        if [ -n "$AVAILABLE_IDENTITIES" ]; then
            echo "$AVAILABLE_IDENTITIES" | while IFS= read -r line; do
                # 提取证书名称
                CERT_NAME=$(echo "$line" | sed 's/.*"\(.*\)"/\1/')
                # 根据证书类型添加说明
                if [[ "$CERT_NAME" == *"Developer ID Application"* ]]; then
                    echo "  - $CERT_NAME [分发证书 - 可公开分发]"
                elif [[ "$CERT_NAME" == *"Apple Development"* ]]; then
                    echo "  - $CERT_NAME [开发证书 - 仅限开发测试]"
                elif [[ "$CERT_NAME" == *"Mac Developer"* ]]; then
                    echo "  - $CERT_NAME [开发证书 - 仅限开发测试]"
                elif [[ "$CERT_NAME" == *"iPhone Developer"* ]]; then
                    echo "  - $CERT_NAME [开发证书 - 仅限开发测试]"
                else
                    echo "  - $CERT_NAME"
                fi
            done
        else
            echo "   未检测到可用的代码签名证书"
        fi
        
        echo
        echo "💡 建议使用以下命令进行代码签名:"
        echo
        
        # 生成所有可能的组合建议
        if [ -n "$AVAILABLE_SCHEMES" ] && [ -n "$AVAILABLE_IDENTITIES" ]; then
            # 将schemes转换为数组避免重复处理
            SCHEMES_ARRAY=()
            while IFS= read -r scheme; do
                [ -n "$scheme" ] && SCHEMES_ARRAY+=("$scheme")
            done <<< "$AVAILABLE_SCHEMES"
            
            # 将identities转换为数组避免重复处理
            IDENTITIES_ARRAY=()
            while IFS= read -r line; do
                CERT_NAME=$(echo "$line" | sed 's/.*"\(.*\)"/\1/')
                [ -n "$CERT_NAME" ] && IDENTITIES_ARRAY+=("$CERT_NAME")
            done <<< "$AVAILABLE_IDENTITIES"
            
            # 生成所有组合
            for scheme in "${SCHEMES_ARRAY[@]}"; do
                for identity in "${IDENTITIES_ARRAY[@]}"; do
                    echo " SCHEME='$scheme' SIGNING_IDENTITY='$identity' ./scripts/codesign-app.sh"
                done
                echo
            done
        elif [ -n "$AVAILABLE_SCHEMES" ]; then
            echo "$AVAILABLE_SCHEMES" | while read -r scheme; do
                if [ -n "$scheme" ]; then
                    echo " SCHEME='$scheme' SIGNING_IDENTITY='YOUR_SIGNING_IDENTITY' ./scripts/codesign-app.sh"
                fi
            done
            echo
            echo "注意: 请将 YOUR_SIGNING_IDENTITY 替换为您的实际代码签名身份"
        fi
        
        echo "📋 证书类型说明:"
        echo "   🟢 Developer ID Application: 用于 Mac App Store 外分发，可被所有用户安装"
        echo "   🟡 Apple Development: 用于开发测试，仅限开发团队内部使用"
        echo "   🔴 Mac App Store: 用于 App Store 上架（需单独申请）"
        echo
        exit 1
    fi
}

# 自动检测和检查必需的环境变量
check_and_suggest

# 设置默认值
BuildPath=${BuildPath:-"./temp"}
VERBOSE=${VERBOSE:-"false"}



# 显示关键环境信息
printf "${BLUE}===========================================${NC}\n"
printf "${BLUE}         🔐 代码签名脚本启动              ${NC}\n"
printf "${BLUE}===========================================${NC}\n"
echo

# 关键环境信息
printf "${GREEN}📋 关键环境信息:${NC}\n"
echo "   应用方案: ${SCHEME}"
echo "   构建路径: ${BuildPath}"
echo "   签名身份: ${SIGNING_IDENTITY}"
echo "   详细日志: ${VERBOSE}"
echo "   工作目录: $(pwd)"
echo "   当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# 设置应用路径
APP_PATH="$BuildPath/Build/Products/Release/$SCHEME.app"

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    print_error "应用程序不存在: $APP_PATH"
    echo
    
    # 自动搜索可能的应用程序目录
    printf "${GREEN}🔍 搜索可能的应用程序位置...${NC}\n"
    
    # 搜索可能的路径
    possible_paths=(
        "./temp/Build/Products/Debug/$SCHEME.app"
        "./temp/Build/Products/Release/$SCHEME.app"
        "./temp/arm64/Build/Products/Release/$SCHEME.app"
        "./temp/arm64/Build/Products/Debug/$SCHEME.app"
        "./temp/x86_64/Build/Products/Release/$SCHEME.app"
        "./temp/x86_64/Build/Products/Debug/$SCHEME.app"
        "./temp/universal/Build/Products/Release/$SCHEME.app"
        "./temp/universal/Build/Products/Debug/$SCHEME.app"
        "./Build/Products/Release/$SCHEME.app"
        "./Build/Products/Debug/$SCHEME.app"
        "./build/Release/$SCHEME.app"
        "./build/Debug/$SCHEME.app"
        "./DerivedData/Build/Products/Release/$SCHEME.app"
        "./DerivedData/Build/Products/Debug/$SCHEME.app"
    )
    
    found_apps=()
    
    # 检查预定义路径
    for path in "${possible_paths[@]}"; do
        if [ -d "$path" ]; then
            found_apps+=("$path")
        fi
    done
    
    # 使用 find 命令搜索更多可能的位置
    while IFS= read -r -d '' app_path; do
        # 避免重复添加
        already_found=false
        for existing in "${found_apps[@]}"; do
            if [ "$existing" = "$app_path" ]; then
                already_found=true
                break
            fi
        done
        if [ "$already_found" = false ]; then
            found_apps+=("$app_path")
        fi
    done < <(find . -name "$SCHEME.app" -type d -not -path "*/.*" -print0 2>/dev/null | head -20)
    
    if [ ${#found_apps[@]} -gt 0 ]; then
        echo
        printf "${GREEN}📍 发现 ${#found_apps[@]} 个可能的应用程序:${NC}\n"
        for i in "${!found_apps[@]}"; do
            app_path="${found_apps[$i]}"
        app_size="未知"
            if [ -d "$app_path" ]; then
                app_size=$(du -sh "$app_path" 2>/dev/null | cut -f1 || echo "未知")
            fi
            printf "   %d. %s (%s)\n" $((i+1)) "$app_path" "$app_size"
        done
        echo
        printf "${YELLOW}💡 建议使用以下命令进行代码签名:${NC}\n"
        echo
        for i in "${!found_apps[@]}"; do
            app_path="${found_apps[$i]}"
        build_path=$(dirname "$app_path")
            echo " SCHEME='$SCHEME' SIGNING_IDENTITY='$SIGNING_IDENTITY' BuildPath='$build_path' ./scripts/codesign-app.sh"
        done
        echo
    else
        printf "${YELLOW}💡 建议先运行构建脚本: ./scripts/build-app.sh${NC}\n"
    fi
    
    exit 1
fi

# 显示应用程序基本信息
printf "${GREEN}🎯 应用程序基本信息:${NC}\n"
echo "   应用路径: ${APP_PATH}"
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    APP_VERSION=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleShortVersionString | awk -F'"' '{print $4}')
    APP_BUILD=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleVersion | awk -F'"' '{print $4}')
    APP_IDENTIFIER=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleIdentifier | awk -F'"' '{print $4}')
    
    echo "   应用名称: ${SCHEME}"
    echo "   应用版本: ${APP_VERSION}"
    echo "   构建版本: ${APP_BUILD}"
    echo "   Bundle ID: ${APP_IDENTIFIER}"
else
    printf "   ${YELLOW}⚠️  无法读取应用信息${NC}\n"
fi
echo

# 显示开发路线图
show_development_roadmap() {
    local current_step="$1"
    
    echo
    printf "${PURPLE}===========================================${NC}\n"
    printf "${PURPLE}         🗺️  开发分发路线图                ${NC}\n"
    printf "${PURPLE}===========================================${NC}\n"
    echo
    
    # 定义路线图步骤
    local steps=(
        "build:🔨 构建应用:编译源代码，生成可执行文件"
        "codesign:🔐 代码签名:为应用添加数字签名，确保安全性"
        "package:📦 打包分发:创建 DMG 安装包"
        "notarize:✅ 公证验证:Apple 官方验证（可选）"
        "distribute:🚀 发布分发:上传到分发平台或直接分发"
    )
    
    printf "${CYAN}📍 当前位置: "
    case "$current_step" in
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





# 开始代码签名
print_separator
print_title "🔐 macOS 应用代码签名脚本"
print_separator
echo

# 显示详细环境信息
printf "${BLUE}===========================================${NC}\n"
printf "${BLUE}         代码签名环境信息                ${NC}\n"
printf "${BLUE}===========================================${NC}\n"
echo

# 系统信息
printf "${GREEN}📱 系统信息:${NC}\n"
echo "   操作系统: $(uname -s) $(uname -r)"
echo "   系统架构: $(uname -m)"
echo "   主机名称: $(hostname)"
echo "   当前用户: $(whoami)"
echo "   当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

# Xcode 信息
printf "${GREEN}🔨 Xcode 开发环境:${NC}\n"
if command -v xcodebuild &> /dev/null; then
    echo "   Xcode 版本: $(xcodebuild -version | head -n 1)"
    echo "   构建版本: $(xcodebuild -version | tail -n 1)"
    echo "   SDK 路径: $(xcrun --show-sdk-path)"
    echo "   开发者目录: $(xcode-select -p)"
else
    printf "   ${RED}❌ 未找到 Xcode${NC}\n"
    exit 1
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

# 环境变量
printf "${GREEN}🌍 签名环境变量:${NC}\n"
echo "   应用方案: ${SCHEME}"
echo "   构建路径: ${BuildPath}"
echo "   签名身份: ${SIGNING_IDENTITY}"
echo "   详细日志: ${VERBOSE:-'false'}"
echo "   工作目录: $(pwd)"
echo

# 应用程序信息
printf "${GREEN}🎯 应用程序信息:${NC}\n"
echo "   应用路径: ${APP_PATH}"
if [ -f "$APP_PATH/Contents/Info.plist" ]; then
    APP_VERSION=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleShortVersionString | awk -F'"' '{print $4}')
    APP_BUILD=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleVersion | awk -F'"' '{print $4}')
    APP_IDENTIFIER=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleIdentifier | awk -F'"' '{print $4}')
    
    echo "   应用名称: ${SCHEME}"
    echo "   应用版本: ${APP_VERSION}"
    echo "   构建版本: ${APP_BUILD}"
    echo "   Bundle ID: ${APP_IDENTIFIER}"
else
    printf "   ${YELLOW}⚠️  无法读取应用信息${NC}\n"
fi
echo

# 代码签名证书信息
printf "${GREEN}🔑 代码签名证书:${NC}\n"
echo "   当前签名身份: ${SIGNING_IDENTITY}"
echo "   可用证书列表:"
security find-identity -v -p codesigning | head -5 | while IFS= read -r line; do
    if [[ "$line" == *"valid identities found"* ]]; then
        echo "   $line"
    elif [[ "$line" =~ ^[[:space:]]*[0-9]+\) ]]; then
        CERT_NAME=$(echo "$line" | sed 's/.*"\(.*\)"/\1/')
        echo "     - $CERT_NAME"
    fi
done
echo



print_separator
print_title "🔐 开始代码签名过程"
print_separator
echo

# 对 Sparkle 框架组件进行代码签名
print_title "🔧 签名 Sparkle 框架组件"

# Sparkle XPC Services
execute_command "codesign -f -s \"$SIGNING_IDENTITY\" -o runtime \"$APP_PATH/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc\"" "签名 Sparkle Installer XPC"

execute_command "codesign -f -s \"$SIGNING_IDENTITY\" -o runtime --preserve-metadata=entitlements \"$APP_PATH/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc\"" "签名 Sparkle Downloader XPC"

# Sparkle 可执行文件
execute_command "codesign -f -s \"$SIGNING_IDENTITY\" -o runtime \"$APP_PATH/Contents/Frameworks/Sparkle.framework/Versions/B/Autoupdate\"" "签名 Sparkle Autoupdate"

execute_command "codesign -f -s \"$SIGNING_IDENTITY\" -o runtime \"$APP_PATH/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app\"" "签名 Sparkle Updater App"

# Sparkle 框架
execute_command "codesign -f -s \"$SIGNING_IDENTITY\" -o runtime \"$APP_PATH/Contents/Frameworks/Sparkle.framework\"" "签名 Sparkle 框架"

# 对主应用程序进行代码签名
print_title "🎯 签名主应用程序"
execute_command "codesign --force -s \"$SIGNING_IDENTITY\" --option=runtime \"$APP_PATH\"" "签名主应用程序"

# 验证代码签名
print_title "✅ 验证代码签名"
execute_command "codesign -dv \"$APP_PATH\"" "基本签名验证"

print_title "🔍 深度签名验证"
echo -e "${PURPLE}🔧 执行深度签名验证（可能会有警告）${NC}"
if codesign -vvv --deep --strict "$APP_PATH"; then
    print_success "深度签名验证通过"
else
    print_warning "深度签名验证有警告，但这通常是正常的"
fi
echo

# 显示签名信息
print_title "📋 签名信息摘要"
echo "签名详细信息:"
codesign -dvvv "$APP_PATH" 2>&1 | head -20
echo

print_separator
print_success "🎉 代码签名完成！"
print_separator
echo
print_info "应用路径" "$APP_PATH"
print_info "签名身份" "$SIGNING_IDENTITY"
print_info "完成时间" "$(date '+%Y-%m-%d %H:%M:%S')"
echo

# 根据证书类型提供详细说明
printf "${GREEN}📋 证书类型说明:${NC}\n"
if [[ "$SIGNING_IDENTITY" == *"Developer ID Application"* ]]; then
    printf "   ${GREEN}🟢 分发证书 - Developer ID Application${NC}\n"
    printf "   ${GREEN}✅ 用途: 在 Mac App Store 外分发应用${NC}\n"
    printf "   ${GREEN}✅ 优势: 可公开分发，用户可直接下载安装${NC}\n"
    printf "   ${GREEN}✅ 限制: 需要 Apple 开发者账号，需要公证${NC}\n"
    print_success "应用程序已成功签名，可以公开分发！"
elif [[ "$SIGNING_IDENTITY" == *"Apple Development"* ]]; then
    printf "   ${YELLOW}🟡 开发证书 - Apple Development${NC}\n"
    printf "   ${YELLOW}⚠️  用途: 仅限开发和测试${NC}\n"
    printf "   ${YELLOW}⚠️  限制: 只能在开发设备上运行${NC}\n"
    printf "   ${YELLOW}⚠️  注意: 不能公开分发给其他用户${NC}\n"
    print_warning "此应用仅限开发测试，无法公开分发！"
elif [[ "$SIGNING_IDENTITY" == *"3rd Party Mac Developer Application"* ]]; then
    printf "   ${BLUE}🔵 商店证书 - Mac App Store${NC}\n"
    printf "   ${BLUE}📱 用途: 专用于 Mac App Store 分发${NC}\n"
    printf "   ${BLUE}✅ 优势: 通过 App Store 官方渠道分发${NC}\n"
    printf "   ${BLUE}⚠️  限制: 只能通过 App Store 分发${NC}\n"
    print_success "应用程序已成功签名，可提交到 Mac App Store！"
else
    printf "   ${RED}🔴 未知证书类型${NC}\n"
    printf "   ${RED}⚠️  请检查证书类型和用途${NC}\n"
    print_warning "请确认证书类型是否适合您的分发需求！"
fi
echo

# 显示开发路线图
show_development_roadmap "codesign"