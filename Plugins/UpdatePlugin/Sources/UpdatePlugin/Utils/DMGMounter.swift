import Foundation
import OSLog

/// DMG 挂载工具
public class DMGMounter {
    nonisolated public static let emoji = "💿"

    /// 挂载 DMG 文件
    public static func mount(_ dmgURL: URL) async throws -> URL {
        os_log(.info, "[DMGMounter] Mounting DMG: %{public}s", dmgURL.path)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        task.arguments = [
            "attach",
            dmgURL.path,
            "-nobrowse",
            "-readonly",
            "-mountpoint",
            "/Volumes/GitOK"
        ]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            os_log(.error, "[DMGMounter] ✗ Mount failed: %{public}s", errorMessage)
            throw UpdateError.dmgMountFailed
        }

        os_log(.info, "[DMGMounter] ✓ Successfully mounted to /Volumes/GitOK")
        return URL(fileURLWithPath: "/Volumes/GitOK")
    }

    /// 卸载 DMG
    public static func unmount(_ mountPath: URL) async throws {
        os_log(.info, "[DMGMounter] Unmounting: %{public}s", mountPath.path)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        task.arguments = ["detach", mountPath.path, "-force"]

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            os_log(.error, "[DMGMounter] Unmount failed, but continuing")
        } else {
            os_log(.info, "[DMGMounter] ✓ Successfully unmounted")
        }
    }
}