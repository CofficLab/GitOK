import Combine
import ProjectRulesKit
import SwiftUI

public enum WorkingStateHostLogEvent {
    case missingProject
    case changedFileCountFailure(Error)
    case syncStatusLoad(projectPath: String)
    case unpushedCountFailure(Error)
    case unpulledCountFailure(Error)
    case syncStatusUpdated(unpushedCount: Int, unpulledCount: Int)
    case pullStart(projectPath: String)
    case pushStart(projectPath: String)
    case pullSuccess
    case pullFailure(Error)
    case pushSuccess(retryAttempt: Int?)
    case pushRetryStart
    case pushRetryFailure(retryAttempt: Int)
    case timerFired
    case timerStarted(interval: TimeInterval)
    case timerStopped
    case systemGitPushFailure(Error)
}

public enum WorkingStateHostEvent {
    case showError(Error)
    case log(WorkingStateHostLogEvent)
}

public struct WorkingStateHostView<Project, Commit, SSHHelpContent: View>: View {
    private let project: Project?
    private let selectedCommit: Commit?
    @Binding private var isRefreshing: Bool
    private let setSelectedCommit: @MainActor (Commit?) -> Void
    private let setActivityStatus: @MainActor (String?) -> Void
    private let updateCleanState: @MainActor (Bool) -> Void
    private let projectPath: @MainActor (Project) -> String
    private let loadChangedFileCount: @MainActor (Project) async throws -> Int
    private let loadUnpushedCommits: @MainActor (Project) async throws -> [Commit]
    private let loadUnpulledCount: @MainActor (Project) async throws -> Int
    private let pull: @MainActor (Project) async throws -> Void
    private let push: @MainActor (Project) async throws -> Void
    private let pushErrorClassification: @MainActor (Error) -> CommitRemoteSyncRules.PushErrorClassification
    private let runNetworkFallback: @MainActor (Project, String, @escaping (String?) -> Void) async -> Bool
    private let currentRemoteAccess: @MainActor () -> CommitRemoteSyncRules.RemoteAccess
    private let showNetworkFallbackSelection: @MainActor (CommitRemoteSyncRules.NetworkFallbackAlertText) -> CommitRemoteSyncRules.NetworkFallbackSelection
    private let eventHandler: @MainActor (WorkingStateHostEvent) -> Void
    private let projectChangeToken: Int
    private let projectDidCommitToken: Int
    private let projectDidPushToken: Int
    private let projectDidPullToken: Int
    private let gitDirectoryChangeToken: Int
    private let gitDirectoryEventProjectPath: String?
    private let gitDirectoryDidHeadChange: Bool
    private let appDidBecomeActiveToken: Int
    private let sshHelpContent: (String?, String?, @escaping () -> Void) -> SSHHelpContent

    @State private var changedFileCount = 0
    @State private var isRefreshingFileList = false
    @State private var unpushedCount = 0
    @State private var unpulledCount = 0
    @State private var isSyncLoading = false
    @State private var timerCancellable: AnyCancellable?
    @State private var isPulling = false
    @State private var isPushing = false
    @State private var showCredentialInput = false
    @State private var credentialHost = CommitRemoteSyncRules.defaultCredentialHost
    @State private var credentialRetryOperation: CommitRemoteSyncRules.RetryOperation?
    @State private var showSSHHelp = false
    @State private var sshHelpRemoteURL: String?
    @State private var sshHelpErrorMessage: String?
    @State private var sshHelpRetryOperation: CommitRemoteSyncRules.RetryOperation?

