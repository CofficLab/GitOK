import GitOKUI
import SwiftUI

public struct WorkspaceSyncButton: View {
    private let trackingStatus: GitOKRemoteTrackingStatus
    private let isWorking: Bool
    private let onFetch: () -> Void
    private let onPull: () -> Void
    private let onPush: () -> Void

    public init(
        trackingStatus: GitOKRemoteTrackingStatus,
        isWorking: Bool,
        onFetch: @escaping () -> Void,
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void
    ) {
        self.trackingStatus = trackingStatus
        self.isWorking = isWorking
        self.onFetch = onFetch
        self.onPull = onPull
        self.onPush = onPush
    }

    public var body: some View {
        AppSplitActionMenu(
            title: primaryActionTitle,
            detail: syncMetricText,
            systemImage: primaryAction.systemImage,
            showsTitle: false,
            showsMenu: false,
            isLoading: isWorking,
            action: {
                perform(primaryAction)
            }
        ) {
            EmptyView()
        }
        .fixedSize(horizontal: true, vertical: false)
        .help(primaryActionHelp)
    }

    private var primaryAction: WorkspaceSyncPrimaryAction {
        WorkspaceSyncPrimaryAction.primaryAction(for: trackingStatus)
    }

    private var primaryActionTitle: String {
        WorkspaceSyncPrimaryAction.title(for: trackingStatus)
    }

    private var primaryActionHelp: String {
        WorkspaceSyncPrimaryAction.help(for: trackingStatus)
    }

    private var syncMetricText: String? {
        WorkspaceSyncPrimaryAction.badgeText(for: trackingStatus)
    }

    private func perform(_ action: WorkspaceSyncPrimaryAction) {
        switch action {
        case .fetch:
            onFetch()
        case .pull:
            onPull()
        case .push:
            onPush()
        }
    }
}

public enum WorkspaceSyncPrimaryAction: Equatable, Sendable {
    case fetch
    case pull
    case push

    public static func primaryAction(for status: GitOKRemoteTrackingStatus) -> WorkspaceSyncPrimaryAction {
        if status.hasUpstream, status.behind > 0 {
            return .pull
        }

        if status.hasUpstream, status.ahead == 0 {
            return .fetch
        }

        return .push
    }

    public static func badgeText(for status: GitOKRemoteTrackingStatus) -> String? {
        guard status.hasUpstream else { return nil }

        if status.ahead > 0, status.behind > 0 {
            return "↑\(status.ahead) ↓\(status.behind)"
        }

        if status.ahead > 0 {
            return "↑\(status.ahead)"
        }

        if status.behind > 0 {
            return "↓\(status.behind)"
        }

        return nil
    }

    public static func title(for status: GitOKRemoteTrackingStatus) -> String {
        let action = primaryAction(for: status)
        if action == .push, !status.hasUpstream {
            return CommitLocalization.string("Publish branch")
        }

        return action.title
    }

    public static func help(for status: GitOKRemoteTrackingStatus) -> String {
        let action = primaryAction(for: status)
        if action == .pull {
            return CommitLocalization.string("New commits on remote")
        }

        return action.help
    }

    var systemImage: String {
        switch self {
        case .fetch:
            "arrow.clockwise"
        case .pull:
            "arrow.down"
        case .push:
            "arrow.up"
        }
    }

    var title: String {
        switch self {
        case .fetch:
            CommitLocalization.string("Fetch origin")
        case .pull:
            CommitLocalization.string("Pull origin")
        case .push:
            CommitLocalization.string("Push origin")
        }
    }

    var help: String {
        switch self {
        case .fetch:
            CommitLocalization.string("Branch is up to date, click Fetch to check for remote updates")
        case .pull:
            CommitLocalization.string("New commits on remote, click Pull; Fetch or Push available in menu")
        case .push:
            CommitLocalization.string("Commits ready to push")
        }
    }
}
