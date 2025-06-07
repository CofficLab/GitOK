#!/bin/bash

# ====================================
# 输出格式公共库
# ====================================
#
# 这个脚本提供了统一的颜色定义和输出格式函数，用于在各个构建脚本中
# 保持一致的输出风格和用户体验。
#
# 功能：
# 1. 统一的颜色定义（RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, NC）
# 2. 标准化的输出函数（成功、错误、警告、信息、标题、分隔线）
# 3. 支持格式化输出和颜色高亮
# 4. 兼容不同终端环境
#
# 使用方法：
# 1. 在其他脚本中引入此库：
#    source "$(dirname "$0")/common-output.sh"
#
# 2. 使用颜色变量：
#    echo -e "${GREEN}成功信息${NC}"
#    printf "${RED}错误信息${NC}\n"
#
# 3. 使用输出函数：
#    print_success "操作成功"
#    print_error "操作失败"
#    print_warning "警告信息"
#    print_info "标签" "值"
#    print_title "标题"
#    print_separator
#
# 注意事项：
# - 颜色变量在不支持颜色的终端中会自动禁用
# - 所有函数都会自动处理换行
# - print_info 函数支持标签-值格式的输出
# - 此脚本不会独立运行，仅作为库文件被其他脚本引用
# ====================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检测终端是否支持颜色
if [ ! -t 1 ] || [ "${NO_COLOR:-}" = "1" ]; then
    # 如果不是终端输出或设置了 NO_COLOR，禁用颜色
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    NC=''
fi

# ====================================
# 输出函数
# ====================================

# 打印成功信息
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 打印错误信息
print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# 打印警告信息
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 打印信息（标签-值格式）
print_info() {
    local label="$1"
    local value="$2"
    if [ -n "$value" ]; then
        printf "${BLUE}ℹ️  %-20s %s${NC}\n" "${label}:" "${value}"
    else
        echo -e "${BLUE}ℹ️  $1${NC}"
    fi
}

# 打印标题
print_title() {
    echo -e "\n${PURPLE}=== $1 ===${NC}"
}

# 打印分隔线
print_separator() {
    echo -e "${BLUE}===========================================${NC}"
}

# 打印带颜色的分隔线（可指定颜色）
print_colored_separator() {
    local color="${1:-$BLUE}"
    echo -e "${color}===========================================${NC}"
}

# 打印居中标题（带分隔线）
print_centered_title() {
    local title="$1"
    local color="${2:-$PURPLE}"
    echo
    print_colored_separator "$color"
    printf "${color}%*s${NC}\n" $(((${#title} + 43) / 2)) "$title"
    print_colored_separator "$color"
    echo
}

# 打印标题框（固定格式的标题输出）
print_title_box() {
    local title="$1"
    local color="${2:-$BLUE}"
    
    printf "${color}===========================================${NC}\n"
    printf "${color}         %-25s${NC}\n" "$title"
    printf "${color}===========================================${NC}\n"
    echo
}

# 显示系统环境信息
print_system_info() {
    printf "${GREEN}📱 系统信息:${NC}\n"
    echo "   操作系统: $(uname -s) $(uname -r)"
    echo "   系统架构: $(uname -m)"
    echo "   主机名称: $(hostname)"
    echo
}

# 显示 Xcode 环境信息
print_xcode_info() {
    local show_details="${1:-false}"
    
    printf "${GREEN}🔨 Xcode 开发环境:${NC}\n"
    if command -v xcodebuild &> /dev/null; then
        echo "   Xcode 版本: $(xcodebuild -version | head -n 1)"
        echo "   构建版本: $(xcodebuild -version | tail -n 1)"
        
        if [[ "$show_details" == "true" ]]; then
            echo "   SDK 路径: $(xcrun --show-sdk-path)"
            echo "   开发者目录: $(xcode-select -p)"
        fi
    else
        print_error "   未找到 Xcode"
        if [[ "$show_details" == "true" ]]; then
            exit 1
        fi
    fi
    echo
}

# 显示 Swift 环境信息
print_swift_info() {
    printf "${GREEN}🚀 Swift 编译器:${NC}\n"
    if command -v swift &> /dev/null; then
        SWIFT_VERSION=$(swift --version 2>/dev/null | grep -o 'Swift version [0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d' ' -f3)
        echo "   Swift 版本: ${SWIFT_VERSION}"
    else
        print_error "   未找到 Swift"
    fi
    echo
}

# 显示 Git 环境信息
print_git_info() {
    printf "${GREEN}📝 Git 版本控制:${NC}\n"
    if command -v git &> /dev/null; then
        echo "   Git 版本: $(git --version)"
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo "   当前分支: $(git branch --show-current)"
            echo "   最新提交: $(git log -1 --pretty=format:'%h - %s (%an, %ar)')"
        fi
    else
        print_error "   未找到 Git"
    fi
    echo
}

# 显示完整的开发环境信息（带固定标题）
print_development_environment() {
    print_title_box "开发环境信息"
    
    print_system_info
    print_xcode_info true
    print_swift_info
    print_git_info
}

# 执行命令并显示结果
execute_command() {
    local cmd="$1"
    local description="${2:-执行命令}"
    
    print_info "${description}: ${cmd}"
    
    if eval "$cmd"; then
        print_success "命令执行成功"
        return 0
    else
        local exit_code=$?
        print_error "命令执行失败 (退出码: $exit_code)"
        return $exit_code
    fi
}

# 打印进度信息
print_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    
    printf "${CYAN}[%d/%d] %s${NC}\n" "$current" "$total" "$description"
}

# 打印键值对列表
print_key_value_list() {
    local title="$1"
    shift
    
    printf "${GREEN}📋 %s:${NC}\n" "$title"
    while [ $# -gt 0 ]; do
        local key="$1"
        local value="$2"
        printf "   %-20s %s\n" "${key}:" "${value}"
        shift 2
    done
    echo
}

# 打印列表项
print_list_item() {
    local item="$1"
    local description="${2:-}"
    
    if [ -n "$description" ]; then
        printf "  - %s (%s)\n" "$item" "$description"
    else
        printf "  - %s\n" "$item"
    fi
}

# 打印带编号的列表项
print_numbered_item() {
    local number="$1"
    local item="$2"
    local description="${3:-}"
    
    if [ -n "$description" ]; then
        printf "  %d. %s (%s)\n" "$number" "$item" "$description"
    else
        printf "  %d. %s\n" "$number" "$item"
    fi
}