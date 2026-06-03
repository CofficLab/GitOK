import ProjectRulesKit
import GitOKUI
import SwiftUI

public struct WorkingStateSummaryView: View {
    @GitOKMotionPreferenceReader private var motionPreference

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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                statusIcon

                statusText
            }

            HStack {
                Spacer()

                trailingAction
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 112)
        .background(
            state.isSelected
                ? Color.accentColor.opacity(0.1)
                : Color(.controlBackgroundColor)
        )
        .animation(summaryAnimation, value: state.changedFileCount)
        .animation(summaryAnimation, value: state.unpulledCount)
        .animation(summaryAnimation, value: isSyncWorking)
    }

    private var statusIcon: some View {
        Image(systemName: state.changedFileCount == 0 ? "checkmark.circle" : "clock.arrow.circlepath")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(statusColor)
            .frame(width: 34, height: 34)
            .background(statusColor.opacity(0.13), in: Circle())
            .contentTransition(.symbolEffect(.replace))
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
        if state.changedFileCount == 0 {
            CommitLocalization.string("Working Tree Clean")
        } else {
            CommitLocalization.string("Changes Pending")
        }
    }

    private var statusSubtitle: String {
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
