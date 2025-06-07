#!/bin/bash

# ====================================
# 通用 iOS/macOS 应用构建脚本
# ====================================
#
# 这个脚本用于构建 iOS/macOS 应用程序，在构建前会显示详细的环境信息，
# 帮助开发者了解当前的构建环境状态，便于调试和问题排查。
#
# 功能：
# 1. 显示系统环境信息（操作系统、架构、主机名等）
# 2. 显示 Xcode 开发环境信息（版本、SDK 路径等）
# 3. 显示 Swift 编译器信息
# 4. 显示 Git 版本控制信息（版本、分支、最新提交等）
# 5. 显示构建环境变量
# 6. 显示构建目标信息（项目、方案、支持的架构等）
# 7. 执行 xcodebuild 构建命令
# 8. 显示构建结果和产物位置
#
# 使用方法：
# 1. 设置必要的环境变量：
#    export SCHEME="YourAppScheme"             # 构建方案名称
#    export BuildPath="/path/to/build"        # 构建输出路径（可选，默认为 ./temp）
#    export ARCH="all"                       # 目标架构（可选，支持 all、universal、x86_64、arm64，默认为所有架构）
#    export VERBOSE="true"                    # 可选：显示详细构建日志
#
# 2. 在项目根目录运行脚本：
#    ./scripts/build-app.sh
#
# 3. 启用详细日志模式：
#    VERBOSE=true ./scripts/build-app.sh
#
# 注意事项：
# - 需要安装 Xcode 和命令行工具
# - 需要在 Xcode 项目根目录下运行
# - 确保 SCHEME 和 BuildPath 环境变量已正确设置
# - 脚本会执行 clean build，会清除之前的构建缓存
# - 脚本会自动检测项目文件（.xcodeproj 或 .xcworkspace）
#
# 输出：
# - 详细的环境信息报告
# - 构建过程的实时输出
# - 构建结果和产物位置
# - 如果构建失败，脚本会以非零状态码退出
# ====================================

# 设置错误处理
set -e

# 引入公共库
source "$(dirname "$0")/common-scheme.sh"
source "$(dirname "$0")/common-output.sh"
source "$(dirname "$0")/common-roadmap.sh"

# ====================================
# 建议生成函数
# ====================================

# 显示构建建议（当 SCHEME 环境变量未设置时使用）
show_build_suggestions() {
    printf "${RED}错误: 未设置 SCHEME 环境变量${NC}\n"
    printf "${YELLOW}正在检查项目中可用的 scheme...${NC}\n"
    
    # 检测项目文件和 Schemes
    if detect_project_file_silent && detect_available_schemes_silent; then
        if [ -n "$AVAILABLE_SCHEMES" ]; then
            printf "${GREEN}在项目 ${PROJECT_FILE} 中找到以下可用的 scheme:${NC}\n"
            
            echo "$AVAILABLE_SCHEMES" | while read -r scheme; do
                if [ -n "$scheme" ]; then
                    printf "   - %s\n" "$scheme"
                fi
            done
            
            echo
            generate_build_suggestions
        else
            echo "   未找到可用的 scheme"
            echo "请设置 SCHEME 环境变量，例如: export SCHEME=\"YourAppScheme\""
        fi
    else
        echo "   未找到 .xcodeproj 或 .xcworkspace 文件"
        echo "请设置 SCHEME 环境变量，例如: export SCHEME=\"YourAppScheme\""
    fi
}

