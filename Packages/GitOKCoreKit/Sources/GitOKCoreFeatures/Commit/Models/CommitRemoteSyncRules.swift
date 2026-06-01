import Foundation

public enum CommitRemoteSyncRules {
    public enum Activity {
        case refreshingFiles
        case checkingRemoteStatus
        case pulling
        case pushing
        case pushingViaSystemGit
    }

    public enum RetryOperation: Equatable, Sendable {
        case pull
        case push
    }

    public enum RetryPrompt: Equatable, Sendable {
        case credential
        case sshHelp
    }

    public struct RetryAction: Equatable, Sendable {
        public let operation: RetryOperation
        public let delayNanoseconds: UInt64

        public init(operation: RetryOperation, delayNanoseconds: UInt64) {
            self.operation = operation
            self.delayNanoseconds = delayNanoseconds
        }
    }

    public struct ChangedFileRefreshState: Equatable, Sendable {
        public let statusText: String?
        public let isRefreshing: Bool

        public init(statusText: String?, isRefreshing: Bool) {
            self.statusText = statusText
            self.isRefreshing = isRefreshing
        }
    }

    public struct ProjectChangedFileCountLoadRequest<Project> {
        public let project: Project

        public init(project: Project) {
            self.project = project
        }
    }

    public struct RemoteOperationState: Equatable, Sendable {
        public let statusText: String?
        public let isPulling: Bool
        public let isPushing: Bool
        public let refreshesSyncStatus: Bool

        public init(statusText: String?, isPulling: Bool, isPushing: Bool, refreshesSyncStatus: Bool) {
            self.statusText = statusText
            self.isPulling = isPulling
            self.isPushing = isPushing
            self.refreshesSyncStatus = refreshesSyncStatus
        }
    }

    public struct SyncStatusRefreshState: Equatable, Sendable {
        public let statusText: String?
        public let isSyncLoading: Bool

        public init(statusText: String?, isSyncLoading: Bool) {
            self.statusText = statusText
            self.isSyncLoading = isSyncLoading
        }
    }

    public struct SyncStatusResultState: Equatable, Sendable {
        public let unpushedCount: Int
        public let unpulledCount: Int
        public let refreshState: SyncStatusRefreshState

        public init(unpushedCount: Int, unpulledCount: Int, refreshState: SyncStatusRefreshState) {
            self.unpushedCount = unpushedCount
            self.unpulledCount = unpulledCount
            self.refreshState = refreshState
        }
    }

    public struct SyncStatusRequest: Equatable, Sendable {
        public let projectPath: String

        public init(projectPath: String) {
            self.projectPath = projectPath
        }
    }

    public struct ProjectSyncStatusRequest<Project> {
        public let request: SyncStatusRequest
        public let project: Project

        public init(request: SyncStatusRequest, project: Project) {
            self.request = request
            self.project = project
        }
    }

    public struct SyncStatusLoadHandlers<Commit> {
        public let loadUnpushedCommits: () async throws -> [Commit]
        public let loadUnpulledCount: () async throws -> Int

        public init(
            loadUnpushedCommits: @escaping () async throws -> [Commit],
            loadUnpulledCount: @escaping () async throws -> Int
        ) {
            self.loadUnpushedCommits = loadUnpushedCommits
            self.loadUnpulledCount = loadUnpulledCount
        }
    }

    public struct ProjectSyncStatusLoadHandlers<Project, Commit> {
        public let loadUnpushedCommits: (Project) async throws -> [Commit]
        public let loadUnpulledCount: (Project) async throws -> Int

        public init(
            loadUnpushedCommits: @escaping (Project) async throws -> [Commit],
            loadUnpulledCount: @escaping (Project) async throws -> Int
        ) {
            self.loadUnpushedCommits = loadUnpushedCommits
            self.loadUnpulledCount = loadUnpulledCount
        }
    }

    public struct RemoteProjectRequest: Equatable, Sendable {
        public let projectPath: String
        public let operation: RetryOperation

        public init(projectPath: String, operation: RetryOperation) {
            self.projectPath = projectPath
            self.operation = operation
        }
    }

    public struct ProjectRemoteOperationCommand<Project> {
        public let request: RemoteProjectRequest
        public let project: Project

        public init(request: RemoteProjectRequest, project: Project) {
            self.request = request
            self.project = project
        }
    }

    public struct RemoteOperationCommandHandlers {
        public let pull: () async throws -> Void
        public let push: () async throws -> Void
        public let pushErrorClassification: (Error) -> PushErrorClassification
        public let runNetworkFallback: () async -> Bool

        public init(
            pull: @escaping () async throws -> Void,
            push: @escaping () async throws -> Void,
            pushErrorClassification: @escaping (Error) -> PushErrorClassification,
            runNetworkFallback: @escaping () async -> Bool
        ) {
            self.pull = pull
            self.push = push
            self.pushErrorClassification = pushErrorClassification
            self.runNetworkFallback = runNetworkFallback
        }
    }

    public struct ProjectRemoteOperationCommandHandlers<Project> {
        public let pull: (Project) async throws -> Void
        public let push: (Project) async throws -> Void
        public let pushErrorClassification: (Error) -> PushErrorClassification
        public let runNetworkFallback: (Project, String) async -> Bool

        public init(
            pull: @escaping (Project) async throws -> Void,
            push: @escaping (Project) async throws -> Void,
            pushErrorClassification: @escaping (Error) -> PushErrorClassification,
            runNetworkFallback: @escaping (Project, String) async -> Bool
        ) {
            self.pull = pull
            self.push = push
            self.pushErrorClassification = pushErrorClassification
            self.runNetworkFallback = runNetworkFallback
        }
    }

    public struct CredentialPromptState: Equatable, Sendable {
        public let showsPrompt: Bool
        public let host: String
        public let retryOperation: RetryOperation?

        public init(showsPrompt: Bool, host: String, retryOperation: RetryOperation?) {
            self.showsPrompt = showsPrompt
            self.host = host
            self.retryOperation = retryOperation
        }
    }

    public struct SSHHelpState: Equatable, Sendable {
        public let showsPrompt: Bool
        public let remoteURL: String?
        public let errorMessage: String?
        public let retryOperation: RetryOperation?

        public init(
            showsPrompt: Bool,
            remoteURL: String?,
            errorMessage: String?,
            retryOperation: RetryOperation?
        ) {
            self.showsPrompt = showsPrompt
            self.remoteURL = remoteURL
            self.errorMessage = errorMessage
            self.retryOperation = retryOperation
        }
    }

    public struct RetryPromptDismissState: Equatable, Sendable {
        public let showsPrompt: Bool
        public let retryAction: RetryAction?

        public init(showsPrompt: Bool, retryAction: RetryAction?) {
            self.showsPrompt = showsPrompt
            self.retryAction = retryAction
        }
    }

    public struct RetryPromptApplicationState: Equatable, Sendable {
        public let showsCredentialPrompt: Bool?
        public let showsSSHHelp: Bool?
        public let retryAction: RetryAction?

        public init(
            showsCredentialPrompt: Bool?,
            showsSSHHelp: Bool?,
            retryAction: RetryAction?
        ) {
            self.showsCredentialPrompt = showsCredentialPrompt
            self.showsSSHHelp = showsSSHHelp
            self.retryAction = retryAction
        }
    }

    public struct PushRetryAttempt: Equatable, Sendable {
        public let attempt: Int
        public let totalAttempts: Int
        public let delayNanoseconds: UInt64
        public let statusText: String

        public init(attempt: Int, totalAttempts: Int, delayNanoseconds: UInt64, statusText: String) {
            self.attempt = attempt
            self.totalAttempts = totalAttempts
            self.delayNanoseconds = delayNanoseconds
            self.statusText = statusText
        }
    }

