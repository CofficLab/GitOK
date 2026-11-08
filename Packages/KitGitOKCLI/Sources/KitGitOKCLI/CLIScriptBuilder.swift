import Foundation

/// 生成 `gitok` CLI 脚本的内容。
///
/// 脚本本身不依赖 App bundle 里的任何资源：它只负责把目标目录编码进
/// `gitok://open?path=...` 并交给 macOS Launch Services，由 GitOK 完成
/// 「加入项目列表 + 切换当前项目」。
///
/// App 路径通过 `GITOK_APP` 环境变量或默认安装位置解析，因此在 App
/// 升级、迁移到别的目录后仍然可用。
///
/// 脚本中的注释与报错信息按生成时的界面语言输出（`CLIScriptLanguage`），
/// 避免在非中文系统上出现中文提示。
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
    ///   - language: 脚本文案使用的语言（默认跟随系统）。
    /// - Returns: 可直接写入磁盘的 shell 脚本内容（以换行结尾）。
    public static func scriptContents(
        commandName: String = commandName,
        urlScheme: String = urlScheme,
        language: CLIScriptLanguage = .current
    ) -> String {
        let text = language.text

        return """
        #!/bin/sh
        #
        # \(commandName) — \(text.summary)
        #
        # \(text.usage):
        #   \(commandName)            # \(text.openCurrentDirectory)
        #   \(commandName) .          # \(text.openCurrentDirectory)
        #   \(commandName) <path>     # \(text.openSpecifiedDirectory)
        #
        # \(text.autoInstalled)
        # \(text.standaloneScript)

        set -eu

        # --- \(text.locateApp) ---------------------------------------------
        # \(text.locateRule):
        # - \(text.envOverrideRule);
        # - \(text.fallbackRule).
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
            echo "\(commandName): \(text.appNotFound)" >&2
            exit 1
        fi

        # --- \(text.resolveDirectory) ---------------------------------------
        TARGET="${1:-.}"

        # \(text.expandTilde)
        case "$TARGET" in
            "~") TARGET="$HOME" ;;
            "~/"*) TARGET="$HOME/${TARGET#\\~/}" ;;
        esac

        if [ ! -e "$TARGET" ]; then
            echo "\(commandName): \(text.pathNotFound)" >&2
            exit 1
        fi

        ABS_TARGET="$(cd "$TARGET" 2>/dev/null && pwd -P || printf '%s' "$TARGET")"

        # --- \(text.encodeURL) ---------------------------------------------
        # \(text.encodeRule)
        urlencode() {
            printf '%s' "$1" | /usr/bin/perl -MURI::Escape -ne 'chomp; print uri_escape($_, "^A-Za-z0-9\\\\-._~")'
        }

        ENCODED_PATH="$(urlencode "$ABS_TARGET")"
        TARGET_URL="\(urlScheme)://open?path=${ENCODED_PATH}"

        # --- \(text.launchServices) -----------------------------------------
        # -g \(text.backgroundLaunch)
        #
        # \(text.routingRule):
        # - \(text.envOverrideRouting);
        # - \(text.urlSchemeRouting)
        #   \(text.urlSchemeNote)
        if [ -n "${GITOK_APP:-}" ]; then
            OPEN_ARGS="-a ${APP_PATH}"
        else
            OPEN_ARGS=""
        fi

        # shellcheck disable=SC2086 -- OPEN_ARGS 需要按空格拆分成多个参数。
        if ! /usr/bin/open -g ${OPEN_ARGS} "${TARGET_URL}"; then
            echo "\(commandName): \(text.openFailed)" >&2
            exit 1
        fi

        exit 0

        """
    }
}

