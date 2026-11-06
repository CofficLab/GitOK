import Foundation

/// CLI 安装结果。
public enum CLIInstallOutcome: Equatable, Sendable {
    /// 安装成功。
    case installed(target: CLIInstallTarget)
    /// 安装成功，但目标目录不在 `PATH` 中，需要用户自行加入 PATH。
    case installedButNotOnPath(target: CLIInstallTarget)
    /// 目标目录不可写，安装失败。
    case failed(reason: String)
}

/// CLI 当前安装状态。
public struct CLIInstallationStatus: Equatable, Sendable {
    /// 已安装脚本的路径；未安装时为 `nil`。
    public let installedPath: URL?
    /// 安装目录是否在 `PATH` 中。
    public let isOnPath: Bool
    /// 建议的安装目录（未安装时用于告诉用户会装到哪里）。
    public let suggestedTarget: CLIInstallTarget?

    public init(
        installedPath: URL?,
        isOnPath: Bool,
        suggestedTarget: CLIInstallTarget?
    ) {
        self.installedPath = installedPath
        self.isOnPath = isOnPath
        self.suggestedTarget = suggestedTarget
    }

    /// 是否已安装。
    public var isInstalled: Bool { installedPath != nil }
}

/// `gitok` 命令行工具的安装器。
///
/// 只写用户可写目录，**不需要管理员权限**，也不会改动用户的 shell 配置。
public enum CLIInstaller {
    /// 查找已安装的脚本。
    ///
    /// 按候选目录顺序查找，找到第一个存在的脚本即返回。
    public static func installedScriptURL(
        commandName: String = CLIScriptBuilder.commandName,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> URL? {
        let candidates = CLIInstallTargetResolver.candidates(
            environment: environment,
            fileManager: fileManager
        )
        for target in candidates {
            let scriptURL = target.scriptURL(for: commandName)
            if fileManager.isExecutableFile(atPath: scriptURL.path) {
                return scriptURL
            }
        }
        return nil
    }

    /// 读取当前安装状态。
    public static func status(
        commandName: String = CLIScriptBuilder.commandName,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> CLIInstallationStatus {
        let installed = installedScriptURL(
            commandName: commandName,
            environment: environment,
            fileManager: fileManager
        )
        let suggested = CLIInstallTargetResolver.bestTarget(
            environment: environment,
            fileManager: fileManager
        )
        guard let installed else {
            return CLIInstallationStatus(
                installedPath: nil,
                isOnPath: false,
                suggestedTarget: suggested
            )
        }
        let directory = installed.deletingLastPathComponent().standardizedFileURL
        let pathEntries = (environment["PATH"] ?? "")
            .split(separator: ":", omittingEmptySubsequences: true)
            .map { URL(fileURLWithPath: String($0)).standardizedFileURL.path }
        return CLIInstallationStatus(
            installedPath: installed,
            isOnPath: pathEntries.contains(directory.path),
            suggestedTarget: suggested
        )
    }

    /// 安装 CLI 脚本。
    ///
    /// - Parameters:
    ///   - commandName: 命令名。
    ///   - target: 安装目录；`nil` 时自动选择最优目录。
    ///   - environment: 环境变量字典。
    ///   - fileManager: 文件管理器。
    /// - Returns: 安装结果。
    @discardableResult
    public static func install(
        commandName: String = CLIScriptBuilder.commandName,
        target: CLIInstallTarget? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default,
        language: CLIScriptLanguage = .current
    ) -> CLIInstallOutcome {
        let resolvedTarget: CLIInstallTarget
        if let target {
            resolvedTarget = target
        } else {
            guard let best = CLIInstallTargetResolver.bestTarget(
                environment: environment,
                fileManager: fileManager
            ) else {
                return .failed(
                    reason: "No writable directory found for the command line tool."
                )
            }
            resolvedTarget = best
        }

        // 显式传入的目标带有不可写标记时直接失败：调用方已经声明该目录
        // 不可用，不应被静默忽略。
        guard resolvedTarget.isWritable else {
            return .failed(
                reason: "Directory is not writable: \(resolvedTarget.directory.path)"
            )
        }

        // 目录不存在时创建（用户级目录 ~/.local/bin 常常还不存在）。
        if !fileManager.fileExists(atPath: resolvedTarget.directory.path) {
            do {
                try fileManager.createDirectory(
                    at: resolvedTarget.directory,
                    withIntermediateDirectories: true
                )
            } catch {
                return .failed(
                    reason: "Failed to create directory: \(error.localizedDescription)"
                )
            }
        }

        // 目录存在但实际不可写时必须失败（例如权限在解析之后被改动）。
        guard fileManager.isWritableFile(atPath: resolvedTarget.directory.path) else {
            return .failed(
                reason: "Directory is not writable: \(resolvedTarget.directory.path)"
            )
        }

        let scriptURL = resolvedTarget.scriptURL(for: commandName)
        let contents = CLIScriptBuilder.scriptContents(
            commandName: commandName,
            language: language
        )
        do {
            try contents.write(to: scriptURL, atomically: true, encoding: .utf8)
            try fileManager.setAttributes(
                [.posixPermissions: NSNumber(value: Int16(0o755))],
                ofItemAtPath: scriptURL.path
            )
        } catch {
            return .failed(
                reason: "Failed to write script: \(error.localizedDescription)"
            )
        }

        return resolvedTarget.isOnPath
            ? .installed(target: resolvedTarget)
            : .installedButNotOnPath(target: resolvedTarget)
    }

    /// 卸载 CLI 脚本。
    ///
    /// - Parameters:
    ///   - commandName: 命令名。
    ///   - environment: 环境变量字典。
    ///   - fileManager: 文件管理器。
    /// - Returns: 是否成功卸载（原本未安装也算成功）。
    @discardableResult
    public static func uninstall(
        commandName: String = CLIScriptBuilder.commandName,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> Bool {
        guard let installed = installedScriptURL(
            commandName: commandName,
            environment: environment,
            fileManager: fileManager
        ) else { return true }
        do {
            try fileManager.removeItem(at: installed)
            return true
        } catch {
            return false
        }
    }
}
