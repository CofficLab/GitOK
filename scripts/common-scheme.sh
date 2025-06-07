#!/bin/bash

# ====================================
# Scheme 检测公共库
# ====================================
#
# 这个脚本提供了 Xcode 项目 Scheme 检测的公共功能，用于在各个构建脚本中
# 检测和获取可用的 Scheme 列表，避免重复代码。
#
# 功能：
# 1. 自动检测项目文件（.xcworkspace 或 .xcodeproj）
# 2. 获取项目中所有可用的 Scheme 列表
# 3. 提供格式化的 Scheme 显示
# 4. 支持错误处理和用户友好的提示
#
# 使用方法：
# 1. 在其他脚本中引入此库：
#    source "$(dirname "$0")/common-scheme.sh"
#
# 2. 调用检测函数：
#    detect_project_file
#    detect_available_schemes
#
# 3. 使用全局变量：
#    PROJECT_FILE: 项目文件路径
#    PROJECT_TYPE: 项目类型（-workspace 或 -project）
#    AVAILABLE_SCHEMES: 可用的 Scheme 列表（换行分隔）
#
# 注意事项：
# - 需要在调用脚本中定义颜色变量（RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, NC）
# - 注意：此脚本依赖输出函数，请确保已引入 common-output.sh：
# source "$(dirname "$0")/common-output.sh"
# - 此脚本不会独立运行，仅作为库文件被其他脚本引用
# ====================================

# 全局变量
PROJECT_FILE=""
PROJECT_TYPE=""
AVAILABLE_SCHEMES=""

# 检测项目文件
detect_project_file() {
    if ls *.xcworkspace 1> /dev/null 2>&1; then
        PROJECT_FILE=$(ls -d *.xcworkspace | head -1)
        PROJECT_TYPE="-workspace"
        if command -v print_info &> /dev/null; then
            print_info "项目文件" "$PROJECT_FILE (workspace)"
        else
            echo "项目文件: $PROJECT_FILE (workspace)"
        fi
    elif ls *.xcodeproj 1> /dev/null 2>&1; then
        PROJECT_FILE=$(ls -d *.xcodeproj | head -1)
        PROJECT_TYPE="-project"
        if command -v print_info &> /dev/null; then
            print_info "项目文件" "$PROJECT_FILE (project)"
        else
            echo "项目文件: $PROJECT_FILE (project)"
        fi
    else
        if command -v print_error &> /dev/null; then
            print_error "未找到 Xcode 项目文件"
        else
            echo "错误: 未找到 Xcode 项目文件" >&2
        fi
        return 1
    fi
    return 0
}

# 检测可用的 Schemes
detect_available_schemes() {
    if [ -z "$PROJECT_FILE" ] || [ -z "$PROJECT_TYPE" ]; then
        if ! detect_project_file; then
            return 1
        fi
    fi
    
    if command -v printf &> /dev/null && [ -n "${CYAN:-}" ]; then
        printf "${CYAN}📋 检测可用 Scheme...${NC}\n"
    else
        echo "检测可用 Scheme..."
    fi
    
    AVAILABLE_SCHEMES=$(xcodebuild $PROJECT_TYPE "$PROJECT_FILE" -list 2>/dev/null | sed -n '/Schemes:/,/^$/p' | grep -v 'Schemes:' | grep -v '^$' | sed 's/^[[:space:]]*//' | sort -u)
    
    if [ -n "$AVAILABLE_SCHEMES" ]; then
        echo "$AVAILABLE_SCHEMES" | while read -r scheme; do
            [ -n "$scheme" ] && echo "  - $scheme"
        done
    else
        if command -v print_warning &> /dev/null; then
            print_warning "未检测到可用的 Scheme"
        else
            echo "警告: 未检测到可用的 Scheme" >&2
        fi
    fi
    echo
    return 0
}

# 静默检测项目文件（不输出信息）
detect_project_file_silent() {
    if ls *.xcworkspace 1> /dev/null 2>&1; then
        PROJECT_FILE=$(ls -d *.xcworkspace | head -1)
        PROJECT_TYPE="-workspace"
        return 0
    elif ls *.xcodeproj 1> /dev/null 2>&1; then
        PROJECT_FILE=$(ls -d *.xcodeproj | head -1)
        PROJECT_TYPE="-project"
        return 0
    else
        return 1
    fi
}

