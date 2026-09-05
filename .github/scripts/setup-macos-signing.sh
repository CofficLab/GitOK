#!/bin/bash

set -euo pipefail

# Configure a temporary keychain and App Store Connect API key for CI.
# The app is archived without a provisioning profile and signed afterwards
# with the imported Developer ID Application certificate.

check_required_env() {
    local required_vars=(
        "BUILD_CERTIFICATE_BASE64"
        "BUILD_CERTIFICATE_P12_PASSWORD"
        "APP_STORE_CONNECT_KEY_BASE64"
        "APP_STORE_CONNECT_KEY_ID"
        "APP_STORE_CONNECT_KEY_ISSUER_ID"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            echo "错误: 环境变量 $var 未设置" >&2
            return 1
        fi
    done
}

setup_certificates() {
    local temp_dir="${RUNNER_TEMP:-/tmp}"
    CERTIFICATE_PATH="$temp_dir/build_certificate.p12"
    KEYCHAIN_PATH="$temp_dir/app-signing.keychain-db"
    KEYCHAIN_PASSWORD="temporary_password"

    echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o "$CERTIFICATE_PATH"
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security import "$CERTIFICATE_PATH" \
        -P "$BUILD_CERTIFICATE_P12_PASSWORD" \
        -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
    security set-key-partition-list \
        -S apple-tool:,apple: \
        -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security list-keychain -d user -s "$KEYCHAIN_PATH"

    export KEYCHAIN_PATH
}

setup_appstore_connect() {
    local key_dir="$HOME/private_keys"
    mkdir -p "$key_dir"
    API_KEY_PATH="$key_dir/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"
    echo -n "$APP_STORE_CONNECT_KEY_BASE64" | base64 --decode -o "$API_KEY_PATH"
    export API_KEY_PATH
}

get_certificate_info() {
    local cert_info
    local identity
    cert_info="$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep '^[[:space:]]*1)' | head -n 1 || true)"
    identity="$(echo "$cert_info" | awk -F'"' '{print $2}')"

    if [ -z "$identity" ]; then
        echo "错误: 未找到可用的 codesigning 身份" >&2
        security find-identity -v -p codesigning "$KEYCHAIN_PATH" >&2 || true
        return 1
    fi

    CERT_ID="$identity"
    TEAM_ID="$(echo "$identity" | sed -n 's/.*(\([A-Z0-9]\{10\}\)).*/\1/p')"
    SIGNING_IDENTITY="$identity"

    if [ -z "$TEAM_ID" ]; then
        echo "错误: 无法从签名身份中解析 Team ID: $SIGNING_IDENTITY" >&2
        return 1
    fi

    export CERT_ID TEAM_ID SIGNING_IDENTITY
}

main() {
    check_required_env
    setup_certificates
    setup_appstore_connect
    get_certificate_info

    echo "✅ macOS 代码签名环境设置完成"
    echo "SIGNING_IDENTITY: $SIGNING_IDENTITY"
    echo "TEAM_ID: $TEAM_ID"
    echo "KEYCHAIN_PATH: $KEYCHAIN_PATH"
    echo "API_KEY_PATH: $API_KEY_PATH"
}

main