    public struct PushErrorClassification: Equatable, Sendable {
        public let isNetworkError: Bool
        public let isAuthenticationError: Bool
        public let isRetryablePushError: Bool

        public init(isNetworkError: Bool, isAuthenticationError: Bool, isRetryablePushError: Bool) {
            self.isNetworkError = isNetworkError
            self.isAuthenticationError = isAuthenticationError
            self.isRetryablePushError = isRetryablePushError
        }
    }

    public enum PushNetworkFallbackAction: Equatable, Sendable {
        case systemGit(statusText: String)
        case showFallback
    }

    public enum NetworkFallbackSelection: Equatable, Sendable {
        case retry
        case toggleSSH
        case cancel
    }

    public enum RemoteFailurePresentation: Equatable, Sendable {
        case credential(CredentialPromptState)
        case sshHelp(SSHHelpState)
        case alert
    }

    public enum RemoteErrorKind: Equatable, Sendable {
        case network
        case authentication
        case known
        case other
    }

    public enum WorkingStateTrailingAction: Equatable, Sendable {
        case refreshing
        case pull
        case push
        case none
    }

    public struct WorkingStatePresentationState: Equatable, Sendable {
        public let changedFileCount: Int
        public let unpulledCount: Int
        public let isSelected: Bool
        public let isPulling: Bool
        public let isPushing: Bool
        public let trailingAction: WorkingStateTrailingAction

        public init(
            changedFileCount: Int,
            unpulledCount: Int,
            isSelected: Bool,
            isPulling: Bool,
            isPushing: Bool,
            trailingAction: WorkingStateTrailingAction
        ) {
            self.changedFileCount = changedFileCount
            self.unpulledCount = unpulledCount
            self.isSelected = isSelected
            self.isPulling = isPulling
            self.isPushing = isPushing
            self.trailingAction = trailingAction
        }
    }

    public struct WorkingStateRefreshAction: Equatable, Sendable {
        public let refreshChangedFiles: Bool
        public let refreshSyncStatus: Bool

        public init(refreshChangedFiles: Bool, refreshSyncStatus: Bool) {
            self.refreshChangedFiles = refreshChangedFiles
            self.refreshSyncStatus = refreshSyncStatus
        }

        public static let none = WorkingStateRefreshAction(refreshChangedFiles: false, refreshSyncStatus: false)
        public static let changedFilesOnly = WorkingStateRefreshAction(refreshChangedFiles: true, refreshSyncStatus: false)
        public static let syncStatusOnly = WorkingStateRefreshAction(refreshChangedFiles: false, refreshSyncStatus: true)
        public static let full = WorkingStateRefreshAction(refreshChangedFiles: true, refreshSyncStatus: true)
    }

    public enum WorkingStateEvent: Equatable, Sendable {
        case appear
        case tap
        case projectChanged
        case projectDidCommit
        case projectDidPush
        case projectDidPull
        case gitDirectoryChanged(eventProjectPath: String, currentProjectPath: String?, didHeadChange: Bool)
        case appDidBecomeActive
    }

    public struct RemoteURLs: Equatable, Sendable {
        public let name: String
        public let url: String?
        public let fetchURL: String?
        public let pushURL: String?

        public init(name: String, url: String?, fetchURL: String?, pushURL: String?) {
            self.name = name
            self.url = url
            self.fetchURL = fetchURL
            self.pushURL = pushURL
        }
    }

    public struct RemoteAccess: Equatable, Sendable {
        public let credentialHost: String?
        public let sshRemoteURL: String?

        public init(credentialHost: String?, sshRemoteURL: String?) {
            self.credentialHost = credentialHost
            self.sshRemoteURL = sshRemoteURL
        }

        public static let empty = RemoteAccess(credentialHost: nil, sshRemoteURL: nil)
    }

    public struct NetworkFallbackAlertText: Equatable, Sendable {
        public let title: String
        public let message: String
        public let retryButtonTitle: String
        public let toggleSSHPushButtonTitle: String
        public let cancelButtonTitle: String

        public init(
            title: String,
            message: String,
            retryButtonTitle: String,
            toggleSSHPushButtonTitle: String,
            cancelButtonTitle: String
        ) {
            self.title = title
            self.message = message
            self.retryButtonTitle = retryButtonTitle
            self.toggleSSHPushButtonTitle = toggleSSHPushButtonTitle
            self.cancelButtonTitle = cancelButtonTitle
        }
    }

    public struct NetworkFallbackSelectionState: Equatable, Sendable {
        public let retryAction: RetryAction?
        public let sshHelpState: SSHHelpState?

        public init(retryAction: RetryAction?, sshHelpState: SSHHelpState?) {
            self.retryAction = retryAction
            self.sshHelpState = sshHelpState
        }
    }

    public static let pushRetryDelays: [UInt64] = [
        2_000_000_000,
        4_000_000_000,
    ]

    public static let remoteStatusRefreshInterval: TimeInterval = 60
    public static let credentialRetryDelayNanoseconds: UInt64 = 500_000_000
    public static let statusClearDelayNanoseconds: UInt64 = 2_000_000_000
    public static let appActivationRefreshDelayNanoseconds: UInt64 = 500_000_000
    public static let fallbackErrorDomain = "GitOK"
    public static let fallbackErrorCode = -1
    public static let gitHeadChangedEventInfoKey = "headChanged"
    public static let defaultCredentialHost = "github.com"

    public static func missingProjectLogMessage() -> String {
        "No project found"
    }

    public static func changedFileCountFailureLogMessage(errorDescription: String) -> String {
        "❌ Failed to load changed file count: \(errorDescription)"
    }

    public static func syncStatusLoadLogMessage(projectPath: String) -> String {
        "<\(projectPath)>Loading sync status"
    }

    public static func unpushedCountFailureLogMessage(errorDescription: String) -> String {
        "❌ Failed to load unpushed commits count: \(errorDescription)"
    }

    public static func unpulledCountFailureLogMessage(errorDescription: String) -> String {
        "❌ Failed to load unpulled commits count: \(errorDescription)"
    }

    public static func syncStatusUpdatedLogMessage(unpushedCount: Int, unpulledCount: Int) -> String {
        "✅ Sync status updated: unpushed=\(unpushedCount), unpulled=\(unpulledCount)"
    }

    public static func pullOperationLogMessage(projectPath: String) -> String {
        "<\(projectPath)>Performing git pull"
    }

    public static func pullSuccessLogMessage() -> String {
        "✅ Git pull succeeded"
    }

    public static func pullFailureLogMessage(errorDescription: String) -> String {
        "❌ Git pull failed: \(errorDescription)"
    }

    public static func pushOperationLogMessage(projectPath: String) -> String {
        "<\(projectPath)>Performing git push"
    }

    public static func systemGitPushFailureLogMessage(errorDescription: String) -> String {
        "CLI push also failed: \(errorDescription)"
    }

    public static func pushSuccessLogMessage(retryAttempt: Int?) -> String {
        if let retryAttempt {
            return "✅ Git push succeeded after retry \(retryAttempt)"
        }

        return "✅ Git push succeeded"
    }

    public static func pushRetryStartLogMessage() -> String {
        "Network error, starting retry with backoff"
    }

    public static func pushRetryFailureLogMessage(retryAttempt: Int) -> String {
        "Retry \(retryAttempt) failed"
    }

    public static func remoteStatusTimerFiredLogMessage() -> String {
        "⏰ Timer fired, checking remote status"
    }

    public static func remoteStatusTimerStartedLogMessage(interval: TimeInterval) -> String {
        "⏰ Started remote status timer (interval: \(interval)s)"
    }

