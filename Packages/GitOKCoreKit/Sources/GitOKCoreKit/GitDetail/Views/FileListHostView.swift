import SwiftUI

public enum FileListHostLogEvent {
    case refreshSkipped(reason: String)
    case refreshStarted(reason: String)
    case commitChangedDuringRefresh
    case refreshCancelled(reason: String)
    case refreshFailure(message: String)
    case fileOperationFailure(failureLogMessage: String, error: Error)
}

public enum FileListHostEvent {
    case showInfoMessage(String)
    case showError(Error)
    case log(FileListHostLogEvent)
}

public struct FileListHostView<Project, Commit, FileItem, StatusEntry>: View where FileItem: Hashable {
    private let project: Project?
    private let selectedCommit: Commit?
    private let projectURL: (Project) -> URL?
    private let projectPath: (Project) -> String
    private let commitHash: (Commit) -> String
    private let filePath: (FileItem) -> String
    private let fileChangeType: (FileItem) -> String
    private let statusPath: (StatusEntry) -> String
    private let statusIndexStatus: (StatusEntry) -> Any
    private let statusWorkTreeStatus: (StatusEntry) -> Any
    private let scrollTarget: FileItem?
    private let syncSelection: @MainActor (FileItem?) -> Void
    private let loadCommitFiles: @MainActor (Project, String) async throws -> [FileItem]
    private let loadWorktreeFiles: @MainActor (Project) async throws -> [FileItem]
    private let loadStatusEntries: @MainActor (Project) async throws -> [StatusEntry]
    private let addFiles: @MainActor (Project, [String]) async throws -> Void
    private let unstageFiles: @MainActor (Project, [String]) async throws -> Void
    private let discardFileChanges: @MainActor (Project, String) async throws -> Void
    private let discardAllChanges: @MainActor (Project) async throws -> Void
    private let mapRefreshError: @MainActor (Error) -> String
    private let eventHandler: @MainActor (FileListHostEvent) -> Void
    private let projectChangeToken: Int
    private let commitChangeToken: Int
    private let projectDidCommitToken: Int
    private let projectDidAddFilesToken: Int
    private let projectDidAddFilesPath: String?
    private let gitDirectoryChangeToken: Int
    private let gitDirectoryEventProjectPath: String?
    private let appWillBecomeActiveToken: Int

    @State private var files: [FileItem] = []
    @State private var isLoading = true
    @State private var selection: FileItem?
    @State private var hoveredFile: FileItem?
    @State private var stagedFilePaths: Set<String> = []
    @State private var unstagedFilePaths: Set<String> = []
    @State private var untrackedFilePaths: Set<String> = []
    @State private var refreshTask: Task<Void, Never>?
    @State private var refreshWorkerTask: Task<Void, Error>?
    @State private var showDiscardFileAlert = false
    @State private var fileToDiscard: FileItem?
    @State private var showDiscardAllAlert = false
    @State private var lastRefreshTime: Date = .distantPast
    @State private var errorMessage: String?
    @State private var filterText = ""
    @State private var selectedBatchFilePaths: Set<String> = []
    @State private var showDiscardSelectedAlert = false

