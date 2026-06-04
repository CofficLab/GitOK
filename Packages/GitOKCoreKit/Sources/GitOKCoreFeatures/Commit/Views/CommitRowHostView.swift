import SwiftUI

public enum CommitRowHostLogEvent {
    case selection(hash: String, message: String)
    case pushStart(hash: String)
    case pushSuccess(hash: String)
    case undoSuccess(hash: String)
    case avatarStart(hash: String)
    case avatarCoAuthors(hash: String, count: Int)
    case commitSuccessReloadTag(hash: String)
}

public enum CommitRowHostEvent {
    case showErrorMessage(String)
    case showInfoMessage(String)
    case showError(Error)
    case log(CommitRowHostLogEvent)
}

public struct CommitRowHostView<Project, Commit>: View {
    private let project: Project?
    private let commit: Commit
    private let isFirstCommit: Bool
    private let commitIndex: Int
    private let graphRow: CommitGraphPresentationRules.Row?
    private let graphLaneCount: Int
    private let currentCommitID: String?
    private let isCommitUnpushed: (String) -> Bool
    private let selectCommit: (Commit?) -> Void
    private let commitHash: (Commit) -> String
    private let commitMessage: (Commit) -> String
    private let commitAuthor: (Commit) -> String
    private let commitAllAuthors: (Commit) -> String
    private let commitRelativeTime: (Commit) -> String
    private let commitFullDateTime: (Commit) -> String
    private let commitParentHashes: (Commit) -> [String]
    private let commitTagCount: (Commit) -> Int
    private let projectPath: (Project) -> String
    private let pushProject: (Project) async throws -> Void
    private let undoCommit: (Project, Commit) async throws -> Void
    private let revertCommit: (Project, Commit) async throws -> Void
    private let resetToCommit: (Project, Commit, GitResetMode) async throws -> Void
    private let squashLastCommits: (Project, CommitHistoryActionRules.SquashValidation) async throws -> Void
    private let loadTags: (Project, String) async throws -> [String]
    private let createLightweightTag: (Project, String, String) async throws -> Void
    private let createAnnotatedTag: (Project, String, String, String) async throws -> Void
    private let deleteLocalTag: (Project, String) async throws -> Void
    private let pushTagOperation: (Project, String) async throws -> Void
    private let deleteRemoteTag: (Project, String) async throws -> Void
    private let eventHandler: @MainActor (CommitRowHostEvent) -> Void
    private let appWillBecomeActiveToken: Int
    private let projectDidCommitToken: Int
    private let refsDidChangeToken: Int
    private let refsDidChangeProjectPath: String?

    @State private var tag = ""
    @State private var avatarUsers: [AvatarUser] = []
    @State private var showPushPopover = false
    @State private var isPushing = false
    @State private var pushError: Error?
    @State private var showUndoConfirmation = false
    @State private var isUndoing = false
    @State private var showRevertConfirmation = false
    @State private var showResetSoftConfirmation = false
    @State private var showResetMixedConfirmation = false
    @State private var showResetHardConfirmation = false
    @State private var showSquashConfirmation = false
    @State private var squashMessage = ""
    @State private var isRunningHistoryOperation = false
    @State private var showCreateTagAlert = false
    @State private var showCreateAnnotatedTagAlert = false
    @State private var newTagName = ""
    @State private var newAnnotatedTagName = ""
    @State private var newAnnotatedTagMessage = ""
    @State private var isCreatingTag = false
    @State private var isCreatingAnnotatedTag = false
    @State private var showDeleteTagConfirmation = false
    @State private var showDeleteRemoteTagConfirmation = false
    @State private var isDeletingTag = false
    @State private var isDeletingRemoteTag = false
    @State private var isPushingTag = false
    @State private var isHovered = false

