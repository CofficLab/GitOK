import Combine
import GitCoreKit
import GitOKCoreKit
import ProjectRulesKit
import SwiftUI

public enum WorkingStateHostLogEvent {
    case missingProject
    case changedFileCountFailure(Error)
    case syncStatusLoad(projectPath: String)
    case unpushedCountFailure(Error)
    case unpulledCountFailure(Error)
    case remoteTrackingFailure(Error)
    case syncStatusUpdated(unpushedCount: Int, unpulledCount: Int)
    case fetchStart(projectPath: String)
    case fetchSuccess
    case fetchFailure(Error)
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
    private let externalActivityStatus: String?
    private let setSelectedCommit: @MainActor (Commit?) -> Void
    private let setActivityStatus: @MainActor (String?) -> Void
    private let updateCleanState: @MainActor (Bool) -> Void
    private let projectPath: @MainActor (Project) -> String
    private let loadChangedFileCount: (Project) async throws -> Int
    private let loadUnpushedCount: (Project) async throws -> Int
    private let loadUnpulledCount: (Project) async throws -> Int
    private let loadRemoteTrackingStatus: (Project) async throws -> GitOKRemoteTrackingStatus
    private let updateRemoteTrackingStatus: @MainActor (GitOKRemoteTrackingStatus?, Date?) -> Void
    private let fetch: (Project) async throws -> Void
    private let pull: (Project) async throws -> Void
    private let push: (Project) async throws -> Void
    private let stashSave: (Project) async throws -> Void
    private let loadConflictState: (Project) async throws -> WorkingStateConflictState
    private let stageConflictFile: (Project, String) async throws -> Void
    private let useConflictFileVersion: (Project, String, GitMergeFileVersion) async throws -> Void
    private let continueMerge: (Project) async throws -> Void
    private let abortMerge: (Project) async throws -> Void
    private let openConflictFile: @MainActor (Project, String) -> Void
    private let revealConflictFile: @MainActor (Project, String) -> Void
    private let pushErrorClassification: @MainActor (Error) -> CommitRemoteSyncRules.PushErrorClassification
    private let runNetworkFallback: @MainActor (Project, String, @escaping (String?) -> Void) async -> Bool
    private let currentRemoteAccess: @MainActor () async -> CommitRemoteSyncRules.RemoteAccess
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
    @State private var remoteTrackingStatus = GitOKRemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
    @State private var activityStatus: String?
    @State private var isSyncLoading = false
    @State private var timerCancellable: AnyCancellable?
    @State private var isFetching = false
    @State private var isPulling = false
    @State private var isPushing = false
    @State private var conflictState: WorkingStateConflictState?
    @State private var isConflictActionRunning = false
    @State private var activeConflictPath: String?
    @State private var showCredentialInput = false
    @State private var credentialHost = CommitRemoteSyncRules.defaultCredentialHost
    @State private var credentialRetryOperation: CommitRemoteSyncRules.RetryOperation?
    @State private var showSSHHelp = false
    @State private var sshHelpRemoteURL: String?
    @State private var sshHelpErrorMessage: String?
    @State private var sshHelpRetryOperation: CommitRemoteSyncRules.RetryOperation?
    @State private var showPullBlockedByLocalChanges = false
    @State private var pullBlockedMessage = ""
    @State private var changedFileCountTask: Task<Void, Never>?
    @State private var syncStatusTask: Task<Void, Never>?
    @State private var conflictRefreshTask: Task<Void, Never>?
    @State private var statusClearTask: Task<Void, Never>?

