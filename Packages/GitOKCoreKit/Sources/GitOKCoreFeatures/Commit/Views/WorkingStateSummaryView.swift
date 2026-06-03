import ProjectRulesKit
import SwiftUI

public struct WorkingStateSummaryView: View {
    private let state: CommitRemoteSyncRules.WorkingStatePresentationState
    private let trackingStatus: GitOKRemoteTrackingStatus
    private let isSyncWorking: Bool
    private let onFetch: () -> Void
    private let onPull: () -> Void
    private let onPush: () -> Void

    public init(
        state: CommitRemoteSyncRules.WorkingStatePresentationState,
        trackingStatus: GitOKRemoteTrackingStatus = GitOKRemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false),
        isSyncWorking: Bool = false,
        onFetch: @escaping () -> Void = {},
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void
    ) {
        self.state = state
        self.trackingStatus = trackingStatus
        self.isSyncWorking = isSyncWorking
        self.onFetch = onFetch
        self.onPull = onPull
        self.onPush = onPush
    }

    public init(
        changedFileCount: Int,
        unpulledCount: Int,
        isSelected: Bool,
        isRefreshing: Bool,
        isPulling: Bool,
        isPushing: Bool,
        trackingStatus: GitOKRemoteTrackingStatus = GitOKRemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false),
        isSyncWorking: Bool = false,
        onFetch: @escaping () -> Void = {},
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void
    ) {
        self.state = CommitRemoteSyncRules.workingStatePresentationState(
            changedFileCount: changedFileCount,
            unpulledCount: unpulledCount,
            isSelected: isSelected,
            isRefreshing: isRefreshing,
            isPulling: isPulling,
            isPushing: isPushing
        )
        self.trackingStatus = trackingStatus
        self.isSyncWorking = isSyncWorking
        self.onFetch = onFetch
        self.onPull = onPull
        self.onPush = onPush
    }

    public var body: some View {
        HStack(spacing: 12) {
            statusIcon

            statusText

            Spacer()

            trailingAction
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            state.isSelected
                ? Color.accentColor.opacity(0.1)
                : Color(.controlBackgroundColor)
        )
    }

    private var statusIcon: some View {
        Image(systemName: state.changedFileCount == 0 ? "checkmark.circle" : "clock.arrow.circlepath")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(state.changedFileCount == 0 ? .green : .orange)
    }

    private var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            if state.changedFileCount == 0 {
                Text(CommitLocalization.string("Working Tree Clean"))
                    .font(.system(size: 14, weight: .medium))

                if state.unpulledCount > 0 {
                    Text(String.localizedStringWithFormat(
                        CommitLocalization.string("%lld remote commits available to pull"),
                        state.unpulledCount
                    ))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text(CommitLocalization.string("All Changes Committed"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(CommitLocalization.string("Current Status"))
                    .font(.system(size: 14, weight: .medium))

                Text(String.localizedStringWithFormat(
                    CommitLocalization.string("(%lld) Uncommitted"),
                    state.changedFileCount
                ))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var trailingAction: some View {
        WorkspaceSyncButton(
            trackingStatus: trackingStatus,
            isWorking: isSyncWorking,
            onFetch: onFetch,
            onPull: onPull,
            onPush: onPush
        )
    }
}