    public init(
        project: Project?,
        selectedCommit: Commit?,
        projectURL: @escaping (Project) -> URL?,
        projectPath: @escaping (Project) -> String,
        commitHash: @escaping (Commit) -> String,
        filePath: @escaping (FileItem) -> String,
        fileChangeType: @escaping (FileItem) -> String,
        statusPath: @escaping (StatusEntry) -> String,
        statusIndexStatus: @escaping (StatusEntry) -> Any,
        statusWorkTreeStatus: @escaping (StatusEntry) -> Any,
        scrollTarget: FileItem?,
        syncSelection: @MainActor @escaping (FileItem?) -> Void,
        loadCommitFiles: @MainActor @escaping (Project, String) async throws -> [FileItem],
        loadWorktreeFiles: @MainActor @escaping (Project) async throws -> [FileItem],
        loadStatusEntries: @MainActor @escaping (Project) async throws -> [StatusEntry],
        addFiles: @MainActor @escaping (Project, [String]) async throws -> Void,
        unstageFiles: @MainActor @escaping (Project, [String]) async throws -> Void,
        discardFileChanges: @MainActor @escaping (Project, String) async throws -> Void,
        discardAllChanges: @MainActor @escaping (Project) async throws -> Void,
        mapRefreshError: @MainActor @escaping (Error) -> String,
        eventHandler: @MainActor @escaping (FileListHostEvent) -> Void = { _ in },
        projectChangeToken: Int = 0,
        commitChangeToken: Int = 0,
        projectDidCommitToken: Int = 0,
        projectDidAddFilesToken: Int = 0,
        projectDidAddFilesPath: String? = nil,
        gitDirectoryChangeToken: Int = 0,
        gitDirectoryEventProjectPath: String? = nil,
        appWillBecomeActiveToken: Int = 0
    ) {
        self.project = project
        self.selectedCommit = selectedCommit
        self.projectURL = projectURL
        self.projectPath = projectPath
        self.commitHash = commitHash
        self.filePath = filePath
        self.fileChangeType = fileChangeType
        self.statusPath = statusPath
        self.statusIndexStatus = statusIndexStatus
        self.statusWorkTreeStatus = statusWorkTreeStatus
        self.scrollTarget = scrollTarget
        self.syncSelection = syncSelection
        self.loadCommitFiles = loadCommitFiles
        self.loadWorktreeFiles = loadWorktreeFiles
        self.loadStatusEntries = loadStatusEntries
        self.addFiles = addFiles
        self.unstageFiles = unstageFiles
        self.discardFileChanges = discardFileChanges
        self.discardAllChanges = discardAllChanges
        self.mapRefreshError = mapRefreshError
        self.eventHandler = eventHandler
        self.projectChangeToken = projectChangeToken
        self.commitChangeToken = commitChangeToken
        self.projectDidCommitToken = projectDidCommitToken
        self.projectDidAddFilesToken = projectDidAddFilesToken
        self.projectDidAddFilesPath = projectDidAddFilesPath
        self.gitDirectoryChangeToken = gitDirectoryChangeToken
        self.gitDirectoryEventProjectPath = gitDirectoryEventProjectPath
        self.appWillBecomeActiveToken = appWillBecomeActiveToken
    }

    public var body: some View {
        FileListRootView(
            filterText: $filterText,
            showDiscardFileAlert: $showDiscardFileAlert,
            showDiscardAllAlert: $showDiscardAllAlert,
            showDiscardSelectedAlert: $showDiscardSelectedAlert,
            fileCount: files.count,
            isLoading: isLoading,
            presentationState: filePresentationState,
            errorMessage: errorMessage,
            discardFileAlertMessage: discardFileAlertMessage,
            onRetry: {
                FileListRules.performRetryAfterError { reason in
                    Task {
                        await self.refresh(reason: reason)
                    }
                }
            },
            onDiscardAllPrompt: promptDiscardAll,
            onCancelDiscardFile: cancelDiscardFile,
            onDiscardFile: confirmDiscardFile,
            onDiscardAll: discardAllChangesAction,
            onDiscardSelected: discardSelectedChanges
        ) {
            fileListView
        }
        .onAppear(perform: onAppear)
        .onChange(of: projectChangeToken) { onProjectChange() }
        .onChange(of: commitChangeToken) { onCommitChange() }
        .onChange(of: selection) { onSelectionChange() }
        .onChange(of: projectDidCommitToken) { onProjectDidCommit() }
        .onChange(of: projectDidAddFilesToken) { onProjectDidAddFiles() }
        .onChange(of: gitDirectoryChangeToken) { onGitDirectoryDidChange() }
        .onChange(of: appWillBecomeActiveToken) { onAppWillBecomeActive() }
    }
}

private extension FileListHostView {
    var fileListView: some View {
        FileListContentView(
            selection: $selection,
            files: files,
            sections: fileSections,
            presentationState: filePresentationState,
            scrollTarget: scrollTarget,
            filesInSection: files(for:),
            rowContent: fileRow,
            onStageSelected: stageSelectedFiles,
            onUnstageSelected: unstageSelectedFiles,
            onDiscardSelected: promptDiscardSelected,
            onSelectAll: selectFilteredFiles,
            onClearSelection: clearBatchSelection
        )
    }

    func fileRow(_ file: FileItem) -> some View {
        let path = filePath(file)
        let rowState = FileListRules.fileRowPresentationState(
            path: path,
            selectedCommit: selectedCommit,
            selectedBatchPaths: selectedBatchFilePaths,
            project: project,
            projectURL: projectURL
        )
        let actionState = rowState.actionState

        return FileListRowView(
            file: file,
            path: path,
            changeType: fileChangeType(file),
            projectURL: rowState.projectURL,
            canEditWorkingTree: actionState.canEditWorkingTree,
            stageState: stageState(for: file),
            showsStageBadge: actionState.showsStageBadge,
            isBatchSelected: actionState.isBatchSelected,
            hoveredFile: $hoveredFile,
            isSelected: selection == file,
            onDiscardChanges: {
                discardChanges(for: file)
            },
            onToggleBatchSelection: {
                toggleBatchSelection(for: file)
            },
            onStage: {
                stageFile(file)
            },
            onUnstage: {
                unstageFile(file)
            },
            onSelect: {
                selectFile(file)
            },
            onMoveCommand: moveSelection,
            onDeleteCommand: {
                FileListRules.performDiscardSelectionPrompt(
                    selection: selection,
                    isHistoryMode: isHistoryMode
                ) { file in
                    promptDiscardFile(file)
                }
            }
        )
    }

