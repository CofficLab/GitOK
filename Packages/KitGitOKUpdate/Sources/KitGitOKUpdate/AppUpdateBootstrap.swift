import Foundation

/// 启动并持有 GitOK 的宿主级更新服务。
@MainActor
public enum AppUpdateBootstrap {
    private static var requestObserver: UpdateRequestObserver?

    public static func start() {
        let service = UpdateService.shared
        requestObserver?.cancel()
        requestObserver = UpdateRequestObserver(
            onCheckForUpdates: { [weak service] in service?.handleCheckForUpdatesRequest() },
            onInstallPreparedUpdate: { [weak service] in service?.handleInstallPreparedAppUpdateRequest() }
        )
        service.setupFeedURLIfNeeded()
    }

    public static func stop() {
        requestObserver?.cancel()
        requestObserver = nil
    }
}
