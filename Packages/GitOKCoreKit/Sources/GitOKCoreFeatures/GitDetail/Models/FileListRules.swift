import Foundation

public enum FileListRules {
    public static let refreshDebounceInterval: TimeInterval = 0.5
    public static let hoveredRowOpacity = 0.10
    public static let hoverAnimationDuration = 0.12
    public static let afterStageFileRefreshReason = "AfterStageFile"
    public static let afterStageSelectedFilesRefreshReason = "AfterStageSelectedFiles"
    public static let afterUnstageFileRefreshReason = "AfterUnstageFile"
    public static let afterUnstageSelectedFilesRefreshReason = "AfterUnstageSelectedFiles"
    public static let afterDiscardChangesRefreshReason = "AfterDiscardChanges"
    public static let afterDiscardAllChangesRefreshReason = "AfterDiscardAllChanges"
    public static let afterDiscardSelectedChangesRefreshReason = "AfterDiscardSelectedChanges"
    public static let appearRefreshReason = "OnAppear"
    public static let projectChangedRefreshReason = "OnProjectChanged"
    public static let commitChangedRefreshReason = "OnCommitChanged"
    public static let projectDidCommitRefreshReason = "OnProjectDidCommit"
    public static let projectDidAddFilesRefreshReason = "OnProjectDidAddFiles"
    public static let gitDirectoryDidChangeRefreshReason = "OnGitDirectoryDidChange"
    public static let appWillBecomeActiveRefreshReason = "OnAppWillBecomeActive"
    public static let retryAfterErrorRefreshReason = "RetryAfterError"
    public static let refreshFileListErrorContext = "refreshFileList"

    public static func fileOperationFailureLogMessage(failureLogMessage: String, errorDescription: String) -> String {
        "❌ \(failureLogMessage): \(errorDescription)"
    }

    public static func refreshSkippedLogMessage(reason: String) -> String {
        "🚫 Refresh skipped (debounced): \(reason)"
    }

    public static func refreshStartedLogMessage(reason: String) -> String {
        "🍋 Refreshing \(reason)"
    }

    public static func commitChangedDuringRefreshLogMessage() -> String {
        "🔄 Commit changed during refresh, skipping UI update"
    }

    public static func refreshCancelledLogMessage(reason: String) -> String {
        "🐜 Refresh cancelled: \(reason)"
    }

    public static func refreshFailureLogMessage(errorDescription: String) -> String {
        "❌ Failed to refresh file list: \(errorDescription)"
    }

    public enum RowBackgroundState: Equatable, Sendable {
        case hovered
        case clear
    }

    public enum SelectionDirection {
        case up
        case down
    }

    public enum RefreshEventAction: Equatable, Sendable {
        case refresh(reason: String)
        case refreshImmediately(reason: String)
        case none
    }

    public enum RefreshEvent: Equatable, Sendable {
        case appear
        case projectChanged
        case commitChanged
        case projectDidCommit
        case projectDidAddFiles(eventProjectPath: String, currentProjectPath: String?)
        case gitDirectoryChanged(eventProjectPath: String, currentProjectPath: String?)
        case appWillBecomeActive
    }

    public enum FileOperationKind: Equatable, Sendable {
        case stage
        case unstage
        case discardFile
        case discardAll
        case discardSelected
    }

    public enum FileOperationAction: Equatable, Sendable {
        case stageFile(path: String)
        case stageSelected(BatchActionState)
        case unstageFile(path: String)
        case unstageSelected(BatchActionState)
        case discardFile(path: String)
        case discardAll
        case discardSelected(BatchActionState)
    }

    public enum SectionKind: String, Equatable, Sendable {
        case changes
        case stagedChanges
        case historyFiles

        public var title: String {
            switch self {
            case .changes:
                return GitDetailLocalization.string("Changes")
            case .stagedChanges:
                return GitDetailLocalization.string("Staged Changes")
            case .historyFiles:
                return GitDetailLocalization.string("History Files")
            }
        }
    }

    public struct FileSection: Equatable, Sendable {
        public let kind: SectionKind
        public let paths: [String]

        public init(kind: SectionKind, paths: [String]) {
            self.kind = kind
            self.paths = paths
        }
    }

    public struct BatchActionState: Equatable, Sendable {
        public let selectedPaths: [String]
        public let stageablePaths: [String]
        public let unstageablePaths: [String]
        public let untrackedCount: Int

        public init(
            selectedPaths: [String],
            stageablePaths: [String],
            unstageablePaths: [String],
            untrackedCount: Int
        ) {
            self.selectedPaths = selectedPaths
            self.stageablePaths = stageablePaths
            self.unstageablePaths = unstageablePaths
            self.untrackedCount = untrackedCount
        }

        public var selectedCount: Int {
            selectedPaths.count
        }

        public var canStage: Bool {
            stageablePaths.isEmpty == false
        }

        public var canUnstage: Bool {
            unstageablePaths.isEmpty == false
        }

        public var canDiscard: Bool {
            selectedPaths.isEmpty == false
        }

        public var discardablePaths: [String] {
            selectedPaths
        }
    }

    public struct DiscardAlertText: Equatable, Sendable {
        public let title: String
        public let cancelButtonTitle: String
        public let destructiveButtonTitle: String

        public init(title: String, cancelButtonTitle: String, destructiveButtonTitle: String) {
            self.title = title
            self.cancelButtonTitle = cancelButtonTitle
            self.destructiveButtonTitle = destructiveButtonTitle
        }
    }

    public struct DiscardPromptState: Equatable, Sendable {
        public let showsPrompt: Bool

        public init(showsPrompt: Bool) {
            self.showsPrompt = showsPrompt
        }
    }

    public struct RefreshState: Equatable, Sendable {
        public let selectedPath: String?
        public let stagedPaths: Set<String>
        public let unstagedPaths: Set<String>
        public let untrackedPaths: Set<String>
        public let selectedBatchPaths: Set<String>

        public init(
            selectedPath: String?,
            stagedPaths: Set<String>,
            unstagedPaths: Set<String>,
            untrackedPaths: Set<String>,
            selectedBatchPaths: Set<String>
        ) {
            self.selectedPath = selectedPath
            self.stagedPaths = stagedPaths
            self.unstagedPaths = unstagedPaths
            self.untrackedPaths = untrackedPaths
            self.selectedBatchPaths = selectedBatchPaths
        }
    }

    public struct RefreshResultApplicationState: Equatable, Sendable {
        public let shouldApply: Bool
        public let refreshState: RefreshState?

        public init(shouldApply: Bool, refreshState: RefreshState?) {
            self.shouldApply = shouldApply
            self.refreshState = refreshState
        }
    }

    public struct RefreshLifecycleState: Equatable, Sendable {
        public let isLoading: Bool
        public let errorMessage: String?