    public init(
        project: Project?,
        commit: Commit,
        isFirstCommit: Bool,
        commitIndex: Int,
        graphRow: CommitGraphPresentationRules.Row?,
        graphLaneCount: Int,
        currentCommitID: String?,
        isCommitUnpushed: @escaping (String) -> Bool,
        selectCommit: @escaping (Commit?) -> Void,
        commitHash: @escaping (Commit) -> String,
        commitMessage: @escaping (Commit) -> String,
        commitAuthor: @escaping (Commit) -> String,
        commitAllAuthors: @escaping (Commit) -> String,
        commitRelativeTime: @escaping (Commit) -> String,
        commitFullDateTime: @escaping (Commit) -> String,
        commitParentHashes: @escaping (Commit) -> [String],
        commitTagCount: @escaping (Commit) -> Int,
        projectPath: @escaping (Project) -> String,
        pushProject: @escaping (Project) async throws -> Void,
        undoCommit: @escaping (Project, Commit) async throws -> Void,
        revertCommit: @escaping (Project, Commit) async throws -> Void,
        resetToCommit: @escaping (Project, Commit, GitResetMode) async throws -> Void,
        squashLastCommits: @escaping (Project, CommitHistoryActionRules.SquashValidation) async throws -> Void,
        loadTags: @escaping (Project, String) async throws -> [String],
        createLightweightTag: @escaping (Project, String, String) async throws -> Void,
        createAnnotatedTag: @escaping (Project, String, String, String) async throws -> Void,
        deleteLocalTag: @escaping (Project, String) async throws -> Void,
        pushTagOperation: @escaping (Project, String) async throws -> Void,
        deleteRemoteTag: @escaping (Project, String) async throws -> Void,
        eventHandler: @MainActor @escaping (CommitRowHostEvent) -> Void = { _ in },
        appWillBecomeActiveToken: Int = 0,
        projectDidCommitToken: Int = 0,
        refsDidChangeToken: Int = 0,
        refsDidChangeProjectPath: String? = nil
    ) {
        self.project = project
        self.commit = commit
        self.isFirstCommit = isFirstCommit
        self.commitIndex = commitIndex
        self.graphRow = graphRow
        self.graphLaneCount = graphLaneCount
        self.currentCommitID = currentCommitID
        self.isCommitUnpushed = isCommitUnpushed
        self.selectCommit = selectCommit
        self.commitHash = commitHash
        self.commitMessage = commitMessage
        self.commitAuthor = commitAuthor
        self.commitAllAuthors = commitAllAuthors
        self.commitRelativeTime = commitRelativeTime
        self.commitFullDateTime = commitFullDateTime
        self.commitParentHashes = commitParentHashes
        self.commitTagCount = commitTagCount
        self.projectPath = projectPath
        self.pushProject = pushProject
        self.undoCommit = undoCommit
        self.revertCommit = revertCommit
        self.resetToCommit = resetToCommit
        self.squashLastCommits = squashLastCommits
        self.loadTags = loadTags
        self.createLightweightTag = createLightweightTag
        self.createAnnotatedTag = createAnnotatedTag
        self.deleteLocalTag = deleteLocalTag
        self.pushTagOperation = pushTagOperation
        self.deleteRemoteTag = deleteRemoteTag
        self.eventHandler = eventHandler
        self.appWillBecomeActiveToken = appWillBecomeActiveToken
        self.projectDidCommitToken = projectDidCommitToken
        self.refsDidChangeToken = refsDidChangeToken
        self.refsDidChangeProjectPath = refsDidChangeProjectPath
    }