    public init(
        project: Project?,
        selectedCommit: Commit?,
        isRefreshing: Binding<Bool> = .constant(false),
        externalActivityStatus: String? = nil,
        setSelectedCommit: @MainActor @escaping (Commit?) -> Void,
        setActivityStatus: @MainActor @escaping (String?) -> Void,
        updateCleanState: @MainActor @escaping (Bool) -> Void,
        projectPath: @MainActor @escaping (Project) -> String,
        loadChangedFileCount: @escaping (Project) async throws -> Int,
        loadUnpushedCount: @escaping (Project) async throws -> Int,
        loadUnpulledCount: @escaping (Project) async throws -> Int,
        loadRemoteTrackingStatus: @escaping (Project) async throws -> GitOKRemoteTrackingStatus,
        updateRemoteTrackingStatus: @MainActor @escaping (GitOKRemoteTrackingStatus?, Date?) -> Void = { _, _ in },
        fetch: @escaping (Project) async throws -> Void,
        pull: @escaping (Project) async throws -> Void,
        push: @escaping (Project) async throws -> Void,
        stashSave: @escaping (Project) async throws -> Void = { _ in },
        loadConflictState: @escaping (Project) async throws -> WorkingStateConflictState = { _ in .inactive },
        stageConflictFile: @escaping (Project, String) async throws -> Void = { _, _ in },
        useConflictFileVersion: @escaping (Project, String, GitMergeFileVersion) async throws -> Void = { _, _, _ in },
        continueMerge: @escaping (Project) async throws -> Void = { _ in },
        abortMerge: @escaping (Project) async throws -> Void = { _ in },
        openConflictFile: @MainActor @escaping (Project, String) -> Void = { _, _ in },
        revealConflictFile: @MainActor @escaping (Project, String) -> Void = { _, _ in },
        pushErrorClassification: @MainActor @escaping (Error) -> CommitRemoteSyncRules.PushErrorClassification,
        runNetworkFallback: @MainActor @escaping (Project, String, @escaping (String?) -> Void) async -> Bool,
        currentRemoteAccess: @MainActor @escaping () async -> CommitRemoteSyncRules.RemoteAccess,
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
        self.externalActivityStatus = externalActivityStatus
        self.setSelectedCommit = setSelectedCommit
        self.setActivityStatus = setActivityStatus
        self.updateCleanState = updateCleanState
        self.projectPath = projectPath
        self.loadChangedFileCount = loadChangedFileCount
        self.loadUnpushedCount = loadUnpushedCount
        self.loadUnpulledCount = loadUnpulledCount
        self.loadRemoteTrackingStatus = loadRemoteTrackingStatus
        self.updateRemoteTrackingStatus = updateRemoteTrackingStatus
        self.fetch = fetch
        self.pull = pull
        self.push = push
        self.stashSave = stashSave
        self.loadConflictState = loadConflictState
        self.stageConflictFile = stageConflictFile
        self.useConflictFileVersion = useConflictFileVersion
        self.continueMerge = continueMerge
        self.abortMerge = abortMerge
        self.openConflictFile = openConflictFile
        self.revealConflictFile = revealConflictFile
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
            activityStatus: displayActivityStatus,
            trackingStatus: remoteTrackingStatus,
            isSyncWorking: isSyncLoading || isFetching || isPulling || isPushing,
            conflictState: conflictState,
            isConflictActionRunning: isConflictActionRunning,
            activeConflictPath: activeConflictPath,
            showCredentialInput: $showCredentialInput,
            showSSHHelp: $showSSHHelp,
            showPullBlockedByLocalChanges: $showPullBlockedByLocalChanges,
            pullBlockedMessage: pullBlockedMessage,
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
            onFetch: performFetch,
            onPull: performPull,
            onPush: performPush,
            onStashAndPull: performStashAndPull,
            onOpenConflictFile: performOpenConflictFile,
            onRevealConflictFile: performRevealConflictFile,
            onStageConflictFile: performStageConflictFile,
            onUseOursConflictFile: { path in performUseConflictVersion(.ours, path: path) },
            onUseTheirsConflictFile: { path in performUseConflictVersion(.theirs, path: path) },
            onContinueMerge: performContinueMerge,
            onAbortMerge: performAbortMerge,
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

fileprivate enum WorkingStateBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

private extension WorkingStateHostView {
    var displayActivityStatus: String? {
        if let activityStatus {
            return activityStatus
        }

        if let externalActivityStatus {
            return externalActivityStatus
        }

        if isPushing {
            return CommitRemoteSyncRules.activityStatus(.pushing)
        }

        if isPulling {
            return CommitRemoteSyncRules.activityStatus(.pulling)
        }

        if isFetching {
            return CommitLocalization.string("Fetching")
        }

        if isSyncLoading {
            return CommitRemoteSyncRules.activityStatus(.checkingRemoteStatus)
        }

        if isRefreshingFileList {
            return CommitRemoteSyncRules.activityStatus(.refreshingFiles)
        }

        return nil
    }

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
            setStatus: setStatus,
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
        guard let loadedProject = project else {
            eventHandler(.log(.missingProject))
            return
        }

        nonisolated(unsafe) let project = loadedProject
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

    func scheduleChangedFileCountRefresh() {
        changedFileCountTask?.cancel()
        changedFileCountTask = Task { @MainActor in
            await loadChangedFileCount()
            changedFileCountTask = nil
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
        let projectTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: command.project)
        let loadUnpushedCountTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: loadUnpushedCount)
        let loadUnpulledCountTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: loadUnpulledCount)
        let loadRemoteTrackingStatusTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: loadRemoteTrackingStatus)
        let eventHandlerTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: eventHandler)
        let updateRemoteTrackingStatusTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: updateRemoteTrackingStatus)

        syncStatusTask?.cancel()
        syncStatusTask = Task.detached(priority: .userInitiated) {
            await MainActor.run {
                applySyncStatusRefreshState(CommitRemoteSyncRules.syncStatusRefreshStartState())
            }
            guard Task.isCancelled == false else { return }

            let unpushedCount: Int
            do {
                unpushedCount = try await loadUnpushedCountTransfer.value(projectTransfer.value)
            } catch {
                unpushedCount = 0
                await MainActor.run {
                    eventHandlerTransfer.value(.log(.unpushedCountFailure(error)))
                }
            }
            guard Task.isCancelled == false else { return }

            let unpulledCount: Int
            do {
                unpulledCount = try await loadUnpulledCountTransfer.value(projectTransfer.value)
            } catch {
                unpulledCount = 0
                await MainActor.run {
                    eventHandlerTransfer.value(.log(.unpulledCountFailure(error)))
                }
            }
            guard Task.isCancelled == false else { return }

            let nextTrackingStatus: GitOKRemoteTrackingStatus
            let trackingFetchedAt = Date()
            do {
                nextTrackingStatus = try await loadRemoteTrackingStatusTransfer.value(projectTransfer.value)
            } catch {
                nextTrackingStatus = GitOKRemoteTrackingStatus(
                    ahead: unpushedCount,
                    behind: unpulledCount,
                    hasUpstream: unpushedCount > 0 || unpulledCount > 0
                )
                await MainActor.run {
                    eventHandlerTransfer.value(.log(.remoteTrackingFailure(error)))
                }
            }
            guard Task.isCancelled == false else { return }

            let resultState = CommitRemoteSyncRules.syncStatusResultState(
                unpushedCount: unpushedCount,
                unpulledCount: unpulledCount
            )
            await MainActor.run {
                guard Task.isCancelled == false else { return }
                remoteTrackingStatus = nextTrackingStatus
                updateRemoteTrackingStatusTransfer.value(nextTrackingStatus, trackingFetchedAt)
                CommitRemoteSyncRules.performSyncStatusResultState(
                    resultState,
                    setUnpushedCount: { self.unpushedCount = $0 },
                    setUnpulledCount: { self.unpulledCount = $0 },
                    applyRefreshState: self.applySyncStatusRefreshState
                )
                eventHandlerTransfer.value(.log(.syncStatusUpdated(
                    unpushedCount: resultState.unpushedCount,
                    unpulledCount: resultState.unpulledCount
                )))
                syncStatusTask = nil
            }
            await MainActor.run {
                statusClearTask?.cancel()
                statusClearTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: CommitRemoteSyncRules.statusClearDelayNanoseconds)
                    guard Task.isCancelled == false else { return }
                    setStatus(nil)
                    statusClearTask = nil
                }
            }
        }
    }

    func setStatus(_ text: String?) {
        Task { @MainActor in
            activityStatus = text
            setActivityStatus(text)
        }
    }

    func performFetch() {
        CommitRemoteSyncRules.performRequiredProjectSyncStatusCommand(
            project: project,
            projectPath: projectPath,
            logMissing: {
                eventHandler(.log(.missingProject))
            }
        ) { command in
            performFetch(command)
        }
    }

    func performFetch(_ command: CommitRemoteSyncRules.ProjectSyncStatusRequest<Project>) {
        eventHandler(.log(.fetchStart(projectPath: command.request.projectPath)))
        let projectTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: command.project)
        let commandTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: command)
        let fetchTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: fetch)
        let eventHandlerTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: eventHandler)

        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                isFetching = true
                setStatus(CommitLocalization.string("Fetching"))
            }

            do {
                try await fetchTransfer.value(projectTransfer.value)
                await MainActor.run {
                    eventHandlerTransfer.value(.log(.fetchSuccess))
                    isFetching = false
                    loadSyncStatus(commandTransfer.value)
                }
            } catch {
                await MainActor.run {
                    eventHandlerTransfer.value(.log(.fetchFailure(error)))
                    isFetching = false
                    setStatus(nil)
                    eventHandlerTransfer.value(.showError(error))
                }
            }
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

        let projectTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: command.project)
        let commandTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: command)
        let pullTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: pull)
        let eventHandlerTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: eventHandler)

        Task.detached(priority: .userInitiated) {
            let command = commandTransfer.value
            let project = projectTransfer.value
            let operation = command.request.operation
            await MainActor.run {
                applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationStartState(operation: operation))
            }

            switch operation {
            case .pull:
                do {
                    try await pullTransfer.value(project)
                    await MainActor.run {
                        eventHandlerTransfer.value(.log(.pullSuccess))
                        applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .pull, succeeded: true))
                    }
                } catch {
                    Task { @MainActor in
                        await finishPullFailure(error, project: project)
                    }
                }
            case .push:
                Task { @MainActor in
                    await performPushOperation(command)
                }
            }
        }
    }

    @MainActor
    func finishPullFailure(_ error: Error, project: Project) async {
        eventHandler(.log(.pullFailure(error)))
        applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .pull, succeeded: false))
        if await refreshConflictState(for: project), conflictState?.isMerging == true {
            setStatus(nil)
            return
        }
        if GitOperationError.isLocalChangesWouldBeOverwritten(error) {
            pullBlockedMessage = pullBlockedAlertMessage(for: error)
            showPullBlockedByLocalChanges = true
            setStatus(nil)
            return
        }
        await presentRemoteFailure(error, operation: .pull)
    }

    func pullBlockedAlertMessage(for error: Error) -> String {
        let localizedError = error as? LocalizedError
        return [localizedError?.errorDescription, localizedError?.recoverySuggestion]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: "\n\n")
    }

    func performStashAndPull() {
        guard let project else { return }
        showPullBlockedByLocalChanges = false

        Task {
            do {
                try await stashSave(project)
                scheduleChangedFileCountRefresh()
                performPull()
            } catch {
                eventHandler(.showError(error))
            }
        }
    }

    func performPushOperation(_ command: CommitRemoteSyncRules.ProjectRemoteOperationCommand<Project>) async {
        nonisolated(unsafe) let project = command.project

        do {
            try await push(project)
            eventHandler(.log(.pushSuccess(retryAttempt: nil)))
            applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: true))
            return
        } catch {
            let classification = pushErrorClassification(error)
            guard classification.isNetworkError else {
                applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false))
                await presentRemoteFailure(error, operation: .push)
                return
            }

            eventHandler(.log(.pushRetryStart))
            for retryAttempt in CommitRemoteSyncRules.pushRetryAttempts() {
                setStatus(retryAttempt.statusText)
                try? await Task.sleep(nanoseconds: retryAttempt.delayNanoseconds)

                do {
                    try await push(project)
                    eventHandler(.log(.pushSuccess(retryAttempt: retryAttempt.attempt)))
                    applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: true))
                    return
                } catch {
                    guard pushErrorClassification(error).isRetryablePushError else {
                        applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false))
                        await presentRemoteFailure(error, operation: .push)
                        return
                    }
                    eventHandler(.log(.pushRetryFailure(retryAttempt: retryAttempt.attempt)))
                }
            }

            if await runNetworkFallback(project, command.request.projectPath, setStatus) {
                eventHandler(.log(.pushSuccess(retryAttempt: nil)))
                applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: true))
                return
            }

            applyRemoteOperationState(CommitRemoteSyncRules.remoteOperationFinishedState(operation: .push, succeeded: false))
            await showNetworkErrorFallback()
        }
    }

    func showNetworkErrorFallback() async {
        let selection = showNetworkFallbackSelection(CommitRemoteSyncRules.networkFallbackAlertText())
        let remoteAccess = await currentRemoteAccess()
        CommitRemoteSyncRules.performNetworkFallbackSelectionState(
            CommitRemoteSyncRules.networkFallbackSelectionState(
                selection: selection,
                remoteURL: remoteAccess.sshRemoteURL,
                fallbackErrorMessage: CommitRemoteSyncRules.fallbackErrorDescription()
            ),
            performRetry: performRetryAction,
            showSSHHelp: applySSHHelpState
        )
    }

    func presentRemoteFailure(_ error: Error, operation: CommitRemoteSyncRules.RetryOperation) async {
        let remoteAccess = await currentRemoteAccess()
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

    @discardableResult
    func refreshConflictState(for project: Project) async -> Bool {
        nonisolated(unsafe) let project = project

        do {
            let state = try await loadConflictState(project)
            conflictState = state.isMerging ? state : nil
            return true
        } catch {
            conflictState = nil
            return false
        }
    }

    func refreshConflictStateForCurrentProject() {
        guard let project else { return }
        conflictRefreshTask?.cancel()
        conflictRefreshTask = Task { @MainActor in
            _ = await refreshConflictState(for: project)
            conflictRefreshTask = nil
        }
    }

    func performOpenConflictFile(_ path: String) {
        guard let project else { return }
        openConflictFile(project, path)
    }

    func performRevealConflictFile(_ path: String) {
        guard let project else { return }
        revealConflictFile(project, path)
    }

    func performStageConflictFile(_ path: String) {
        performConflictAction(path: path) { project in
            nonisolated(unsafe) let project = project
            try await stageConflictFile(project, path)
        }
    }

    func performUseConflictVersion(_ version: GitMergeFileVersion, path: String) {
        performConflictAction(path: path) { project in
            nonisolated(unsafe) let project = project
            try await useConflictFileVersion(project, path, version)
        }
    }

    func performContinueMerge() {
        performConflictAction(path: nil) { project in
            nonisolated(unsafe) let project = project
            try await continueMerge(project)
        }
    }

    func performAbortMerge() {
        performConflictAction(path: nil) { project in
            nonisolated(unsafe) let project = project
            try await abortMerge(project)
        }
    }

    func performConflictAction(
        path: String?,
        action: @escaping (Project) async throws -> Void
    ) {
        guard let project, isConflictActionRunning == false else { return }
        isConflictActionRunning = true
        activeConflictPath = path
        let projectTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: project)
        let actionTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: action)
        let eventHandlerTransfer = WorkingStateBackgroundRunner.UnsafeTransfer(value: eventHandler)

        Task.detached(priority: .userInitiated) {
            do {
                try await actionTransfer.value(projectTransfer.value)
                Task { @MainActor in
                    isConflictActionRunning = false
                    activeConflictPath = nil
                    _ = await refreshConflictState(for: projectTransfer.value)
                    scheduleChangedFileCountRefresh()
                }
            } catch {
                Task { @MainActor in
                    isConflictActionRunning = false
                    activeConflictPath = nil
                    eventHandlerTransfer.value(.showError(error))
                    _ = await refreshConflictState(for: projectTransfer.value)
                }
            }
        }
    }
}

