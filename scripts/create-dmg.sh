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

# 引入公共库
source "$(dirname "$0")/common-roadmap.sh"
source "$(dirname "$0")/common-scheme.sh"
source "$(dirname "$0")/common-output.sh"
source "$(dirname "$0")/common-app-detection.sh"

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
        # 使用公共库检测项目文件和可用schemes
        detect_project_file
        detect_available_schemes
        
        # 尝试获取第一个可用的scheme
        local first_scheme=$(get_first_scheme)
        if [ -n "$first_scheme" ]; then
            SCHEME="$first_scheme"
            print_info "自动检测到方案" "$SCHEME"
        else
            # 如果仍然没有找到，使用默认值
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
        
        # 使用公共函数检测应用程序路径
        detect_available_app_paths "$SCHEME"
        show_detected_apps
        
        # 生成构建路径建议
        generate_build_path_suggestions "./scripts/create-dmg.sh"
        
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
    local mount_point
    mount_point=$(hdiutil attach "$temp_dmg" -readwrite -noverify -noautoopen | grep -E '^/dev/' | sed 1q | awk '{print $3}')
    
    if [ -z "$mount_point" ]; then
        print_error "无法挂载 DMG"
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