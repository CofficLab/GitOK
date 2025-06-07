#!/bin/bash

# ====================================
# 应用程序路径检测公共库
# ====================================
#
# 这个脚本提供了应用程序路径检测的公共功能，用于在各个构建脚本中
# 自动检测和查找可用的应用程序路径，避免重复代码。
#
# 功能：
# 1. 自动检测可能的应用程序路径
# 2. 支持多种构建目录结构（temp、Build、build、DerivedData等）
# 3. 支持多种架构（arm64、x86_64、universal）
# 4. 过滤无效的应用程序（大小为0的应用程序）
# 5. 提供格式化的应用程序列表显示
# 6. 生成构建路径建议
#
# 使用方法：
# 1. 在其他脚本中引入此库：
#    source "$(dirname "$0")/common-app-detection.sh"
#
# 2. 调用检测函数：
#    detect_available_app_paths "YourScheme"
#    # 或者使用环境变量中的 SCHEME
#    detect_available_app_paths
#
# 3. 使用全局变量：
#    AVAILABLE_APP_PATHS: 可用的应用程序路径数组
#
# 4. 显示检测结果：
#    show_detected_apps
#
# 5. 生成构建建议：
#    generate_build_path_suggestions
#
# 注意事项：
# - 需要在调用脚本中定义颜色变量（RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, NC）
# - 注意：此脚本依赖输出函数，请确保已引入 common-output.sh：
# source "$(dirname "$0")/common-output.sh"
# - 此脚本不会独立运行，仅作为库文件被其他脚本引用
# ====================================

# 依赖的外部文件
# source "$(dirname "$0")/common-output.sh"

# 全局变量
AVAILABLE_APP_PATHS=()

# 检测可能的应用程序路径
# 参数：
#   $1: Scheme 名称（可选，默认使用环境变量 SCHEME 或通配符 *）
detect_available_app_paths() {
    local search_scheme="${1:-${SCHEME:-*}}"
    
    if command -v print_info &> /dev/null; then
        printf "${CYAN}📋 检测可能的应用程序路径...${NC}\n"
    else
        echo "📋 检测可能的应用程序路径..."
    fi
    
    # 搜索可能的路径模式
    local possible_paths=(
        "./temp/Build/Products/Debug/${search_scheme}.app"
        "./temp/Build/Products/Release/${search_scheme}.app"
        "./temp/arm64/Build/Products/Release/${search_scheme}.app"
        "./temp/arm64/Build/Products/Debug/${search_scheme}.app"
        "./temp/x86_64/Build/Products/Release/${search_scheme}.app"
        "./temp/x86_64/Build/Products/Debug/${search_scheme}.app"
        "./temp/universal/Build/Products/Release/${search_scheme}.app"
        "./temp/universal/Build/Products/Debug/${search_scheme}.app"
        "./Build/Products/Release/${search_scheme}.app"
        "./Build/Products/Debug/${search_scheme}.app"
        "./build/Release/${search_scheme}.app"
        "./build/Debug/${search_scheme}.app"
        "./DerivedData/Build/Products/Release/${search_scheme}.app"
        "./DerivedData/Build/Products/Debug/${search_scheme}.app"
    )
    
    AVAILABLE_APP_PATHS=()
    
    # 检查预定义路径
    for path in "${possible_paths[@]}"; do
        # 使用通配符展开路径
        for expanded_path in $path; do
            if [ -d "$expanded_path" ]; then
                # 检查应用程序大小，过滤掉大小为0的应用程序
                local app_size_bytes=$(du -s "$expanded_path" 2>/dev/null | /usr/bin/cut -f1 2>/dev/null || echo "0")
                if [ -n "$app_size_bytes" ] && [ "$app_size_bytes" -gt 0 ] 2>/dev/null; then
                    AVAILABLE_APP_PATHS+=("$expanded_path")
                fi
            fi
        done
    done
    
    # 使用 find 命令搜索更多可能的位置
    while IFS= read -r -d '' app_path; do
        local app_size_bytes=$(du -s "$app_path" 2>/dev/null | cut -f1 || echo "0")
        if [ "$app_size_bytes" -gt 0 ]; then
            # 检查是否已经在列表中
            local already_exists=false
            for existing_path in "${AVAILABLE_APP_PATHS[@]}"; do
                if [ "$existing_path" = "$app_path" ]; then
                    already_exists=true
                    break
                fi
            done
            if [ "$already_exists" = false ]; then
                AVAILABLE_APP_PATHS+=("$app_path")
            fi
        fi
    done <<< "$(find . -name "${search_scheme}.app" -type d -not -path "*/.*" 2>/dev/null | tr '\n' '\0')"
}