/// CLI 脚本文案使用的语言。
public enum CLIScriptLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    /// 当前生效的语言。
    ///
    /// 依据系统语言偏好选择；简体中文与繁体中文共用脚本文案，
    /// 因此繁体回落到简体文案。
    public static var current: CLIScriptLanguage {
        for preference in Locale.preferredLanguages {
            let identifier = preference.replacingOccurrences(of: "_", with: "-")
            if identifier.hasPrefix("zh-Hant") || identifier.hasPrefix("zh-TW")
                || identifier.hasPrefix("zh-HK") || identifier.hasPrefix("zh-MO") {
                return .traditionalChinese
            }
            if identifier.hasPrefix("zh-Hans") || identifier.hasPrefix("zh-CN")
                || identifier.hasPrefix("zh-SG") || identifier == "zh" {
                return .simplifiedChinese
            }
            if identifier.hasPrefix("en") {
                return .english
            }
        }
        return .english
    }

    /// 与应用内界面语言一致的脚本语言。
    ///
    /// 应用内设置了界面语言覆盖时以覆盖为准，否则跟随系统语言。
    /// 由 `PluginSettingGeneral` 在安装时传入，本类型不直接依赖本地化包，
    /// 以保持 `KitGitOKCLI` 无第三方依赖。
    public static var resolved: CLIScriptLanguage {
        current
    }

    /// 按语言标识解析脚本语言；未知语言回落到英文。
    ///
    /// - Parameter languageCode: 语言标识（如 `zh-Hans`）。
    public static func language(for languageCode: String?) -> CLIScriptLanguage {
        guard let languageCode else { return .current }
        let identifier = languageCode.replacingOccurrences(of: "_", with: "-")
        if identifier.hasPrefix("zh-Hant") || identifier.hasPrefix("zh-TW")
            || identifier.hasPrefix("zh-HK") || identifier.hasPrefix("zh-MO") {
            return .traditionalChinese
        }
        if identifier.hasPrefix("zh-Hans") || identifier.hasPrefix("zh-CN")
            || identifier.hasPrefix("zh-SG") || identifier == "zh" {
            return .simplifiedChinese
        }
        if identifier.hasPrefix("en") {
            return .english
        }
        return .english
    }

    /// 该语言的脚本文案。
    var text: CLIScriptText {
        switch self {
        case .english: .english
        case .simplifiedChinese: .simplifiedChinese
        case .traditionalChinese: .traditionalChinese
        }
    }
}

/// CLI 脚本中的全部文案。
public struct CLIScriptText: Sendable {
    /// 脚本功能简介。
    public var summary: String
    /// 「用法」标签。
    public var usage: String
    /// 打开当前目录的说明。
    public var openCurrentDirectory: String
    /// 打开指定目录的说明。
    public var openSpecifiedDirectory: String
    /// 自动安装来源说明。
    public var autoInstalled: String
    /// 脚本独立性说明。
    public var standaloneScript: String
    /// 定位 App 阶段的标题。
    public var locateApp: String
    /// 定位规则的引导语。
    public var locateRule: String
    /// 环境变量覆盖规则。
    public var envOverrideRule: String
    /// 默认位置回退规则。
    public var fallbackRule: String
    /// 未找到 App 的报错。
    public var appNotFound: String
    /// 解析目录阶段的标题。
    public var resolveDirectory: String
    /// 展开 `~` 的说明。
    public var expandTilde: String
    /// 路径不存在的报错。
    public var pathNotFound: String
    /// 编码阶段标题。
    public var encodeURL: String
    /// 编码规则说明。
    public var encodeRule: String
    /// Launch Services 阶段标题。
    public var launchServices: String
    /// 后台启动说明。
    public var backgroundLaunch: String
    /// 路由规则引导语。
    public var routingRule: String
    /// 环境变量路由说明。
    public var envOverrideRouting: String
    /// URL scheme 路由说明。
    public var urlSchemeRouting: String
    /// URL scheme 路由补充说明。
    public var urlSchemeNote: String
    /// 打开失败的报错。
    public var openFailed: String

    public init(
        summary: String,
        usage: String,
        openCurrentDirectory: String,
        openSpecifiedDirectory: String,
        autoInstalled: String,
        standaloneScript: String,
        locateApp: String,
        locateRule: String,
        envOverrideRule: String,
        fallbackRule: String,
        appNotFound: String,
        resolveDirectory: String,
        expandTilde: String,
        pathNotFound: String,
        encodeURL: String,
        encodeRule: String,
        launchServices: String,
        backgroundLaunch: String,
        routingRule: String,
        envOverrideRouting: String,
        urlSchemeRouting: String,
        urlSchemeNote: String,
        openFailed: String
    ) {
        self.summary = summary
        self.usage = usage
        self.openCurrentDirectory = openCurrentDirectory
        self.openSpecifiedDirectory = openSpecifiedDirectory
        self.autoInstalled = autoInstalled
        self.standaloneScript = standaloneScript
        self.locateApp = locateApp
        self.locateRule = locateRule
        self.envOverrideRule = envOverrideRule
        self.fallbackRule = fallbackRule
        self.appNotFound = appNotFound
        self.resolveDirectory = resolveDirectory
        self.expandTilde = expandTilde
        self.pathNotFound = pathNotFound
        self.encodeURL = encodeURL
        self.encodeRule = encodeRule
        self.launchServices = launchServices
        self.backgroundLaunch = backgroundLaunch
        self.routingRule = routingRule
        self.envOverrideRouting = envOverrideRouting
        self.urlSchemeRouting = urlSchemeRouting
        self.urlSchemeNote = urlSchemeNote
        self.openFailed = openFailed
    }