    public init(
        project: Project?,
        selectedCommit: Commit?,
        isRefreshing: Binding<Bool> = .constant(false),
        setSelectedCommit: @MainActor @escaping (Commit?) -> Void,
        setActivityStatus: @MainActor @escaping (String?) -> Void,
        updateCleanState: @MainActor @escaping (Bool) -> Void,
        projectPath: @MainActor @escaping (Project) -> String,
        loadChangedFileCount: @MainActor @escaping (Project) async throws -> Int,
        loadUnpushedCommits: @MainActor @escaping (Project) async throws -> [Commit],
        loadUnpulledCount: @MainActor @escaping (Project) async throws -> Int,
        pull: @MainActor @escaping (Project) async throws -> Void,
        push: @MainActor @escaping (Project) async throws -> Void,
        pushErrorClassification: @MainActor @escaping (Error) -> CommitRemoteSyncRules.PushErrorClassification,
        runNetworkFallback: @MainActor @escaping (Project, String, @escaping (String?) -> Void) async -> Bool,
        currentRemoteAccess: @MainActor @escaping () -> CommitRemoteSyncRules.RemoteAccess,
        showNetworkFallbackSelection: @MainActor @escaping (CommitRemoteSyncRules.NetworkFallbackAlertText) -> CommitRemoteSyncRules.NetworkFallbackSelection,
        eventHandler: @MainActor @escaping (WorkingStateHostEvent) -> Void = { _ in },
        projectChangeToken: Int = 0,
        projectDidCommitToken: Int = 0,
        projectDidPushToken: Int = 0,
        projectDidPullToken: Int = 0,
        gitDirectoryChangeToken: Int = 0,
        gitDirectoryEventProjectPath: String? = nil,
        gitDirectoryDidHeadChange: Bool = false,
        appDidBecomeActiveToken: Int = 0,
        @ViewBuilder sshHelpContent: @escaping (String?, String?, @escaping () -> Void) -> SSHHelpContent
    ) {
        self.project = project
        self.selectedCommit = selectedCommit
        _isRefreshing = isRefreshing
        self.setSelectedCommit = setSelectedCommit
        self.setActivityStatus = setActivityStatus
        self.updateCleanState = updateCleanState
        self.projectPath = projectPath
        self.loadChangedFileCount = loadChangedFileCount
        self.loadUnpushedCommits = loadUnpushedCommits
        self.loadUnpulledCount = loadUnpulledCount
        self.pull = pull
        self.push = push
        self.pushErrorClassification = pushErrorClassification
        self.runNetworkFallback = runNetworkFallback
        self.currentRemoteAccess = currentRemoteAccess
        self.showNetworkFallbackSelection = showNetworkFallbackSelection
        self.eventHandler = eventHandler
        self.projectChangeToken = projectChangeToken
        self.projectDidCommitToken = projectDidCommitToken
        self.projectDidPushToken = projectDidPushToken
        self.projectDidPullToken = projectDidPullToken
        self.gitDirectoryChangeToken = gitDirectoryChangeToken
        self.gitDirectoryEventProjectPath = gitDirectoryEventProjectPath
        self.gitDirectoryDidHeadChange = gitDirectoryDidHeadChange
        self.appDidBecomeActiveToken = appDidBecomeActiveToken
        self.sshHelpContent = sshHelpContent
    }

    public var body: some View {
        WorkingStateContentView(
            changedFileCount: changedFileCount,
            unpulledCount: unpulledCount,
            isSelected: CommitRemoteSyncRules.isWorkingStateSelected(selectedCommit: selectedCommit),
            isRefreshing: isRefreshing,
            isPulling: isPulling,
            isPushing: isPushing,
            showCredentialInput: $showCredentialInput,
            showSSHHelp: $showSSHHelp,
            credentialHost: credentialHost,
            credentialRetryOperation: credentialRetryOperation,
            sshHelpContent: {
                sshHelpContent(sshHelpRemoteURL, sshHelpErrorMessage) {
                    applyRetryPromptDismissState(
                        CommitRemoteSyncRules.retryPromptDismissState(
                            for: .sshHelp,
                            operation: sshHelpRetryOperation
                        ),
                        prompt: .sshHelp
                    )
                }
            },
            onPull: performPull,
            onPush: performPush,
            onTap: onTap,
            onAppear: onAppear,
            onDisappear: onDisappear,
            onCredentialDismiss: { state in
                applyRetryPromptDismissState(state, prompt: .credential)
            }
        )
        .onChange(of: projectChangeToken) { onProjectDidChange() }
        .onChange(of: projectDidCommitToken) { onProjectDidCommit() }
        .onChange(of: projectDidPushToken) { onProjectDidPush() }
        .onChange(of: projectDidPullToken) { onProjectDidPull() }
        .onChange(of: gitDirectoryChangeToken) { onGitDirectoryDidChange() }
        .onChange(of: appDidBecomeActiveToken) { onAppDidBecomeActive() }
    }
}