    public static func remoteStatusTimerStoppedLogMessage() -> String {
        "⏰ Stopped remote status timer"
    }

    public static let credentialErrorKeywords = [
        "authentication",
        "auth",
        "credential",
        "permission",
        "denied",
        "unauthorized",
        "401",
        "403",
        "forbidden",
    ]

    public static func isCredentialErrorDescription(_ description: String) -> Bool {
        let normalizedDescription = description.lowercased()
        return credentialErrorKeywords.contains { normalizedDescription.contains($0) }
    }

    public static func isCredentialError(
        _ error: Error,
        isAuthenticationError: (Error) -> Bool
    ) -> Bool {
        isAuthenticationError(error) || isCredentialErrorDescription(error.localizedDescription)
    }

    public static func isCredentialError(
        kind: RemoteErrorKind,
        description: String
    ) -> Bool {
        kind == .authentication || isCredentialErrorDescription(description)
    }

    public static func isSSHAuthenticationErrorDescription(_ description: String) -> Bool {
        let cloneFailureDescription = CloneRepositoryValidation.cloneFailureDescription(from: description)
        return cloneFailureDescription.kind == .sshAuthentication ||
            cloneFailureDescription.kind == .sshHostKey
    }

    public static func retryStatus(attempt: Int, totalAttempts: Int) -> String {
        String(localized: "Network fluctuation, retrying (\(attempt)/\(totalAttempts))…", table: "GitCommit")
    }

    public static func pushRetryAttempts(delays: [UInt64] = pushRetryDelays) -> [PushRetryAttempt] {
        delays.enumerated().map { index, delay in
            let attempt = index + 1
            return PushRetryAttempt(
                attempt: attempt,
                totalAttempts: delays.count,
                delayNanoseconds: delay,
                statusText: retryStatus(attempt: attempt, totalAttempts: delays.count)
            )
        }
    }

    public static func pushErrorClassification(
        error: Error,
        isNetworkError: (Error) -> Bool,
        isAuthenticationError: (Error) -> Bool,
        isKnownPushError: (Error) -> Bool
    ) -> PushErrorClassification {
        PushErrorClassification(
            isNetworkError: isNetworkError(error),
            isAuthenticationError: isAuthenticationError(error),
            isRetryablePushError: isKnownPushError(error)
        )
    }

    public static func remoteErrorKind(
        isNetworkError: Bool,
        isAuthenticationError: Bool,
        isKnownError: Bool
    ) -> RemoteErrorKind {
        if isNetworkError {
            return .network
        }

        if isAuthenticationError {
            return .authentication
        }

        if isKnownError {
            return .known
        }

        return .other
    }

    public static func pushErrorClassification(kind: RemoteErrorKind) -> PushErrorClassification {
        PushErrorClassification(
            isNetworkError: kind == .network,
            isAuthenticationError: kind == .authentication,
            isRetryablePushError: kind == .network || kind == .authentication || kind == .known
        )
    }

    public static func pushNetworkFallbackAction(isGitCLIAvailable: Bool) -> PushNetworkFallbackAction {
        isGitCLIAvailable ? .systemGit(statusText: activityStatus(.pushingViaSystemGit)) : .showFallback
    }

    public static func repositoryURL(projectPath: String) -> URL {
        URL(fileURLWithPath: projectPath)
    }

    public static func performPushNetworkFallbackAction(
        _ action: PushNetworkFallbackAction,
        setStatus: (String) async -> Void,
        runSystemGit: () async throws -> Void,
        onSystemGitFailure: (Error) async -> Void
    ) async -> Bool {
        switch action {
        case let .systemGit(statusText):
            await setStatus(statusText)

            do {
                try await runSystemGit()
                return true
            } catch {
                await onSystemGitFailure(error)
                return false
            }
        case .showFallback:
            return false
        }
    }

    public static func performSystemGitPushFallback(
        isGitCLIAvailable: Bool,
        setStatus: (String) async -> Void,
        runSystemGit: () async throws -> Void,
        onSystemGitFailure: (Error) async -> Void
    ) async -> Bool {
        await performPushNetworkFallbackAction(
            pushNetworkFallbackAction(isGitCLIAvailable: isGitCLIAvailable),
            setStatus: setStatus,
            runSystemGit: runSystemGit,
            onSystemGitFailure: onSystemGitFailure
        )
    }

    public static func fallbackError() -> NSError {
        NSError(domain: fallbackErrorDomain, code: fallbackErrorCode, userInfo: nil)
    }

    public static func fallbackErrorDescription() -> String {
        fallbackError().localizedDescription
    }

    public static func workingStatePresentationState(
        changedFileCount: Int,
        unpulledCount: Int,
        isSelected: Bool,
        isRefreshing: Bool,
        isPulling: Bool,
        isPushing: Bool
    ) -> WorkingStatePresentationState {
        let trailingAction: WorkingStateTrailingAction
        if isRefreshing {
            trailingAction = .refreshing
        } else if changedFileCount == 0 && unpulledCount > 0 {
            trailingAction = .pull
        } else if changedFileCount > 0 && unpulledCount == 0 {
            trailingAction = .push
        } else {
            trailingAction = .none
        }

        return WorkingStatePresentationState(
            changedFileCount: changedFileCount,
            unpulledCount: unpulledCount,
            isSelected: isSelected,
            isPulling: isPulling,
            isPushing: isPushing,
            trailingAction: trailingAction
        )
    }

    public static func isWorkingStateSelected(hasSelectedCommit: Bool) -> Bool {
        hasSelectedCommit == false
    }

    public static func isWorkingStateSelected<Commit>(selectedCommit: Commit?) -> Bool {
        isWorkingStateSelected(hasSelectedCommit: selectedCommit != nil)
    }

    public static func selectedCommitAfterWorkingStateTap<Commit>(current: Commit?) -> Commit? {
        nil
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        logMissing: () -> Void = {},
        perform: (Project) -> Void
    ) -> Bool {
        guard let project else {
            logMissing()
            return false
        }

        perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        logMissing: () async -> Void = {},
        perform: (Project) async -> Void
    ) async -> Bool {
        guard let project else {
            await logMissing()
            return false
        }

        await perform(project)
        return true
    }

    public static func optionalRequiredProjectValue<Project, Value>(
        _ project: Project?,
        perform: (Project) -> Value?
    ) -> Value? {
        guard let project else {
            return nil
        }

        return perform(project)
    }

    @discardableResult
    public static func performRequiredProjectSyncStatus<Project>(
        project: Project?,
        projectPath: (Project) -> String,
        logMissing: () -> Void = {},
        perform: (SyncStatusRequest) -> Void
    ) -> Bool {
        guard let project else {
            logMissing()
            return false
        }

        perform(SyncStatusRequest(projectPath: projectPath(project)))
        return true
    }

    @discardableResult
    public static func performRequiredProjectSyncStatusCommand<Project>(
        project: Project?,
        projectPath: (Project) -> String,
        logMissing: () -> Void = {},
        perform: (ProjectSyncStatusRequest<Project>) -> Void
    ) -> Bool {
        guard let project else {
            logMissing()
            return false
        }

        perform(ProjectSyncStatusRequest(
            request: SyncStatusRequest(projectPath: projectPath(project)),
            project: project
        ))
        return true
    }

    @discardableResult
    public static func performRequiredProjectRemoteOperation<Project>(
        project: Project?,
        projectPath: (Project) -> String,
        operation: RetryOperation,
        logMissing: () -> Void = {},
        perform: (RemoteProjectRequest) -> Void
    ) -> Bool {
        guard let project else {
            logMissing()
            return false
        }

        perform(RemoteProjectRequest(projectPath: projectPath(project), operation: operation))
        return true
    }

