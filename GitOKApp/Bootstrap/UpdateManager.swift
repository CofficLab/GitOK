import Foundation
import OSLog
import Sparkle

/// 更新管理器：基于 Sparkle 实现，支持多 feed URL fallback
///
/// 优先使用自有服务器 appcast，如果不可达则 fallback 到 GitHub。
/// Sparkle 负责下载、验证、安装更新（内置特权 Helper，免密码替换）。
public final class UpdateManager: NSObject {
    nonisolated public static let emoji = "✨"

    public static let shared = UpdateManager()

    /// 主 feed URL（自有服务器）
    private let primaryFeedURL = URL(string: "https://api.kuaiyizhi.cn/gitok/appcast.xml")!

    /// 备用 feed URL（GitHub）
    private let fallbackFeedURL = URL(string: "https://raw.githubusercontent.com/CofficLab/GitOK/main/appcast-arm64.xml")!

    /// 缓存网络检测结果，避免每次检查都做网络请求
    private var detectedFeedURL: URL?
    private var lastDetectionTime: Date?

    private override init() {
        super.init()
    }

    /// 检测可用的 feed URL 并设置给 Sparkle
    ///
    /// 在应用启动时调用一次。先尝试自有服务器，不可达则使用 GitHub。
    public func setupFeedURLIfNeeded() async {
        // 30 分钟内不重复检测
        if let lastDetectionTime,
           Date().timeIntervalSince(lastDetectionTime) < 1800,
           detectedFeedURL != nil {
            return
        }

        let url = await detectFeedURL()
        detectedFeedURL = url
        lastDetectionTime = Date()

        SUUpdater.shared().setFeedURL(url)
        os_log(.info, "[UpdateManager] Feed URL set to: %{public}@", url.absoluteString)
    }

    /// 手动检查更新（用于设置面板中的"检查更新"按钮）
    public func checkForUpdates() {
        SUUpdater.shared().checkForUpdates()
    }

    /// 检测哪个 feed URL 可用
    private func detectFeedURL() async -> URL {
        // 先尝试主 URL（自有服务器）
        if await isURLReachable(primaryFeedURL) {
            os_log(.info, "[UpdateManager] Primary feed reachable")
            return primaryFeedURL
        }

        // fallback 到 GitHub
        os_log(.info, "[UpdateManager] Primary unreachable, using GitHub fallback")
        return fallbackFeedURL
    }

    /// 快速检测 URL 是否可达（HEAD 请求， 5 秒超时）
    private func isURLReachable(_ url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}
