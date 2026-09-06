import Foundation

@MainActor
final class UpdateRequestObserver {
    private var tokens: [NSObjectProtocol] = []

    init(
        onCheckForUpdates: @escaping @MainActor @Sendable () -> Void,
        onInstallPreparedUpdate: @escaping @MainActor @Sendable () -> Void
    ) {
        tokens = [
            NotificationCenter.default.addObserver(
                forName: .checkForUpdates,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in onCheckForUpdates() }
            },
            NotificationCenter.default.addObserver(
                forName: .installPreparedAppUpdate,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in onInstallPreparedUpdate() }
            },
        ]
    }

    func cancel() {
        tokens.forEach(NotificationCenter.default.removeObserver)
        tokens.removeAll()
    }
}
