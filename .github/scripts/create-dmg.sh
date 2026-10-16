#!/bin/bash

# =============================================================================
# DMG 创建脚本
# =============================================================================
#
# 功能说明:
#   为 macOS 应用程序创建 DMG 安装包
#   支持自动检测应用程序路径和自定义输出名称
#
# 使用方法:
#   ./scripts/create-dmg.sh [选项]
#
# 环境变量:
#   SCHEME        - 应用程序方案名称 (可选，默认自动检测)
#   BuildPath     - 构建产物路径 (可选，默认: ./temp/Build/Products/Release)
#   OUTPUT_DIR    - DMG 输出目录 (可选，默认: ./temp)
#   DMG_NAME      - DMG 文件名称 (可选，默认: 应用名称)
#   INCLUDE_ARCH  - 是否在文件名中包含架构信息 (可选，默认: true)
#   VERBOSE       - 详细日志输出 (可选，默认: false)
#
# 示例:
#   # 基本使用
#   ./scripts/create-dmg.sh
#
#   # 指定应用方案
#   SCHEME="GitOK" ./scripts/create-dmg.sh
#
#   # 指定构建路径和输出目录
#   BuildPath="./build" OUTPUT_DIR="./dist" ./scripts/create-dmg.sh
#
#   # 启用详细日志
#   VERBOSE=true ./scripts/create-dmg.sh
#
# 注意事项:
#   1. 需要先构建应用程序 (使用 build-app.sh)
#   2. 需要安装 create-dmg 工具 (npm i -g create-dmg)
#   3. 生成的 DMG 文件名会自动替换空格为连字符
#   4. 脚本会自动检测可用的应用程序
#
# 依赖工具:
#   - hdiutil (macOS 原生工具)
#   - create-dmg (npm package, 可选备用方案)
#
# =============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印函数
print_title() {
    echo -e "\n${PURPLE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    local label="$1"
    local value="$2"
    printf "%-20s %s\n" "${label}:" "${value}"
}

print_separator() {
    echo -e "${CYAN}================================================${NC}"
}

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

# 执行命令函数
execute_command() {
    local cmd="$1"
    local desc="$2"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}🔧 执行: $desc${NC}"
        echo -e "${CYAN}命令: $cmd${NC}"
    fi
    
    if eval "$cmd"; then
        if [[ "$VERBOSE" == "true" ]]; then
            print_success "$desc 完成"
        fi
    else
        print_error "$desc 失败"
        exit 1
    fi
}

# 自动检测 SCHEME
detect_scheme() {
    if [ -z "$SCHEME" ]; then
        # Xcode 27 起工程配置迁移为 JSON 格式（project.xcproj），旧格式为 project.pbxproj
        local project_file=""
        if [ -f "GitOK.xcodeproj/project.xcproj" ]; then
            project_file="GitOK.xcodeproj/project.xcproj"
        elif [ -f "GitOK.xcodeproj/project.pbxproj" ]; then
            project_file="GitOK.xcodeproj/project.pbxproj"
        fi

        if [ -n "$project_file" ]; then
            # 从 Xcode 项目文件中提取 scheme
            # JSON 格式的产物路径形如 "<PRODUCTS>/GitOK.app"，需去掉 <PRODUCTS>/ 前缀
            SCHEME=$(grep -o '"[^"]*\.app"' "$project_file" | head -1 | sed 's/\.app"//g; s/"//g; s|<PRODUCTS>/||g')
            if [ -n "$SCHEME" ]; then
                print_info "自动检测到方案" "$SCHEME"
            fi
        fi
        
        # 如果仍然没有找到，使用默认值
        if [ -z "$SCHEME" ]; then
            SCHEME="GitOK"
            print_warning "未找到项目方案，使用默认值: $SCHEME"
        fi
    fi
}

