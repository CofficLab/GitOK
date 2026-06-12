import Foundation
import Sparkle
import OSLog

public final class AppUpdateController {
    public static let shared = AppUpdateController()

    public let updaterController: SPUStandardUpdaterController

    public var updater: SPUUpdater {
        updaterController.updater
    }

    private let updaterDelegate = UpdaterDelegate()

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: nil
        )

        // 启动后延迟检查更新，确保 UI 已完全加载
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            checkForUpdatesOnLaunch()
        }
    }

    /// 启动时自动检查更新
    private func checkForUpdatesOnLaunch() {
        // 仅在自动检查未启用时才手动触发，避免重复
        guard !updater.automaticallyChecksForUpdates else { return }

        updater.checkForUpdates()
        os_log(.info, "[AppUpdate] Triggered launch update check")
    }
}

private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private static let feedURLBase = "https://raw.githubusercontent.com/CofficLab/GitOK/main"

    func feedURLString(for updater: SPUUpdater) -> String? {
        #if arch(arm64)
        let feedPath = "appcast-arm64.xml"
        #else
        let feedPath = "appcast-x86_64.xml"
        #endif

        return "\(Self.feedURLBase)/\(feedPath)"
    }
}