    var filteredFiles: [FileItem] {
        FileListRules.visibleItems(
            from: files,
            presentationState: filePresentationState,
            path: filePath
        )
    }

    var filePresentationState: FileListRules.PresentationState {
        FileListRules.presentationState(
            items: files,
            path: filePath,
            filterText: filterText,
            selectedCommit: selectedCommit,
            stagedPaths: stagedFilePaths,
            unstagedPaths: unstagedFilePaths,
            untrackedPaths: untrackedFilePaths,
            selectedBatchPaths: selectedBatchFilePaths
        )
    }

    var isHistoryMode: Bool {
        FileListRules.isHistoryMode(selectedCommit: selectedCommit)
    }

    var fileSections: [FileListRules.FileSection] {
        filePresentationState.sections
    }

    func files(for section: FileListRules.FileSection) -> [FileItem] {
        FileListRules.items(from: filteredFiles, in: section, path: filePath)
    }

    var batchActionState: FileListRules.BatchActionState {
        filePresentationState.batchActionState
    }

    var discardFileAlertMessage: String {
        FileListRules.discardFileAlertMessage(
            file: fileToDiscard,
            path: filePath,
            untrackedPaths: untrackedFilePaths
        )
    }

    func applyRefreshLifecycleState(_ state: FileListRules.RefreshLifecycleState) {
        FileListRules.performRefreshLifecycleState(
            state,
            setLoading: { isLoading = $0 },
            setErrorMessage: { errorMessage = $0 }
        )
    }

    func applyOperationSuccessState(_ state: FileListRules.OperationSuccessState) {
        FileListRules.performOperationSuccessState(
            state,
            selectedBatchPaths: selectedBatchFilePaths,
            showMessage: { eventHandler(.showInfoMessage($0)) },
            setSelectedBatchPaths: { selectedBatchFilePaths = $0 }
        )
    }

    func toggleBatchSelection(for file: FileItem) {
        FileListRules.performBatchSelectionToggle(
            currentSelection: selectedBatchFilePaths,
            path: filePath(file),
            setSelectedBatchPaths: { selectedBatchFilePaths = $0 }
        )
    }

    func selectFilteredFiles() {
        FileListRules.performBatchSelectionSelectAll(
            currentSelection: selectedBatchFilePaths,
            presentationState: filePresentationState,
            setSelectedBatchPaths: { selectedBatchFilePaths = $0 }
        )
    }

    func clearBatchSelection() {
        FileListRules.performBatchSelectionClear {
            selectedBatchFilePaths = $0
        }
    }

    func selectFile(_ file: FileItem?) {
        FileListRules.performFileSelection(
            file,
            setSelection: { selection = $0 },
            syncSelection: syncSelection
        )
    }

    func promptDiscardFile(_ file: FileItem) {
        FileListRules.performDiscardFilePrompt(
            file,
            setFileToDiscard: { fileToDiscard = $0 },
            setPresented: { showDiscardFileAlert = $0 }
        )
    }

    func cancelDiscardFile() {
        FileListRules.performDiscardFilePromptCancellation {
            fileToDiscard = $0
        }
    }

    func confirmDiscardFile() {
        FileListRules.performConfirmedDiscardFile(
            fileToDiscard,
            discard: discardChanges(for:),
            clearFileToDiscard: { fileToDiscard = $0 }
        )
    }

    func promptDiscardAll() {
        FileListRules.performDiscardAllPrompt(
            presentationState: filePresentationState,
            setPresented: { showDiscardAllAlert = $0 }
        )
    }

    func promptDiscardSelected() {
        FileListRules.performDiscardSelectedPrompt(
            presentationState: filePresentationState,
            setPresented: { showDiscardSelectedAlert = $0 }
        )
    }

    func moveSelection(_ direction: MoveCommandDirection) {
        FileListRules.performMoveSelection(
            currentPath: selection.map(filePath),
            presentationState: filePresentationState,
            isMovingUp: direction == .up,
            isMovingDown: direction == .down,
            in: filteredFiles,
            path: filePath,
            select: { nextFile in
                selectFile(nextFile)
            }
        )
    }