# 生成构建建议命令
generate_build_suggestions() {
    printf "${GREEN}💡 建议使用以下命令进行构建:${NC}\n"
    echo
    
    # 将schemes转换为数组
    local schemes_array=()
    while IFS= read -r scheme; do
        [ -n "$scheme" ] && schemes_array+=("$scheme")
    done <<< "$AVAILABLE_SCHEMES"
    
    # 定义可用的架构选项
    local arch_options=("all" "universal" "x86_64" "arm64")
    local arch_descriptions=(
        "构建所有架构 (x86_64, arm64, universal)"
        "构建通用二进制文件 (x86_64 + arm64)"
        "仅构建 Intel 架构 (x86_64)"
        "仅构建 Apple Silicon 架构 (arm64)"
    )
    
    # 定义可用的构建路径选项
    local build_paths=("./temp" "./build" "./Build")
    
    local command_count=0
    
    # 为每个 scheme 生成建议
    for scheme in "${schemes_array[@]}"; do
        printf "${CYAN}📦 Scheme: ${scheme}${NC}\n"
        
        # 生成基本构建命令（使用默认设置）
        echo " SCHEME='$scheme' ./scripts/build-app.sh"
        command_count=$((command_count + 1))
        
        # 生成不同架构的构建命令
        for i in "${!arch_options[@]}"; do
            local arch="${arch_options[$i]}"
            echo " SCHEME='$scheme' ARCH='$arch' ./scripts/build-app.sh"
            command_count=$((command_count + 1))
        done
        
        # 生成自定义构建路径的命令
        for build_path in "${build_paths[@]}"; do
            if [ "$build_path" != "./temp" ]; then  # 跳过默认路径
                echo " SCHEME='$scheme' BuildPath='$build_path' ./scripts/build-app.sh"
                command_count=$((command_count + 1))
            fi
        done
        
        # 生成详细日志命令
        echo " SCHEME='$scheme' VERBOSE='true' ./scripts/build-app.sh"
        command_count=$((command_count + 1))
        
        # 生成完整配置命令示例
        echo " SCHEME='$scheme' ARCH='universal' BuildPath='./build' VERBOSE='true' ./scripts/build-app.sh"
        command_count=$((command_count + 1))
        
        echo
    done
    
    printf "${GREEN}📊 总共生成了 ${command_count} 个命令建议 (${#schemes_array[@]} 个 Scheme)${NC}\n"
    echo
    
    printf "${GREEN}📋 参数说明:${NC}\n"
    echo "   🎯 SCHEME: 构建方案名称（必需）"
    echo "   🏗️  ARCH: 目标架构 (all|universal|x86_64|arm64，默认: all)"
    echo "   📁 BuildPath: 构建输出路径（默认: ./temp）"
    echo "   📝 VERBOSE: 显示详细日志 (true|false，默认: false)"
    echo
    
    printf "${GREEN}🏗️  架构说明:${NC}\n"
    echo "   🔄 all: 分别构建所有架构 (x86_64, arm64, universal)"
    echo "   🔗 universal: 构建通用二进制文件，兼容 Intel 和 Apple Silicon"
    echo "   💻 x86_64: 仅构建 Intel Mac 架构"
    echo "   🍎 arm64: 仅构建 Apple Silicon 架构"
    echo
}

# 检查必需的环境变量
if [ -z "$SCHEME" ]; then
    show_build_suggestions
    exit 1
fi

# 设置默认构建路径
if [ -z "$BuildPath" ]; then
    BuildPath="./temp"
fi

# 设置默认架构（默认构建所有可能的架构）
if [ -z "$ARCH" ]; then
    ARCH="all"
fi

# 定义构建架构函数
build_for_arch() {
    local arch="$1"
    local build_path="$2"
    local destination="$3"
    local archs="$4"
    
    printf "${YELLOW}正在构建架构: ${arch}...${NC}\n"
    
    # 构建通用的 xcodebuild 参数
    BASE_ARGS="-scheme \"${SCHEME}\" -configuration Release -derivedDataPath \"${build_path}\""
    if [ "${PROJECT_TYPE}" = "workspace" ]; then
        BASE_ARGS="-workspace \"${PROJECT_FILE}\" ${BASE_ARGS}"
    else
        BASE_ARGS="-project \"${PROJECT_FILE}\" ${BASE_ARGS}"
    fi
    
    # 添加目标和架构参数
    BUILD_ARGS="${BASE_ARGS} -destination \"${destination}\""
    if [ -n "$archs" ]; then
        BUILD_ARGS="${BUILD_ARGS} ARCHS=\"${archs}\" ONLY_ACTIVE_ARCH=NO"
    fi
    
    # 添加静默参数
    if [ "${VERBOSE}" != "true" ]; then
        BUILD_ARGS="${BUILD_ARGS} -quiet"
    fi
    
    # 执行构建命令
    printf "${YELLOW}正在清理之前的构建...${NC}\n"
    eval "xcodebuild ${BUILD_ARGS} clean"
    
    printf "${YELLOW}开始构建应用...${NC}\n"
    eval "xcodebuild ${BUILD_ARGS} build"
    
    # 检查构建结果
    if [ $? -eq 0 ]; then
        print_success "${arch} 架构构建成功！"
        printf "${GREEN}📦 构建产物位置: ${build_path}/Build/Products/Release/${NC}\n"
        echo
    else
        print_error "${arch} 架构构建失败！"
        return 1
    fi
}

