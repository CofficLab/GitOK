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

        do {
            // 1. 验证签名
            installProgress = "验证文件签名..."
            try await SignatureVerifier.verify(dmgURL)
            os_log(.info, "[UpdateInstaller] ✓ Signature verified")

            // 2. 挂载 DMG
            installProgress = "挂载安装包..."
            let mountPath = try await DMGMounter.mount(dmgURL)
            os_log(.info, "[UpdateInstaller] ✓ DMG mounted")

            // 3. 替换应用（需要管理员权限）
            installProgress = "安装新版本..."
            try await replaceAppBundle(mountPath)
            os_log(.info, "[UpdateInstaller] ✓ App replaced")

            // 4. 清理
            installProgress = "清理临时文件..."
            try await DMGMounter.unmount(mountPath)
            try FileManager.default.removeItem(at: dmgURL)
            os_log(.info, "[UpdateInstaller] ✓ Temp files cleaned")

            // 5. 重启应用
            installProgress = "重启应用..."
            await AppRestarter.restart()

            isInstalling = false
        } catch {
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
        let script = """
        do shell script "rm -rf '\(currentAppPath.path)' && cp -R '\(newAppPath.path)' '\(currentAppPath.path)'" with administrator privileges
        """

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