    /// 英文文案。
    public static let english = CLIScriptText(
        summary: "Open the current directory in GitOK and add it to the project list.",
        usage: "Usage:",
        openCurrentDirectory: "open the current working directory",
        openSpecifiedDirectory: "open the specified directory",
        autoInstalled: "Automatically installed by GitOK.app via Settings > General > Command Line Tool.",
        standaloneScript: "This script does not depend on any file inside the App bundle.",
        locateApp: "Locate GitOK.app",
        locateRule: "Rules:",
        envOverrideRule: "if GITOK_APP is set, use only it (explicit override, allows multiple versions to coexist)",
        fallbackRule: "otherwise try the common installation locations",
        appNotFound: "GitOK.app not found. Install GitOK or set the GITOK_APP environment variable.",
        resolveDirectory: "Resolve the target directory",
        expandTilde: "Expand ~ into an absolute path.",
        pathNotFound: "path does not exist",
        encodeURL: "Encode as URL",
        encodeRule: "Manual percent encoding keeps spaces, #, & and non-ASCII characters safe in the query.",
        launchServices: "Hand over to Launch Services",
        backgroundLaunch: "launches in the background so the current terminal is not interrupted",
        routingRule: "Routing:",
        envOverrideRouting: "if GITOK_APP is set, pass it explicitly with -a (explicit override)",
        urlSchemeRouting: "otherwise rely on URL scheme routing.",
        urlSchemeNote: "Only GitOK registers gitok://, so Launch Services hands the request to the running GitOK instance (no duplicate launch).",
        openFailed: "could not open GitOK"
    )

    /// 简体中文文案。
    public static let simplifiedChinese = CLIScriptText(
        summary: "在 GitOK 中打开当前目录（或指定目录）并加入项目列表。",
        usage: "用法：",
        openCurrentDirectory: "打开当前工作目录",
        openSpecifiedDirectory: "打开指定目录",
        autoInstalled: "由 GitOK.app 的「设置 → 通用 → 命令行工具」自动安装。",
        standaloneScript: "本脚本不依赖 App bundle 内的任何文件。",
        locateApp: "定位 GitOK.app",
        locateRule: "规则：",
        envOverrideRule: "设置了 GITOK_APP 时**只**用它（显式覆盖，便于多版本共存）",
        fallbackRule: "否则依次尝试常见安装位置",
        appNotFound: "未找到 GitOK.app，请先安装 GitOK 或设置 GITOK_APP 环境变量。",
        resolveDirectory: "解析目标目录",
        expandTilde: "展开 ~ 并转成绝对路径。",
        pathNotFound: "路径不存在",
        encodeURL: "编码为 URL",
        encodeRule: "手工百分号编码，保证路径中的空格、#、&、中文等字符都能安全通过 query 传递。",
        launchServices: "交给 Launch Services 打开",
        backgroundLaunch: "后台启动，不打断当前终端",
        routingRule: "路由方式：",
        envOverrideRouting: "设置了 GITOK_APP 时用 -a 显式指定 App（显式覆盖场景）",
        urlSchemeRouting: "否则依赖 URL scheme 路由。",
        urlSchemeNote: "只有 GitOK 注册 gitok://，Launch Services 会把请求交给注册了该 scheme 的 GitOK 实例（已在运行时直接复用现有进程，不会重复启动）。",
        openFailed: "无法打开 GitOK"
    )

    /// 繁体中文文案。
    public static let traditionalChinese = CLIScriptText(
        summary: "在 GitOK 中開啟目前目錄（或指定目錄）並加入專案列表。",
        usage: "用法：",
        openCurrentDirectory: "開啟目前工作目錄",
        openSpecifiedDirectory: "開啟指定目錄",
        autoInstalled: "由 GitOK.app 的「設定 → 一般 → 命令列工具」自動安裝。",
        standaloneScript: "本腳本不依賴 App bundle 內的任何檔案。",
        locateApp: "定位 GitOK.app",
        locateRule: "規則：",
        envOverrideRule: "設定了 GITOK_APP 時**只**用它（明確覆寫，方便多版本共存）",
        fallbackRule: "否則依序嘗試常見安裝位置",
        appNotFound: "找不到 GitOK.app，請先安裝 GitOK 或設定 GITOK_APP 環境變數。",
        resolveDirectory: "解析目標目錄",
        expandTilde: "展開 ~ 並轉成絕對路徑。",
        pathNotFound: "路徑不存在",
        encodeURL: "編碼為 URL",
        encodeRule: "手動百分比編碼，確保路徑中的空格、#、&、中文等字元都能安全通過 query 傳遞。",
        launchServices: "交給 Launch Services 開啟",
        backgroundLaunch: "背景啟動，不打斷目前終端機",
        routingRule: "路由方式：",
        envOverrideRouting: "設定了 GITOK_APP 時用 -a 明確指定 App（明確覆寫場景）",
        urlSchemeRouting: "否則依賴 URL scheme 路由。",
        urlSchemeNote: "只有 GitOK 註冊 gitok://，Launch Services 會把請求交給註冊了該 scheme 的 GitOK 實例（已在執行時直接復用現有程序，不會重複啟動）。",
        openFailed: "無法開啟 GitOK"
    )
}