        public init(isLoading: Bool, errorMessage: String?) {
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public struct RefreshRequestState: Equatable, Sendable {
        public let shouldStartRefresh: Bool
        public let lastRefreshTime: Date

        public init(shouldStartRefresh: Bool, lastRefreshTime: Date) {
            self.shouldStartRefresh = shouldStartRefresh
            self.lastRefreshTime = lastRefreshTime
        }
    }

    public struct ProjectRefreshRequest: Equatable, Sendable {
        public let reason: String

        public init(reason: String) {
            self.reason = reason
        }
    }

    public struct ProjectRefreshCommand<Project> {
        public let request: ProjectRefreshRequest
        public let project: Project

        public init(request: ProjectRefreshRequest, project: Project) {
            self.request = request
            self.project = project
        }
    }

    public struct RefreshLoadResult<FileItem, StatusEntry> {
        public let files: [FileItem]
        public let selectedCommitHash: String?
        public let statusEntries: [StatusEntry]

        public init(files: [FileItem], selectedCommitHash: String?, statusEntries: [StatusEntry]) {
            self.files = files
            self.selectedCommitHash = selectedCommitHash
            self.statusEntries = statusEntries
        }
    }

    public struct RefreshLoadHandlers<FileItem, StatusEntry> {
        public let loadCommitFiles: (String) async throws -> [FileItem]
        public let loadWorktreeFiles: () async throws -> [FileItem]
        public let loadStatusEntries: () async throws -> [StatusEntry]

        public init(
            loadCommitFiles: @escaping (String) async throws -> [FileItem],
            loadWorktreeFiles: @escaping () async throws -> [FileItem],
            loadStatusEntries: @escaping () async throws -> [StatusEntry]
        ) {
            self.loadCommitFiles = loadCommitFiles
            self.loadWorktreeFiles = loadWorktreeFiles
            self.loadStatusEntries = loadStatusEntries
        }
    }

    public struct ProjectRefreshLoadHandlers<Project, FileItem, StatusEntry> {
        public let loadCommitFiles: (Project, String) async throws -> [FileItem]
        public let loadWorktreeFiles: (Project) async throws -> [FileItem]
        public let loadStatusEntries: (Project) async throws -> [StatusEntry]

        public init(
            loadCommitFiles: @escaping (Project, String) async throws -> [FileItem],
            loadWorktreeFiles: @escaping (Project) async throws -> [FileItem],
            loadStatusEntries: @escaping (Project) async throws -> [StatusEntry]
        ) {
            self.loadCommitFiles = loadCommitFiles
            self.loadWorktreeFiles = loadWorktreeFiles
            self.loadStatusEntries = loadStatusEntries
        }
    }

    public struct OperationSuccessState: Equatable, Sendable {
        public let message: String
        public let refreshReason: String
        public let removesBatchSelectionPaths: [String]

        public init(message: String, refreshReason: String, removesBatchSelectionPaths: [String]) {
            self.message = message
            self.refreshReason = refreshReason
            self.removesBatchSelectionPaths = removesBatchSelectionPaths
        }
    }

    public struct OperationCompletionState: Equatable, Sendable {
        public let message: String
        public let selectedBatchPaths: Set<String>

        public init(message: String, selectedBatchPaths: Set<String>) {
            self.message = message
            self.selectedBatchPaths = selectedBatchPaths
        }
    }

    public struct FileOperationRequestState: Equatable, Sendable {
        public let paths: [String]

        public var canPerform: Bool {
            paths.isEmpty == false
        }

        public var primaryPath: String? {
            paths.first
        }

        public init(paths: [String]) {
            self.paths = paths
        }
    }

    public struct FileOperationCommand: Equatable, Sendable {
        public let kind: FileOperationKind
        public let request: FileOperationRequestState
        public let failureLogMessage: String

        public init(
            kind: FileOperationKind,
            request: FileOperationRequestState = FileOperationRequestState(paths: []),
            failureLogMessage: String
        ) {
            self.kind = kind
            self.request = request
            self.failureLogMessage = failureLogMessage
        }
    }

    public struct ProjectFileOperationCommand<Project> {
        public let command: FileOperationCommand
        public let project: Project

        public init(command: FileOperationCommand, project: Project) {
            self.command = command
            self.project = project
        }
    }

    public struct FileOperationHandlers {
        public let addFiles: ([String]) async throws -> Void
        public let unstageFiles: ([String]) async throws -> Void
        public let discard: (String) async throws -> Void
        public let discardAllChanges: () async throws -> Void

        public init(
            addFiles: @escaping ([String]) async throws -> Void,
            unstageFiles: @escaping ([String]) async throws -> Void,
            discard: @escaping (String) async throws -> Void,
            discardAllChanges: @escaping () async throws -> Void
        ) {
            self.addFiles = addFiles
            self.unstageFiles = unstageFiles
            self.discard = discard
            self.discardAllChanges = discardAllChanges
        }
    }

    public struct ProjectFileOperationHandlers<Project> {
        public let addFiles: (Project, [String]) async throws -> Void
        public let unstageFiles: (Project, [String]) async throws -> Void
        public let discard: (Project, String) async throws -> Void
        public let discardAllChanges: (Project) async throws -> Void

        public init(
            addFiles: @escaping (Project, [String]) async throws -> Void,
            unstageFiles: @escaping (Project, [String]) async throws -> Void,
            discard: @escaping (Project, String) async throws -> Void,
            discardAllChanges: @escaping (Project) async throws -> Void
        ) {
            self.addFiles = addFiles
            self.unstageFiles = unstageFiles
            self.discard = discard
            self.discardAllChanges = discardAllChanges
        }
    }

    public struct PresentationState: Equatable, Sendable {
        public let visiblePaths: [String]
        public let sections: [FileSection]
        public let batchActionState: BatchActionState
        public let discardAllAlertMessage: String
        public let discardSelectedAlertMessage: String
        public let showsDiscardAll: Bool
        public let showsBatchActionBar: Bool
        public let canSelectAll: Bool
        public let showsEmptyState: Bool
        public let emptyStateIsFiltering: Bool

        public init(
            visiblePaths: [String],
            sections: [FileSection],
            batchActionState: BatchActionState,
            discardAllAlertMessage: String,
            discardSelectedAlertMessage: String,
            showsDiscardAll: Bool,
            showsBatchActionBar: Bool,
            canSelectAll: Bool,
            showsEmptyState: Bool,
            emptyStateIsFiltering: Bool
        ) {
            self.visiblePaths = visiblePaths
            self.sections = sections
            self.batchActionState = batchActionState
            self.discardAllAlertMessage = discardAllAlertMessage
            self.discardSelectedAlertMessage = discardSelectedAlertMessage
            self.showsDiscardAll = showsDiscardAll
            self.showsBatchActionBar = showsBatchActionBar
            self.canSelectAll = canSelectAll
            self.showsEmptyState = showsEmptyState
            self.emptyStateIsFiltering = emptyStateIsFiltering
        }
    }

    public struct FileRowActionState: Equatable, Sendable {
        public let canEditWorkingTree: Bool
        public let showsStageBadge: Bool
        public let isBatchSelected: Bool

        public init(canEditWorkingTree: Bool, showsStageBadge: Bool, isBatchSelected: Bool) {
            self.canEditWorkingTree = canEditWorkingTree
            self.showsStageBadge = showsStageBadge
            self.isBatchSelected = isBatchSelected
        }
    }

    public struct FileRowPresentationState: Equatable, Sendable {
        public let projectURL: URL?
        public let actionState: FileRowActionState

        public init(projectURL: URL?, actionState: FileRowActionState) {
            self.projectURL = projectURL
            self.actionState = actionState
        }
    }

    public static func normalizedFilterQuery(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func filteredPaths(_ paths: [String], query: String) -> [String] {
        let normalizedQuery = normalizedFilterQuery(query)
        guard normalizedQuery.isEmpty == false else {
            return paths
        }

        return paths.filter { $0.localizedCaseInsensitiveContains(normalizedQuery) }
    }

    public static func isHistoryMode(hasSelectedCommit: Bool) -> Bool {
        hasSelectedCommit
    }

    public static func isHistoryMode<Commit>(selectedCommit: Commit?) -> Bool {
        isHistoryMode(hasSelectedCommit: selectedCommit != nil)
    }

    public static func items<Item>(
        from items: [Item],
        matching paths: [String],
        path: (Item) -> String
    ) -> [Item] {
        let pathSet = Set(paths)
        return items.filter { pathSet.contains(path($0)) }
    }

    public static func itemLookup<Item>(
        from items: [Item],
        path: (Item) -> String
    ) -> [String: Item] {
        var result: [String: Item] = [:]
        result.reserveCapacity(items.count)

        for item in items {
            result[path(item)] = item
        }

        return result
    }

    public static func items<Item>(
        from itemLookup: [String: Item],
        matching paths: [String]
    ) -> [Item] {
        paths.compactMap { itemLookup[$0] }
    }

    public static func visibleItems<Item>(
        from items: [Item],
        presentationState: PresentationState,
        path: (Item) -> String
    ) -> [Item] {
        self.items(from: items, matching: presentationState.visiblePaths, path: path)
    }

    public static func items<Item>(
        from items: [Item],
        in section: FileSection,
        path: (Item) -> String
    ) -> [Item] {
        self.items(from: items, matching: section.paths, path: path)
    }

    public static func firstItem<Item>(
        matching path: String,
        in items: [Item],
        path itemPath: (Item) -> String
    ) -> Item? {
        items.first { itemPath($0) == path }
    }

    public static func selectedItem<Item>(
        from refreshState: RefreshState,
        in items: [Item],
        path itemPath: (Item) -> String
    ) -> Item? {
        guard let selectedPath = refreshState.selectedPath else {
            return nil
        }

        return firstItem(matching: selectedPath, in: items, path: itemPath)
    }

    public static func shouldRefresh(
        now: Date,
        lastRefreshTime: Date,
        debounceInterval: TimeInterval = refreshDebounceInterval
    ) -> Bool {
        now.timeIntervalSince(lastRefreshTime) > debounceInterval
    }

    public static func currentDate(now: () -> Date = Date.init) -> Date {
        now()
    }

    public static func refreshRequestState(
        now: Date,
        lastRefreshTime: Date,
        debounceInterval: TimeInterval = refreshDebounceInterval
    ) -> RefreshRequestState {
        let shouldStartRefresh = shouldRefresh(
            now: now,
            lastRefreshTime: lastRefreshTime,
            debounceInterval: debounceInterval
        )
        return RefreshRequestState(
            shouldStartRefresh: shouldStartRefresh,
            lastRefreshTime: shouldStartRefresh ? now : lastRefreshTime
        )
    }

    public static func refreshRequestState(
        lastRefreshTime: Date,
        debounceInterval: TimeInterval = refreshDebounceInterval,
        now: () -> Date = Date.init
    ) -> RefreshRequestState {
        refreshRequestState(
            now: currentDate(now: now),
            lastRefreshTime: lastRefreshTime,
            debounceInterval: debounceInterval
        )
    }

    @discardableResult
    public static func performRefreshRequestState(
        _ state: RefreshRequestState,
        logSkipped: () -> Void,
        setLastRefreshTime: (Date) -> Void,
        cancelPreviousRefreshes: () -> Void,
        startRefresh: () -> Void
    ) -> Bool {
        guard state.shouldStartRefresh else {
            logSkipped()
            return false
        }

        setLastRefreshTime(state.lastRefreshTime)
        cancelPreviousRefreshes()
        startRefresh()
        return true
    }

    public static func refreshActionOnAppear() -> RefreshEventAction {
        .refresh(reason: appearRefreshReason)
    }

    public static func refreshActionOnProjectChanged() -> RefreshEventAction {
        .refresh(reason: projectChangedRefreshReason)
    }

    public static func refreshActionOnCommitChanged() -> RefreshEventAction {
        .refresh(reason: commitChangedRefreshReason)
    }

    public static func refreshActionOnProjectDidCommit() -> RefreshEventAction {
        .refresh(reason: projectDidCommitRefreshReason)
    }

    public static func isCurrentProject(eventProjectPath: String, currentProjectPath: String?) -> Bool {
        eventProjectPath == currentProjectPath
    }

    public static func refreshActionOnProjectDidAddFiles(isCurrentProject: Bool) -> RefreshEventAction {
        isCurrentProject ? .refresh(reason: projectDidAddFilesRefreshReason) : .none
    }

    public static func refreshActionOnProjectDidAddFiles(
        eventProjectPath: String,
        currentProjectPath: String?
    ) -> RefreshEventAction {
        refreshActionOnProjectDidAddFiles(
            isCurrentProject: isCurrentProject(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            )
        )
    }

    public static func refreshActionOnProjectDidAddFiles<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String
    ) -> RefreshEventAction {
        refreshActionOnProjectDidAddFiles(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath)
        )
    }