# 检查依赖工具
check_dependencies() {
    print_title "🔍 检查依赖工具"
    
    # 检查 hdiutil (macOS 原生工具)
    if ! command -v hdiutil &> /dev/null; then
        print_error "未找到 hdiutil，请确保在 macOS 系统上运行"
        exit 1
    fi
    print_success "hdiutil: macOS 原生工具"
    
    # 检查 create-dmg (备用方案)
    if command -v create-dmg &> /dev/null; then
        print_success "create-dmg: 已安装 (备用方案)"
        USE_CREATE_DMG=true
    else
        print_info "create-dmg" "未安装，将使用 hdiutil"
        USE_CREATE_DMG=false
    fi
}

# 检测应用架构
detect_architecture() {
    local executable_path="$APP_PATH/Contents/MacOS/$SCHEME"
    
    if [ ! -f "$executable_path" ]; then
        print_warning "未找到可执行文件: $executable_path"
        APP_ARCH="unknown"
        return
    fi
    
    # 使用 lipo 检测架构
    local arch_info
    arch_info=$(lipo -info "$executable_path" 2>/dev/null || echo "")
    
    if [[ "$arch_info" == *"arm64"* ]] && [[ "$arch_info" == *"x86_64"* ]]; then
        APP_ARCH="universal"
    elif [[ "$arch_info" == *"arm64"* ]]; then
        APP_ARCH="arm64"
    elif [[ "$arch_info" == *"x86_64"* ]]; then
        APP_ARCH="x86_64"
    else
        # 备用方法：使用 file 命令
        local file_info
        file_info=$(file "$executable_path" 2>/dev/null || echo "")
        
        if [[ "$file_info" == *"arm64"* ]] && [[ "$file_info" == *"x86_64"* ]]; then
            APP_ARCH="universal"
        elif [[ "$file_info" == *"arm64"* ]]; then
            APP_ARCH="arm64"
        elif [[ "$file_info" == *"x86_64"* ]]; then
            APP_ARCH="x86_64"
        else
            APP_ARCH="unknown"
        fi
    fi
    
    print_info "应用架构" "$APP_ARCH"
}

# 检查应用程序
check_application() {
    print_title "🎯 检查应用程序"
    
    APP_PATH="$BuildPath/$SCHEME.app"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "应用程序不存在: $APP_PATH"
        echo
        
        # 自动搜索可能的应用程序目录
        print_info "🔍 搜索" "正在查找可能的应用程序位置..."
        
        # 搜索可能的路径
        local possible_paths=(
            "./temp/Build/Products/Debug/$SCHEME.app"
            "./Build/Products/Release/$SCHEME.app"
            "./Build/Products/Debug/$SCHEME.app"
            "./build/Release/$SCHEME.app"
            "./build/Debug/$SCHEME.app"
            "./DerivedData/Build/Products/Release/$SCHEME.app"
            "./DerivedData/Build/Products/Debug/$SCHEME.app"
        )
        
        local found_apps=()
        
        # 检查预定义路径
        for path in "${possible_paths[@]}"; do
            if [ -d "$path" ]; then
                found_apps+=("$path")
            fi
        done
        
        # 使用 find 命令搜索更多可能的位置
        while IFS= read -r -d '' app_path; do
            # 避免重复添加
            local already_found=false
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
            print_info "📍 发现" "找到 ${#found_apps[@]} 个可能的应用程序:"
            for i in "${!found_apps[@]}"; do
                local app_path="${found_apps[$i]}"
                local app_size="未知"
                if [ -d "$app_path" ]; then
                    app_size=$(du -sh "$app_path" 2>/dev/null | cut -f1 || echo "未知")
                fi
                printf "   %d. %s (%s)\n" $((i+1)) "$app_path" "$app_size"
            done
            echo
            print_info "💡 建议" "请设置 BuildPath 环境变量指向正确的构建目录，例如："
            echo
            for i in "${!found_apps[@]}"; do
                local app_path="${found_apps[$i]}"
                local build_path=$(dirname "$app_path")
                echo " BuildPath='$build_path' ./scripts/create-dmg.sh"
            done
            echo
        else
            print_info "💡 建议" "请先运行构建脚本: ./scripts/build-app.sh"
        fi
        
        exit 1
    fi
    
    # 显示应用信息
    if [ -f "$APP_PATH/Contents/Info.plist" ]; then
        APP_VERSION=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleShortVersionString | awk -F'"' '{print $4}')
        APP_BUILD=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleVersion | awk -F'"' '{print $4}')
        APP_IDENTIFIER=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleIdentifier | awk -F'"' '{print $4}')
        
        print_info "应用路径" "$APP_PATH"
        print_info "应用版本" "$APP_VERSION"
        print_info "构建版本" "$APP_BUILD"
        print_info "应用标识" "$APP_IDENTIFIER"
    fi
    
    # 检测架构
    detect_architecture
}