    @discardableResult
    public static func performRequiredProjectRemoteOperationCommand<Project>(
        project: Project?,
        projectPath: (Project) -> String,
        operation: RetryOperation,
        logMissing: () -> Void = {},
        perform: (ProjectRemoteOperationCommand<Project>) -> Void
    ) -> Bool {
        guard let project else {
            logMissing()
            return false
        }

        perform(ProjectRemoteOperationCommand(
            request: RemoteProjectRequest(projectPath: projectPath(project), operation: operation),
            project: project
        ))
        return true
    }

    public static func activityStatus(_ activity: Activity) -> String {
        switch activity {
        case .refreshingFiles:
            return String(localized: "Refresh File List…", table: "GitCommit")
        case .checkingRemoteStatus:
            return String(localized: "Checking Remote Status…", table: "GitCommit")
        case .pulling:
            return String(localized: "Pulling…", table: "GitCommit")
        case .pushing:
            return String(localized: "Pushing…", table: "GitCommit")
        case .pushingViaSystemGit:
            return String(localized: "Pushing via system Git…", table: "GitCommit")
        }
    }

    public static func changedFileRefreshStartState() -> ChangedFileRefreshState {
        ChangedFileRefreshState(
            statusText: activityStatus(.refreshingFiles),
            isRefreshing: true
        )
    }

    public static func changedFileRefreshFinishedState() -> ChangedFileRefreshState {
        ChangedFileRefreshState(
            statusText: nil,
            isRefreshing: false
        )
    }

    public static func performChangedFileRefreshState(
        _ state: ChangedFileRefreshState,
        setStatus: (String?) -> Void,
        setRefreshing: (Bool) -> Void
    ) {
        setStatus(state.statusText)
        setRefreshing(state.isRefreshing)
    }

    public static func performChangedFileCountResult(
        _ count: Int,
        setChangedFileCount: (Int) -> Void,
        updateCleanState: (Bool) -> Void
    ) {
        setChangedFileCount(count)
        updateCleanState(count == 0)
    }

