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
    private var feedPreparationTask: Task<Void, Never>?
    private let stateMachine = UpdateServiceStateMachine()
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

        _ = prepareFeedURLIfNeeded()
    }

    @discardableResult
    private func prepareFeedURLIfNeeded() -> Task<Void, Never> {
        if let feedPreparationTask {
            return feedPreparationTask
        }

        let detector = feedURLDetector
        let task = Task { @MainActor [weak self] in
            await detector.detectIfNeeded()
            guard let self else { return }
            self.resolvedFeedURL = await detector.resolvedFeedURL
            self.feedPreparationTask = nil
            self.ensureUpdaterInitialized()
        }
        feedPreparationTask = task
        return task
    }

    public func checkForUpdates() {
        guard AppUpdateRuntimeEnvironment.allowsAppUpdates else { return }

        // Feed selection is asynchronous. Wait for it before starting Sparkle so
        // a slow/unavailable primary endpoint cannot race a manual check and
        // cause that check to use the wrong feed.
        let preparationTask = prepareFeedURLIfNeeded()
        Task { @MainActor [weak self] in
            await preparationTask.value
            guard let self, AppUpdateRuntimeEnvironment.allowsAppUpdates else { return }
            self.ensureUpdaterInitialized()
            await self.stateMachine.beginChecking()
            self.updaterController?.checkForUpdates(nil)
        }
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
        Task {
            await stateMachine.markReadyToInstall(version: item.displayVersionString)
        }
        NotificationCenter.postAppUpdateReadyToInstall(version: item.displayVersionString)

        // The standard Sparkle user driver owns the install/relaunch UI. Returning
        // true here would transfer ownership to this service, but GitOK has no
        // custom install UI that invokes immediateInstallHandler.
        return false
    }

    public func feedURLString(for updater: SPUUpdater) -> String? {
        resolvedFeedURL.absoluteString
    }

    public func handleCheckForUpdatesRequest() {
        checkForUpdates()
    }

    public func handleInstallPreparedAppUpdateRequest() {
        // Kept as a notification endpoint for compatibility with older clients.
        // Installation is intentionally left to Sparkle's standard user driver.
    }

    public func updater(
        _ updater: SPUUpdater,
        willDownloadUpdate item: SUAppcastItem,
        with request: NSMutableURLRequest
    ) {
        Task { await stateMachine.beginDownloading() }
    }

    public func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        Task { await stateMachine.markError() }
    }

    public func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        Task { await stateMachine.markError() }
    }

    public func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: Error?
    ) {
        if error != nil {
            Task { await stateMachine.markError() }
        } else {
            Task { await stateMachine.finishCheckingIfNeeded() }
        }
    }
}
