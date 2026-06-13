import Foundation
import OSLog
import Cocoa

/// 应用重启工具
public class AppRestarter {
    nonisolated public static let emoji = "🔄"

    /// 重启应用
    @MainActor
    public static func restart() async {
        os_log(.info, "[AppRestarter] Restarting application...")

        let appURL = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = true

        // 启动新实例
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            if let error = error {
                os_log(.error, "[AppRestarter] ✗ Failed to restart: %{public}s", error.localizedDescription)
            } else {
                os_log(.info, "[AppRestarter] ✓ Successfully restarted")
            }
        }

        // 等待新实例启动完成，使用轮询检测而非固定延迟
        // 检查新进程的 PID 是否不同于当前进程
        let currentPID = ProcessInfo.processInfo.processIdentifier
        for _ in 0..<20 {  // 最多等待 2 秒
            try? await Task.sleep(for: .milliseconds(100))

            // 查找所有 GitOK 进程
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            task.arguments = ["-f", "GitOK.app"]
            let pipe = Pipe()
            task.standardOutput = pipe

            try? task.run()
            task.waitUntilExit()

            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let pids = output.trimmingCharacters(in: .whitespacesAndNewlines)
                           .split(separator: "\n")
                           .compactMap { Int32($0) }

            // 如果存在其他 GitOK 进程，说明新实例已启动
            if pids.contains(where: { $0 != currentPID }) {
                os_log(.info, "[AppRestarter] ✓ New instance detected, terminating current")
                break
            }
        }

        // 退出当前实例
        NSApplication.shared.terminate(nil)
    }
}