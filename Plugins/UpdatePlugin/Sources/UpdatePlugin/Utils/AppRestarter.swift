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

        // 等待短暂延迟后退出当前实例
        try? await Task.sleep(for: .seconds(1))
        NSApplication.shared.terminate(nil)
    }
}