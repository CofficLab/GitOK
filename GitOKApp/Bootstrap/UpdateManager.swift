import Foundation
import OSLog
import Sparkle

/// 更新管理器：基于 Sparkle 2.x 实现，支持多 feed URL fallback
///
/// 启动时创建 SPUStandardUpdaterController（启动 Sparkle updater），
/// 然后检测网络选择 feed URL（自有服务器优先，GitHub fallback）。
/// Sparkle 负责下载、验证、安装更新（内置特权 Helper，免密码替换）。
public final class UpdateManager: NSObject {
    nonisolated public static let emoji = "✨"

    public static let shared = UpdateManager()

    /// Sparkle 控制器（持有它以保持 updater 运行）
    public private(set) var updaterController: SPUStandardUpdaterController!

    /// 主 feed URL（根据架构选择对应的 appcast）
    private var primaryFeedURL: URL {
        #if arch(arm64)
        URL(string: "https://s.kuaiyizhi.cn/gitok/appcast-arm64.xml")!
        #else
        URL(string: "https://s.kuaiyizhi.cn/gitok/appcast-x86_64.xml")!
        #endif
    }

    /// 备用 feed URL（GitHub Release，根据架构选择对应的 appcast）
    private var fallbackFeedURL: URL {
        #if arch(arm64)
        URL(string: "https://github.com/CofficLab/GitOK/releases/latest/download/appcast-arm64.xml")!
        #else
        URL(string: "https://github.com/CofficLab/GitOK/releases/latest/download/appcast-x86_64.xml")!
        #endif
    }

    /// 缓存网络检测结果，避免每次检查都做网络请求
    private var lastDetectionTime: Date?

    private override init() {
        // 创建控制器即启动 Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    /// 检测可用的 feed URL 并设置给 Sparkle
    ///
    /// 在应用启动时调用一次。先尝试自有服务器，不可达则使用 GitHub。
    public func setupFeedURLIfNeeded() async {
        // 30 分钟内不重复检测
        if let lastDetectionTime,
           Date().timeIntervalSince(lastDetectionTime) < 1800 {
            return
        }

        let url = await detectFeedURL()
        lastDetectionTime = Date()

        // setFeedURL 必须在主线程调用
        await MainActor.run {
            updaterController.updater.setFeedURL(url)
            os_log(.info, "[UpdateManager] Feed URL set to: %{public}@", url.absoluteString)
        }
    }

    /// 手动检查更新
    public func checkForUpdates() {
        updaterController.updater.checkForUpdates()
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