    public var body: some View {
        CommitRowContentView(
            presentationState: presentationState,
            currentCommitID: currentCommitID,
            graphRow: graphRow,
            graphLaneCount: graphLaneCount,
            message: commitMessage(commit),
            tag: tag,
            authors: commitAllAuthors(commit),
            relativeTime: commitRelativeTime(commit),
            fullDateTime: commitFullDateTime(commit),
            avatarUsers: avatarUsers,
            isHovered: $isHovered,
            showPushPopover: $showPushPopover,
            isPushing: $isPushing,
            pushError: $pushError,
            showUndoConfirmation: $showUndoConfirmation,
            showRevertConfirmation: $showRevertConfirmation,
            showResetSoftConfirmation: $showResetSoftConfirmation,
            showResetMixedConfirmation: $showResetMixedConfirmation,
            showResetHardConfirmation: $showResetHardConfirmation,
            showSquashConfirmation: $showSquashConfirmation,
            squashMessage: $squashMessage,
            showCreateTagAlert: $showCreateTagAlert,
            newTagName: $newTagName,
            showCreateAnnotatedTagAlert: $showCreateAnnotatedTagAlert,
            newAnnotatedTagName: $newAnnotatedTagName,
            newAnnotatedTagMessage: $newAnnotatedTagMessage,
            showDeleteTagConfirmation: $showDeleteTagConfirmation,
            showDeleteRemoteTagConfirmation: $showDeleteRemoteTagConfirmation,
            isRunningHistoryOperation: isRunningHistoryOperation,
            isCreatingTag: isCreatingTag,
            isCreatingAnnotatedTag: isCreatingAnnotatedTag,
            isDeletingTag: isDeletingTag,
            isDeletingRemoteTag: isDeletingRemoteTag,
            isPushingTag: isPushingTag,
            commitHash: commitHash(commit),
            commitIndex: commitIndex,
            onSelect: selectCurrentCommit,
            onAppear: onAppear,
            onPush: performPush,
            onCreateTag: {
                applyTagPromptState(CommitTagRules.promptState(for: .lightweight), prompt: .lightweight)
            },
            onCreateAnnotatedTag: {
                applyTagPromptState(CommitTagRules.promptState(for: .annotated), prompt: .annotated)
            },
            onPushTag: pushTag,
            onDeleteRemoteTagPrompt: {
                CommitTagRules.performDeleteRemotePrompt {
                    showDeleteRemoteTagConfirmation = $0
                }
            },
            onDeleteTagPrompt: {
                CommitTagRules.performDeleteLocalPrompt {
                    showDeleteTagConfirmation = $0
                }
            },
            onUndoPrompt: {
                CommitHistoryActionRules.performUndoPrompt {
                    showUndoConfirmation = $0
                }
            },
            onRevertPrompt: {
                CommitHistoryActionRules.performRevertPrompt {
                    showRevertConfirmation = $0
                }
            },
            onSquashPrompt: {
                applySquashPromptState(CommitHistoryActionRules.squashPromptState(commitMessage: commitMessage(commit)))
            },
            onSoftResetPrompt: {
                CommitHistoryActionRules.performSoftResetPrompt {
                    showResetSoftConfirmation = $0
                }
            },
            onMixedResetPrompt: {
                CommitHistoryActionRules.performMixedResetPrompt {
                    showResetMixedConfirmation = $0
                }
            },
            onHardResetPrompt: {
                CommitHistoryActionRules.performHardResetPrompt {
                    showResetHardConfirmation = $0
                }
            },
            onUndo: performUndo,
            onRevert: performRevert,
            onReset: performReset,
            onSquash: performSquash,
            onCreateLightweightTag: createLightweightTagAction,
            onCreateAnnotatedTagAction: createAnnotatedTagAction,
            onDeleteLocalTag: deleteLocalTagAction,
            onDeleteRemoteTag: deleteRemoteTagAction
        )
        .onChange(of: appWillBecomeActiveToken) {
            CommitTagRules.performReloadEvent(.appWillBecomeActive) {
                Task { await loadTag() }
            }
        }
        .onChange(of: projectDidCommitToken) {
            eventHandler(.log(.commitSuccessReloadTag(hash: commitHash(commit))))
            CommitTagRules.performReloadEvent(.commitSuccess) {
                Task { await loadTag() }
            }
        }
        .onChange(of: refsDidChangeToken) {
            onGitRefsChanged()
        }
    }
}

fileprivate enum CommitRowBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

private extension CommitRowHostView {
    var presentationState: CommitRowAppearanceRules.PresentationState {
        let hash = commitHash(commit)
        return CommitRowAppearanceRules.presentationState(
            isFirstCommit: isFirstCommit,
            commitIndex: commitIndex,
            isUnpushed: isCommitUnpushed(hash),
            tag: tag,
            commitTagCount: commitTagCount(commit),
            parentHashCount: commitParentHashes(commit).count
        )
    }

    func selectCurrentCommit() {
        eventHandler(.log(.selection(hash: commitHash(commit), message: commitMessage(commit))))
        CommitRowAppearanceRules.performCommitSelection(commit, select: selectCommit)
    }

