import Foundation
import OSLog

/// 更新通知服务
@MainActor
public class UpdateNotifier: ObservableObject {
    nonisolated public static let emoji = "🔔"

    public static let shared = UpdateNotifier()

    @Published public var showUpdateNotification = false
    @Published public var updateInfo: UpdateInfo?
    @Published public var hasUpdate = false
    @Published public var errorMessage: String?

    private let checker = UpdateChecker.shared
    private var autoCheckTimer: Timer?

    private init() {
        // 启动时检查（延迟 3 秒，避免影响启动速度）
        Task {
            try? await Task.sleep(for: .seconds(3))
            await checkForUpdatesInBackground()
        }

        // 定期检查（每 24 小时）
        startAutoCheckTimer()
    }

    /// 启动自动检查定时器
    private func startAutoCheckTimer() {
        autoCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForUpdatesInBackground()
            }
        }
    }

    /// 后台自动检查更新
    public func checkForUpdatesInBackground() async {
        os_log(.info, "[UpdateNotifier] Checking for updates in background...")

        await checker.checkForUpdates()

        if let updateInfo = checker.latestVersion, updateInfo.isNewerThanCurrent {
            self.updateInfo = updateInfo
            self.hasUpdate = true
            self.showUpdateNotification = true  // 显示通知弹窗
            os_log(.info, "[UpdateNotifier] New version available: %{public}s", updateInfo.version)
        } else {
            os_log(.info, "[UpdateNotifier] No update available")
        }
    }

    /// 用户手动检查更新
    public func checkForUpdatesManually() async {
        os_log(.info, "[UpdateNotifier] Checking for updates manually...")

        await checker.checkForUpdates()

        if let updateInfo = checker.latestVersion {
            if updateInfo.isNewerThanCurrent {
                self.updateInfo = updateInfo
                self.hasUpdate = true
                self.showUpdateNotification = true
                os_log(.info, "[UpdateNotifier] New version available: %{public}s", updateInfo.version)
            } else {
                // 显示"已是最新版本"提示
                errorMessage = "已是最新版本"
                os_log(.info, "[UpdateNotifier] Already up to date")
            }
        } else if checker.hasError {
            errorMessage = checker.errorMessage
        }
    }

    /// 关闭更新通知弹窗
    public func dismissNotification() {
        showUpdateNotification = false
    }
}