# 生成 DMG 文件名
generate_dmg_filename() {
    local base_name="$SCHEME"
    
    # 如果指定了自定义名称，使用自定义名称
    if [ -n "$DMG_NAME" ]; then
        base_name="$DMG_NAME"
    else
        # 默认格式：应用名字+版本+架构
        if [ -n "$APP_VERSION" ]; then
            base_name="${base_name} ${APP_VERSION}"
        fi
    fi
    
    # 添加架构信息（如果启用）
    if [ "${INCLUDE_ARCH:-true}" = "true" ] && [ -n "$APP_ARCH" ] && [ "$APP_ARCH" != "unknown" ]; then
        case "$APP_ARCH" in
            "universal")
                base_name="${base_name}-universal"
                ;;
            "arm64")
                base_name="${base_name}-arm64"
                ;;
            "x86_64")
                base_name="${base_name}-x86_64"
                ;;
        esac
    fi
    
    # 替换空格为连字符
    echo "${base_name// /-}.dmg"
}

# 使用 hdiutil 创建 DMG
create_dmg_with_hdiutil() {
    local final_dmg
    final_dmg=$(generate_dmg_filename)
    
    # 替换空格为连字符
    final_dmg="${final_dmg// /-}"
    
    local temp_dmg="temp-${final_dmg}"
    
    # 创建临时 DMG
    execute_command "hdiutil create -srcfolder \"$APP_PATH\" -volname \"$SCHEME\" -fs HFS+ -fsargs \"-c c=64,a=16,e=16\" -format UDRW -size 200m \"$temp_dmg\"" "创建临时 DMG"
    
    # 挂载 DMG
    local mount_output
    local mount_point
    
    if [[ "$VERBOSE" == "true" ]]; then
        print_info "挂载命令" "hdiutil attach \"$temp_dmg\" -readwrite -noverify -noautoopen"
    fi
    
    mount_output=$(hdiutil attach "$temp_dmg" -readwrite -noverify -noautoopen 2>&1)
    local attach_exit_code=$?
    
    if [[ "$VERBOSE" == "true" ]]; then
        print_info "挂载输出" "$mount_output"
        print_info "退出码" "$attach_exit_code"
    fi
    
    if [ $attach_exit_code -ne 0 ]; then
        print_error "hdiutil attach 命令失败，退出码: $attach_exit_code"
        print_error "错误输出: $mount_output"
        exit 1
    fi
    
    # 尝试多种方式解析挂载点
    mount_point=$(echo "$mount_output" | grep -E '^/dev/' | tail -1 | awk '{print $3}')
    
    # 如果第一种方式失败，尝试其他解析方式
    if [ -z "$mount_point" ]; then
        mount_point=$(echo "$mount_output" | grep -E '/Volumes/' | tail -1 | awk '{print $NF}')
    fi
    
    # 如果仍然失败，尝试直接查找 /Volumes 下的目录
    if [ -z "$mount_point" ]; then
        mount_point="/Volumes/$SCHEME"
        if [ ! -d "$mount_point" ]; then
            mount_point=""
        fi
    fi
    
    if [ -z "$mount_point" ]; then
        print_error "无法解析 DMG 挂载点"
        print_error "hdiutil attach 输出: $mount_output"
        exit 1
    fi
    
    if [ ! -d "$mount_point" ]; then
        print_error "挂载点目录不存在: $mount_point"
        exit 1
    fi
    
    print_success "DMG 已挂载到: $mount_point"
    
    # 创建应用程序快捷方式
    execute_command "ln -s /Applications \"$mount_point/Applications\"" "创建 Applications 快捷方式"
    
    # 卸载 DMG
    execute_command "hdiutil detach \"$mount_point\"" "卸载 DMG"
    
    # 直接压缩为最终文件名
    execute_command "hdiutil convert \"$temp_dmg\" -format UDZO -imagekey zlib-level=9 -o \"$final_dmg\"" "压缩 DMG"
    
    # 删除临时文件
    execute_command "rm -f \"$temp_dmg\"" "清理临时文件"
    
    DMG_FILES[0]="$final_dmg"
    DMG_COUNT=1
}