    func performPush() async throws {
        let loadedProject = try CommitHistoryActionRules.requiredProject(project)
        nonisolated(unsafe) let project = loadedProject
        let hash = commitHash(commit)
        eventHandler(.log(.pushStart(hash: hash)))
        try await pushProject(project)
        eventHandler(.log(.pushSuccess(hash: hash)))
    }

    func performUndo() {
        performHistoryCommand(.undo(
            commit: commit,
            commitHash: commitHash(commit),
            parentHashes: commitParentHashes(commit)
        ))
    }

    func performRevert() {
        performHistoryCommand(.revert(commit: commit, commitHash: commitHash(commit)))
    }

    func performReset(_ mode: GitResetMode) {
        performHistoryCommand(.reset(
            commit: commit,
            commitHash: commitHash(commit),
            mode: mode,
            modeName: mode.rawValue
        ))
    }

    func performSquash() {
        let validation = CommitHistoryActionRules.squashValidation(
            message: squashMessage,
            commitIndex: commitIndex
        )
        performHistoryCommand(.squash(commitHash: commitHash(commit), validation: validation))
    }

    func performHistoryCommand(_ command: CommitHistoryActionRules.ProjectHistoryCommand<Commit, GitResetMode>) {
        guard let loadedProject = project else {
            eventHandler(.showErrorMessage(CommitHistoryActionRules.projectUnavailableMessage()))
            return
        }
        let projectTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: loadedProject)
        let commandTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: command)
        let undoCommitTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: undoCommit)
        let revertCommitTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: revertCommit)
        let resetToCommitTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: resetToCommit)
        let squashLastCommitsTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: squashLastCommits)
        let eventHandlerTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: eventHandler)

        Task.detached(priority: .userInitiated) {
            let project = projectTransfer.value
            let command = commandTransfer.value

            switch command {
            case let .undo(loadedCommit, hash, parentHashes):
                let commitTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: loadedCommit)
                let request = CommitHistoryActionRules.undoRequestState(parentHashes: parentHashes)
                if let message = CommitHistoryActionRules.validationFailureMessage(for: request) {
                    await MainActor.run {
                        eventHandlerTransfer.value(.showErrorMessage(message))
                    }
                    return
                }
                await MainActor.run {
                    applyHistoryCompletionState(CommitHistoryActionRules.startState(for: .undo))
                }
                do {
                    try await undoCommitTransfer.value(project, commitTransfer.value)
                    await MainActor.run {
                        eventHandlerTransfer.value(.log(.undoSuccess(hash: hash)))
                        applyHistoryCompletionState(CommitHistoryActionRules.completionState(for: .undo, succeeded: true))
                    }
                } catch {
                    await MainActor.run {
                        applyHistoryCompletionState(CommitHistoryActionRules.completionState(for: .undo, succeeded: false))
                        eventHandlerTransfer.value(.showError(error))
                    }
                }
            case let .revert(loadedCommit, hash):
                let commitTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: loadedCommit)
                await runSimpleHistoryOperation(
                    operation: .revert,
                    hash: hash,
                    perform: {
                        try await revertCommitTransfer.value(project, commitTransfer.value)
                    }
                )
            case let .reset(loadedCommit, hash, mode, modeName):
                let commitTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: loadedCommit)
                await runSimpleHistoryOperation(
                    operation: .reset,
                    hash: hash,
                    resetMode: modeName,
                    perform: {
                        try await resetToCommitTransfer.value(project, commitTransfer.value, mode)
                    }
                )
            case let .squash(hash, loadedValidation):
                let validation = loadedValidation
                if let message = CommitHistoryActionRules.validationFailureMessage(for: validation) {
                    await MainActor.run {
                        eventHandlerTransfer.value(.showErrorMessage(message))
                    }
                    return
                }
                await runSimpleHistoryOperation(
                    operation: .squash,
                    hash: hash,
                    squashCount: validation.count,
                    perform: {
                        try await squashLastCommitsTransfer.value(project, validation)
                    }
                )
            }
        }
    }

    func runSimpleHistoryOperation(
        operation: CommitHistoryActionRules.HistoryOperation,
        hash: String,
        resetMode: String? = nil,
        squashCount: Int? = nil,
        perform: () async throws -> Void
    ) async {
        await MainActor.run {
            applyHistoryCompletionState(CommitHistoryActionRules.startState(for: operation))
        }
        do {
            try await perform()
            await MainActor.run {
                applyHistoryOperationResult(CommitHistoryActionRules.operationResult(
                    for: operation,
                    succeeded: true,
                    commitHash: hash,
                    resetMode: resetMode,
                    squashCount: squashCount
                ))
            }
        } catch {
            await MainActor.run {
                applyHistoryOperationResult(CommitHistoryActionRules.operationResult(
                    for: operation,
                    succeeded: false,
                    commitHash: hash,
                    resetMode: resetMode,
                    squashCount: squashCount
                ))
                eventHandler(.showError(error))
            }
        }
    }
}

