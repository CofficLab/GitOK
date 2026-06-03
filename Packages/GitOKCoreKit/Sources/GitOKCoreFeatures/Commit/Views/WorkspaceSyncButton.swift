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
        HStack(spacing: 0) {
            Button {
                perform(primaryAction)
            } label: {
                HStack(spacing: 6) {
                    actionIcon

                    Text(primaryAction.title)
                        .font(.caption)
                        .lineLimit(1)

                    if let badgeText {
                        Text(badgeText)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Menu {
                Button {
                    onFetch()
                } label: {
                    Label(CommitLocalization.string("Fetch origin"), systemImage: "arrow.clockwise")
                }

                Button {
                    onPull()
                } label: {
                    Label(CommitLocalization.string("Pull origin"), systemImage: "arrow.down")
                }
                .disabled(trackingStatus.hasUpstream != true)

                Button {
                    onPush()
                } label: {
                    Label(pushTitle, systemImage: "arrow.up")
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .frame(width: 18)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .frame(width: 148)
        .fixedSize(horizontal: true, vertical: false)
        .disabled(isWorking)
        .help(primaryAction.help)
    }

    private var primaryAction: WorkspaceSyncPrimaryAction {
        WorkspaceSyncPrimaryAction.primaryAction(for: trackingStatus)
    }

    private var pushTitle: String {
        trackingStatus.hasUpstream
            ? CommitLocalization.string("Push origin")
            : CommitLocalization.string("Publish branch")
    }

    private var badgeText: String? {
        WorkspaceSyncPrimaryAction.badgeText(for: trackingStatus)
    }

    @ViewBuilder
    private var actionIcon: some View {
        if isWorking {
            SpinningSyncIcon()
        } else {
            primaryAction.icon
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 16, height: 16)
        }
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

private struct SpinningSyncIcon: View {
    @State private var isRotating = false

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
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

    var icon: Image {
        switch self {
        case .fetch:
            Image(systemName: "arrow.clockwise")
        case .pull:
            Image(systemName: "arrow.down")
        case .push:
            Image(systemName: "arrow.up")
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
