import AppKit
import Foundation

/// 打开应用目标的执行器。
///
/// - 常规应用：按 bundle identifier 定位（回退到应用路径），用
///   `NSWorkspace` 以该应用打开项目文件夹；
/// - Remote：读取 git remote 的 web 链接，用默认浏览器打开。
///
/// 复刻旧版各 `*ProjectLauncher` / `OpenRemoteURLProvider` 的逻辑，
/// 在沙盒外环境下可直接访问任意本地目录。
public enum AppLauncher {
    /// 应用是否已安装（Remote 恒为 true）。
    public static func isInstalled(_ target: OpenTarget) -> Bool {
        if target.isAlwaysAvailable { return true }
        return applicationURL(for: target) != nil
    }

    /// 打开项目（后台线程执行，主线程调用 NSWorkspace）。
    public static func open(_ target: OpenTarget, projectURL: URL) {
        Task.detached(priority: .userInitiated) {
            switch target {
            case .remote:
                guard let webURL = remoteWebURL(for: projectURL) else { return }
                await MainActor.run {
                    NSWorkspace.shared.open(webURL)
                }
            default:
                guard let appURL = applicationURL(for: target) else { return }
                await MainActor.run {
                    NSWorkspace.shared.open(
                        [projectURL],
                        withApplicationAt: appURL,
                        configuration: NSWorkspace.OpenConfiguration()
                    )
                }
            }
        }
    }

    // MARK: - App Resolution

    static func applicationURL(for target: OpenTarget) -> URL? {
        let bundleID = target.bundleIdentifier
        if !bundleID.isEmpty,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url
        }
        for path in target.fallbackPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    // MARK: - Remote Web URL

    /// 读取项目 git remote（优先 origin）并转换为浏览器可访问的 HTTPS 链接。
    public static func remoteWebURL(for projectURL: URL) -> URL? {
        guard let remote = gitRemoteURL(for: projectURL) else { return nil }
        return webURL(fromRemote: remote)
    }

    /// 读取 git remote origin URL（git CLI，零依赖）。
    static func gitRemoteURL(for projectURL: URL) -> String? {
        guard FileManager.default.fileExists(atPath: projectURL.appendingPathComponent(".git").path) else {
            return nil
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", projectURL.path, "remote", "get-url", "origin"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 把 git remote URL 转换为 HTTPS web 链接。
    ///
    /// - `git@github.com:user/repo.git` → `https://github.com/user/repo`
    /// - `https://github.com/user/repo.git` → `https://github.com/user/repo`
    /// - `ssh://git@github.com/user/repo.git` → `https://github.com/user/repo`
    static func webURL(fromRemote remote: String) -> URL? {
        var value = remote.trimmingCharacters(in: .whitespacesAndNewlines)

        // scp-like 语法：git@host:path
        if let atIndex = value.firstIndex(of: "@"),
           let colonIndex = value[atIndex...].firstIndex(of: ":") {
            let host = String(value[value.index(after: atIndex)..<colonIndex])
            let path = String(value[value.index(after: colonIndex)...])
            value = "https://\(host)/\(path)"
        } else if value.hasPrefix("ssh://") {
            value = String(value.dropFirst("ssh://".count))
            // 去掉 user@ 前缀
            if let atIndex = value.firstIndex(of: "@") {
                value = String(value[value.index(after: atIndex)...])
            }
            value = "https://\(value)"
        }

        // 去掉 .git 后缀
        if value.hasSuffix(".git") {
            value = String(value.dropLast(4))
        }
        return URL(string: value)
    }
}
