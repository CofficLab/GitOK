import GitOKCoreKit
import ProjectRulesKit
import GitOKUI
import SwiftUI

public struct WorkingStateSummaryView: View {
    @GitOKMotionPreferenceReader private var motionPreference

    private let state: CommitRemoteSyncRules.WorkingStatePresentationState
    private let activityStatus: String?
    private let trackingStatus: GitOKRemoteTrackingStatus
    private let isSyncWorking: Bool
    private let onFetch: () -> Void
    private let onPull: () -> Void
    private let onPush: () -> Void

    public init(
        state: CommitRemoteSyncRules.WorkingStatePresentationState,
        activityStatus: String? = nil,
        trackingStatus: GitOKRemoteTrackingStatus = GitOKRemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false),
        isSyncWorking: Bool = false,
        onFetch: @escaping () -> Void = {},
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void
    ) {
        self.state = state
        self.activityStatus = activityStatus
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
        activityStatus: String? = nil,
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
        self.activityStatus = activityStatus
        self.trackingStatus = trackingStatus
        self.isSyncWorking = isSyncWorking
        self.onFetch = onFetch
        self.onPull = onPull
        self.onPush = onPush
    }

    public var body: some View {
        HStack(spacing: 14) {
            statusText

            Spacer()

            trailingAction
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(
            state.isSelected
                ? Color.accentColor.opacity(0.1)
                : Color(.controlBackgroundColor)
        )
        .animation(summaryAnimation, value: state.changedFileCount)
        .animation(summaryAnimation, value: state.unpulledCount)
        .animation(summaryAnimation, value: isSyncWorking)
    }

    private var statusText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(statusTitle)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .contentTransition(.opacity)

            Text(statusSubtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
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

    private var statusTitle: String {
        if let activityStatus {
            return activityStatus
        }

        if state.changedFileCount == 0 {
            return CommitLocalization.string("Working Tree Clean")
        } else {
            return CommitLocalization.string("Changes Pending")
        }
    }

    private var statusSubtitle: String {
        if activityStatus != nil {
            return baselineStatusSubtitle
        }

        return baselineStatusSubtitle
    }

    private var baselineStatusSubtitle: String {
        if state.changedFileCount > 0 {
            return String.localizedStringWithFormat(
                CommitLocalization.string("(%lld) Uncommitted"),
                state.changedFileCount
            )
        }

        if state.unpulledCount > 0 {
            return String.localizedStringWithFormat(
                CommitLocalization.string("%lld remote commits available to pull"),
                state.unpulledCount
            )
        }

        return CommitLocalization.string("All Changes Committed")
    }

    private var statusColor: Color {
        state.changedFileCount == 0 ? .green : .orange
    }

    private var summaryAnimation: Animation? {
        motionPreference.allowsMotion ? .easeInOut(duration: 0.20) : nil
    }
}
