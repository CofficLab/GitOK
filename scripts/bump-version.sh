#!/bin/bash

# 读取配置文件路径
projectFile=$(find $(pwd) ! -path "*Resources*" -type f -name "*.pbxproj" | head -n 1)

# 读取文件中的版本号
version=$(grep -o 'MARKETING_VERSION = [^"']*' "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')

echo "旧版本号->$version"

# 将版本号拆分为数组
IFS='.' read -r -a versionArray <<< "$version"

# 递增最后一位数字
((versionArray[2]++))

# 重新组合版本号
newVersion="${versionArray[0]}.${versionArray[1]}.${versionArray[2]}"

echo "新版本号->$newVersion"

echo "新版本号将要写入文件->$projectFile"

# 新版本号写入文件
sed -i '' "s/MARKETING_VERSION = $version/MARKETING_VERSION = $newVersion/" "$projectFile"

updatedVersion=$(grep -o 'MARKETING_VERSION = [^"']*' "$projectFile" | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
echo "更新后的版本号->$updatedVersion"

git status 