private extension WorkingStateHostView {
    func performRefreshAction(_ action: CommitRemoteSyncRules.WorkingStateRefreshAction) {
        CommitRemoteSyncRules.performWorkingStateRefreshAction(
            action,
            refreshChangedFiles: {
                scheduleChangedFileCountRefresh()
            },
            refreshSyncStatus: loadSyncStatus
        )
    }

    func onAppear() {
        CommitRemoteSyncRules.performWorkingStateAppear(
            performRefreshAction: performRefreshAction,
            startTimer: startRemoteStatusTimer
        )
        refreshConflictStateForCurrentProject()
    }

    func onDisappear() {
        CommitRemoteSyncRules.performWorkingStateDisappear(stopTimer: stopRemoteStatusTimer)
        cancelRefreshTasks()
        clearTransientState()
    }

    func cancelRefreshTasks() {
        changedFileCountTask?.cancel()
        syncStatusTask?.cancel()
        conflictRefreshTask?.cancel()
        statusClearTask?.cancel()
        changedFileCountTask = nil
        syncStatusTask = nil
        conflictRefreshTask = nil
        statusClearTask = nil
    }

    func clearTransientState() {
        isRefreshingFileList = false
        isSyncLoading = false
        activityStatus = nil
        setActivityStatus(nil)
        conflictState = nil
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
        refreshConflictStateForCurrentProject()
    }

    func onProjectDidChange() {
        CommitRemoteSyncRules.performProjectDidChange(performRefreshAction: performRefreshAction)
        refreshConflictStateForCurrentProject()
    }

    func onProjectDidPush() {
        CommitRemoteSyncRules.performProjectDidPush(performRefreshAction: performRefreshAction)
        refreshConflictStateForCurrentProject()
    }

    func onProjectDidPull() {
        CommitRemoteSyncRules.performProjectDidPull(performRefreshAction: performRefreshAction)
        refreshConflictStateForCurrentProject()
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
        refreshConflictStateForCurrentProject()
    }

    func onAppDidBecomeActive() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: CommitRemoteSyncRules.appActivationRefreshDelayNanoseconds)
            performRefreshAction(CommitRemoteSyncRules.refreshAction(for: .appDidBecomeActive))
            refreshConflictStateForCurrentProject()
        }
    }
}
