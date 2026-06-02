import ProjectRulesKit
import SwiftUI

public struct WorkingStateSummaryView: View {
    private let state: CommitRemoteSyncRules.WorkingStatePresentationState
    private let onPull: () -> Void
    private let onPush: () -> Void

    public init(
        state: CommitRemoteSyncRules.WorkingStatePresentationState,
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void
    ) {
        self.state = state
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
        switch state.trailingAction {
        case .refreshing:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.8)
                Text(CommitLocalization.string("Refreshing"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        case .pull:
            Button {
                onPull()
            } label: {
                Label(
                    state.isPulling ? CommitLocalization.string("Pulling...") : CommitLocalization.string("Pull"),
                    systemImage: "arrow.down.circle.fill"
                )
            }
            .disabled(state.isPulling)
            .help(CommitLocalization.string("Click to run git pull and fetch remote commits"))
        case .push:
            Button {
                onPush()
            } label: {
                Label(
                    state.isPushing ? CommitLocalization.string("Pushing...") : CommitLocalization.string("Push"),
                    systemImage: "arrow.up.circle.fill"
                )
            }
            .disabled(state.isPushing)
            .help(CommitLocalization.string("Click to run git push and push local commits"))
        case .none:
            EmptyView()
        }
    }
}