private extension WorkingStateHostView {
    func performRetryAction(_ retryAction: CommitRemoteSyncRules.RetryAction) {
        CommitRemoteSyncRules.performRetryAction(
            retryAction,
            schedule: { delay, action in
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    action()
                }
            },
            onPush: performPush,
            onPull: performPull
        )
    }

    func applyCredentialPromptState(_ state: CommitRemoteSyncRules.CredentialPromptState) {
        CommitRemoteSyncRules.performCredentialPromptState(
            state,
            setShowsPrompt: { showCredentialInput = $0 },
            setHost: { credentialHost = $0 },
            setRetryOperation: { credentialRetryOperation = $0 }
        )
    }

    func applySSHHelpState(_ state: CommitRemoteSyncRules.SSHHelpState) {
        CommitRemoteSyncRules.performSSHHelpState(
            state,
            setShowsPrompt: { showSSHHelp = $0 },
            setRemoteURL: { sshHelpRemoteURL = $0 },
            setErrorMessage: { sshHelpErrorMessage = $0 },
            setRetryOperation: { sshHelpRetryOperation = $0 }
        )
    }

    func applyRetryPromptDismissState(
        _ state: CommitRemoteSyncRules.RetryPromptDismissState,
        prompt: CommitRemoteSyncRules.RetryPrompt
    ) {
        CommitRemoteSyncRules.performRetryPromptApplicationState(
            CommitRemoteSyncRules.retryPromptApplicationState(state: state, prompt: prompt),
            setCredentialPrompt: { showCredentialInput = $0 },
            setSSHHelp: { showSSHHelp = $0 },
            performRetry: performRetryAction
        )
    }

    func applyChangedFileRefreshState(_ state: CommitRemoteSyncRules.ChangedFileRefreshState) {
        CommitRemoteSyncRules.performChangedFileRefreshState(
            state,
            setStatus: setActivityStatus,
            setRefreshing: { isRefreshingFileList = $0 }
        )
    }

    func applyRemoteOperationState(_ state: CommitRemoteSyncRules.RemoteOperationState) {
        CommitRemoteSyncRules.performRemoteOperationState(
            state,
            setPulling: { isPulling = $0 },
            setPushing: { isPushing = $0 },
            setStatus: setStatus,
            refreshSyncStatus: loadSyncStatus
        )
    }

    func applySyncStatusRefreshState(_ state: CommitRemoteSyncRules.SyncStatusRefreshState) {
        CommitRemoteSyncRules.performSyncStatusRefreshState(
            state,
            setLoading: { isSyncLoading = $0 },
            setStatus: setStatus
        )
    }

    func loadChangedFileCount() async {
        guard let project else {
            eventHandler(.log(.missingProject))
            return
        }

        applyChangedFileRefreshState(CommitRemoteSyncRules.changedFileRefreshStartState())

        do {
            let count = try await loadChangedFileCount(project)
            CommitRemoteSyncRules.performChangedFileCountResult(
                count,
                setChangedFileCount: { changedFileCount = $0 },
                updateCleanState: updateCleanState
            )
            applyChangedFileRefreshState(CommitRemoteSyncRules.changedFileRefreshFinishedState())
        } catch {
            applyChangedFileRefreshState(CommitRemoteSyncRules.changedFileRefreshFinishedState())
            eventHandler(.log(.changedFileCountFailure(error)))
        }
    }

    func loadSyncStatus() {
        CommitRemoteSyncRules.performRequiredProjectSyncStatusCommand(
            project: project,
            projectPath: projectPath,
            logMissing: {
                eventHandler(.log(.missingProject))
            }
        ) { command in
            loadSyncStatus(command)
        }
    }

    func loadSyncStatus(_ command: CommitRemoteSyncRules.ProjectSyncStatusRequest<Project>) {
        eventHandler(.log(.syncStatusLoad(projectPath: command.request.projectPath)))

        Task { @MainActor in
            applySyncStatusRefreshState(CommitRemoteSyncRules.syncStatusRefreshStartState())

            let unpushedCount: Int
            do {
                unpushedCount = try await loadUnpushedCommits(command.project).count
            } catch {
                unpushedCount = 0
                eventHandler(.log(.unpushedCountFailure(error)))
            }

            let unpulledCount: Int
            do {
                unpulledCount = try await loadUnpulledCount(command.project)
            } catch {
                unpulledCount = 0
                eventHandler(.log(.unpulledCountFailure(error)))
            }

            let resultState = CommitRemoteSyncRules.syncStatusResultState(
                unpushedCount: unpushedCount,
                unpulledCount: unpulledCount
            )
            CommitRemoteSyncRules.performSyncStatusResultState(
                resultState,
                setUnpushedCount: { self.unpushedCount = $0 },
                setUnpulledCount: { self.unpulledCount = $0 },
                applyRefreshState: self.applySyncStatusRefreshState
            )
            eventHandler(.log(.syncStatusUpdated(
                unpushedCount: resultState.unpushedCount,
                unpulledCount: resultState.unpulledCount
            )))
            try? await Task.sleep(nanoseconds: CommitRemoteSyncRules.statusClearDelayNanoseconds)
            setStatus(nil)
        }
    }

    func setStatus(_ text: String?) {
        Task { @MainActor in
            setActivityStatus(text)
        }
    }

    func performPull() {
        performRemoteOperation(.pull)
    }

    func performPush() {
        performRemoteOperation(.push)
    }

    func performRemoteOperation(_ operation: CommitRemoteSyncRules.RetryOperation) {
        CommitRemoteSyncRules.performRequiredProjectRemoteOperationCommand(
            project: project,
            projectPath: projectPath,
            operation: operation,
            logMissing: {
                eventHandler(.log(.missingProject))
            }
        ) { command in
            performRemoteOperation(command)
        }
    }

    func performRemoteOperation(_ command: CommitRemoteSyncRules.ProjectRemoteOperationCommand<Project>) {
        switch command.request.operation {
        case .pull:
            eventHandler(.log(.pullStart(projectPath: command.request.projectPath)))
        case .push:
            eventHandler(.log(.pushStart(projectPath: command.request.projectPath)))
        }

        Task { @MainActor in
            applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationStartState(operation: command.request.operation))

            switch command.request.operation {
            case .pull:
                do {
                    try await pull(command.project)
                    eventHandler(.log(.pullSuccess))
                    applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .pull, succeeded: true))
                } catch {
                    eventHandler(.log(.pullFailure(error)))
                    applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .pull, succeeded: false))
                    presentRemoteFailure(error, operation: .pull)
                }
            case .push:
                await performPushOperation(command)
            }
        }
    }

    func performPushOperation(_ command: CommitRemoteSyncRules.ProjectRemoteOperationCommand<Project>) async {
        do {
            try await push(command.project)
            eventHandler(.log(.pushSuccess(retryAttempt: nil)))
            applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: true))
            return
        } catch {
            let classification = pushErrorClassification(error)
            guard classification.isNetworkError else {
                applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false))
                presentRemoteFailure(error, operation: .push)
                return
            }

            eventHandler(.log(.pushRetryStart))
            for retryAttempt in CommitRemoteSyncRules.pushRetryAttempts() {
                setStatus(retryAttempt.statusText)
                try? await Task.sleep(nanoseconds: retryAttempt.delayNanoseconds)

                do {
                    try await push(command.project)
                    eventHandler(.log(.pushSuccess(retryAttempt: retryAttempt.attempt)))
                    applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: true))
                    return
                } catch {
                    guard pushErrorClassification(error).isRetryablePushError else {
                        applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false))
                        presentRemoteFailure(error, operation: .push)
                        return
                    }
                    eventHandler(.log(.pushRetryFailure(retryAttempt: retryAttempt.attempt)))
                }
            }

            if await runNetworkFallback(command.project, command.request.projectPath, setStatus) {
                eventHandler(.log(.pushSuccess(retryAttempt: nil)))
                applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: true))
                return
            }

            applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false))
            showNetworkErrorFallback()
        }
    }

    func showNetworkErrorFallback() {
        let selection = showNetworkFallbackSelection(CommitRemoteSyncRules.networkFallbackAlertText())
        CommitRemoteSyncRules.performNetworkFallbackSelectionState(
            CommitRemoteSyncRules.networkFallbackSelectionState(
                selection: selection,
                remoteURL: currentRemoteAccess().sshRemoteURL,
                fallbackErrorMessage: CommitRemoteSyncRules.fallbackErrorDescription()
            ),
            performRetry: performRetryAction,
            showSSHHelp: applySSHHelpState
        )
    }

    func presentRemoteFailure(_ error: Error, operation: CommitRemoteSyncRules.RetryOperation) {
        let remoteAccess = currentRemoteAccess()
        CommitRemoteSyncRules.performRemoteFailurePresentation(
            CommitRemoteSyncRules.remoteFailurePresentation(
                errorDescription: error.localizedDescription,
                isCredentialError: CommitRemoteSyncRules.isCredentialError(
                    kind: pushErrorClassification(error).isAuthenticationError ? .authentication : .other,
                    description: error.localizedDescription
                ),
                credentialHost: remoteAccess.credentialHost,
                sshRemoteURL: remoteAccess.sshRemoteURL,
                operation: operation
            ),
            showCredentialPrompt: applyCredentialPromptState,
            showSSHHelp: applySSHHelpState,
            showAlert: {
                eventHandler(.showError(error))
            }
        )
    }
}