    func stageState(for file: FileItem) -> FileStageState {
        FileListRules.stageState(
            path: filePath(file),
            stagedPaths: stagedFilePaths,
            unstagedPaths: unstagedFilePaths
        )
    }
}

private extension FileListHostView {
    func stageFile(_ file: FileItem) {
        performProjectFileOperation(.stageFile(path: filePath(file)))
    }

    func stageSelectedFiles() {
        performProjectFileOperation(.stageSelected(batchActionState))
    }

    func unstageFile(_ file: FileItem) {
        performProjectFileOperation(.unstageFile(path: filePath(file)))
    }

    func unstageSelectedFiles() {
        performProjectFileOperation(.unstageSelected(batchActionState))
    }

    func discardChanges(for file: FileItem) {
        performProjectFileOperation(.discardFile(path: filePath(file)))
    }

    func discardAllChangesAction() {
        performProjectFileOperation(.discardAll)
    }

    func discardSelectedChanges() {
        performProjectFileOperation(.discardSelected(batchActionState))
    }

    func performProjectFileOperation(_ action: FileListRules.FileOperationAction) {
        FileListRules.performRequiredProjectFileOperationCommand(
            project: project,
            action: action,
            perform: performFileOperation
        )
    }

    func performFileOperation(_ projectCommand: FileListRules.ProjectFileOperationCommand<Project>) {
        Task { @MainActor in
            await performFileOperation(command: projectCommand)
        }
    }

    func performFileOperation(command projectCommand: FileListRules.ProjectFileOperationCommand<Project>) async {
        let command = projectCommand.command

        do {
            let successState: FileListRules.OperationSuccessState?
            switch command.kind {
            case .stage:
                guard command.request.canPerform else { return }
                try await addFiles(projectCommand.project, command.request.paths)
                successState = command.request.paths.count == 1 && command.request.primaryPath != nil
                    ? FileListRules.stageFileSuccessState(path: command.request.primaryPath ?? "")
                    : FileListRules.stageSelectedFilesSuccessState(paths: command.request.paths)
            case .unstage:
                guard command.request.canPerform else { return }
                try await unstageFiles(projectCommand.project, command.request.paths)
                successState = command.request.paths.count == 1 && command.request.primaryPath != nil
                    ? FileListRules.unstageFileSuccessState(path: command.request.primaryPath ?? "")
                    : FileListRules.unstageSelectedFilesSuccessState(paths: command.request.paths)
            case .discardFile:
                guard let path = command.request.primaryPath else { return }
                try await discardFileChanges(projectCommand.project, path)
                successState = FileListRules.discardFileChangesSuccessState(path: path)
            case .discardAll:
                try await discardAllChanges(projectCommand.project)
                successState = FileListRules.discardAllChangesSuccessState()
            case .discardSelected:
                guard command.request.canPerform else { return }
                for path in command.request.paths {
                    try await discardFileChanges(projectCommand.project, path)
                }
                successState = FileListRules.discardSelectedChangesSuccessState(paths: command.request.paths)
            }

            guard let successState else { return }
            applyOperationSuccessState(successState)
            await refresh(reason: successState.refreshReason)
        } catch {
            eventHandler(.log(.fileOperationFailure(
                failureLogMessage: command.failureLogMessage,
                error: error
            )))
            eventHandler(.showError(error))
        }
    }
}

private extension FileListHostView {
    func refresh(reason: String) async {
        let requestState = FileListRules.refreshRequestState(lastRefreshTime: lastRefreshTime)
        let didStartRefresh = FileListRules.performRefreshRequestState(
            requestState,
            logSkipped: {
                eventHandler(.log(.refreshSkipped(reason: reason)))
            },
            setLastRefreshTime: { lastRefreshTime = $0 },
            cancelPreviousRefreshes: {
                refreshTask?.cancel()
                refreshWorkerTask?.cancel()
            },
            startRefresh: {
                refreshTask = Task {
                    await performRefresh(reason: reason)
                }
            }
        )

        if didStartRefresh {
            await refreshTask?.value
        }
    }

    func performRefresh(reason: String) async {
        applyRefreshLifecycleState(FileListRules.refreshStartState())

        guard let project else {
            applyRefreshLifecycleState(FileListRules.refreshStoppedState())
            return
        }

        await performRefresh(FileListRules.ProjectRefreshCommand(
            request: .init(reason: reason),
            project: project
        ))
    }