    public static func refreshActionOnGitDirectoryChanged(isCurrentProject: Bool) -> RefreshEventAction {
        isCurrentProject ? .refresh(reason: gitDirectoryDidChangeRefreshReason) : .none
    }

    public static func refreshActionOnGitDirectoryChanged(
        eventProjectPath: String,
        currentProjectPath: String?
    ) -> RefreshEventAction {
        refreshActionOnGitDirectoryChanged(
            isCurrentProject: isCurrentProject(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            )
        )
    }

    public static func refreshActionOnGitDirectoryChanged<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String
    ) -> RefreshEventAction {
        refreshActionOnGitDirectoryChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath)
        )
    }

    public static func refreshActionOnAppWillBecomeActive() -> RefreshEventAction {
        .refreshImmediately(reason: appWillBecomeActiveRefreshReason)
    }

    public static func refreshAction(for event: RefreshEvent) -> RefreshEventAction {
        switch event {
        case .appear:
            return refreshActionOnAppear()
        case .projectChanged:
            return refreshActionOnProjectChanged()
        case .commitChanged:
            return refreshActionOnCommitChanged()
        case .projectDidCommit:
            return refreshActionOnProjectDidCommit()
        case let .projectDidAddFiles(eventProjectPath, currentProjectPath):
            return refreshActionOnProjectDidAddFiles(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            )
        case let .gitDirectoryChanged(eventProjectPath, currentProjectPath):
            return refreshActionOnGitDirectoryChanged(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            )
        case .appWillBecomeActive:
            return refreshActionOnAppWillBecomeActive()
        }
    }

    public static func refreshAction<Project>(
        projectDidAddFilesEventProjectPath eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String
    ) -> RefreshEventAction {
        refreshAction(for: .projectDidAddFiles(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath)
        ))
    }

    public static func refreshAction<Project>(
        gitDirectoryChangedEventProjectPath eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String
    ) -> RefreshEventAction {
        refreshAction(for: .gitDirectoryChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath)
        ))
    }

    public static func performRefreshAction(
        _ action: RefreshEventAction,
        refresh: (String) -> Void,
        refreshImmediately: (String) -> Void
    ) {
        switch action {
        case let .refresh(reason):
            refresh(reason)
        case let .refreshImmediately(reason):
            refreshImmediately(reason)
        case .none:
            break
        }
    }

    public static func performRetryAfterError(refresh: (String) -> Void) {
        refresh(retryAfterErrorRefreshReason)
    }

    public static func performRefreshEvent(
        _ event: RefreshEvent,
        performRefreshAction: (RefreshEventAction) -> Void
    ) {
        performRefreshAction(refreshAction(for: event))
    }

    public static func performAppear(performRefreshAction: (RefreshEventAction) -> Void) {
        performRefreshEvent(.appear, performRefreshAction: performRefreshAction)
    }

    public static func performProjectChange(performRefreshAction: (RefreshEventAction) -> Void) {
        performRefreshEvent(.projectChanged, performRefreshAction: performRefreshAction)
    }

    public static func performCommitChange(performRefreshAction: (RefreshEventAction) -> Void) {
        performRefreshEvent(.commitChanged, performRefreshAction: performRefreshAction)
    }

    public static func performProjectDidCommit(performRefreshAction: (RefreshEventAction) -> Void) {
        performRefreshEvent(.projectDidCommit, performRefreshAction: performRefreshAction)
    }

    public static func performAppWillBecomeActive(performRefreshAction: (RefreshEventAction) -> Void) {
        performRefreshEvent(.appWillBecomeActive, performRefreshAction: performRefreshAction)
    }

    public static func performProjectDidAddFiles<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        performRefreshAction: (RefreshEventAction) -> Void
    ) {
        performRefreshAction(refreshAction(
            projectDidAddFilesEventProjectPath: eventProjectPath,
            currentProject: currentProject,
            currentProjectPath: currentProjectPath
        ))
    }

    public static func performGitDirectoryChanged<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        performRefreshAction: (RefreshEventAction) -> Void
    ) {
        performRefreshAction(refreshAction(
            gitDirectoryChangedEventProjectPath: eventProjectPath,
            currentProject: currentProject,
            currentProjectPath: currentProjectPath
        ))
    }

    public static func refreshStartState() -> RefreshLifecycleState {
        RefreshLifecycleState(isLoading: true, errorMessage: nil)
    }

    public static func refreshStoppedState() -> RefreshLifecycleState {
        RefreshLifecycleState(isLoading: false, errorMessage: nil)
    }

    public static func refreshFailedState(errorMessage: String) -> RefreshLifecycleState {
        RefreshLifecycleState(isLoading: false, errorMessage: errorMessage)
    }

    public static func performRefreshLifecycleState(
        _ state: RefreshLifecycleState,
        setLoading: (Bool) -> Void,
        setErrorMessage: (String?) -> Void
    ) {
        setLoading(state.isLoading)
        setErrorMessage(state.errorMessage)
    }

    @discardableResult
    public static func performRequiredProjectRefresh<Project>(
        project: Project?,
        applyStartState: (RefreshLifecycleState) async -> Void,
        applyMissingProjectState: (RefreshLifecycleState) async -> Void,
        refresh: (Project) async -> Void
    ) async -> Bool {
        await applyStartState(refreshStartState())

        guard let project else {
            await applyMissingProjectState(refreshStoppedState())
            return false
        }

        await refresh(project)
        return true
    }

    public static func performRequiredProjectRefreshRequest<Project>(
        project: Project?,
        reason: String,
        applyStartState: (RefreshLifecycleState) async -> Void,
        applyMissingProjectState: (RefreshLifecycleState) async -> Void,
        refresh: (ProjectRefreshRequest, Project) async -> Void
    ) async -> Bool {
        await applyStartState(refreshStartState())

        guard let project else {
            await applyMissingProjectState(refreshStoppedState())
            return false
        }

        await refresh(ProjectRefreshRequest(reason: reason), project)
        return true
    }

    public static func performRequiredProjectRefreshCommand<Project>(
        project: Project?,
        reason: String,
        applyStartState: (RefreshLifecycleState) async -> Void,
        applyMissingProjectState: (RefreshLifecycleState) async -> Void,
        refresh: (ProjectRefreshCommand<Project>) async -> Void
    ) async -> Bool {
        await performRequiredProjectRefreshRequest(
            project: project,
            reason: reason,
            applyStartState: applyStartState,
            applyMissingProjectState: applyMissingProjectState
        ) { request, project in
            await refresh(ProjectRefreshCommand(request: request, project: project))
        }
    }

    public static func rowBackgroundState(isHovered: Bool) -> RowBackgroundState {
        isHovered ? .hovered : .clear
    }

    public static func stageState(
        path: String,
        stagedPaths: Set<String>,
        unstagedPaths: Set<String>
    ) -> FileStageState {
        let isStaged = stagedPaths.contains(path)
        let isUnstaged = unstagedPaths.contains(path)

        if isStaged && isUnstaged {
            return .stagedAndUnstaged
        }

        if isStaged {
            return .staged
        }

        return .unstaged
    }

    public static func discardSelectedAlertMessage(
        selectedCount: Int,
        untrackedCount: Int
    ) -> String {
        if untrackedCount > 0 {
            return GitDetailLocalization.string("Are you sure you want to discard changes for \(selectedCount) files? \(untrackedCount) untracked files will be deleted. This action cannot be undone.")
        }

        return GitDetailLocalization.string("Are you sure you want to discard changes for \(selectedCount) files? This action cannot be undone.")
    }

    public static func discardFileAlertMessage(path: String, isUntracked: Bool) -> String {
        if isUntracked {
            return GitDetailLocalization.string("Are you sure you want to discard changes for \(path)? This untracked file will be deleted. This action cannot be undone.")
        }

        return GitDetailLocalization.string("Are you sure you want to discard changes for \(path)? This action cannot be undone.")
    }

    public static func discardFileAlertMessage(path: String, untrackedPaths: Set<String>) -> String {
        discardFileAlertMessage(
            path: path,
            isUntracked: untrackedPaths.contains(path)
        )
    }

    public static func discardFileAlertMessage<Item>(
        file: Item?,
        path: (Item) -> String,
        untrackedPaths: Set<String>
    ) -> String {
        guard let file else {
            return ""
        }

        return discardFileAlertMessage(
            path: path(file),
            untrackedPaths: untrackedPaths
        )
    }

    public static func discardAllAlertMessage(
        totalFileCount: Int,
        stagedCount: Int,
        unstagedCount: Int,
        untrackedCount: Int
    ) -> String {
        var details: [String] = []
        if stagedCount > 0 {
            details.append(GitDetailLocalization.string("\(stagedCount) staged files"))
        }
        if unstagedCount > 0 {
            details.append(GitDetailLocalization.string("\(unstagedCount) unstaged files"))
        }
        if untrackedCount > 0 {
            details.append(GitDetailLocalization.string("\(untrackedCount) untracked files will be deleted"))
        }

        let summary = details.isEmpty ? GitDetailLocalization.string("\(totalFileCount) files") : details.joined(separator: ", ")
        return GitDetailLocalization.string("Are you sure you want to discard all changes? This will affect \(summary). This action cannot be undone.")
    }

    public static func discardAllAlertText() -> DiscardAlertText {
        DiscardAlertText(
            title: GitDetailLocalization.string("Confirm Discard All Changes"),
            cancelButtonTitle: GitDetailLocalization.string("Cancel"),
            destructiveButtonTitle: GitDetailLocalization.string("Discard All")
        )
    }

    public static func discardSelectedAlertText() -> DiscardAlertText {
        DiscardAlertText(
            title: GitDetailLocalization.string("Confirm Discard Selected Changes"),
            cancelButtonTitle: GitDetailLocalization.string("Cancel"),
            destructiveButtonTitle: GitDetailLocalization.string("Discard Selected")
        )
    }

    public static func discardFileAlertText() -> DiscardAlertText {
        DiscardAlertText(
            title: GitDetailLocalization.string("Confirm Discard File Changes"),
            cancelButtonTitle: GitDetailLocalization.string("Cancel"),
            destructiveButtonTitle: GitDetailLocalization.string("Discard File")
        )
    }

    public static func discardAllPromptState(from presentationState: PresentationState) -> DiscardPromptState {
        DiscardPromptState(showsPrompt: presentationState.showsDiscardAll)
    }

    public static func discardSelectedPromptState(from presentationState: PresentationState) -> DiscardPromptState {
        DiscardPromptState(showsPrompt: presentationState.showsBatchActionBar)
    }

    public static func performDiscardAllPrompt(
        presentationState: PresentationState,
        setPresented: (Bool) -> Void
    ) {
        setPresented(discardAllPromptState(from: presentationState).showsPrompt)
    }

    public static func performDiscardSelectedPrompt(
        presentationState: PresentationState,
        setPresented: (Bool) -> Void
    ) {
        setPresented(discardSelectedPromptState(from: presentationState).showsPrompt)
    }

    public static func discardFilePromptState(canDiscard: Bool) -> DiscardPromptState {
        DiscardPromptState(showsPrompt: canDiscard)
    }

    public static func discardSelectionPromptState(
        hasSelection: Bool,
        isHistoryMode: Bool
    ) -> DiscardPromptState {
        DiscardPromptState(showsPrompt: hasSelection && isHistoryMode == false)
    }

    @discardableResult
    public static func performDiscardSelectionPrompt<Item>(
        selection: Item?,
        isHistoryMode: Bool,
        prompt: (Item) -> Void
    ) -> Bool {
        guard let selection,
              discardSelectionPromptState(
                  hasSelection: true,
                  isHistoryMode: isHistoryMode
              ).showsPrompt else {
            return false
        }

        prompt(selection)
        return true
    }

    public static func performFileSelection<Item>(
        _ item: Item?,
        setSelection: (Item?) -> Void,
        syncSelection: (Item?) -> Void
    ) {
        setSelection(item)
        syncSelection(item)
    }

    public static func performSelectionChange<Item>(
        _ item: Item?,
        syncSelection: (Item?) -> Void
    ) {
        syncSelection(item)
    }

    public static func performDiscardFilePrompt<Item>(
        _ item: Item,
        setFileToDiscard: (Item) -> Void,
        setPresented: (Bool) -> Void
    ) {
        setFileToDiscard(item)
        setPresented(true)
    }

    public static func performDiscardFilePromptCancellation<Item>(
        setFileToDiscard: (Item?) -> Void
    ) {
        setFileToDiscard(nil)
    }

    @discardableResult
    public static func performConfirmedDiscardFile<Item>(
        _ item: Item?,
        discard: (Item) -> Void,
        clearFileToDiscard: (Item?) -> Void
    ) -> Bool {
        defer {
            clearFileToDiscard(nil)
        }

        guard let item else {
            return false
        }

        discard(item)
        return true
    }

    public static func stagedFileMessage(path: String) -> String {
        GitDetailLocalization.string("Staged: \(path)")
    }

    public static func stagedFilesMessage(count: Int) -> String {
        GitDetailLocalization.string("Staged \(count) files")
    }

    public static func unstagedFileMessage(path: String) -> String {
        GitDetailLocalization.string("Unstaged: \(path)")
    }

    public static func unstagedFilesMessage(count: Int) -> String {
        GitDetailLocalization.string("Unstaged \(count) files")
    }

    public static func discardedFileChangesMessage(path: String) -> String {
        GitDetailLocalization.string("Discarded file changes: \(path)")
    }

    public static func discardedAllChangesMessage() -> String {
        GitDetailLocalization.string("Discarded all file changes")
    }

    public static func discardedSelectedChangesMessage(count: Int) -> String {
        GitDetailLocalization.string("Discarded changes for \(count) files")
    }

    public static func stageFileSuccessState(path: String) -> OperationSuccessState {
        OperationSuccessState(
            message: stagedFileMessage(path: path),
            refreshReason: afterStageFileRefreshReason,
            removesBatchSelectionPaths: []
        )
    }

    public static func stageSelectedFilesSuccessState(paths: [String]) -> OperationSuccessState {
        OperationSuccessState(
            message: stagedFilesMessage(count: paths.count),
            refreshReason: afterStageSelectedFilesRefreshReason,
            removesBatchSelectionPaths: paths
        )
    }

    public static func unstageFileSuccessState(path: String) -> OperationSuccessState {
        OperationSuccessState(
            message: unstagedFileMessage(path: path),
            refreshReason: afterUnstageFileRefreshReason,
            removesBatchSelectionPaths: []
        )
    }

    public static func unstageSelectedFilesSuccessState(paths: [String]) -> OperationSuccessState {
        OperationSuccessState(
            message: unstagedFilesMessage(count: paths.count),
            refreshReason: afterUnstageSelectedFilesRefreshReason,
            removesBatchSelectionPaths: paths
        )
    }

    public static func discardFileChangesSuccessState(path: String) -> OperationSuccessState {
        OperationSuccessState(
            message: discardedFileChangesMessage(path: path),
            refreshReason: afterDiscardChangesRefreshReason,
            removesBatchSelectionPaths: []
        )
    }

    public static func discardAllChangesSuccessState() -> OperationSuccessState {
        OperationSuccessState(
            message: discardedAllChangesMessage(),
            refreshReason: afterDiscardAllChangesRefreshReason,
            removesBatchSelectionPaths: []
        )
    }

    public static func discardSelectedChangesSuccessState(paths: [String]) -> OperationSuccessState {
        OperationSuccessState(
            message: discardedSelectedChangesMessage(count: paths.count),
            refreshReason: afterDiscardSelectedChangesRefreshReason,
            removesBatchSelectionPaths: paths
        )
    }

    public static func operationCompletionState(
        successState: OperationSuccessState,
        selectedBatchPaths: Set<String>
    ) -> OperationCompletionState {
        OperationCompletionState(
            message: successState.message,
            selectedBatchPaths: retainedBatchSelection(
                afterRemoving: successState.removesBatchSelectionPaths,
                from: selectedBatchPaths
            )
        )
    }

    public static func performOperationSuccessState(
        _ state: OperationSuccessState,
        selectedBatchPaths: Set<String>,
        showMessage: (String) -> Void,
        setSelectedBatchPaths: (Set<String>) -> Void
    ) {
        let completionState = operationCompletionState(
            successState: state,
            selectedBatchPaths: selectedBatchPaths
        )
        showMessage(completionState.message)
        setSelectedBatchPaths(completionState.selectedBatchPaths)
    }

    public static func singleFileOperationRequest(path: String) -> FileOperationRequestState {
        FileOperationRequestState(paths: [path])
    }

    public static func stageSelectedOperationRequest(from batchState: BatchActionState) -> FileOperationRequestState {
        FileOperationRequestState(paths: batchState.stageablePaths)
    }

    public static func unstageSelectedOperationRequest(from batchState: BatchActionState) -> FileOperationRequestState {
        FileOperationRequestState(paths: batchState.unstageablePaths)
    }

    public static func discardSelectedOperationRequest(from batchState: BatchActionState) -> FileOperationRequestState {
        FileOperationRequestState(paths: batchState.discardablePaths)
    }

    public static func stageFileOperationCommand(path: String) -> FileOperationCommand {
        FileOperationCommand(
            kind: .stage,
            request: singleFileOperationRequest(path: path),
            failureLogMessage: "Stage file failed"
        )
    }

    public static func stageSelectedOperationCommand(from batchState: BatchActionState) -> FileOperationCommand {
        FileOperationCommand(
            kind: .stage,
            request: stageSelectedOperationRequest(from: batchState),
            failureLogMessage: "Batch stage failed"
        )
    }

    public static func unstageFileOperationCommand(path: String) -> FileOperationCommand {
        FileOperationCommand(
            kind: .unstage,
            request: singleFileOperationRequest(path: path),
            failureLogMessage: "Unstage file failed"
        )
    }

    public static func unstageSelectedOperationCommand(from batchState: BatchActionState) -> FileOperationCommand {
        FileOperationCommand(
            kind: .unstage,
            request: unstageSelectedOperationRequest(from: batchState),
            failureLogMessage: "Batch unstage failed"
        )
    }

    public static func discardFileOperationCommand(path: String) -> FileOperationCommand {
        FileOperationCommand(
            kind: .discardFile,
            request: singleFileOperationRequest(path: path),
            failureLogMessage: "Failed to discard file changes"
        )
    }

    public static func discardAllOperationCommand() -> FileOperationCommand {
        FileOperationCommand(
            kind: .discardAll,
            failureLogMessage: "Failed to discard all changes"
        )
    }

    public static func discardSelectedOperationCommand(from batchState: BatchActionState) -> FileOperationCommand {
        FileOperationCommand(
            kind: .discardSelected,
            request: discardSelectedOperationRequest(from: batchState),
            failureLogMessage: "Failed to batch discard"
        )
    }

    public static func fileOperationCommand(for action: FileOperationAction) -> FileOperationCommand {
        switch action {
        case let .stageFile(path):
            return stageFileOperationCommand(path: path)
        case let .stageSelected(batchState):
            return stageSelectedOperationCommand(from: batchState)
        case let .unstageFile(path):
            return unstageFileOperationCommand(path: path)
        case let .unstageSelected(batchState):
            return unstageSelectedOperationCommand(from: batchState)
        case let .discardFile(path):
            return discardFileOperationCommand(path: path)
        case .discardAll:
            return discardAllOperationCommand()
        case let .discardSelected(batchState):
            return discardSelectedOperationCommand(from: batchState)
        }
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        perform: (Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        perform: (Project) async -> Void
    ) async -> Bool {
        guard let project else {
            return false
        }

        await perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectFileOperation<Project>(
        project: Project?,
        command: FileOperationCommand,
        perform: (FileOperationCommand, Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(command, project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectFileOperation<Project>(
        project: Project?,
        action: FileOperationAction,
        perform: (FileOperationCommand, Project) -> Void
    ) -> Bool {
        performRequiredProjectFileOperation(
            project: project,
            command: fileOperationCommand(for: action),
            perform: perform
        )
    }

    @discardableResult
    public static func performRequiredProjectFileOperationCommand<Project>(
        project: Project?,
        command: FileOperationCommand,
        perform: (ProjectFileOperationCommand<Project>) -> Void
    ) -> Bool {
        performRequiredProjectFileOperation(
            project: project,
            command: command
        ) { command, project in
            perform(ProjectFileOperationCommand(command: command, project: project))
        }
    }

    @discardableResult
    public static func performRequiredProjectFileOperationCommand<Project>(
        project: Project?,
        action: FileOperationAction,
        perform: (ProjectFileOperationCommand<Project>) -> Void
    ) -> Bool {
        performRequiredProjectFileOperationCommand(
            project: project,
            command: fileOperationCommand(for: action),
            perform: perform
        )
    }

    @discardableResult
    public static func performRequiredProjectStageFileOperation<Project, File>(
        project: Project?,
        file: File,
        path: (File) -> String,
        perform: (FileOperationCommand, Project) -> Void
    ) -> Bool {
        performRequiredProjectFileOperation(
            project: project,
            action: .stageFile(path: path(file)),
            perform: perform
        )
    }

    @discardableResult
    public static func performRequiredProjectUnstageFileOperation<Project, File>(
        project: Project?,
        file: File,
        path: (File) -> String,
        perform: (FileOperationCommand, Project) -> Void
    ) -> Bool {
        performRequiredProjectFileOperation(
            project: project,
            action: .unstageFile(path: path(file)),
            perform: perform
        )
    }

    @discardableResult
    public static func performRequiredProjectDiscardFileOperation<Project, File>(
        project: Project?,
        file: File,
        path: (File) -> String,
        perform: (FileOperationCommand, Project) -> Void
    ) -> Bool {
        performRequiredProjectFileOperation(
            project: project,
            action: .discardFile(path: path(file)),
            perform: perform
        )
    }

    public static func performFileOperationRequest(
        _ request: FileOperationRequestState,
        perform: (FileOperationRequestState) -> Void
    ) -> Bool {
        guard request.canPerform else {
            return false
        }

        perform(request)
        return true
    }

    public static func performFileOperation(
        _ request: FileOperationRequestState,
        operation: (FileOperationRequestState) async throws -> OperationSuccessState,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        guard request.canPerform else {
            return
        }

        do {
            let successState = try await operation(request)
            await applySuccess(successState)
            await refresh(successState.refreshReason)
        } catch {
            await handleFailure(error)
        }
    }

    public static func performFileOperation(
        operation: () async throws -> OperationSuccessState,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        do {
            let successState = try await operation()
            await applySuccess(successState)
            await refresh(successState.refreshReason)
        } catch {
            await handleFailure(error)
        }
    }

    public static func performStageFiles(
        _ request: FileOperationRequestState,
        addFiles: ([String]) throws -> Void
    ) throws -> OperationSuccessState {
        try addFiles(request.paths)
        if request.paths.count == 1, let path = request.primaryPath {
            return stageFileSuccessState(path: path)
        }
        return stageSelectedFilesSuccessState(paths: request.paths)
    }

    public static func performUnstageFiles(
        _ request: FileOperationRequestState,
        unstageFiles: ([String]) throws -> Void
    ) throws -> OperationSuccessState {
        try unstageFiles(request.paths)
        if request.paths.count == 1, let path = request.primaryPath {
            return unstageFileSuccessState(path: path)
        }
        return unstageSelectedFilesSuccessState(paths: request.paths)
    }

    public static func performDiscardFileChanges(
        _ request: FileOperationRequestState,
        discard: (String) throws -> Void
    ) throws -> OperationSuccessState {
        guard let path = request.primaryPath else {
            return discardFileChangesSuccessState(path: "")
        }

        try discard(path)
        return discardFileChangesSuccessState(path: path)
    }

    public static func performDiscardSelectedChanges(
        _ request: FileOperationRequestState,
        discard: (String) throws -> Void
    ) throws -> OperationSuccessState {
        for path in request.paths {
            try discard(path)
        }
        return discardSelectedChangesSuccessState(paths: request.paths)
    }

    public static func performStageFileOperation(
        _ request: FileOperationRequestState,
        addFiles: ([String]) async throws -> Void,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performFileOperation(
            request,
            operation: { request in
                try await addFiles(request.paths)
                if request.paths.count == 1, let path = request.primaryPath {
                    return stageFileSuccessState(path: path)
                }
                return stageSelectedFilesSuccessState(paths: request.paths)
            },
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func performUnstageFileOperation(
        _ request: FileOperationRequestState,
        unstageFiles: ([String]) async throws -> Void,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performFileOperation(
            request,
            operation: { request in
                try await unstageFiles(request.paths)
                if request.paths.count == 1, let path = request.primaryPath {
                    return unstageFileSuccessState(path: path)
                }
                return unstageSelectedFilesSuccessState(paths: request.paths)
            },
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func performDiscardFileOperation(
        _ request: FileOperationRequestState,
        discard: (String) async throws -> Void,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performFileOperation(
            request,
            operation: { request in
                guard let path = request.primaryPath else {
                    return discardFileChangesSuccessState(path: "")
                }

                try await discard(path)
                return discardFileChangesSuccessState(path: path)
            },
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func performDiscardAllChangesOperation(
        discardAllChanges: () async throws -> Void,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performFileOperation(
            operation: {
                try await discardAllChanges()
                return discardAllChangesSuccessState()
            },
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func performDiscardSelectedChangesOperation(
        _ request: FileOperationRequestState,
        discard: (String) async throws -> Void,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performFileOperation(
            request,
            operation: { request in
                for path in request.paths {
                    try await discard(path)
                }
                return discardSelectedChangesSuccessState(paths: request.paths)
            },
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func performFileOperation(
        kind: FileOperationKind,
        request: FileOperationRequestState = FileOperationRequestState(paths: []),
        addFiles: ([String]) async throws -> Void = { _ in },
        unstageFiles: ([String]) async throws -> Void = { _ in },
        discard: (String) async throws -> Void = { _ in },
        discardAllChanges: () async throws -> Void = {},
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        switch kind {
        case .stage:
            await performStageFileOperation(
                request,
                addFiles: addFiles,
                applySuccess: applySuccess,
                refresh: refresh,
                handleFailure: handleFailure
            )
        case .unstage:
            await performUnstageFileOperation(
                request,
                unstageFiles: unstageFiles,
                applySuccess: applySuccess,
                refresh: refresh,
                handleFailure: handleFailure
            )
        case .discardFile:
            await performDiscardFileOperation(
                request,
                discard: discard,
                applySuccess: applySuccess,
                refresh: refresh,
                handleFailure: handleFailure
            )
        case .discardAll:
            await performDiscardAllChangesOperation(
                discardAllChanges: discardAllChanges,
                applySuccess: applySuccess,
                refresh: refresh,
                handleFailure: handleFailure
            )
        case .discardSelected:
            await performDiscardSelectedChangesOperation(
                request,
                discard: discard,
                applySuccess: applySuccess,
                refresh: refresh,
                handleFailure: handleFailure
            )
        }
    }

    public static func performFileOperation(
        command: FileOperationCommand,
        addFiles: ([String]) async throws -> Void = { _ in },
        unstageFiles: ([String]) async throws -> Void = { _ in },
        discard: (String) async throws -> Void = { _ in },
        discardAllChanges: () async throws -> Void = {},
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (String, Error) async -> Void
    ) async {
        await performFileOperation(
            kind: command.kind,
            request: command.request,
            addFiles: addFiles,
            unstageFiles: unstageFiles,
            discard: discard,
            discardAllChanges: discardAllChanges,
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: { error in
                await handleFailure(command.failureLogMessage, error)
            }
        )
    }

    public static func performFileOperation(
        command: FileOperationCommand,
        handlers: FileOperationHandlers,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (String, Error) async -> Void
    ) async {
        await performFileOperation(
            command: command,
            addFiles: handlers.addFiles,
            unstageFiles: handlers.unstageFiles,
            discard: handlers.discard,
            discardAllChanges: handlers.discardAllChanges,
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func fileOperationHandlers<Project>(
        for project: Project,
        handlers: ProjectFileOperationHandlers<Project>
    ) -> FileOperationHandlers {
        FileOperationHandlers(
            addFiles: { paths in
                try await handlers.addFiles(project, paths)
            },
            unstageFiles: { paths in
                try await handlers.unstageFiles(project, paths)
            },
            discard: { path in
                try await handlers.discard(project, path)
            },
            discardAllChanges: {
                try await handlers.discardAllChanges(project)
            }
        )
    }

    public static func performFileOperation<Project>(
        projectCommand: ProjectFileOperationCommand<Project>,
        handlers: ProjectFileOperationHandlers<Project>,
        applySuccess: (OperationSuccessState) async -> Void,
        refresh: (String) async -> Void,
        handleFailure: (String, Error) async -> Void
    ) async {
        await performFileOperation(
            command: projectCommand.command,
            handlers: fileOperationHandlers(for: projectCommand.project, handlers: handlers),
            applySuccess: applySuccess,
            refresh: refresh,
            handleFailure: handleFailure
        )
    }

    public static func performPrimaryFileOperationRequest(
        _ request: FileOperationRequestState,
        perform: (String) -> Void
    ) -> Bool {
        guard let path = request.primaryPath else {
            return false
        }

        perform(path)
        return true
    }

    public static func refreshedSelectionPath(
        preferredPath: String?,
        newPaths: [String]
    ) -> String? {
        if let preferredPath, newPaths.contains(preferredPath) {
            return preferredPath
        }

        return newPaths.first
    }

    public static func selectedBatchPathsAfterRefresh(
        selectedPaths: Set<String>,
        newPaths: [String]
    ) -> Set<String> {
        selectedPaths.intersection(Set(newPaths))
    }

    public static func refreshState<Status>(
        preferredPath: String?,
        newPaths: [String],
        statusEntries: [(path: String, indexStatus: Status, workTreeStatus: Status)],
        selectedBatchPaths: Set<String>
    ) -> RefreshState {
        RefreshState(
            selectedPath: refreshedSelectionPath(preferredPath: preferredPath, newPaths: newPaths),
            stagedPaths: stagedPaths(indexStatuses: statusEntries.map {
                (path: $0.path, indexStatus: $0.indexStatus)
            }),
            unstagedPaths: unstagedPaths(statuses: statusEntries),
            untrackedPaths: untrackedPaths(indexStatuses: statusEntries.map {
                (path: $0.path, indexStatus: $0.indexStatus)
            }),
            selectedBatchPaths: selectedBatchPathsAfterRefresh(
                selectedPaths: selectedBatchPaths,
                newPaths: newPaths
            )
        )
    }

    public static func shouldApplyRefreshResult(
        expectedCommitHash: String?,
        currentCommitHash: String?
    ) -> Bool {
        expectedCommitHash == currentCommitHash
    }

    public static func selectedCommitHash<Commit>(
        selectedCommit: Commit?,
        hash: (Commit) -> String
    ) -> String? {
        selectedCommit.map(hash)
    }

    public static func performRefreshLoad<FileItem, StatusEntry>(
        selectedCommitHash: String?,
        loadCommitFiles: (String) async throws -> [FileItem],
        loadWorktreeFiles: () async throws -> [FileItem],
        loadStatusEntries: () async throws -> [StatusEntry]
    ) async throws -> RefreshLoadResult<FileItem, StatusEntry> {
        try Task.checkCancellation()

        let files: [FileItem]
        let statusEntries: [StatusEntry]
        if let selectedCommitHash {
            files = try await loadCommitFiles(selectedCommitHash)
            statusEntries = []
        } else {
            files = try await loadWorktreeFiles()
            statusEntries = try await loadStatusEntries()
        }

        try Task.checkCancellation()
        return RefreshLoadResult(
            files: files,
            selectedCommitHash: selectedCommitHash,
            statusEntries: statusEntries
        )
    }

    public static func performRefreshLoad<FileItem, StatusEntry>(
        selectedCommitHash: String?,
        handlers: RefreshLoadHandlers<FileItem, StatusEntry>
    ) async throws -> RefreshLoadResult<FileItem, StatusEntry> {
        try await performRefreshLoad(
            selectedCommitHash: selectedCommitHash,
            loadCommitFiles: handlers.loadCommitFiles,
            loadWorktreeFiles: handlers.loadWorktreeFiles,
            loadStatusEntries: handlers.loadStatusEntries
        )
    }

    public static func refreshLoadHandlers<Project, FileItem, StatusEntry>(
        for project: Project,
        handlers: ProjectRefreshLoadHandlers<Project, FileItem, StatusEntry>
    ) -> RefreshLoadHandlers<FileItem, StatusEntry> {
        RefreshLoadHandlers(
            loadCommitFiles: { hash in
                try await handlers.loadCommitFiles(project, hash)
            },
            loadWorktreeFiles: {
                try await handlers.loadWorktreeFiles(project)
            },
            loadStatusEntries: {
                try await handlers.loadStatusEntries(project)
            }
        )
    }

    public static func refreshResultApplicationState<Status>(
        expectedCommitHash: String?,
        currentCommitHash: String?,
        preferredPath: String?,
        newPaths: [String],
        statusEntries: [(path: String, indexStatus: Status, workTreeStatus: Status)],
        selectedBatchPaths: Set<String>
    ) -> RefreshResultApplicationState {
        guard shouldApplyRefreshResult(
            expectedCommitHash: expectedCommitHash,
            currentCommitHash: currentCommitHash
        ) else {
            return RefreshResultApplicationState(shouldApply: false, refreshState: nil)
        }

        return RefreshResultApplicationState(
            shouldApply: true,
            refreshState: refreshState(
                preferredPath: preferredPath,
                newPaths: newPaths,
                statusEntries: statusEntries,
                selectedBatchPaths: selectedBatchPaths
            )
        )
    }

    public static func refreshResultApplicationState<FileItem, StatusEntry, Status>(
        expectedCommitHash: String?,
        currentCommitHash: String?,
        preferredPath: String?,
        newItems: [FileItem],
        itemPath: (FileItem) -> String,
        statusEntries: [StatusEntry],
        statusPath: (StatusEntry) -> String,
        indexStatus: (StatusEntry) -> Status,
        workTreeStatus: (StatusEntry) -> Status,
        selectedBatchPaths: Set<String>
    ) -> RefreshResultApplicationState {
        refreshResultApplicationState(
            expectedCommitHash: expectedCommitHash,
            currentCommitHash: currentCommitHash,
            preferredPath: preferredPath,
            newPaths: newItems.map(itemPath),
            statusEntries: statusEntries.map {
                (
                    path: statusPath($0),
                    indexStatus: indexStatus($0),
                    workTreeStatus: workTreeStatus($0)
                )
            },
            selectedBatchPaths: selectedBatchPaths
        )
    }

    public static func performRefreshResultApplicationState<FileItem>(
        _ state: RefreshResultApplicationState,
        newItems: [FileItem],
        itemPath: (FileItem) -> String,
        apply: ([FileItem], RefreshState, FileItem?) -> Void,
        skip: () -> Void
    ) {
        guard state.shouldApply, let refreshState = state.refreshState else {
            skip()
            return
        }

        apply(
            newItems,
            refreshState,
            selectedItem(from: refreshState, in: newItems, path: itemPath)
        )
    }

    public static func performRefreshResultState<FileItem>(
        items: [FileItem],
        refreshState: RefreshState,
        refreshedSelection: FileItem?,
        setItems: ([FileItem]) -> Void,
        setStagedPaths: (Set<String>) -> Void,
        setUnstagedPaths: (Set<String>) -> Void,
        setUntrackedPaths: (Set<String>) -> Void,
        setSelectedBatchPaths: (Set<String>) -> Void,
        setSelection: (FileItem?) -> Void,
        syncSelection: (FileItem?) -> Void,
        applyLifecycleState: (RefreshLifecycleState) -> Void
    ) {
        setItems(items)
        setStagedPaths(refreshState.stagedPaths)
        setUnstagedPaths(refreshState.unstagedPaths)
        setUntrackedPaths(refreshState.untrackedPaths)
        setSelectedBatchPaths(refreshState.selectedBatchPaths)
        setSelection(refreshedSelection)
        syncSelection(refreshedSelection)
        applyLifecycleState(refreshStoppedState())
    }

    public static func performRefreshOperation<FileItem, StatusEntry, Status>(
        selectedCommitHash: String?,
        loadCommitFiles: (String) async throws -> [FileItem],
        loadWorktreeFiles: () async throws -> [FileItem],
        loadStatusEntries: () async throws -> [StatusEntry],
        currentCommitHash: () async -> String?,
        preferredPath: () async -> String?,
        selectedBatchPaths: () async -> Set<String>,
        itemPath: (FileItem) -> String,
        statusPath: (StatusEntry) -> String,
        indexStatus: (StatusEntry) -> Status,
        workTreeStatus: (StatusEntry) -> Status,
        apply: ([FileItem], RefreshState, FileItem?) async -> Void,
        skip: () async -> Void
    ) async throws {
        let result = try await performRefreshLoad(
            selectedCommitHash: selectedCommitHash,
            loadCommitFiles: loadCommitFiles,
            loadWorktreeFiles: loadWorktreeFiles,
            loadStatusEntries: loadStatusEntries
        )
        let latestCommitHash = await currentCommitHash()
        let latestPreferredPath = await preferredPath()
        let latestSelectedBatchPaths = await selectedBatchPaths()
        let applicationState = refreshResultApplicationState(
            expectedCommitHash: result.selectedCommitHash,
            currentCommitHash: latestCommitHash,
            preferredPath: latestPreferredPath,
            newItems: result.files,
            itemPath: itemPath,
            statusEntries: result.statusEntries,
            statusPath: statusPath,
            indexStatus: indexStatus,
            workTreeStatus: workTreeStatus,
            selectedBatchPaths: latestSelectedBatchPaths
        )

        guard applicationState.shouldApply, let refreshState = applicationState.refreshState else {
            await skip()
            return
        }

        await apply(
            result.files,
            refreshState,
            selectedItem(from: refreshState, in: result.files, path: itemPath)
        )
    }

    public static func performRefreshOperation<FileItem, StatusEntry, Status>(
        selectedCommitHash: String?,
        handlers: RefreshLoadHandlers<FileItem, StatusEntry>,
        currentCommitHash: () async -> String?,
        preferredPath: () async -> String?,
        selectedBatchPaths: () async -> Set<String>,
        itemPath: (FileItem) -> String,
        statusPath: (StatusEntry) -> String,
        indexStatus: (StatusEntry) -> Status,
        workTreeStatus: (StatusEntry) -> Status,
        apply: ([FileItem], RefreshState, FileItem?) async -> Void,
        skip: () async -> Void
    ) async throws {
        try await performRefreshOperation(
            selectedCommitHash: selectedCommitHash,
            loadCommitFiles: handlers.loadCommitFiles,
            loadWorktreeFiles: handlers.loadWorktreeFiles,
            loadStatusEntries: handlers.loadStatusEntries,
            currentCommitHash: currentCommitHash,
            preferredPath: preferredPath,
            selectedBatchPaths: selectedBatchPaths,
            itemPath: itemPath,
            statusPath: statusPath,
            indexStatus: indexStatus,
            workTreeStatus: workTreeStatus,
            apply: apply,
            skip: skip
        )
    }

    public static func performRefreshOperation<Project, FileItem, StatusEntry, Status>(
        command: ProjectRefreshCommand<Project>,
        selectedCommitHash: String?,
        handlers: ProjectRefreshLoadHandlers<Project, FileItem, StatusEntry>,
        currentCommitHash: () async -> String?,
        preferredPath: () async -> String?,
        selectedBatchPaths: () async -> Set<String>,
        itemPath: (FileItem) -> String,
        statusPath: (StatusEntry) -> String,
        indexStatus: (StatusEntry) -> Status,
        workTreeStatus: (StatusEntry) -> Status,
        apply: ([FileItem], RefreshState, FileItem?) async -> Void,
        skip: () async -> Void
    ) async throws {
        try await performRefreshOperation(
            selectedCommitHash: selectedCommitHash,
            handlers: refreshLoadHandlers(for: command.project, handlers: handlers),
            currentCommitHash: currentCommitHash,
            preferredPath: preferredPath,
            selectedBatchPaths: selectedBatchPaths,
            itemPath: itemPath,
            statusPath: statusPath,
            indexStatus: indexStatus,
            workTreeStatus: workTreeStatus,
            apply: apply,
            skip: skip
        )
    }

    public static func batchSelectionPathsAfterToggle(
        currentSelection: Set<String>,
        path: String
    ) -> Set<String> {
        var selection = currentSelection
        if selection.contains(path) {
            selection.remove(path)
        } else {
            selection.insert(path)
        }
        return selection
    }

    public static func performBatchSelectionToggle(
        currentSelection: Set<String>,
        path: String,
        setSelectedBatchPaths: (Set<String>) -> Void
    ) {
        setSelectedBatchPaths(batchSelectionPathsAfterToggle(
            currentSelection: currentSelection,
            path: path
        ))
    }

    public static func batchSelectionPathsAfterSelectAll(
        currentSelection: Set<String>,
        visiblePaths: [String]
    ) -> Set<String> {
        currentSelection.union(Set(visiblePaths))
    }

    public static func batchSelectionPathsAfterSelectAll(
        currentSelection: Set<String>,
        presentationState: PresentationState
    ) -> Set<String> {
        batchSelectionPathsAfterSelectAll(
            currentSelection: currentSelection,
            visiblePaths: presentationState.visiblePaths
        )
    }

    public static func performBatchSelectionSelectAll(
        currentSelection: Set<String>,
        presentationState: PresentationState,
        setSelectedBatchPaths: (Set<String>) -> Void
    ) {
        setSelectedBatchPaths(batchSelectionPathsAfterSelectAll(
            currentSelection: currentSelection,
            presentationState: presentationState
        ))
    }

    public static func batchSelectionPathsAfterClear() -> Set<String> {
        []
    }

    public static func performBatchSelectionClear(
        setSelectedBatchPaths: (Set<String>) -> Void
    ) {
        setSelectedBatchPaths(batchSelectionPathsAfterClear())
    }

    public static func nextSelectionPath(
        currentPath: String?,
        visiblePaths: [String],
        direction: SelectionDirection
    ) -> String? {
        guard visiblePaths.isEmpty == false else { return nil }

        let currentIndex = currentPath.flatMap { visiblePaths.firstIndex(of: $0) }

        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = max((currentIndex ?? 0) - 1, 0)
        case .down:
            nextIndex = min((currentIndex ?? -1) + 1, visiblePaths.count - 1)
        }

        return visiblePaths[nextIndex]
    }

    public static func nextSelectionItem<Item>(
        currentPath: String?,
        presentationState: PresentationState,
        direction: SelectionDirection,
        in items: [Item],
        path itemPath: (Item) -> String
    ) -> Item? {
        guard let nextPath = nextSelectionPath(
            currentPath: currentPath,
            visiblePaths: presentationState.visiblePaths,
            direction: direction
        ) else {
            return nil
        }

        return firstItem(matching: nextPath, in: items, path: itemPath)
    }

    public static func selectionDirection(isMovingUp: Bool, isMovingDown: Bool) -> SelectionDirection? {
        if isMovingUp {
            return .up
        }

        if isMovingDown {
            return .down
        }

        return nil
    }

    @discardableResult
    public static func performNextSelection<Item>(
        currentPath: String?,
        presentationState: PresentationState,
        direction: SelectionDirection,
        in items: [Item],
        path itemPath: (Item) -> String,
        select: (Item) -> Void
    ) -> Bool {
        guard let nextItem = nextSelectionItem(
            currentPath: currentPath,
            presentationState: presentationState,
            direction: direction,
            in: items,
            path: itemPath
        ) else {
            return false
        }

        select(nextItem)
        return true
    }

    @discardableResult
    public static func performMoveSelection<Item>(
        currentPath: String?,
        presentationState: PresentationState,
        isMovingUp: Bool,
        isMovingDown: Bool,
        in items: [Item],
        path itemPath: (Item) -> String,
        select: (Item) -> Void
    ) -> Bool {
        guard let direction = selectionDirection(
            isMovingUp: isMovingUp,
            isMovingDown: isMovingDown
        ) else {
            return false
        }

        return performNextSelection(
            currentPath: currentPath,
            presentationState: presentationState,
            direction: direction,
            in: items,
            path: itemPath,
            select: select
        )
    }

    public static func sections(
        visiblePaths: [String],
        isHistoryMode: Bool,
        stagedPaths: Set<String>,
        unstagedPaths: Set<String>
    ) -> [FileSection] {
        guard visiblePaths.isEmpty == false else { return [] }

        if isHistoryMode {
            return [FileSection(kind: .historyFiles, paths: visiblePaths)]
        }

        var changes: [String] = []
        var staged: [String] = []
        changes.reserveCapacity(visiblePaths.count)
        staged.reserveCapacity(visiblePaths.count)

        for path in visiblePaths {
            let state = stageState(path: path, stagedPaths: stagedPaths, unstagedPaths: unstagedPaths)
            if state == .unstaged || state == .stagedAndUnstaged {
                changes.append(path)
            } else if state == .staged {
                staged.append(path)
            }
        }

        var sections: [FileSection] = []
        if changes.isEmpty == false {
            sections.append(FileSection(kind: .changes, paths: changes))
        }
        if staged.isEmpty == false {
            sections.append(FileSection(kind: .stagedChanges, paths: staged))
        }
        return sections
    }

    public static func batchActionState(
        allPaths: [String],
        selectedPaths: Set<String>,
        stagedPaths: Set<String>,
        unstagedPaths: Set<String>,
        untrackedPaths: Set<String>
    ) -> BatchActionState {
        guard selectedPaths.isEmpty == false else {
            return BatchActionState(
                selectedPaths: [],
                stageablePaths: [],
                unstageablePaths: [],
                untrackedCount: 0
            )
        }

        let selected = allPaths.filter { selectedPaths.contains($0) }
        let stageable = selected.filter {
            stageState(path: $0, stagedPaths: stagedPaths, unstagedPaths: unstagedPaths).canStage
        }
        let unstageable = selected.filter {
            stageState(path: $0, stagedPaths: stagedPaths, unstagedPaths: unstagedPaths).canUnstage
        }
        let untrackedCount = selected.filter { untrackedPaths.contains($0) }.count

        return BatchActionState(
            selectedPaths: selected,
            stageablePaths: stageable,
            unstageablePaths: unstageable,
            untrackedCount: untrackedCount
        )
    }

    public static func presentationState(
        allPaths: [String],
        filterText: String,
        isHistoryMode: Bool,
        stagedPaths: Set<String>,
        unstagedPaths: Set<String>,
        untrackedPaths: Set<String>,
        selectedBatchPaths: Set<String>
    ) -> PresentationState {
        let visiblePaths = filteredPaths(allPaths, query: filterText)
        let sections = sections(
            visiblePaths: visiblePaths,
            isHistoryMode: isHistoryMode,
            stagedPaths: stagedPaths,
            unstagedPaths: unstagedPaths
        )
        let batchActionState = batchActionState(
            allPaths: allPaths,
            selectedPaths: selectedBatchPaths,
            stagedPaths: stagedPaths,
            unstagedPaths: unstagedPaths,
            untrackedPaths: untrackedPaths
        )

        return PresentationState(
            visiblePaths: visiblePaths,
            sections: sections,
            batchActionState: batchActionState,
            discardAllAlertMessage: discardAllAlertMessage(
                totalFileCount: allPaths.count,
                stagedCount: stagedPaths.count,
                unstagedCount: unstagedPaths.count,
                untrackedCount: untrackedPaths.count
            ),
            discardSelectedAlertMessage: discardSelectedAlertMessage(
                selectedCount: batchActionState.selectedCount,
                untrackedCount: batchActionState.untrackedCount
            ),
            showsDiscardAll: isHistoryMode == false && allPaths.isEmpty == false,
            showsBatchActionBar: isHistoryMode == false && selectedBatchPaths.isEmpty == false,
            canSelectAll: visiblePaths.isEmpty == false,
            showsEmptyState: visiblePaths.isEmpty,
            emptyStateIsFiltering: normalizedFilterQuery(filterText).isEmpty == false
        )
    }

    public static func presentationState<Item>(
        items: [Item],
        path: (Item) -> String,
        filterText: String,
        isHistoryMode: Bool,
        stagedPaths: Set<String>,
        unstagedPaths: Set<String>,
        untrackedPaths: Set<String>,
        selectedBatchPaths: Set<String>
    ) -> PresentationState {
        presentationState(
            allPaths: items.map(path),
            filterText: filterText,
            isHistoryMode: isHistoryMode,
            stagedPaths: stagedPaths,
            unstagedPaths: unstagedPaths,
            untrackedPaths: untrackedPaths,
            selectedBatchPaths: selectedBatchPaths
        )
    }

    public static func presentationState<Item, Commit>(
        items: [Item],
        path: (Item) -> String,
        filterText: String,
        selectedCommit: Commit?,
        stagedPaths: Set<String>,
        unstagedPaths: Set<String>,
        untrackedPaths: Set<String>,
        selectedBatchPaths: Set<String>
    ) -> PresentationState {
        presentationState(
            items: items,
            path: path,
            filterText: filterText,
            isHistoryMode: isHistoryMode(selectedCommit: selectedCommit),
            stagedPaths: stagedPaths,
            unstagedPaths: unstagedPaths,
            untrackedPaths: untrackedPaths,
            selectedBatchPaths: selectedBatchPaths
        )
    }

    public static func fileRowActionState(
        path: String,
        isHistoryMode: Bool,
        selectedBatchPaths: Set<String>
    ) -> FileRowActionState {
        let canEditWorkingTree = isHistoryMode == false
        return FileRowActionState(
            canEditWorkingTree: canEditWorkingTree,
            showsStageBadge: canEditWorkingTree,
            isBatchSelected: selectedBatchPaths.contains(path)
        )
    }

    public static func fileRowActionState<Commit>(
        path: String,
        selectedCommit: Commit?,
        selectedBatchPaths: Set<String>
    ) -> FileRowActionState {
        fileRowActionState(
            path: path,
            isHistoryMode: isHistoryMode(selectedCommit: selectedCommit),
            selectedBatchPaths: selectedBatchPaths
        )
    }

    public static func fileRowPresentationState<Project, Commit>(
        path: String,
        selectedCommit: Commit?,
        selectedBatchPaths: Set<String>,
        project: Project?,
        projectURL: (Project) -> URL?
    ) -> FileRowPresentationState {
        FileRowPresentationState(
            projectURL: project.map(projectURL) ?? nil,
            actionState: fileRowActionState(
                path: path,
                selectedCommit: selectedCommit,
                selectedBatchPaths: selectedBatchPaths
            )
        )
    }

    public static func retainedBatchSelection(afterRemoving removedPaths: [String], from selectedPaths: Set<String>) -> Set<String> {
        selectedPaths.subtracting(removedPaths)
    }

    public static func stagedPaths<Status>(indexStatuses: [(path: String, indexStatus: Status)]) -> Set<String> {
        Set(indexStatuses.filter {
            let indexStatus = String(describing: $0.indexStatus)
            return indexStatus != " " && indexStatus != "?"
        }.map(\.path))
    }

    public static func unstagedPaths<Status>(statuses: [(path: String, indexStatus: Status, workTreeStatus: Status)]) -> Set<String> {
        Set(statuses.filter {
            let indexStatus = String(describing: $0.indexStatus)
            let workTreeStatus = String(describing: $0.workTreeStatus)
            return workTreeStatus != " " || indexStatus == "?"
        }.map(\.path))
    }

    public static func untrackedPaths<Status>(indexStatuses: [(path: String, indexStatus: Status)]) -> Set<String> {
        Set(indexStatuses.filter {
            String(describing: $0.indexStatus) == "?"
        }.map(\.path))
    }
}