private extension WorkingStateHostView {
    func performRefreshAction(_ action: CommitRemoteSyncRules.WorkingStateRefreshAction) {
        CommitRemoteSyncRules.performWorkingStateRefreshAction(
            action,
            refreshChangedFiles: {
                Task {
                    await self.loadChangedFileCount()
                }
            },
            refreshSyncStatus: loadSyncStatus
        )
    }

    func onAppear() {
        CommitRemoteSyncRules.performWorkingStateAppear(
            performRefreshAction: performRefreshAction,
            startTimer: startRemoteStatusTimer
        )
    }

    func onDisappear() {
        CommitRemoteSyncRules.performWorkingStateDisappear(stopTimer: stopRemoteStatusTimer)
    }

    func startRemoteStatusTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(
            every: CommitRemoteSyncRules.remoteStatusRefreshInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { _ in
            eventHandler(.log(.timerFired))
            loadSyncStatus()
        }
        eventHandler(.log(.timerStarted(interval: CommitRemoteSyncRules.remoteStatusRefreshInterval)))
    }

    func stopRemoteStatusTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        eventHandler(.log(.timerStopped))
    }

    func onTap() {
        CommitRemoteSyncRules.performWorkingStateTap(
            currentCommit: selectedCommit,
            setCommit: setSelectedCommit,
            performRefreshAction: performRefreshAction
        )
    }

    func onProjectDidCommit() {
        CommitRemoteSyncRules.performProjectDidCommit(performRefreshAction: performRefreshAction)
    }

    func onProjectDidChange() {
        CommitRemoteSyncRules.performProjectDidChange(performRefreshAction: performRefreshAction)
    }

    func onProjectDidPush() {
        CommitRemoteSyncRules.performProjectDidPush(performRefreshAction: performRefreshAction)
    }

    func onProjectDidPull() {
        CommitRemoteSyncRules.performProjectDidPull(performRefreshAction: performRefreshAction)
    }

    func onGitDirectoryDidChange() {
        guard let gitDirectoryEventProjectPath else {
            return
        }

        CommitRemoteSyncRules.performGitDirectoryChangedWorkingStateEvent(
            eventProjectPath: gitDirectoryEventProjectPath,
            currentProject: project,
            currentProjectPath: projectPath,
            didHeadChange: gitDirectoryDidHeadChange,
            performRefreshAction: performRefreshAction
        )
    }

    func onAppDidBecomeActive() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: CommitRemoteSyncRules.appActivationRefreshDelayNanoseconds)
            performRefreshAction(CommitRemoteSyncRules.refreshAction(for: .appDidBecomeActive))
        }
    }
}