    public static func performChangedFileCountLoad(
        loadCount: () async throws -> Int,
        applyCount: (Int) async -> Void,
        applyFinishedState: (ChangedFileRefreshState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        do {
            let count = try await loadCount()
            await applyCount(count)
            await applyFinishedState(changedFileRefreshFinishedState())
        } catch {
            await applyFinishedState(changedFileRefreshFinishedState())
            await handleFailure(error)
        }
    }

    public static func performStartedChangedFileCountLoad(
        applyStartState: (ChangedFileRefreshState) async -> Void,
        loadCount: () async throws -> Int,
        applyCount: (Int) async -> Void,
        applyFinishedState: (ChangedFileRefreshState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await applyStartState(changedFileRefreshStartState())
        await performChangedFileCountLoad(
            loadCount: loadCount,
            applyCount: applyCount,
            applyFinishedState: applyFinishedState,
            handleFailure: handleFailure
        )
    }

    @discardableResult
    public static func performRequiredProjectStartedChangedFileCountLoad<Project>(
        project: Project?,
        logMissing: () async -> Void = {},
        applyStartState: (ChangedFileRefreshState) async -> Void,
        loadCount: (Project) async throws -> Int,
        applyCount: (Int) async -> Void,
        applyFinishedState: (ChangedFileRefreshState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async -> Bool {
        guard let project else {
            await logMissing()
            return false
        }

        await performStartedChangedFileCountLoad(
            applyStartState: applyStartState,
            loadCount: {
                try await loadCount(project)
            },
            applyCount: applyCount,
            applyFinishedState: applyFinishedState,
            handleFailure: handleFailure
        )
        return true
    }

    @discardableResult
    public static func performRequiredProjectStartedChangedFileCountLoadCommand<Project>(
        project: Project?,
        logMissing: () async -> Void = {},
        applyStartState: (ChangedFileRefreshState) async -> Void,
        loadCount: (ProjectChangedFileCountLoadRequest<Project>) async throws -> Int,
        applyCount: (Int) async -> Void,
        applyFinishedState: (ChangedFileRefreshState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async -> Bool {
        guard let project else {
            await logMissing()
            return false
        }

        let request = ProjectChangedFileCountLoadRequest(project: project)
        await performStartedChangedFileCountLoad(
            applyStartState: applyStartState,
            loadCount: {
                try await loadCount(request)
            },
            applyCount: applyCount,
            applyFinishedState: applyFinishedState,
            handleFailure: handleFailure
        )
        return true
    }

    public static func remoteOperationStartState(operation: RetryOperation) -> RemoteOperationState {
        RemoteOperationState(
            statusText: activityStatus(operation == .pull ? .pulling : .pushing),
            isPulling: operation == .pull,
            isPushing: operation == .push,
            refreshesSyncStatus: false
        )
    }

    public static func remoteOperationFinishedState(
        operation: RetryOperation,
        succeeded: Bool
    ) -> RemoteOperationState {
        RemoteOperationState(
            statusText: nil,
            isPulling: false,
            isPushing: false,
            refreshesSyncStatus: succeeded
        )
    }

    public static func performRemoteOperationResult(
        _ result: Result<Void, Error>,
        operation: RetryOperation,
        applyState: (RemoteOperationState) -> Void,
        presentFailure: (Error, RetryOperation) -> Void
    ) {
        switch result {
        case .success:
            applyState(remoteOperationFinishedState(operation: operation, succeeded: true))
        case let .failure(error):
            applyState(remoteOperationFinishedState(operation: operation, succeeded: false))
            presentFailure(error, operation)
        }
    }

    public static func performRemoteOperation(
        perform: () async throws -> Void,
        logSuccess: () async -> Void,
        logFailure: (Error) async -> Void,
        applyResult: (Result<Void, Error>) async -> Void
    ) async {
        do {
            try await perform()
            await logSuccess()
            await applyResult(.success(()))
        } catch {
            await logFailure(error)
            await applyResult(.failure(error))
        }
    }

    public static func performStartedRemoteOperation(
        operation: RetryOperation,
        perform: () async throws -> Void,
        logSuccess: () async -> Void,
        logFailure: (Error) async -> Void,
        applyState: (RemoteOperationState) async -> Void,
        presentFailure: (Error, RetryOperation) async -> Void
    ) async {
        await applyState(remoteOperationStartState(operation: operation))
        await performRemoteOperation(
            perform: perform,
            logSuccess: logSuccess,
            logFailure: logFailure,
            applyResult: { result in
                switch result {
                case .success:
                    await applyState(remoteOperationFinishedState(operation: operation, succeeded: true))
                case let .failure(error):
                    await applyState(remoteOperationFinishedState(operation: operation, succeeded: false))
                    await presentFailure(error, operation)
                }
            }
        )
    }

    public static func performStartedPullOperation(
        pull: () async throws -> Void,
        logSuccess: () async -> Void,
        logFailure: (Error) async -> Void,
        applyState: (RemoteOperationState) async -> Void,
        presentFailure: (Error, RetryOperation) async -> Void
    ) async {
        await performStartedRemoteOperation(
            operation: .pull,
            perform: pull,
            logSuccess: logSuccess,
            logFailure: logFailure,
            applyState: applyState,
            presentFailure: presentFailure
        )
    }

    public static func performPushOperation(
        push: () async throws -> Void,
        isNetworkError: (Error) -> Bool,
        isAuthenticationError: (Error) -> Bool,
        isRetryablePushError: (Error) -> Bool,
        retryAttempts: [PushRetryAttempt] = pushRetryAttempts(),
        setStatus: (String) async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        },
        runNetworkFallback: () async -> Bool,
        logSuccess: (Int?) async -> Void,
        logRetryStart: () async -> Void,
        logRetryFailure: (Int) async -> Void,
        applyState: (RemoteOperationState) async -> Void,
        showNetworkFallback: () async -> Void,
        presentFailure: (Error) async -> Void
    ) async {
        do {
            try await push()
            await logSuccess(nil)
            await applyState(remoteOperationFinishedState(operation: .push, succeeded: true))
            return
        } catch {
            if isNetworkError(error) {
                await logRetryStart()

                for retryAttempt in retryAttempts {
                    await setStatus(retryAttempt.statusText)
                    await sleep(retryAttempt.delayNanoseconds)

                    do {
                        try await push()
                        await logSuccess(retryAttempt.attempt)
                        await applyState(remoteOperationFinishedState(operation: .push, succeeded: true))
                        return
                    } catch {
                        guard isRetryablePushError(error) else {
                            await applyState(remoteOperationFinishedState(operation: .push, succeeded: false))
                            await presentFailure(error)
                            return
                        }

                        await logRetryFailure(retryAttempt.attempt)
                    }
                }

                if await runNetworkFallback() {
                    await logSuccess(nil)
                    await applyState(remoteOperationFinishedState(operation: .push, succeeded: true))
                    return
                }

                await applyState(remoteOperationFinishedState(operation: .push, succeeded: false))
                await showNetworkFallback()
                return
            }

            await applyState(remoteOperationFinishedState(operation: .push, succeeded: false))
            await presentFailure(error)

            if isAuthenticationError(error) {
                return
            }
        }
    }

    public static func performStartedPushOperation(
        push: () async throws -> Void,
        isNetworkError: (Error) -> Bool,
        isAuthenticationError: (Error) -> Bool,
        isRetryablePushError: (Error) -> Bool,
        retryAttempts: [PushRetryAttempt] = pushRetryAttempts(),
        setStatus: (String) async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        },
        runNetworkFallback: () async -> Bool,
        logSuccess: (Int?) async -> Void,
        logRetryStart: () async -> Void,
        logRetryFailure: (Int) async -> Void,
        applyState: (RemoteOperationState) async -> Void,
        showNetworkFallback: () async -> Void,
        presentFailure: (Error) async -> Void
    ) async {
        await applyState(remoteOperationStartState(operation: .push))
        await performPushOperation(
            push: push,
            isNetworkError: isNetworkError,
            isAuthenticationError: isAuthenticationError,
            isRetryablePushError: isRetryablePushError,
            retryAttempts: retryAttempts,
            setStatus: setStatus,
            sleep: sleep,
            runNetworkFallback: runNetworkFallback,
            logSuccess: logSuccess,
            logRetryStart: logRetryStart,
            logRetryFailure: logRetryFailure,
            applyState: applyState,
            showNetworkFallback: showNetworkFallback,
            presentFailure: presentFailure
        )
    }

    public static func performStartedRemoteOperationCommand(
        operation: RetryOperation,
        handlers: RemoteOperationCommandHandlers,
        setStatus: (String) async -> Void,
        retryAttempts: [PushRetryAttempt] = pushRetryAttempts(),
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        },
        logPullSuccess: () async -> Void,
        logPullFailure: (Error) async -> Void,
        logPushSuccess: (Int?) async -> Void,
        logPushRetryStart: () async -> Void,
        logPushRetryFailure: (Int) async -> Void,
        applyState: (RemoteOperationState) async -> Void,
        showNetworkFallback: () async -> Void,
        presentFailure: (Error, RetryOperation) async -> Void
    ) async {
        switch operation {
        case .pull:
            await performStartedPullOperation(
                pull: handlers.pull,
                logSuccess: logPullSuccess,
                logFailure: logPullFailure,
                applyState: applyState,
                presentFailure: presentFailure
            )
        case .push:
            await performStartedPushOperation(
                push: handlers.push,
                isNetworkError: { error in
                    handlers.pushErrorClassification(error).isNetworkError
                },
                isAuthenticationError: { error in
                    handlers.pushErrorClassification(error).isAuthenticationError
                },
                isRetryablePushError: { error in
                    handlers.pushErrorClassification(error).isRetryablePushError
                },
                retryAttempts: retryAttempts,
                setStatus: setStatus,
                sleep: sleep,
                runNetworkFallback: handlers.runNetworkFallback,
                logSuccess: logPushSuccess,
                logRetryStart: logPushRetryStart,
                logRetryFailure: logPushRetryFailure,
                applyState: applyState,
                showNetworkFallback: showNetworkFallback,
                presentFailure: { error in
                    await presentFailure(error, .push)
                }
            )
        }
    }

    public static func remoteOperationCommandHandlers<Project>(
        command: ProjectRemoteOperationCommand<Project>,
        handlers: ProjectRemoteOperationCommandHandlers<Project>
    ) -> RemoteOperationCommandHandlers {
        RemoteOperationCommandHandlers(
            pull: {
                try await handlers.pull(command.project)
            },
            push: {
                try await handlers.push(command.project)
            },
            pushErrorClassification: handlers.pushErrorClassification,
            runNetworkFallback: {
                await handlers.runNetworkFallback(command.project, command.request.projectPath)
            }
        )
    }

    public static func performStartedRemoteOperationCommand<Project>(
        command: ProjectRemoteOperationCommand<Project>,
        handlers: ProjectRemoteOperationCommandHandlers<Project>,
        setStatus: (String) async -> Void,
        retryAttempts: [PushRetryAttempt] = pushRetryAttempts(),
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        },
        logPullSuccess: () async -> Void,
        logPullFailure: (Error) async -> Void,
        logPushSuccess: (Int?) async -> Void,
        logPushRetryStart: () async -> Void,
        logPushRetryFailure: (Int) async -> Void,
        applyState: (RemoteOperationState) async -> Void,
        showNetworkFallback: () async -> Void,
        presentFailure: (Error, RetryOperation) async -> Void
    ) async {
        await performStartedRemoteOperationCommand(
            operation: command.request.operation,
            handlers: remoteOperationCommandHandlers(command: command, handlers: handlers),
            setStatus: setStatus,
            retryAttempts: retryAttempts,
            sleep: sleep,
            logPullSuccess: logPullSuccess,
            logPullFailure: logPullFailure,
            logPushSuccess: logPushSuccess,
            logPushRetryStart: logPushRetryStart,
            logPushRetryFailure: logPushRetryFailure,
            applyState: applyState,
            showNetworkFallback: showNetworkFallback,
            presentFailure: presentFailure
        )
    }

    public static func performRemoteOperationState(
        _ state: RemoteOperationState,
        setPulling: (Bool) -> Void,
        setPushing: (Bool) -> Void,
        setStatus: (String?) -> Void,
        refreshSyncStatus: () -> Void
    ) {
        setPulling(state.isPulling)
        setPushing(state.isPushing)
        setStatus(state.statusText)

        if state.refreshesSyncStatus {
            refreshSyncStatus()
        }
    }

    public static func syncStatusRefreshStartState() -> SyncStatusRefreshState {
        SyncStatusRefreshState(
            statusText: activityStatus(.checkingRemoteStatus),
            isSyncLoading: true
        )
    }

    public static func syncStatusRefreshFinishedState() -> SyncStatusRefreshState {
        SyncStatusRefreshState(
            statusText: nil,
            isSyncLoading: false
        )
    }

    public static func performSyncStatusRefreshState(
        _ state: SyncStatusRefreshState,
        setLoading: (Bool) -> Void,
        setStatus: (String?) -> Void
    ) {
        setLoading(state.isSyncLoading)
        setStatus(state.statusText)
    }

    public static func syncStatusResultState(
        unpushedCount: Int,
        unpulledCount: Int
    ) -> SyncStatusResultState {
        SyncStatusResultState(
            unpushedCount: unpushedCount,
            unpulledCount: unpulledCount,
            refreshState: syncStatusRefreshFinishedState()
        )
    }

    public static func performSyncStatusResultState(
        _ state: SyncStatusResultState,
        setUnpushedCount: (Int) -> Void,
        setUnpulledCount: (Int) -> Void,
        applyRefreshState: (SyncStatusRefreshState) -> Void
    ) {
        setUnpushedCount(state.unpushedCount)
        setUnpulledCount(state.unpulledCount)
        applyRefreshState(state.refreshState)
    }

    public static func unpushedCommitCount<Commit>(
        loadUnpushedCommits: () async throws -> [Commit]
    ) async throws -> Int {
        try await loadUnpushedCommits().count
    }

    public static func performSyncStatusLoad(
        loadUnpushedCount: () async throws -> Int,
        loadUnpulledCount: () async throws -> Int,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        let unpushedCount: Int
        do {
            unpushedCount = try await loadUnpushedCount()
        } catch {
            unpushedCount = 0
            await handleUnpushedFailure(error)
        }

        let unpulledCount: Int
        do {
            unpulledCount = try await loadUnpulledCount()
        } catch {
            unpulledCount = 0
            await handleUnpulledFailure(error)
        }

        await applyResult(syncStatusResultState(
            unpushedCount: unpushedCount,
            unpulledCount: unpulledCount
        ))
        await sleep(statusClearDelayNanoseconds)
        await clearStatus()
    }

    public static func performStartedSyncStatusLoad(
        applyStartState: (SyncStatusRefreshState) async -> Void,
        loadUnpushedCount: () async throws -> Int,
        loadUnpulledCount: () async throws -> Int,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await applyStartState(syncStatusRefreshStartState())
        await performSyncStatusLoad(
            loadUnpushedCount: loadUnpushedCount,
            loadUnpulledCount: loadUnpulledCount,
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func performSyncStatusLoad<Commit>(
        loadUnpushedCommits: () async throws -> [Commit],
        loadUnpulledCount: () async throws -> Int,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await performSyncStatusLoad(
            loadUnpushedCount: {
                try await unpushedCommitCount(loadUnpushedCommits: loadUnpushedCommits)
            },
            loadUnpulledCount: loadUnpulledCount,
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func performSyncStatusLoad<Commit>(
        handlers: SyncStatusLoadHandlers<Commit>,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await performSyncStatusLoad(
            loadUnpushedCommits: handlers.loadUnpushedCommits,
            loadUnpulledCount: handlers.loadUnpulledCount,
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func performStartedSyncStatusLoad<Commit>(
        applyStartState: (SyncStatusRefreshState) async -> Void,
        loadUnpushedCommits: () async throws -> [Commit],
        loadUnpulledCount: () async throws -> Int,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await applyStartState(syncStatusRefreshStartState())
        await performSyncStatusLoad(
            loadUnpushedCommits: loadUnpushedCommits,
            loadUnpulledCount: loadUnpulledCount,
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func performStartedSyncStatusLoad<Commit>(
        applyStartState: (SyncStatusRefreshState) async -> Void,
        handlers: SyncStatusLoadHandlers<Commit>,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await performStartedSyncStatusLoad(
            applyStartState: applyStartState,
            loadUnpushedCommits: handlers.loadUnpushedCommits,
            loadUnpulledCount: handlers.loadUnpulledCount,
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func syncStatusLoadHandlers<Project, Commit>(
        for project: Project,
        handlers: ProjectSyncStatusLoadHandlers<Project, Commit>
    ) -> SyncStatusLoadHandlers<Commit> {
        SyncStatusLoadHandlers(
            loadUnpushedCommits: {
                try await handlers.loadUnpushedCommits(project)
            },
            loadUnpulledCount: {
                try await handlers.loadUnpulledCount(project)
            }
        )
    }

    public static func performSyncStatusLoad<Project, Commit>(
        command: ProjectSyncStatusRequest<Project>,
        handlers: ProjectSyncStatusLoadHandlers<Project, Commit>,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await performSyncStatusLoad(
            handlers: syncStatusLoadHandlers(for: command.project, handlers: handlers),
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func performStartedSyncStatusLoad<Project, Commit>(
        command: ProjectSyncStatusRequest<Project>,
        applyStartState: (SyncStatusRefreshState) async -> Void,
        handlers: ProjectSyncStatusLoadHandlers<Project, Commit>,
        handleUnpushedFailure: (Error) async -> Void,
        handleUnpulledFailure: (Error) async -> Void,
        applyResult: (SyncStatusResultState) async -> Void,
        clearStatus: () async -> Void,
        sleep: (UInt64) async -> Void = { nanoseconds in
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    ) async {
        await performStartedSyncStatusLoad(
            applyStartState: applyStartState,
            handlers: syncStatusLoadHandlers(for: command.project, handlers: handlers),
            handleUnpushedFailure: handleUnpushedFailure,
            handleUnpulledFailure: handleUnpulledFailure,
            applyResult: applyResult,
            clearStatus: clearStatus,
            sleep: sleep
        )
    }

    public static func networkFallbackAlertText() -> NetworkFallbackAlertText {
        NetworkFallbackAlertText(
            title: String(localized: "Push Failed", table: "GitCommit"),
            message: String(localized: "Network connection error, auto-retry failed. You can try:", table: "GitCommit"),
            retryButtonTitle: String(localized: "Retry", table: "GitCommit"),
            toggleSSHPushButtonTitle: String(localized: "Toggle SSH Push", table: "GitCommit"),
            cancelButtonTitle: String(localized: "Cancel", table: "GitCommit")
        )
    }

    public static func networkFallbackSelection(buttonIndex: Int) -> NetworkFallbackSelection {
        switch buttonIndex {
        case 0:
            return .retry
        case 1:
            return .toggleSSH
        default:
            return .cancel
        }
    }

    public static func networkFallbackSelection<Response: Equatable>(
        response: Response,
        firstButton: Response,
        secondButton: Response
    ) -> NetworkFallbackSelection {
        if response == firstButton {
            return .retry
        }

        if response == secondButton {
            return .toggleSSH
        }

        return .cancel
    }

    public static func networkFallbackSelectionState(
        selection: NetworkFallbackSelection,
        remoteURL: String?,
        fallbackErrorMessage: String
    ) -> NetworkFallbackSelectionState {
        switch selection {
        case .retry:
            return NetworkFallbackSelectionState(
                retryAction: RetryAction(operation: .push, delayNanoseconds: 0),
                sshHelpState: nil
            )
        case .toggleSSH:
            return NetworkFallbackSelectionState(
                retryAction: nil,
                sshHelpState: sshHelpState(
                    isSSHAuthenticationError: true,
                    remoteURL: remoteURL,
                    errorMessage: fallbackErrorMessage,
                    operation: .push
                )
            )
        case .cancel:
            return NetworkFallbackSelectionState(retryAction: nil, sshHelpState: nil)
        }
    }

    public static func performNetworkFallbackSelectionState(
        _ state: NetworkFallbackSelectionState,
        performRetry: (RetryAction) -> Void,
        showSSHHelp: (SSHHelpState) -> Void
    ) {
        if let retryAction = state.retryAction {
            performRetry(retryAction)
        }

        if let sshHelpState = state.sshHelpState {
            showSSHHelp(sshHelpState)
        }
    }

    public static func refreshActionOnAppear() -> WorkingStateRefreshAction {
        .full
    }

    public static func refreshActionOnTap() -> WorkingStateRefreshAction {
        .changedFilesOnly
    }

    public static func refreshActionOnProjectChanged() -> WorkingStateRefreshAction {
        .full
    }

    public static func refreshActionOnProjectDidCommit() -> WorkingStateRefreshAction {
        .full
    }

    public static func refreshActionOnProjectDidPush() -> WorkingStateRefreshAction {
        .syncStatusOnly
    }

    public static func refreshActionOnProjectDidPull() -> WorkingStateRefreshAction {
        .syncStatusOnly
    }

    public static func isCurrentProject(eventProjectPath: String, currentProjectPath: String?) -> Bool {
        eventProjectPath == currentProjectPath
    }

    public static func refreshActionOnGitDirectoryChanged(
        isCurrentProject: Bool,
        didHeadChange: Bool
    ) -> WorkingStateRefreshAction {
        guard isCurrentProject else {
            return .none
        }

        if didHeadChange {
            return .full
        }

        return .changedFilesOnly
    }

    public static func refreshActionOnGitDirectoryChanged(
        eventProjectPath: String,
        currentProjectPath: String?,
        didHeadChange: Bool
    ) -> WorkingStateRefreshAction {
        refreshActionOnGitDirectoryChanged(
            isCurrentProject: isCurrentProject(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            ),
            didHeadChange: didHeadChange
        )
    }

    public static func refreshActionOnGitDirectoryChanged<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        didHeadChange: Bool
    ) -> WorkingStateRefreshAction {
        refreshActionOnGitDirectoryChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath),
            didHeadChange: didHeadChange
        )
    }

    public static func refreshActionOnAppDidBecomeActive() -> WorkingStateRefreshAction {
        .changedFilesOnly
    }

    public static func refreshAction(for event: WorkingStateEvent) -> WorkingStateRefreshAction {
        switch event {
        case .appear:
            return refreshActionOnAppear()
        case .tap:
            return refreshActionOnTap()
        case .projectChanged:
            return refreshActionOnProjectChanged()
        case .projectDidCommit:
            return refreshActionOnProjectDidCommit()
        case .projectDidPush:
            return refreshActionOnProjectDidPush()
        case .projectDidPull:
            return refreshActionOnProjectDidPull()
        case let .gitDirectoryChanged(eventProjectPath, currentProjectPath, didHeadChange):
            return refreshActionOnGitDirectoryChanged(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath,
                didHeadChange: didHeadChange
            )
        case .appDidBecomeActive:
            return refreshActionOnAppDidBecomeActive()
        }
    }

    public static func refreshAction<Project>(
        gitDirectoryChangedEventProjectPath eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        didHeadChange: Bool
    ) -> WorkingStateRefreshAction {
        refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath),
            didHeadChange: didHeadChange
        ))
    }

    public static func performWorkingStateRefreshAction(
        _ action: WorkingStateRefreshAction,
        refreshChangedFiles: () -> Void,
        refreshSyncStatus: () -> Void
    ) {
        if action.refreshChangedFiles {
            refreshChangedFiles()
        }

        if action.refreshSyncStatus {
            refreshSyncStatus()
        }
    }

    public static func performWorkingStateEvent(
        _ event: WorkingStateEvent,
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        performRefreshAction(refreshAction(for: event))
    }

    public static func performWorkingStateAppear(
        performRefreshAction: (WorkingStateRefreshAction) -> Void,
        startTimer: () -> Void
    ) {
        performWorkingStateEvent(.appear, performRefreshAction: performRefreshAction)
        startTimer()
    }

    public static func performWorkingStateDisappear(stopTimer: () -> Void) {
        stopTimer()
    }

    public static func performWorkingStateTap<Commit>(
        currentCommit: Commit?,
        setCommit: (Commit?) -> Void,
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        setCommit(selectedCommitAfterWorkingStateTap(current: currentCommit))
        performWorkingStateEvent(.tap, performRefreshAction: performRefreshAction)
    }

    public static func performProjectDidCommit(
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        performWorkingStateEvent(.projectDidCommit, performRefreshAction: performRefreshAction)
    }

    public static func performProjectDidChange(
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        performWorkingStateEvent(.projectChanged, performRefreshAction: performRefreshAction)
    }

    public static func performProjectDidPush(
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        performWorkingStateEvent(.projectDidPush, performRefreshAction: performRefreshAction)
    }

    public static func performProjectDidPull(
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        performWorkingStateEvent(.projectDidPull, performRefreshAction: performRefreshAction)
    }

    public static func performGitDirectoryChangedWorkingStateEvent<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        didHeadChange: Bool,
        performRefreshAction: (WorkingStateRefreshAction) -> Void
    ) {
        performRefreshAction(refreshAction(
            gitDirectoryChangedEventProjectPath: eventProjectPath,
            currentProject: currentProject,
            currentProjectPath: currentProjectPath,
            didHeadChange: didHeadChange
        ))
    }

    public static func performDelayedWorkingStateRefreshAction(
        _ action: WorkingStateRefreshAction,
        delayNanoseconds: UInt64 = appActivationRefreshDelayNanoseconds,
        sleep: (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
        performRefreshAction: (WorkingStateRefreshAction) async -> Void
    ) async {
        do {
            try await sleep(delayNanoseconds)
        } catch {
            return
        }

        await performRefreshAction(action)
    }

    public static func retryActionAfterCredentialSave(operation: RetryOperation?) -> RetryAction? {
        operation.map {
            RetryAction(operation: $0, delayNanoseconds: credentialRetryDelayNanoseconds)
        }
    }

    public static func retryActionAfterSSHHelp(operation: RetryOperation?) -> RetryAction? {
        operation.map {
            RetryAction(operation: $0, delayNanoseconds: 0)
        }
    }

    public static func performRetryOperation(
        _ operation: RetryOperation,
        onPush: () -> Void,
        onPull: () -> Void
    ) {
        switch operation {
        case .push:
            onPush()
        case .pull:
            onPull()
        }
    }

    public static func retryDelaySeconds(_ retryAction: RetryAction) -> TimeInterval {
        TimeInterval(retryAction.delayNanoseconds) / 1_000_000_000
    }

    public static func performRetryAction(
        _ retryAction: RetryAction,
        schedule: (TimeInterval, @escaping () -> Void) -> Void,
        onPush: @escaping () -> Void,
        onPull: @escaping () -> Void
    ) {
        schedule(retryDelaySeconds(retryAction)) {
            performRetryOperation(
                retryAction.operation,
                onPush: onPush,
                onPull: onPull
            )
        }
    }

    public static func credentialPromptState(
        isCredentialError: Bool,
        host: String?,
        operation: RetryOperation
    ) -> CredentialPromptState? {
        guard isCredentialError else {
            return nil
        }

        return CredentialPromptState(
            showsPrompt: true,
            host: host ?? defaultCredentialHost,
            retryOperation: operation
        )
    }

    public static func performCredentialPromptState(
        _ state: CredentialPromptState,
        setShowsPrompt: (Bool) -> Void,
        setHost: (String) -> Void,
        setRetryOperation: (RetryOperation?) -> Void
    ) {
        setShowsPrompt(state.showsPrompt)
        setHost(state.host)
        setRetryOperation(state.retryOperation)
    }

    public static func sshHelpState(
        isSSHAuthenticationError: Bool,
        remoteURL: String?,
        errorMessage: String,
        operation: RetryOperation
    ) -> SSHHelpState? {
        guard isSSHAuthenticationError else {
            return nil
        }

        return SSHHelpState(
            showsPrompt: true,
            remoteURL: remoteURL,
            errorMessage: errorMessage,
            retryOperation: operation
        )
    }

    public static func performSSHHelpState(
        _ state: SSHHelpState,
        setShowsPrompt: (Bool) -> Void,
        setRemoteURL: (String?) -> Void,
        setErrorMessage: (String?) -> Void,
        setRetryOperation: (RetryOperation?) -> Void
    ) {
        setShowsPrompt(state.showsPrompt)
        setRemoteURL(state.remoteURL)
        setErrorMessage(state.errorMessage)
        setRetryOperation(state.retryOperation)
    }

    public static func remoteFailurePresentation(
        credentialState: CredentialPromptState?,
        sshHelpState: SSHHelpState?
    ) -> RemoteFailurePresentation {
        if let credentialState {
            return .credential(credentialState)
        }

        if let sshHelpState {
            return .sshHelp(sshHelpState)
        }

        return .alert
    }

    public static func remoteFailurePresentation(
        errorDescription: String,
        isCredentialError: Bool,
        credentialHost: String?,
        sshRemoteURL: String?,
        operation: RetryOperation
    ) -> RemoteFailurePresentation {
        remoteFailurePresentation(
            credentialState: credentialPromptState(
                isCredentialError: isCredentialError,
                host: credentialHost,
                operation: operation
            ),
            sshHelpState: sshHelpState(
                isSSHAuthenticationError: isSSHAuthenticationErrorDescription(errorDescription),
                remoteURL: sshRemoteURL,
                errorMessage: errorDescription,
                operation: operation
            )
        )
    }

    public static func performRemoteFailurePresentation(
        _ presentation: RemoteFailurePresentation,
        showCredentialPrompt: (CredentialPromptState) -> Void,
        showSSHHelp: (SSHHelpState) -> Void,
        showAlert: () -> Void
    ) {
        switch presentation {
        case let .credential(state):
            showCredentialPrompt(state)
        case let .sshHelp(state):
            showSSHHelp(state)
        case .alert:
            showAlert()
        }
    }

    public static func credentialPromptDismissState(operation: RetryOperation?) -> RetryPromptDismissState {
        RetryPromptDismissState(
            showsPrompt: false,
            retryAction: retryActionAfterCredentialSave(operation: operation)
        )
    }

    public static func sshHelpDismissState(operation: RetryOperation?) -> RetryPromptDismissState {
        RetryPromptDismissState(
            showsPrompt: false,
            retryAction: retryActionAfterSSHHelp(operation: operation)
        )
    }

    public static func retryPromptDismissState(
        for prompt: RetryPrompt,
        operation: RetryOperation?
    ) -> RetryPromptDismissState {
        switch prompt {
        case .credential:
            return credentialPromptDismissState(operation: operation)
        case .sshHelp:
            return sshHelpDismissState(operation: operation)
        }
    }

    public static func retryPromptApplicationState(
        state: RetryPromptDismissState,
        prompt: RetryPrompt
    ) -> RetryPromptApplicationState {
        switch prompt {
        case .credential:
            return RetryPromptApplicationState(
                showsCredentialPrompt: state.showsPrompt,
                showsSSHHelp: nil,
                retryAction: state.retryAction
            )
        case .sshHelp:
            return RetryPromptApplicationState(
                showsCredentialPrompt: nil,
                showsSSHHelp: state.showsPrompt,
                retryAction: state.retryAction
            )
        }
    }

    public static func performRetryPromptApplicationState(
        _ state: RetryPromptApplicationState,
        setCredentialPrompt: (Bool) -> Void,
        setSSHHelp: (Bool) -> Void,
        performRetry: (RetryAction) -> Void
    ) {
        if let showsCredentialPrompt = state.showsCredentialPrompt {
            setCredentialPrompt(showsCredentialPrompt)
        }

        if let showsSSHHelp = state.showsSSHHelp {
            setSSHHelp(showsSSHHelp)
        }

        if let retryAction = state.retryAction {
            performRetry(retryAction)
        }
    }

    public static func preferredCandidateURLs(from remotes: [RemoteURLs]) -> [String] {
        let preferredRemote = remotes.first(where: { $0.name == "origin" }) ?? remotes.first
        return [
            preferredRemote?.pushURL,
            preferredRemote?.fetchURL,
            preferredRemote?.url,
        ].compactMap { $0 }
    }

    public static func remoteURLs<Remote>(
        from remotes: [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> [RemoteURLs] {
        remotes.map {
            RemoteURLs(
                name: name($0),
                url: url($0),
                fetchURL: fetchURL($0),
                pushURL: pushURL($0)
            )
        }
    }

    public static func credentialHost(from remotes: [RemoteURLs]) -> String? {
        for remoteURL in preferredCandidateURLs(from: remotes) {
            if let host = CloneRepositoryValidation.credentialHost(from: remoteURL) {
                return host
            }
        }

        return nil
    }

    public static func credentialHost<Remote>(
        loadRemotes: () throws -> [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> String? {
        guard let remotes = try? loadRemotes() else {
            return nil
        }

        return credentialHost(from: remoteURLs(
            from: remotes,
            name: name,
            url: url,
            fetchURL: fetchURL,
            pushURL: pushURL
        ))
    }

    public static func projectCredentialHost<Project, Remote>(
        project: Project?,
        loadRemotes: (Project) throws -> [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> String? {
        optionalRequiredProjectValue(project) { project in
            credentialHost(
                loadRemotes: { try loadRemotes(project) },
                name: name,
                url: url,
                fetchURL: fetchURL,
                pushURL: pushURL
            )
        }
    }

    public static func remoteAccess(from remotes: [RemoteURLs]) -> RemoteAccess {
        RemoteAccess(
            credentialHost: credentialHost(from: remotes),
            sshRemoteURL: sshRemoteURL(from: remotes)
        )
    }

    public static func remoteAccess<Remote>(
        loadRemotes: () throws -> [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> RemoteAccess {
        guard let remotes = try? loadRemotes() else {
            return .empty
        }

        return remoteAccess(from: remoteURLs(
            from: remotes,
            name: name,
            url: url,
            fetchURL: fetchURL,
            pushURL: pushURL
        ))
    }

    public static func projectRemoteAccess<Project, Remote>(
        project: Project?,
        loadRemotes: (Project) throws -> [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> RemoteAccess {
        optionalRequiredProjectValue(project) { project in
            remoteAccess(
                loadRemotes: { try loadRemotes(project) },
                name: name,
                url: url,
                fetchURL: fetchURL,
                pushURL: pushURL
            )
        } ?? .empty
    }

    public static func sshRemoteURL(from remotes: [RemoteURLs]) -> String? {
        preferredCandidateURLs(from: remotes).first {
            CloneRepositoryValidation.sshHost(from: $0) != nil
        }
    }

    public static func sshRemoteURL<Remote>(
        loadRemotes: () throws -> [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> String? {
        guard let remotes = try? loadRemotes() else {
            return nil
        }

        return sshRemoteURL(from: remoteURLs(
            from: remotes,
            name: name,
            url: url,
            fetchURL: fetchURL,
            pushURL: pushURL
        ))
    }

    public static func projectSSHRemoteURL<Project, Remote>(
        project: Project?,
        loadRemotes: (Project) throws -> [Remote],
        name: (Remote) -> String,
        url: (Remote) -> String?,
        fetchURL: (Remote) -> String?,
        pushURL: (Remote) -> String?
    ) -> String? {
        optionalRequiredProjectValue(project) { project in
            sshRemoteURL(
                loadRemotes: { try loadRemotes(project) },
                name: name,
                url: url,
                fetchURL: fetchURL,
                pushURL: pushURL
            )
        }
    }
}