private extension CommitRowHostView {
    func createLightweightTagAction() {
        performProjectTagRequest(operation: .createLightweight, tagName: newTagName)
    }

    func createAnnotatedTagAction() {
        performProjectTagRequest(
            operation: .createAnnotated,
            tagName: newAnnotatedTagName,
            tagMessage: newAnnotatedTagMessage
        )
    }

    func deleteLocalTagAction() {
        performProjectTagRequest(operation: .deleteLocal, tagName: tag)
    }

    func pushTag() {
        performProjectTagRequest(operation: .push, tagName: tag)
    }

    func deleteRemoteTagAction() {
        performProjectTagRequest(operation: .deleteRemote, tagName: tag)
    }

    func performProjectTagRequest(
        operation: CommitTagRules.TagOperation,
        tagName: String,
        tagMessage: String = ""
    ) {
        guard let loadedProject = project else {
            eventHandler(.showErrorMessage(CommitHistoryActionRules.projectUnavailableMessage()))
            return
        }

        let request = CommitTagRules.tagRequest(for: operation, tagName: tagName, tagMessage: tagMessage)
        if let failureMessage = CommitTagRules.validationFailureMessage(for: request) {
            eventHandler(.showErrorMessage(failureMessage))
            return
        }

        let projectTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: loadedProject)
        let requestTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: request)
        let createLightweightTagTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: createLightweightTag)
        let createAnnotatedTagTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: createAnnotatedTag)
        let deleteLocalTagTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: deleteLocalTag)
        let pushTagOperationTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: pushTagOperation)
        let deleteRemoteTagTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: deleteRemoteTag)
        let eventHandlerTransfer = CommitRowBackgroundRunner.UnsafeTransfer(value: eventHandler)
        let targetCommitHash = commitHash(commit)

        applyTagCompletionState(request.startState)

        Task.detached(priority: .userInitiated) {
            let project = projectTransfer.value
            let request = requestTransfer.value

            do {
                switch request.operation {
                case .createLightweight:
                    try await createLightweightTagTransfer.value(project, request.tagName, targetCommitHash)
                case .createAnnotated:
                    try await createAnnotatedTagTransfer.value(project, request.tagName, targetCommitHash, request.tagMessage ?? "")
                case .deleteLocal:
                    try await deleteLocalTagTransfer.value(project, request.tagName)
                case .push:
                    try await pushTagOperationTransfer.value(project, request.tagName)
                case .deleteRemote:
                    try await deleteRemoteTagTransfer.value(project, request.tagName)
                }

                await MainActor.run {
                    applyTagOperationResult(CommitTagRules.operationResult(request: request, succeeded: true))
                }
            } catch {
                await MainActor.run {
                    applyTagOperationResult(CommitTagRules.operationResult(request: request, succeeded: false))
                    eventHandlerTransfer.value(.showError(error))
                }
            }
        }
    }
}

private extension CommitRowHostView {
    func applyHistoryCompletionState(_ state: CommitHistoryActionRules.CompletionState) {
        CommitHistoryActionRules.performCompletionState(
            state,
            setRunningHistoryOperation: { isRunningHistoryOperation = $0 },
            setUndoing: { isUndoing = $0 },
            closeUndoConfirmation: { showUndoConfirmation = false },
            closeRevertConfirmation: { showRevertConfirmation = false },
            closeResetConfirmations: {
                showResetSoftConfirmation = false
                showResetMixedConfirmation = false
                showResetHardConfirmation = false
            },
            closeSquashConfirmation: { showSquashConfirmation = false },
            clearSelectedCommit: { selectCommit(nil) }
        )
    }