# 静默检测可用 Schemes（不输出信息）
detect_available_schemes_silent() {
    if [ -z "$PROJECT_FILE" ] || [ -z "$PROJECT_TYPE" ]; then
        return 1
    fi
    
    AVAILABLE_SCHEMES=$(xcodebuild $PROJECT_TYPE "$PROJECT_FILE" -list 2>/dev/null | sed -n '/Schemes:/,/^$/p' | grep -v 'Schemes:' | grep -v '^$' | sed 's/^[[:space:]]*//' | sort -u)
    
    if [ -n "$AVAILABLE_SCHEMES" ]; then
        return 0
    else
        return 1
    fi
}

# 显示 Scheme 建议（当 SCHEME 环境变量未设置时使用）
show_scheme_suggestions() {
    local show_exit_hint="${1:-true}"
    
    if command -v printf &> /dev/null && [ -n "${RED:-}" ]; then
        printf "${RED}错误: 未设置 SCHEME 环境变量${NC}\n"
        printf "${YELLOW}正在检查项目中可用的 scheme...${NC}\n"
    else
        echo "错误: 未设置 SCHEME 环境变量" >&2
        echo "正在检查项目中可用的 scheme..."
    fi
    
    # 检测项目文件和 Schemes（静默模式，避免重复输出）
    if detect_project_file_silent && detect_available_schemes_silent; then
        if [ -n "$AVAILABLE_SCHEMES" ]; then
            if command -v printf &> /dev/null && [ -n "${GREEN:-}" ]; then
                printf "${GREEN}在项目 ${PROJECT_FILE} 中找到以下可用的 scheme:${NC}\n"
            else
                echo "在项目 ${PROJECT_FILE} 中找到以下可用的 scheme:"
            fi
            
            echo "$AVAILABLE_SCHEMES" | while read -r scheme; do
                if [ -n "$scheme" ]; then
                    printf "   - %s\n" "$scheme"
                fi
            done
            
            if command -v printf &> /dev/null && [ -n "${CYAN:-}" ]; then
                printf "\n${CYAN}请选择一个 scheme 并设置环境变量，例如:${NC}\n"
            else
                echo
                echo "请选择一个 scheme 并设置环境变量，例如:"
            fi
            
            FIRST_SCHEME=$(echo "$AVAILABLE_SCHEMES" | head -n 1 | sed 's/^[[:space:]]*//')
            if [ -n "$FIRST_SCHEME" ]; then
                printf "export SCHEME=\"%s\"\n" "$FIRST_SCHEME"
            fi
        else
            echo "   未找到可用的 scheme"
            echo "请设置 SCHEME 环境变量，例如: export SCHEME=\"YourAppScheme\""
        fi
    else
        echo "   未找到 .xcodeproj 或 .xcworkspace 文件"
        echo "请设置 SCHEME 环境变量，例如: export SCHEME=\"YourAppScheme\""
    fi
    
    if [ "$show_exit_hint" = "true" ]; then
        return 1
    fi
    return 0
}

# 获取 Scheme 数量
get_scheme_count() {
    if [ -n "$AVAILABLE_SCHEMES" ]; then
        echo "$AVAILABLE_SCHEMES" | grep -c . || echo "0"
    else
        echo "0"
    fi
}

# 检查指定的 Scheme 是否存在
validate_scheme() {
    local scheme="$1"
    
    if [ -z "$scheme" ]; then
        return 1
    fi
    
    if [ -z "$AVAILABLE_SCHEMES" ]; then
        detect_available_schemes
    fi
    
    if [ -n "$AVAILABLE_SCHEMES" ] && echo "$AVAILABLE_SCHEMES" | grep -q "^$scheme$"; then
        return 0
    else
        return 1
    fi
}

# 获取第一个可用的 Scheme
get_first_scheme() {
    if [ -z "$AVAILABLE_SCHEMES" ]; then
        detect_available_schemes
    fi
    
    if [ -n "$AVAILABLE_SCHEMES" ]; then
        echo "$AVAILABLE_SCHEMES" | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
    fi
}