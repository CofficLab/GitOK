import ProjectRulesKit
import SwiftUI

public struct WorkingStateContentView<SSHHelpContent: View>: View {
    private let changedFileCount: Int
    private let unpulledCount: Int
    private let isSelected: Bool
    private let isRefreshing: Bool
    private let isPulling: Bool
    private let isPushing: Bool
    private let trackingStatus: GitOKRemoteTrackingStatus
    private let isSyncWorking: Bool
    @Binding private var showCredentialInput: Bool
    @Binding private var showSSHHelp: Bool
    private let credentialHost: String
    private let credentialRetryOperation: CommitRemoteSyncRules.RetryOperation?
    private let sshHelpContent: () -> SSHHelpContent
    private let onFetch: () -> Void
    private let onPull: () -> Void
    private let onPush: () -> Void
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
        trackingStatus: GitOKRemoteTrackingStatus,
        isSyncWorking: Bool,
        showCredentialInput: Binding<Bool>,
        showSSHHelp: Binding<Bool>,
        credentialHost: String,
        credentialRetryOperation: CommitRemoteSyncRules.RetryOperation?,
        @ViewBuilder sshHelpContent: @escaping () -> SSHHelpContent,
        onFetch: @escaping () -> Void,
        onPull: @escaping () -> Void,
        onPush: @escaping () -> Void,
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
        self.trackingStatus = trackingStatus
        self.isSyncWorking = isSyncWorking
        _showCredentialInput = showCredentialInput
        _showSSHHelp = showSSHHelp
        self.credentialHost = credentialHost
        self.credentialRetryOperation = credentialRetryOperation
        self.sshHelpContent = sshHelpContent
        self.onFetch = onFetch
        self.onPull = onPull
        self.onPush = onPush
        self.onTap = onTap
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        self.onCredentialDismiss = onCredentialDismiss
    }

    public var body: some View {
        WorkingStateSummaryView(
            state: CommitRemoteSyncRules.workingStatePresentationState(
                changedFileCount: changedFileCount,
                unpulledCount: unpulledCount,
                isSelected: isSelected,
                isRefreshing: isRefreshing,
                isPulling: isPulling,
                isPushing: isPushing
            ),
            trackingStatus: trackingStatus,
            isSyncWorking: isSyncWorking,
            onFetch: onFetch,
            onPull: onPull,
            onPush: onPush
        )
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
