import AppKit
import Foundation
import Sparkle

/// GitOK 的宿主级 Sparkle 更新服务。
///
/// 更新服务不注册为业务插件 Provider：它属于发行渠道能力，由 GitOKApp 在
/// 内核完成装配后启动。菜单、设置页和其他模块通过通知或注入的闭包请求检查。
@MainActor
public final class UpdateService: NSObject, SPUUpdaterDelegate {
    public static let shared = UpdateService()

    public private(set) var updaterController: SPUStandardUpdaterController?
    public var updater: SPUUpdater? { updaterController?.updater }

    private var feedURLDetector: FeedURLDetector
    private var resolvedFeedURL = UpdateFeedURLProvider.primary
    private let stateMachine = UpdateServiceStateMachine()
    private var pendingImmediateInstallHandler: (() -> Void)?

    private override init() {
        feedURLDetector = FeedURLDetector(
            initialURL: UpdateFeedURLProvider.primary,
            reachabilityChecker: URLSessionFeedURLReachabilityChecker()
        )
        super.init()
    }

    public func ensureUpdaterInitialized() {
        guard AppUpdateRuntimeEnvironment.allowsAppUpdates else { return }
        guard updaterController == nil else { return }

        let controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        _ = controller.updater.clearFeedURLFromUserDefaults()
        controller.startUpdater()
        updaterController = controller
    }

    public func setupFeedURLIfNeeded() {
        guard AppUpdateRuntimeEnvironment.allowsAppUpdates else { return }

        let detector = feedURLDetector
        Task { @MainActor [weak self] in
            await detector.detectIfNeeded()
            guard let self else { return }
            self.resolvedFeedURL = await detector.resolvedFeedURL
            self.ensureUpdaterInitialized()
        }
    }

    public func checkForUpdates() {
        guard AppUpdateRuntimeEnvironment.allowsAppUpdates else { return }
        ensureUpdaterInitialized()
        Task { await stateMachine.beginChecking() }
        updaterController?.checkForUpdates(nil)
    }

    public var currentState: UpdateLifecycleState {
        get async { await stateMachine.state }
    }

    public var latestVersion: String? {
        get async { await stateMachine.latestVersion }
    }

    public func updater(
        _ updater: SPUUpdater,
        willInstallUpdateOnQuit item: SUAppcastItem,
        immediateInstallationBlock immediateInstallHandler: @escaping () -> Void
    ) -> Bool {
        pendingImmediateInstallHandler = immediateInstallHandler
        Task {
            await stateMachine.markReadyToInstall(version: item.displayVersionString)
        }
        NotificationCenter.postAppUpdateReadyToInstall(version: item.displayVersionString)
        return true
    }

    public func feedURLString(for updater: SPUUpdater) -> String? {
        resolvedFeedURL.absoluteString
    }

    public func handleCheckForUpdatesRequest() {
        checkForUpdates()
    }

    public func handleInstallPreparedAppUpdateRequest() {
        guard let handler = pendingImmediateInstallHandler else { return }
        pendingImmediateInstallHandler = nil
        Task { await stateMachine.beginInstalling() }
        handler()
    }
}