# 根据架构设置构建目标和路径
case "$ARCH" in
    "x86_64")
        DESTINATION="platform=macOS,arch=x86_64"
        BuildPath="${BuildPath}/x86_64"
        ;;
    "arm64")
        DESTINATION="platform=macOS,arch=arm64"
        BuildPath="${BuildPath}/arm64"
        ;;
    "universal")
        DESTINATION="platform=macOS"
        ARCHS="x86_64 arm64"
        BuildPath="${BuildPath}/universal"
        ;;
    "all")
        # 构建所有架构
        BUILD_ALL=true
        ;;
    *)
        printf "${RED}错误: 不支持的架构 '$ARCH'。支持的架构: all, universal, x86_64, arm64${NC}\n"
        exit 1
        ;;
esac

# 显示开发环境信息
print_development_environment

# 环境变量
printf "${GREEN}🌍 构建环境变量:${NC}\n"
echo "   构建方案: ${SCHEME}"
echo "   构建路径: ${BuildPath}"
echo "   目标架构: ${ARCH}"
echo "   构建目标: ${DESTINATION}"
if [ -n "$ARCHS" ]; then
    echo "   支持架构: ${ARCHS}"
fi
echo "   构建配置: Release"
echo "   详细日志: ${VERBOSE:-'false'}"
echo "   工作目录: $(pwd)"
echo

# 构建目标信息
printf "${GREEN}🎯 构建目标信息:${NC}\n"

# 自动检测项目文件
PROJECT_FILE=""
if [ -n "$(find . -maxdepth 1 -name '*.xcworkspace' -type d)" ]; then
    PROJECT_FILE=$(find . -maxdepth 1 -name '*.xcworkspace' -type d | head -n 1)
    PROJECT_TYPE="workspace"
    echo "   项目文件: ${PROJECT_FILE}"
    echo "   项目类型: Xcode Workspace"
elif [ -n "$(find . -maxdepth 1 -name '*.xcodeproj' -type d)" ]; then
    PROJECT_FILE=$(find . -maxdepth 1 -name '*.xcodeproj' -type d | head -n 1)
    PROJECT_TYPE="project"
    echo "   项目文件: ${PROJECT_FILE}"
    echo "   项目类型: Xcode Project"
else
    print_error "   未找到 .xcodeproj 或 .xcworkspace 文件"
    exit 1
fi

echo "   构建方案: ${SCHEME}"

# 显示支持的架构
if [ "${PROJECT_TYPE}" = "workspace" ]; then
    PROJECT_ARCHS=$(xcodebuild -workspace "${PROJECT_FILE}" -scheme "${SCHEME}" -showBuildSettings -configuration Release 2>/dev/null | grep 'ARCHS =' | head -n 1 | cut -d'=' -f2 | xargs || echo '无法确定')
else
    PROJECT_ARCHS=$(xcodebuild -project "${PROJECT_FILE}" -scheme "${SCHEME}" -showBuildSettings -configuration Release 2>/dev/null | grep 'ARCHS =' | head -n 1 | cut -d'=' -f2 | xargs || echo '无法确定')
fi
echo "   项目支持架构: ${PROJECT_ARCHS}"
if [ -n "$ARCHS" ]; then
    echo "   构建目标架构: ${ARCHS}"
else
    echo "   构建目标架构: ${ARCH}"
fi
echo

print_title_box "🚀 开始构建过程..." "$YELLOW"

# 开始构建
printf "${GREEN}正在构建应用(VERBOSE=${VERBOSE:-false})...${NC}\n"
echo

# 根据架构类型执行构建
if [ "$BUILD_ALL" = "true" ]; then
    # 构建所有架构
    printf "${CYAN}🏗️  构建所有架构: x86_64, arm64, universal${NC}\n"
    echo
    
    # 构建 x86_64
    build_for_arch "x86_64" "${BuildPath}/x86_64" "platform=macOS,arch=x86_64" ""
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 构建 arm64
    build_for_arch "arm64" "${BuildPath}/arm64" "platform=macOS,arch=arm64" ""
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 构建 universal
    build_for_arch "universal" "${BuildPath}/universal" "platform=macOS" "x86_64 arm64"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    print_success "所有架构构建完成！"
    printf "${GREEN}📦 构建产物位置:${NC}\n"
    printf "   x86_64: ${BuildPath}/x86_64/Build/Products/Release/\n"
    printf "   arm64: ${BuildPath}/arm64/Build/Products/Release/\n"
    printf "   universal: ${BuildPath}/universal/Build/Products/Release/\n"
else
    # 构建单一架构
    build_for_arch "$ARCH" "$BuildPath" "$DESTINATION" "$ARCHS"
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

# 显示开发路线图
show_development_roadmap "build"