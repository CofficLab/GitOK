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

# 引入公共输出库
source "$(dirname "$0")/common-output.sh"

# 显示开发环境信息
print_development_environment

print_title_box "开始版本号更新流程"

# 读取配置文件路径
projectFile=$(find $(pwd) -maxdepth 2 ! -path "*Resources*" ! -path "*temp*" -type f -name "*.pbxproj" | head -n 1)

if [ -z "$projectFile" ]; then
  print_error "未找到 .pbxproj 配置文件！"
  exit 1
fi

echo "🔍 配置文件路径: $projectFile"

# 读取文件中的版本号
version=$(grep -o "MARKETING_VERSION = [^\"']*" "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')

if [ -z "$version" ]; then
  print_error "未找到 MARKETING_VERSION！"
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

print_success "更新后的版本号: $updatedVersion"