    func applySquashPromptState(_ state: CommitHistoryActionRules.SquashPromptState) {
        CommitHistoryActionRules.performSquashPromptState(
            state,
            setMessage: { squashMessage = $0 },
            setPresented: { showSquashConfirmation = $0 }
        )
    }

    func applyHistoryOperationResult(_ result: CommitHistoryActionRules.OperationResult) {
        CommitHistoryActionRules.performOperationResult(
            result,
            applyCompletionState: applyHistoryCompletionState,
            showSuccessMessage: { eventHandler(.showInfoMessage($0)) }
        )
    }

    func applyTagPromptState(_ state: CommitTagRules.TagPromptState, prompt: CommitTagRules.TagPrompt) {
        CommitTagRules.performPromptApplicationState(
            CommitTagRules.promptApplicationState(state: state, prompt: prompt),
            setLightweightTagName: { newTagName = $0 },
            setAnnotatedTagName: { newAnnotatedTagName = $0 },
            setAnnotatedTagMessage: { newAnnotatedTagMessage = $0 },
            setLightweightPromptPresented: { showCreateTagAlert = $0 },
            setAnnotatedPromptPresented: { showCreateAnnotatedTagAlert = $0 }
        )
    }

    func applyTagCompletionState(_ state: CommitTagRules.CompletionState) {
        CommitTagRules.performCompletionState(
            state,
            setCreatingTag: { isCreatingTag = $0 },
            setCreatingAnnotatedTag: { isCreatingAnnotatedTag = $0 },
            setDeletingTag: { isDeletingTag = $0 },
            setDeletingRemoteTag: { isDeletingRemoteTag = $0 },
            setPushingTag: { isPushingTag = $0 },
            clearLightweightTagName: { newTagName = "" },
            clearAnnotatedTagFields: {
                newAnnotatedTagName = ""
                newAnnotatedTagMessage = ""
            },
            closeCreateTagAlert: { showCreateTagAlert = false },
            closeCreateAnnotatedTagAlert: { showCreateAnnotatedTagAlert = false },
            closeDeleteTagConfirmation: { showDeleteTagConfirmation = false },
            closeDeleteRemoteTagConfirmation: { showDeleteRemoteTagConfirmation = false },
            reloadTag: {
                Task { await loadTag() }
            }
        )
    }

    func applyTagOperationResult(_ result: CommitTagRules.TagOperationResult) {
        CommitTagRules.performOperationResult(
            result,
            applyCompletionState: applyTagCompletionState,
            showSuccessMessage: { eventHandler(.showInfoMessage($0)) }
        )
    }
}

private extension CommitRowHostView {
    func loadTag() async {
        guard let loadedProject = project else {
            return
        }

        nonisolated(unsafe) let project = loadedProject
        let hash = commitHash(commit)
        let tags = (try? await loadTags(project, hash)) ?? []
        tag = CommitTagRules.visibleTag(from: tags)
    }

    func loadInitialCommitRowState() async {
        eventHandler(.log(.avatarStart(hash: commitHash(commit))))
        let users = CommitAuthorParser.avatarUsers(
            author: commitAuthor(commit),
            message: commitMessage(commit)
        )
        eventHandler(.log(.avatarCoAuthors(hash: commitHash(commit), count: max(0, users.count - 1))))
        avatarUsers = users
        await loadTag()
    }

    func onGitRefsChanged() {
        guard let refsDidChangeProjectPath else {
            return
        }

        CommitTagRules.performRefsChangedReloadEvent(
            eventProjectPath: refsDidChangeProjectPath,
            currentProject: project,
            currentProjectPath: projectPath,
            reloadTag: {
                Task { await loadTag() }
            }
        )
    }

    func onAppear() {
        CommitRowLoadRules.performAppear {
            Task { await loadInitialCommitRowState() }
        }
    }
}
