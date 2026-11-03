import Foundation

/// 生成 `gitok` CLI 脚本的内容。
///
/// 脚本本身不依赖 App bundle 里的任何资源：它只负责把目标目录编码进
/// `gitok://open?path=...` 并交给 macOS Launch Services，由 GitOK 完成
/// 「加入项目列表 + 切换当前项目」。
///
/// App 路径通过 `GITOK_APP` 环境变量或默认安装位置解析，因此在 App
/// 升级、迁移到别的目录后仍然可用。
public enum CLIScriptBuilder {
    /// CLI 命令名。
    public static let commandName = "gitok"

    /// URL scheme。
    public static let urlScheme = "gitok"

    /// 生成脚本内容。
    ///
    /// - Parameters:
    ///   - commandName: 命令名（默认 `gitok`）。
    ///   - urlScheme: URL scheme（默认 `gitok`）。
    /// - Returns: 可直接写入磁盘的 shell 脚本内容（以换行结尾）。
    public static func scriptContents(
        commandName: String = commandName,
        urlScheme: String = urlScheme
    ) -> String {
        """
        #!/bin/sh
        #
        # \(commandName) — 在 GitOK 中打开当前目录（或指定目录）并加入项目列表。
        #
        # 用法：
        #   \(commandName)            # 打开当前工作目录
        #   \(commandName) .          # 打开当前工作目录
        #   \(commandName) <path>     # 打开指定目录
        #
        # 由 GitOK.app 的「设置 → 通用 → 命令行工具」自动安装。
        # 本脚本不依赖 App bundle 内的任何文件。

        set -eu

        # --- 定位 GitOK.app -------------------------------------------------------
        # 规则：
        # - 设置了 GITOK_APP 时**只**用它（显式覆盖，便于多版本共存）；
        # - 否则依次尝试常见安装位置。
        find_gitok_app() {
            if [ -n "${GITOK_APP:-}" ]; then
                if [ -d "${GITOK_APP}" ]; then
                    printf '%s' "${GITOK_APP}"
                    return 0
                fi
                return 1
            fi
            for candidate in \\
                "/Applications/GitOK.app" \\
                "$HOME/Applications/GitOK.app"
            do
                if [ -d "$candidate" ]; then
                    printf '%s' "$candidate"
                    return 0
                fi
            done
            return 1
        }

        APP_PATH="$(find_gitok_app || true)"
        if [ -z "$APP_PATH" ]; then
            echo "\(commandName): 未找到 GitOK.app，请先安装 GitOK 或设置 GITOK_APP 环境变量。" >&2
            exit 1
        fi

        # --- 解析目标目录 ---------------------------------------------------------
        TARGET="${1:-.}"

        # 展开 ~ 并转成绝对路径。
        case "$TARGET" in
            "~") TARGET="$HOME" ;;
            "~/"*) TARGET="$HOME/${TARGET#\\~/}" ;;
        esac

        if [ ! -e "$TARGET" ]; then
            echo "\(commandName): 路径不存在：$TARGET" >&2
            exit 1
        fi

        ABS_TARGET="$(cd "$TARGET" 2>/dev/null && pwd -P || printf '%s' "$TARGET")"

        # --- 编码为 URL -----------------------------------------------------------
        # 手工百分号编码，保证路径中的空格、#、&、中文等字符都能安全通过
        # query 传递。
        urlencode() {
            printf '%s' "$1" | /usr/bin/perl -MURI::Escape -ne 'chomp; print uri_escape($_, "^A-Za-z0-9\\\\-._~")'
        }

        ENCODED_PATH="$(urlencode "$ABS_TARGET")"
        TARGET_URL="\(urlScheme)://open?path=${ENCODED_PATH}"

        # --- 交给 Launch Services 打开 -------------------------------------------
        # -g 后台启动，不打断当前终端。
        #
        # 路由方式：
        # - 设置了 GITOK_APP 时用 `-a` 显式指定 App（显式覆盖场景）；
        # - 否则依赖 URL scheme 路由。`\(urlScheme)://` 只有 GitOK 注册，
        #   Launch Services 会把请求交给注册了该 scheme 的 GitOK 实例
        #   （已在运行时直接复用现有进程，不会重复启动）。
        if [ -n "${GITOK_APP:-}" ]; then
            OPEN_ARGS="-a ${APP_PATH}"
        else
            OPEN_ARGS=""
        fi

        # shellcheck disable=SC2086 -- OPEN_ARGS 需要按空格拆分成多个参数。
        if ! /usr/bin/open -g ${OPEN_ARGS} "${TARGET_URL}"; then
            echo "\(commandName): 无法打开 GitOK（${TARGET_URL}）" >&2
            exit 1
        fi

        exit 0

        """
    }
}