    func performRefresh(_ command: FileListRules.ProjectRefreshCommand<Project>) async {
        let expectedCommitHash = selectedCommit.map(commitHash)

        do {
            let worker = Task { @MainActor in
                eventHandler(.log(.refreshStarted(reason: command.request.reason)))
                try Task.checkCancellation()

                let loadedFiles: [FileItem]
                let statusEntries: [StatusEntry]
                if let expectedCommitHash {
                    loadedFiles = try await loadCommitFiles(command.project, expectedCommitHash)
                    statusEntries = []
                } else {
                    loadedFiles = try await loadWorktreeFiles(command.project)
                    statusEntries = try await loadStatusEntries(command.project)
                }

                try Task.checkCancellation()
                let latestCommitHash = selectedCommit.map(commitHash)
                let preferredPath = selection.map(filePath) ?? scrollTarget.map(filePath)
                let applicationState = FileListRules.refreshResultApplicationState(
                    expectedCommitHash: expectedCommitHash,
                    currentCommitHash: latestCommitHash,
                    preferredPath: preferredPath,
                    newItems: loadedFiles,
                    itemPath: filePath,
                    statusEntries: statusEntries,
                    statusPath: statusPath,
                    indexStatus: statusIndexStatus,
                    workTreeStatus: statusWorkTreeStatus,
                    selectedBatchPaths: selectedBatchFilePaths
                )

                FileListRules.performRefreshResultApplicationState(
                    applicationState,
                    newItems: loadedFiles,
                    itemPath: filePath,
                    apply: { items, refreshState, refreshedSelection in
                        FileListRules.performRefreshResultState(
                            items: items,
                            refreshState: refreshState,
                            refreshedSelection: refreshedSelection,
                            setItems: { self.files = $0 },
                            setStagedPaths: { self.stagedFilePaths = $0 },
                            setUnstagedPaths: { self.unstagedFilePaths = $0 },
                            setUntrackedPaths: { self.untrackedFilePaths = $0 },
                            setSelectedBatchPaths: { self.selectedBatchFilePaths = $0 },
                            setSelection: { self.selection = $0 },
                            syncSelection: self.syncSelection,
                            applyLifecycleState: self.applyRefreshLifecycleState
                        )
                    },
                    skip: {
                        eventHandler(.log(.commitChangedDuringRefresh))
                    }
                )
            }

            refreshWorkerTask = worker
            try await worker.value
        } catch is CancellationError {
            applyRefreshLifecycleState(FileListRules.refreshStoppedState())
            eventHandler(.log(.refreshCancelled(reason: command.request.reason)))
        } catch {
            let message = mapRefreshError(error)
            applyRefreshLifecycleState(FileListRules.refreshFailedState(errorMessage: message))
            eventHandler(.log(.refreshFailure(message: message)))
        }
    }
}

private extension FileListHostView {
    func performRefreshAction(_ action: FileListRules.RefreshEventAction) {
        FileListRules.performRefreshAction(
            action,
            refresh: { reason in
                Task {
                    await self.refresh(reason: reason)
                }
            },
            refreshImmediately: { reason in
                Task {
                    await self.performRefresh(reason: reason)
                }
            }
        )
    }

    func onAppear() {
        FileListRules.performAppear(performRefreshAction: performRefreshAction)
    }

    func onProjectChange() {
        FileListRules.performProjectChange(performRefreshAction: performRefreshAction)
    }

    func onCommitChange() {
        FileListRules.performCommitChange(performRefreshAction: performRefreshAction)
    }

    func onSelectionChange() {
        FileListRules.performSelectionChange(selection, syncSelection: syncSelection)
    }

    func onProjectDidCommit() {
        FileListRules.performProjectDidCommit(performRefreshAction: performRefreshAction)
    }

    func onProjectDidAddFiles() {
        guard let projectDidAddFilesPath else { return }
        FileListRules.performProjectDidAddFiles(
            eventProjectPath: projectDidAddFilesPath,
            currentProject: project,
            currentProjectPath: projectPath,
            performRefreshAction: performRefreshAction
        )
    }

    func onGitDirectoryDidChange() {
        guard let gitDirectoryEventProjectPath else { return }
        FileListRules.performGitDirectoryChanged(
            eventProjectPath: gitDirectoryEventProjectPath,
            currentProject: project,
            currentProjectPath: projectPath,
            performRefreshAction: performRefreshAction
        )
    }

    func onAppWillBecomeActive() {
        FileListRules.performAppWillBecomeActive(performRefreshAction: performRefreshAction)
    }
}