# 使用 create-dmg 创建 DMG
create_dmg_with_create_dmg() {
    local final_dmg
    final_dmg=$(generate_dmg_filename)
    
    # 替换空格为连字符
    final_dmg="${final_dmg// /-}"
    
    # 使用 --overwrite 参数创建 DMG，避免 "Target already exists" 错误
    execute_command "create-dmg --overwrite \"$APP_PATH\"" "生成 DMG 文件"
        
    
    # 查找生成的 DMG 文件并重命名
    DMG_COUNT=0
    for file in *.dmg; do
        if [ -f "$file" ] && [ "$file" != "$final_dmg" ]; then
            execute_command "mv \"$file\" \"$final_dmg\"" "重命名为最终名称: $final_dmg"
            DMG_FILES[DMG_COUNT]="$final_dmg"
            ((DMG_COUNT++))
            break
        fi
    done
}

# 创建 DMG
create_dmg_file() {
    print_title "📦 创建 DMG 安装包"
    
    # 设置输出目录
    if [ -n "$OUTPUT_DIR" ] && [ "$OUTPUT_DIR" != "." ]; then
        mkdir -p "$OUTPUT_DIR"
        cd "$OUTPUT_DIR"
        APP_PATH="../$APP_PATH"
    fi
    
    # 选择创建方法
    if [ "$USE_CREATE_DMG" = "true" ]; then
        print_info "创建方法" "create-dmg (npm)"
        create_dmg_with_create_dmg
    else
        print_info "创建方法" "hdiutil (原生)"
        create_dmg_with_hdiutil
    fi
    
    if [ $DMG_COUNT -eq 0 ]; then
        print_error "未找到生成的 DMG 文件"
        exit 1
    fi
}

# 显示结果
show_results() {
    print_title "📋 DMG 创建结果"
    
    for dmg_file in "${DMG_FILES[@]}"; do
        if [ -f "$dmg_file" ]; then
            file_size=$(ls -lh "$dmg_file" | awk '{print $5}')
            print_info "$dmg_file" "$file_size"
        fi
    done
    
    echo
    print_success "DMG 安装包创建完成！"
}

# 主函数
main() {
    print_separator
    print_title "🚀 DMG 创建脚本"
    print_separator
    
    # 设置默认值
    BuildPath=${BuildPath:-"./temp/Build/Products/Release"}
    OUTPUT_DIR=${OUTPUT_DIR:-"./temp"}
    INCLUDE_ARCH=${INCLUDE_ARCH:-"true"}
    VERBOSE=${VERBOSE:-"false"}
    
    # 自动检测 SCHEME
    detect_scheme
    
    # 显示配置信息
    print_title "⚙️  配置信息"
    print_info "应用方案" "$SCHEME"
    print_info "构建路径" "$BuildPath"
    print_info "输出目录" "$OUTPUT_DIR"
    print_info "DMG 名称" "${DMG_NAME:-'自动生成'}"
    print_info "包含架构" "$INCLUDE_ARCH"
    print_info "详细日志" "$VERBOSE"
    echo
    
    # 执行步骤
    check_dependencies
    check_application
    create_dmg_file
    show_results
    
    # 显示开发路线图
    show_development_roadmap "package"
}

# 声明数组
declare -a DMG_FILES

# 运行主函数
main "$@"