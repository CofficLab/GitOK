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
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = true
        config.createsNewApplicationInstance = true

        let newPID: Int32? = await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { runningApp, error in
                if let error = error {
                    os_log(.error, "[AppRestarter] ✗ Failed to restart: %{public}s", error.localizedDescription)
                    continuation.resume(returning: nil)
                } else if let pid = runningApp?.processIdentifier {
                    os_log(.info, "[AppRestarter] ✓ Launched new instance (PID %d)", pid)
                    continuation.resume(returning: pid)
                } else {
                    os_log(.error, "[AppRestarter] ✗ Launch completed but no running app returned")
                    continuation.resume(returning: nil)
                }
            }
        }

        guard let newPID, newPID != currentPID else {
            os_log(.error, "[AppRestarter] ✗ New instance not confirmed, keeping current instance alive")
            return
        }

        // 等待新实例完成初始化
        try? await Task.sleep(for: .milliseconds(500))

        os_log(.info, "[AppRestarter] Terminating current instance (PID %d)", currentPID)
        NSApplication.shared.terminate(nil)
    }
}