import Foundation
import KitGitOKCLI
import KitGitOKLocalization
import LumiLoggingKit
import os

/// 「命令行工具」分组的视图模型。
///
/// 负责查询 CLI 安装状态、执行安装与卸载，并把结果转成可直接展示的
/// 状态描述。视图层只依赖本类型，不直接调用 `CLIInstaller`。
@MainActor
final class CLIInstallViewModel: ObservableObject {
    nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok.plugin.setting-general",
        category: "CLIInstall"
    )

    /// 是否输出详细日志。
    nonisolated static let verbose = false

    /// 安装状态描述。
    enum Status: Equatable {
        /// 未安装。
        case notInstalled
        /// 已安装，且目标目录在 `PATH` 中。
        case installed(path: String)
        /// 已安装，但目标目录不在 `PATH` 中。
        case installedNotOnPath(path: String, directory: String)

        /// 是否已安装。
        var isInstalled: Bool {
            switch self {
            case .notInstalled: false
            case .installed, .installedNotOnPath: true
            }
        }
    }

    /// 当前状态。
    @Published private(set) var status: Status = .notInstalled

    /// 最近一次操作的错误描述；`nil` 表示没有错误。
    @Published private(set) var lastError: String?

    /// 安装器接口，便于测试注入替身。
    private let installer: CLIInstalling

    init(installer: CLIInstalling = LiveCLIInstaller()) {
        self.installer = installer
        refresh()
    }

    /// 重新读取安装状态。
    func refresh() {
        let installation = installer.status()
        if let installedPath = installation.installedPath {
            let path = installedPath.path
            if installation.isOnPath {
                status = .installed(path: path)
            } else {
                let directory = installedPath
                    .deletingLastPathComponent()
                    .standardizedFileURL
                    .path
                status = .installedNotOnPath(path: path, directory: directory)
            }
        } else {
            status = .notInstalled
        }
    }

    /// 执行安装。
    ///
    /// 安装到**已在 `PATH` 中且可写**的目录；找不到时回落到 `~/.local/bin`
    /// 并在状态里提示用户自行加入 `PATH`。
    func install() {
        lastError = nil
        switch installer.install() {
        case .installed:
            if Self.verbose {
                Self.logger.info("Command line tool installation completed")
            }
            refresh()
        case .installedButNotOnPath(let target):
            if Self.verbose {
                Self.logger.info(
                    "Command line tool installed at \(target.directory.path, privacy: .public), but that directory is not in PATH"
                )
            }
            refresh()
        case .failed(let reason):
            Self.logger.error("Command line tool installation failed: \(reason, privacy: .public)")
            lastError = reason
        }
    }

    /// 执行卸载。
    func uninstall() {
        lastError = nil
        if installer.uninstall() {
            if Self.verbose {
                Self.logger.info("Command line tool uninstalled")
            }
            refresh()
        } else {
            Self.logger.error("Command line tool uninstall failed")
            lastError = "uninstallFailed"
        }
    }
}

/// `CLIInstaller` 的抽象接口，便于测试注入替身。
protocol CLIInstalling: AnyObject {
    func status() -> CLIInstallationStatus
    func install() -> CLIInstallOutcome
    func uninstall() -> Bool
}

/// 走真实文件系统的 `CLIInstaller` 实现。
final class LiveCLIInstaller: CLIInstalling {
    func status() -> CLIInstallationStatus {
        CLIInstaller.status()
    }

    func install() -> CLIInstallOutcome {
        // 脚本文案跟随应用内界面语言，未覆盖时跟随系统语言。
        let language = CLIScriptLanguage.language(
            for: GitOKLanguageOverride.shared.languageCode
        )
        return CLIInstaller.install(language: language)
    }

    func uninstall() -> Bool {
        CLIInstaller.uninstall()
    }
}
