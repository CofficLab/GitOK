#!/bin/bash

# ====================================
# macOS 应用签名环境配置脚本
# ====================================
#
# 这个脚本用于配置 macOS 应用的签名环境，使 CI/CD 环境能够像本地开发环境一样
# 进行应用签名和公证。它不涉及具体的构建过程，只负责证书和签名环境的配置。
#
# 功能：
# 1. 配置开发证书和描述文件
# 2. 设置临时钥匙串
# 3. 配置 App Store Connect API
# 4. 提供签名身份信息
#
# 使用方法：
# 1. 设置必要的环境变量：
#    export BUILD_CERTIFICATE_BASE64="..."        # Base64 编码的证书文件
#    export BUILD_CERTIFICATE_P12_PASSWORD="..."  # 证书密码
#    export BUILD_PROVISION_PROFILE_BASE64="..."  # Base64 编码的描述文件
#    export APP_STORE_CONNECT_KEY_BASE64="..."   # Base64 编码的 App Store Connect API 密钥
#    export APP_STORE_CONNECT_KEY_ID="..."       # App Store Connect API 密钥 ID
#    export APP_STORE_CONNECT_KEY_ISSER_ID="..." # App Store Connect API 发行者 ID
#
# 2. 运行脚本：
#    source ./scripts/setup-macos-signing.sh
#
# 注意事项：
# - 需要安装 Xcode 命令行工具
# - 需要有效的 Apple 开发者账号
# - 需要有效的应用签名证书和描述文件
# - 使用 source 命令运行脚本，这样环境变量可以在当前 shell 中使用
#
# 输出：
# - 配置好的签名环境
# - 导出以下环境变量供后续使用：
#   CERT_ID: 证书 ID
#   TEAM_ID: 开发者团队 ID
#   SIGNING_IDENTITY: 签名身份
#   KEYCHAIN_PATH: 临时钥匙串路径
# ====================================

# 检查必要的环境变量
check_required_env() {
    local required_vars=(
        "BUILD_CERTIFICATE_BASE64"
        "BUILD_CERTIFICATE_P12_PASSWORD"
        "BUILD_PROVISION_PROFILE_BASE64"
        "APP_STORE_CONNECT_KEY_BASE64"
        "APP_STORE_CONNECT_KEY_ID"
        "APP_STORE_CONNECT_KEY_ISSER_ID"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "错误: 环境变量 $var 未设置"
            return 1
        fi
    done
}

# 设置证书和配置文件
setup_certificates() {
    echo "正在设置证书和配置文件..."
    
    # 创建临时文件路径
    local temp_dir="${RUNNER_TEMP:-/tmp}"
    CERTIFICATE_PATH="$temp_dir/build_certificate.p12"
    PP_PATH="$temp_dir/build_pp.provisionprofile"
    KEYCHAIN_PATH="$temp_dir/app-signing.keychain-db"
    KEYCHAIN_PASSWORD="temporary_password"

    # 解码证书和配置文件
    echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o "$CERTIFICATE_PATH"
    echo -n "$BUILD_PROVISION_PROFILE_BASE64" | base64 --decode -o "$PP_PATH"

    # 创建临时钥匙串
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

    # 导入证书到钥匙串
    security import "$CERTIFICATE_PATH" -P "$BUILD_CERTIFICATE_P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
    security list-keychain -d user -s "$KEYCHAIN_PATH"

    # 设置描述文件权限
    chmod 644 "$PP_PATH"
    echo "验证描述文件:"
    ls -l "$PP_PATH"

    # 导出环境变量
    export KEYCHAIN_PATH
    export PP_PATH
}

# 设置 App Store Connect API 密钥
setup_appstore_connect() {
    echo "正在设置 App Store Connect API 密钥..."
    mkdir -p ./private_keys
    echo -n "$APP_STORE_CONNECT_KEY_BASE64" | base64 --decode -o "./private_keys/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"
}

# 获取并导出证书信息
get_certificate_info() {
    echo "正在获取证书信息..."
    local cert_info
    cert_info=$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep '^[[:space:]]*1)' | head -n 1)
    
    # 导出环境变量
    export CERT_ID=$(echo "$cert_info" | awk -F'"' '{print $2}')
    export TEAM_ID=$(echo "$cert_info" | grep -o '[A-Z0-9]\{10\}' | tail -n 1)
    export SIGNING_IDENTITY=$(echo "$cert_info" | awk -F'[(|)]' '{print $3}')

    echo "证书信息："
    echo "CERT_ID: $CERT_ID"
    echo "TEAM_ID: $TEAM_ID"
    echo "SIGNING_IDENTITY: $SIGNING_IDENTITY"
}

# 清理函数
cleanup() {
    if [ -f "$CERTIFICATE_PATH" ]; then
        rm "$CERTIFICATE_PATH"
    fi
    if [ -f "$PP_PATH" ]; then
        rm "$PP_PATH"
    fi
}

# 主函数
main() {
    # 设置错误处理
    set -e
    trap cleanup EXIT

    if ! check_required_env; then
        return 1
    fi

    setup_certificates
    setup_appstore_connect
    get_certificate_info
    
    echo "签名环境配置完成！"
    echo "可以使用以下环境变量进行签名操作："
    echo "CERT_ID: $CERT_ID"
    echo "TEAM_ID: $TEAM_ID"
    echo "SIGNING_IDENTITY: $SIGNING_IDENTITY"
    echo "KEYCHAIN_PATH: $KEYCHAIN_PATH"
    echo "PP_PATH: $PP_PATH"
}

# 执行主函数
main 