# 显示检测到的应用程序
show_detected_apps() {
    if [ ${#AVAILABLE_APP_PATHS[@]} -gt 0 ]; then
        if command -v print_info &> /dev/null; then
            print_info "📍 发现" "找到 ${#AVAILABLE_APP_PATHS[@]} 个可能的应用程序:"
        else
            echo "📍 发现: 找到 ${#AVAILABLE_APP_PATHS[@]} 个可能的应用程序:"
        fi
        
        for i in "${!AVAILABLE_APP_PATHS[@]}"; do
            local app_path="${AVAILABLE_APP_PATHS[$i]}"
            local app_size=$(du -sh "$app_path" 2>/dev/null | cut -f1 || echo "未知")
            echo "  $((i+1)). $app_path ($app_size)"
        done
    else
        if command -v print_warning &> /dev/null; then
            print_warning "未找到任何应用程序"
        else
            echo "⚠️  未找到任何应用程序"
        fi
    fi
}

# 生成构建路径建议
# 参数：
#   $1: 脚本名称（用于生成建议命令）
generate_build_path_suggestions() {
    local script_name="${1:-./scripts/build-app.sh}"
    
    if [ ${#AVAILABLE_APP_PATHS[@]} -gt 0 ]; then
        echo
        if command -v print_info &> /dev/null; then
            print_info "💡 建议" "请设置 BuildPath 环境变量指向正确的构建目录，例如:"
        else
            echo "💡 建议: 请设置 BuildPath 环境变量指向正确的构建目录，例如:"
        fi
        echo
        
        for i in "${!AVAILABLE_APP_PATHS[@]}"; do
            local app_path="${AVAILABLE_APP_PATHS[$i]}"
            local build_path=$(dirname "$app_path")
            echo " BuildPath='$build_path' $script_name"
        done
    fi
}

# 查找匹配的应用程序路径
# 参数：
#   $1: Scheme 名称
# 返回：
#   匹配的应用程序路径（如果找到）
find_matching_app_path() {
    local target_scheme="$1"
    
    if [ -z "$target_scheme" ]; then
        return 1
    fi
    
    for app_path in "${AVAILABLE_APP_PATHS[@]}"; do
        if [[ "$app_path" == *"/$target_scheme.app" ]]; then
            echo "$app_path"
            return 0
        fi
    done
    
    return 1
}

# 验证应用程序路径是否有效
# 参数：
#   $1: 应用程序路径
# 返回：
#   0: 有效，1: 无效
validate_app_path() {
    local app_path="$1"
    
    if [ -z "$app_path" ]; then
        return 1
    fi
    
    if [ ! -d "$app_path" ]; then
        return 1
    fi
    
    # 检查是否是有效的 .app 包
    if [[ "$app_path" != *.app ]]; then
        return 1
    fi
    
    # 检查应用程序大小
    local app_size_bytes=$(du -s "$app_path" 2>/dev/null | cut -f1 || echo "0")
    if [ "$app_size_bytes" -eq 0 ]; then
        return 1
    fi
    
    return 0
}

# 获取应用程序信息
# 参数：
#   $1: 应用程序路径
get_app_info() {
    local app_path="$1"
    
    if ! validate_app_path "$app_path"; then
        return 1
    fi
    
    local info_plist="$app_path/Contents/Info.plist"
    
    if [ -f "$info_plist" ]; then
        local app_version=$(plutil -p "$info_plist" 2>/dev/null | grep CFBundleShortVersionString | awk -F'"' '{print $4}' || echo "未知")
        local app_build=$(plutil -p "$info_plist" 2>/dev/null | grep CFBundleVersion | awk -F'"' '{print $4}' || echo "未知")
        local app_identifier=$(plutil -p "$info_plist" 2>/dev/null | grep CFBundleIdentifier | awk -F'"' '{print $4}' || echo "未知")
        local app_size=$(du -sh "$app_path" 2>/dev/null | cut -f1 || echo "未知")
        
        echo "版本: $app_version"
        echo "构建号: $app_build"
        echo "标识符: $app_identifier"
        echo "大小: $app_size"
    else
        echo "无法读取应用程序信息"
    fi
}