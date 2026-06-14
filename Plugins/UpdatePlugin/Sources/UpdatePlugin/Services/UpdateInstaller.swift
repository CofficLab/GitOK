import Foundation
import OSLog

/// DMG 安装服务
@MainActor
public class UpdateInstaller: ObservableObject {
    nonisolated public static let emoji = "📦"

    @Published public var isInstalling = false
    @Published public var installProgress: String = ""
    @Published public var installError: String?

    public init() {}

    /// 安装更新
    public func installUpdate(dmgURL: URL) async throws {
        isInstalling = true
        installError = nil
        installProgress = ""

        var mountPath: URL?

        do {
            // 1. 挂载 DMG
            installProgress = "挂载安装包..."
            mountPath = try await DMGMounter.mount(dmgURL)
            os_log(.info, "[UpdateInstaller] ✓ DMG mounted")

            let newAppPath = mountPath!.appendingPathComponent("GitOK.app")
            guard FileManager.default.fileExists(atPath: newAppPath.path) else {
                throw UpdateError.installationFailed("安装包中未找到 GitOK.app")
            }

            // 2. 验证 .app 签名（DMG 本身无代码签名）
            installProgress = "验证文件签名..."
            try await SignatureVerifier.verify(newAppPath)
            os_log(.info, "[UpdateInstaller] ✓ Signature verified")

            // 3. 替换应用（需要管理员权限）
            installProgress = "安装新版本..."
            try await replaceAppBundle(mountPath!)
            os_log(.info, "[UpdateInstaller] ✓ App replaced")

            // 4. 清理
            installProgress = "清理临时文件..."
            try await DMGMounter.unmount(mountPath!)
            mountPath = nil
            try FileManager.default.removeItem(at: dmgURL)
            os_log(.info, "[UpdateInstaller] ✓ Temp files cleaned")

            // 5. 重启应用
            installProgress = "重启应用..."
            await AppRestarter.restart()

            isInstalling = false
        } catch {
            if let mountPath {
                try? await DMGMounter.unmount(mountPath)
            }
            installError = error.localizedDescription
            os_log(.error, "[UpdateInstaller] ✗ Installation failed: %{public}s", error.localizedDescription)
            isInstalling = false
            throw error
        }
    }

    /// 替换应用 bundle（需要管理员权限）
    private func replaceAppBundle(_ mountPath: URL) async throws {
        let currentAppPath = Bundle.main.bundleURL
        let newAppPath = mountPath.appendingPathComponent("GitOK.app")

        // 检查新应用是否存在
        guard FileManager.default.fileExists(atPath: newAppPath.path) else {
            throw UpdateError.installationFailed("新应用不存在")
        }

        // 使用 AppleScript 请求管理员权限
        // 1. 清除新应用的 quarantine 属性，避免 Gatekeeper 拦截
        // 2. 删除旧应用并复制新应用
        // 3. 清除目标应用的 quarantine 属性
        // 使用 shell 的 single quote 转义：将路径中的 ' 替换为 '\''
        let escapedNewPath = newAppPath.path.replacingOccurrences(of: "'", with: "'\\''")
        let escapedOldPath = currentAppPath.path.replacingOccurrences(of: "'", with: "'\\''")

        let shellScript = "xattr -cr '\(escapedNewPath)' && rm -rf '\(escapedOldPath)' && cp -R '\(escapedNewPath)' '\(escapedOldPath)' && xattr -cr '\(escapedOldPath)'"
        let script = "do shell script \(shellScript.applescriptQuoted) with administrator privileges"

        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?

        guard appleScript?.executeAndReturnError(&errorInfo) != nil else {
            if let error = errorInfo {
                let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                throw UpdateError.installationFailed(errorMessage)
            }
            throw UpdateError.installationFailed("AppleScript execution failed")
        }
    }
}

// MARK: - String Extension for AppleScript
private extension String {
    /// 将字符串转换为 AppleScript 的双引号格式，转义内部双引号和反斜杠
    var applescriptQuoted: String {
        let escaped = self.replacingOccurrences(of: "\\", with: "\\\\")
                       .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}