import GitOKCoreKit
import ProjectRulesKit
import SwiftUI

public struct WorkingStateContentView<SSHHelpContent: View>: View {
    private let changedFileCount: Int
    private let unpulledCount: Int
    private let isSelected: Bool
    private let isRefreshing: Bool
    private let isPulling: Bool
    private let isPushing: Bool
    private let activityStatus: String?
    private let trackingStatus: GitOKRemoteTrackingStatus
    private let isSyncWorking: Bool
    private let conflictState: WorkingStateConflictState?
    private let isConflictActionRunning: Bool
    private let activeConflictPath: String?
    @Binding private var showCredentialInput: Bool
    @Binding private var showSSHHelp: Bool
    private let credentialHost: String
    private let credentialRetryOperation: CommitRemoteSyncRules.RetryOperation?
    private let sshHelpContent: () -> SSHHelpContent
    private let onFetch: () -> Void
    private let onPull: () -> Void
    private let onPush: () -> Void
    private let onOpenConflictFile: (String) -> Void
    private let onRevealConflictFile: (String) -> Void
    private let onStageConflictFile: (String) -> Void
    private let onUseOursConflictFile: (String) -> Void
    private let onUseTheirsConflictFile: (String) -> Void
    private let onContinueMerge: () -> Void
    private let onAbortMerge: () -> Void
    private let onTap: () -> Void
    private let onAppear: () -> Void
    private let onDisappear: () -> Void
    private let onCredentialDismiss: (CommitRemoteSyncRules.RetryPromptDismissState) -> Void

    public init(
        changedFileCount: Int,
        unpulledCount: Int,
        isSelected: Bool,
        isRefreshing: Bool,
        isPulling: Bool,
        isPushing: Bool,
        activityStatus: String?,
        trackingStatus: GitOKRemoteTrackingStatus,
        isSyncWorking: Bool,
        conflictState: WorkingStateConflictState?,
        isConflictActionRunning: Bool = false,
        activeConflictPath: String? = nil,
        showCredentialInput: Binding<Bool>,
        showSSHHelp: Binding<Bool>,
        credentialHost: String,
        credentialRetryOperation: CommitRemoteSyncRules.RetryOperation?,
        @ViewBuilder sshHelpContent: @escaping () -> SSHHelpContent,
        onFetch: @escaping () -> Void,
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void,
        onOpenConflictFile: @escaping (String) -> Void = { _ in },
        onRevealConflictFile: @escaping (String) -> Void = { _ in },
        onStageConflictFile: @escaping (String) -> Void = { _ in },
        onUseOursConflictFile: @escaping (String) -> Void = { _ in },
        onUseTheirsConflictFile: @escaping (String) -> Void = { _ in },
        onContinueMerge: @escaping () -> Void = {},
        onAbortMerge: @escaping () -> Void = {},
        onTap: @escaping () -> Void,
        onAppear: @escaping () -> Void,
        onDisappear: @escaping () -> Void,
        onCredentialDismiss: @escaping (CommitRemoteSyncRules.RetryPromptDismissState) -> Void
    ) {
        self.changedFileCount = changedFileCount
        self.unpulledCount = unpulledCount
        self.isSelected = isSelected
        self.isRefreshing = isRefreshing
        self.isPulling = isPulling
        self.isPushing = isPushing
        self.activityStatus = activityStatus
        self.trackingStatus = trackingStatus
        self.isSyncWorking = isSyncWorking
        self.conflictState = conflictState
        self.isConflictActionRunning = isConflictActionRunning
        self.activeConflictPath = activeConflictPath
        _showCredentialInput = showCredentialInput
        _showSSHHelp = showSSHHelp
        self.credentialHost = credentialHost
        self.credentialRetryOperation = credentialRetryOperation
        self.sshHelpContent = sshHelpContent
        self.onFetch = onFetch
        self.onPull = onPull
        self.onPush = onPush
        self.onOpenConflictFile = onOpenConflictFile
        self.onRevealConflictFile = onRevealConflictFile
        self.onStageConflictFile = onStageConflictFile
        self.onUseOursConflictFile = onUseOursConflictFile
        self.onUseTheirsConflictFile = onUseTheirsConflictFile
        self.onContinueMerge = onContinueMerge
        self.onAbortMerge = onAbortMerge
        self.onTap = onTap
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        self.onCredentialDismiss = onCredentialDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            WorkingStateSummaryView(
                state: CommitRemoteSyncRules.workingStatePresentationState(
                    changedFileCount: changedFileCount,
                    unpulledCount: unpulledCount,
                    isSelected: isSelected,
                    isRefreshing: isRefreshing,
                    isPulling: isPulling,
                    isPushing: isPushing
                ),
                activityStatus: activityStatus,
                trackingStatus: trackingStatus,
                isSyncWorking: isSyncWorking,
                onFetch: onFetch,
                onPull: onPull,
                onPush: onPush
            )

            if let conflictState, conflictState.isMerging {
                WorkingStateConflictPanel(
                    state: conflictState,
                    isPerformingAction: isConflictActionRunning,
                    activePath: activeConflictPath,
                    onOpen: onOpenConflictFile,
                    onReveal: onRevealConflictFile,
                    onStage: onStageConflictFile,
                    onUseOurs: onUseOursConflictFile,
                    onUseTheirs: onUseTheirsConflictFile,
                    onContinue: onContinueMerge,
                    onAbort: onAbortMerge
                )
            }
        }
        .onTapGesture(perform: onTap)
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .sheet(isPresented: $showCredentialInput) {
            CredentialInputView(server: credentialHost) {
                onCredentialDismiss(
                    CommitRemoteSyncRules.retryPromptDismissState(
                        for: .credential,
                        operation: credentialRetryOperation
                    )
                )
            }
        }
        .sheet(isPresented: $showSSHHelp) {
            sshHelpContent()
        }
    }
}
