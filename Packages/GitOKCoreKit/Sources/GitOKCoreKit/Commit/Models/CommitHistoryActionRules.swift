import Foundation

public enum CommitHistoryActionRules {
    public enum HistoryOperation: Equatable, Sendable {
        case undo
        case revert
        case reset
        case squash
    }

    public struct CompletionState: Equatable, Sendable {
        public let isRunningHistoryOperation: Bool
        public let isUndoing: Bool
        public let closesUndoConfirmation: Bool
        public let closesRevertConfirmation: Bool
        public let closesResetConfirmations: Bool
        public let closesSquashConfirmation: Bool
        public let clearsSelectedCommit: Bool

        public init(
            isRunningHistoryOperation: Bool,
            isUndoing: Bool,
            closesUndoConfirmation: Bool,
            closesRevertConfirmation: Bool,
            closesResetConfirmations: Bool,
            closesSquashConfirmation: Bool,
            clearsSelectedCommit: Bool
        ) {
            self.isRunningHistoryOperation = isRunningHistoryOperation
            self.isUndoing = isUndoing
            self.closesUndoConfirmation = closesUndoConfirmation
            self.closesRevertConfirmation = closesRevertConfirmation
            self.closesResetConfirmations = closesResetConfirmations
            self.closesSquashConfirmation = closesSquashConfirmation
            self.clearsSelectedCommit = clearsSelectedCommit
        }
    }

    public struct SquashValidation: Equatable, Sendable {
        public let message: String
        public let count: Int
        public let errorMessage: String?

        public var canProceed: Bool {
            errorMessage == nil
        }

        public init(message: String, count: Int, errorMessage: String?) {
            self.message = message
            self.count = count
            self.errorMessage = errorMessage
        }
    }

    public struct SquashPromptState: Equatable, Sendable {
        public let showsPrompt: Bool
        public let message: String

        public init(showsPrompt: Bool, message: String) {
            self.showsPrompt = showsPrompt
            self.message = message
        }
    }

    public struct PromptState: Equatable, Sendable {
        public let showsPrompt: Bool

        public init(showsPrompt: Bool) {
            self.showsPrompt = showsPrompt
        }
    }

    public struct UndoRequestState: Equatable, Sendable {
        public let parentHash: String?
        public let errorMessage: String?

        public var canPerform: Bool {
            parentHash != nil && errorMessage == nil
        }

        public init(parentHash: String?, errorMessage: String?) {
            self.parentHash = parentHash
            self.errorMessage = errorMessage
        }
    }

    public struct OperationResult: Equatable, Sendable {
        public let completionState: CompletionState
        public let successMessage: String?

        public init(completionState: CompletionState, successMessage: String?) {
            self.completionState = completionState
            self.successMessage = successMessage
        }
    }

    public struct HistoryOperationRequest: Equatable, Sendable {
        public let operation: HistoryOperation
        public let commitHash: String
        public let resetMode: String?
        public let squashValidation: SquashValidation?

        public init(
            operation: HistoryOperation,
            commitHash: String,
            resetMode: String? = nil,
            squashValidation: SquashValidation? = nil
        ) {
            self.operation = operation
            self.commitHash = commitHash
            self.resetMode = resetMode
            self.squashValidation = squashValidation
        }
    }

    public enum ProjectHistoryCommand<Commit, ResetMode> {
        case undo(commit: Commit, commitHash: String, parentHashes: [String])
        case revert(commit: Commit, commitHash: String)
        case reset(commit: Commit, commitHash: String, mode: ResetMode, modeName: String)
        case squash(commitHash: String, validation: SquashValidation)
    }

    public struct ProjectHistoryCommandRequest<Commit, ResetMode> {
        public let command: ProjectHistoryCommand<Commit, ResetMode>

        public init(command: ProjectHistoryCommand<Commit, ResetMode>) {
            self.command = command
        }
    }

    public struct ProjectPushRequest<Project> {
        public let project: Project

        public init(project: Project) {
            self.project = project
        }
    }

    public struct ProjectHistoryCommandHandlers<Commit, ResetMode> {
        public let undoCommit: (Commit) async throws -> Void
        public let revertCommit: (Commit) async throws -> Void
        public let resetToCommit: (Commit, ResetMode) async throws -> Void
        public let squashLastCommits: (SquashValidation) async throws -> Void

        public init(
            undoCommit: @escaping (Commit) async throws -> Void,
            revertCommit: @escaping (Commit) async throws -> Void,
            resetToCommit: @escaping (Commit, ResetMode) async throws -> Void,
            squashLastCommits: @escaping (SquashValidation) async throws -> Void
        ) {
            self.undoCommit = undoCommit
            self.revertCommit = revertCommit
            self.resetToCommit = resetToCommit
            self.squashLastCommits = squashLastCommits
        }
    }

    public struct ProjectHistoryProjectCommandHandlers<Project, Commit, ResetMode> {
        public let undoCommit: (Project, Commit) async throws -> Void
        public let revertCommit: (Project, Commit) async throws -> Void
        public let resetToCommit: (Project, Commit, ResetMode) async throws -> Void
        public let squashLastCommits: (Project, SquashValidation) async throws -> Void

        public init(
            undoCommit: @escaping (Project, Commit) async throws -> Void,
            revertCommit: @escaping (Project, Commit) async throws -> Void,
            resetToCommit: @escaping (Project, Commit, ResetMode) async throws -> Void,
            squashLastCommits: @escaping (Project, SquashValidation) async throws -> Void
        ) {
            self.undoCommit = undoCommit
            self.revertCommit = revertCommit
            self.resetToCommit = resetToCommit
            self.squashLastCommits = squashLastCommits
        }
    }

    public struct UndoProjectRequest: Equatable, Sendable {
        public let projectPath: String
        public let commitHash: String
        public let parentHashes: [String]

        public init(projectPath: String, commitHash: String, parentHashes: [String]) {
            self.projectPath = projectPath
            self.commitHash = commitHash
            self.parentHashes = parentHashes
        }
    }

    public struct EventPayload: Equatable, Sendable {
        public let operation: String
        public let additionalInfo: [String: String]

        public var projectEventAdditionalInfo: [String: Any] {
            additionalInfo.mapValues { $0 as Any }
        }

        public init(operation: String, additionalInfo: [String: String]) {
            self.operation = operation
            self.additionalInfo = additionalInfo
        }
    }

    public static let errorDomain = "GitOK"
    public static let genericErrorCode = -1
    public static let undoResetMode = "mixed"
    public static let undoCommitOperation = "undoCommit"
    public static let commitHashInfoKey = "commitHash"
    public static let parentHashInfoKey = "parentHash"

    public static func performPushOperation(
        push: () async throws -> Void,
        logStart: () async -> Void,
        logSuccess: () async -> Void
    ) async throws {
        await logStart()
        try await push()
        await logSuccess()
    }

    public static func performRequiredProjectPushOperation<Project>(
        project: Project?,
        push: (ProjectPushRequest<Project>) async throws -> Void,
        logStart: () async -> Void,
        logSuccess: () async -> Void
    ) async throws {
        let project = try requiredProject(project)
        try await performPushOperation(
            push: {
                try await push(ProjectPushRequest(project: project))
            },
            logStart: logStart,
            logSuccess: logSuccess
        )
    }

    public static func canUndoLatestCommit(
        isFirstCommit: Bool,
        isUnpushed: Bool,
        tagCount: Int,
        parentHashCount: Int
    ) -> Bool {
        isFirstCommit && isUnpushed && tagCount == 0 && parentHashCount > 0
    }

    public static func canSquashThroughHead(commitIndex: Int, isUnpushed: Bool) -> Bool {
        commitIndex >= 1 && isUnpushed
    }

    public static func squashCountThroughHead(commitIndex: Int) -> Int {
        commitIndex + 1
    }

    public static func squashPromptState(commitMessage: String) -> SquashPromptState {
        SquashPromptState(showsPrompt: true, message: commitMessage)
    }

    public static func confirmationPromptState() -> PromptState {
        PromptState(showsPrompt: true)
    }

    public static func performConfirmationPromptState(
        _ state: PromptState,
        setPresented: (Bool) -> Void
    ) {
        setPresented(state.showsPrompt)
    }

    public static func performUndoPrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(confirmationPromptState(), setPresented: setPresented)
    }

    public static func performRevertPrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(confirmationPromptState(), setPresented: setPresented)
    }

    public static func performSoftResetPrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(confirmationPromptState(), setPresented: setPresented)
    }

    public static func performMixedResetPrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(confirmationPromptState(), setPresented: setPresented)
    }

    public static func performHardResetPrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(confirmationPromptState(), setPresented: setPresented)
    }

    public static func performSquashPromptState(
        _ state: SquashPromptState,
        setMessage: (String) -> Void,
        setPresented: (Bool) -> Void
    ) {
        setMessage(state.message)
        setPresented(state.showsPrompt)
    }

    public static func undoRequestState(parentHashes: [String]) -> UndoRequestState {
        guard let parentHash = parentHashes.first else {
            return UndoRequestState(
                parentHash: nil,
                errorMessage: undoInitialCommitUnsupportedMessage()
            )
        }

        return UndoRequestState(parentHash: parentHash, errorMessage: nil)
    }

    public static func validationFailureMessage(for request: UndoRequestState) -> String? {
        request.canPerform ? nil : request.errorMessage
    }

    public static func validationFailureError(for request: UndoRequestState) -> NSError? {
        validationFailureMessage(for: request).map {
            operationError(message: $0)
        }
    }

    public static func validatedParentHash(for request: UndoRequestState) throws -> String {
        if let failureError = validationFailureError(for: request) {
            throw failureError
        }

        guard let parentHash = request.parentHash else {
            throw operationError(message: undoInitialCommitUnsupportedMessage())
        }

        return parentHash
    }

    public static func completionState(
        for operation: HistoryOperation,
        succeeded: Bool
    ) -> CompletionState {
        CompletionState(
            isRunningHistoryOperation: false,
            isUndoing: false,
            closesUndoConfirmation: operation == .undo,
            closesRevertConfirmation: operation == .revert,
            closesResetConfirmations: operation == .reset,
            closesSquashConfirmation: operation == .squash,
            clearsSelectedCommit: succeeded
        )
    }

    public static func startState(for operation: HistoryOperation) -> CompletionState {
        CompletionState(
            isRunningHistoryOperation: operation != .undo,
            isUndoing: operation == .undo,
            closesUndoConfirmation: false,
            closesRevertConfirmation: false,
            closesResetConfirmations: false,
            closesSquashConfirmation: false,
            clearsSelectedCommit: false
        )
    }

    public static func operationResult(
        for operation: HistoryOperation,
        succeeded: Bool,
        commitHash: String,
        resetMode: String? = nil,
        squashCount: Int? = nil
    ) -> OperationResult {
        let message: String?
        if succeeded {
            switch operation {
            case .undo:
                message = nil
            case .revert:
                message = revertedMessage(hash: commitHash)
            case .reset:
                message = resetMessage(hash: commitHash, mode: resetMode ?? "")
            case .squash:
                message = squashedMessage(count: squashCount ?? 0)
            }
        } else {
            message = nil
        }

        return OperationResult(
            completionState: completionState(for: operation, succeeded: succeeded),
            successMessage: message
        )
    }

    public static func performCompletionState(
        _ state: CompletionState,
        setRunningHistoryOperation: (Bool) -> Void,
        setUndoing: (Bool) -> Void,
        closeUndoConfirmation: () -> Void,
        closeRevertConfirmation: () -> Void,
        closeResetConfirmations: () -> Void,
        closeSquashConfirmation: () -> Void,
        clearSelectedCommit: () -> Void
    ) {
        setRunningHistoryOperation(state.isRunningHistoryOperation)
        setUndoing(state.isUndoing)

        if state.closesUndoConfirmation {
            closeUndoConfirmation()
        }
        if state.closesRevertConfirmation {
            closeRevertConfirmation()
        }
        if state.closesResetConfirmations {
            closeResetConfirmations()
        }
        if state.closesSquashConfirmation {
            closeSquashConfirmation()
        }
        if state.clearsSelectedCommit {
            clearSelectedCommit()
        }
    }

    public static func performOperationResult(
        _ result: OperationResult,
        applyCompletionState: (CompletionState) -> Void,
        showSuccessMessage: (String) -> Void
    ) {
        applyCompletionState(result.completionState)
        if let successMessage = result.successMessage {
            showSuccessMessage(successMessage)
        }
    }

    public static func performHistoryOperation(
        operation: HistoryOperation,
        commitHash: String,
        resetMode: String? = nil,
        squashCount: Int? = nil,
        perform: () async throws -> Void,
        applyResult: (OperationResult) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        do {
            try await perform()
            await applyResult(operationResult(
                for: operation,
                succeeded: true,
                commitHash: commitHash,
                resetMode: resetMode,
                squashCount: squashCount
            ))
        } catch {
            await applyResult(operationResult(
                for: operation,
                succeeded: false,
                commitHash: commitHash,
                resetMode: resetMode,
                squashCount: squashCount
            ))
            await handleFailure(error)
        }
    }

    public static func performStartedHistoryOperation(
        operation: HistoryOperation,
        commitHash: String,
        resetMode: String? = nil,
        squashCount: Int? = nil,
        applyStartState: (CompletionState) async -> Void,
        perform: () async throws -> Void,
        applyResult: (OperationResult) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await applyStartState(startState(for: operation))
        await performHistoryOperation(
            operation: operation,
            commitHash: commitHash,
            resetMode: resetMode,
            squashCount: squashCount,
            perform: perform,
            applyResult: applyResult,
            handleFailure: handleFailure
        )
    }

    public static func performValidatedSquashOperation(
        validation: SquashValidation,
        commitHash: String,
        showValidationFailure: (String) async -> Void,
        applyStartState: (CompletionState) async -> Void,
        perform: (SquashValidation) async throws -> Void,
        applyResult: (OperationResult) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        if let failureMessage = validationFailureMessage(for: validation) {
            await showValidationFailure(failureMessage)
            return
        }

        await performStartedHistoryOperation(
            operation: .squash,
            commitHash: commitHash,
            squashCount: validation.count,
            applyStartState: applyStartState,
            perform: {
                try await perform(validation)
            },
            applyResult: applyResult,
            handleFailure: handleFailure
        )
    }

    public static func performUndoOperation(
        commitHash: String,
        parentHashes: [String],
        resetToParent: (String) async throws -> Void,
        logSuccess: (String) async -> Void,
        postSuccess: (EventPayload) async -> Void,
        postFailure: (EventPayload, Error) async -> Void,
        applyCompletionState: (CompletionState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        do {
            let requestState = undoRequestState(parentHashes: parentHashes)
            let parentHash = try validatedParentHash(for: requestState)
            try await resetToParent(parentHash)
            await logSuccess(commitHash)
            await postSuccess(undoSuccessEventPayload(commitHash: commitHash, parentHash: parentHash))
            await applyCompletionState(completionState(for: .undo, succeeded: true))
        } catch {
            await postFailure(undoFailureEventPayload(commitHash: commitHash), error)
            await applyCompletionState(completionState(for: .undo, succeeded: false))
            await handleFailure(error)
        }
    }

    public static func performStartedUndoOperation(
        commitHash: String,
        parentHashes: [String],
        applyStartState: (CompletionState) async -> Void,
        resetToParent: (String) async throws -> Void,
        logSuccess: (String) async -> Void,
        postSuccess: (EventPayload) async -> Void,
        postFailure: (EventPayload, Error) async -> Void,
        applyCompletionState: (CompletionState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await applyStartState(startState(for: .undo))
        await performUndoOperation(
            commitHash: commitHash,
            parentHashes: parentHashes,
            resetToParent: resetToParent,
            logSuccess: logSuccess,
            postSuccess: postSuccess,
            postFailure: postFailure,
            applyCompletionState: applyCompletionState,
            handleFailure: handleFailure
        )
    }

    public static func performProjectHistoryCommand<Commit, ResetMode>(
        command: ProjectHistoryCommand<Commit, ResetMode>,
        handlers: ProjectHistoryCommandHandlers<Commit, ResetMode>,
        showValidationFailure: (String) async -> Void,
        applyStartState: (CompletionState) async -> Void,
        logUndoSuccess: (String) async -> Void,
        postUndoSuccess: (EventPayload) async -> Void,
        postUndoFailure: (EventPayload, Error) async -> Void,
        applyResult: (OperationResult) async -> Void,
        applyCompletionState: (CompletionState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        switch command {
        case let .undo(commit, commitHash, parentHashes):
            await performStartedUndoOperation(
                commitHash: commitHash,
                parentHashes: parentHashes,
                applyStartState: applyStartState,
                resetToParent: { _ in
                    try await handlers.undoCommit(commit)
                },
                logSuccess: logUndoSuccess,
                postSuccess: postUndoSuccess,
                postFailure: postUndoFailure,
                applyCompletionState: applyCompletionState,
                handleFailure: handleFailure
            )
        case let .revert(commit, commitHash):
            await performStartedHistoryOperation(
                operation: .revert,
                commitHash: commitHash,
                applyStartState: applyStartState,
                perform: {
                    try await handlers.revertCommit(commit)
                },
                applyResult: applyResult,
                handleFailure: handleFailure
            )
        case let .reset(commit, commitHash, mode, modeName):
            await performStartedHistoryOperation(
                operation: .reset,
                commitHash: commitHash,
                resetMode: modeName,
                applyStartState: applyStartState,
                perform: {
                    try await handlers.resetToCommit(commit, mode)
                },
                applyResult: applyResult,
                handleFailure: handleFailure
            )
        case let .squash(commitHash, validation):
            await performValidatedSquashOperation(
                validation: validation,
                commitHash: commitHash,
                showValidationFailure: showValidationFailure,
                applyStartState: applyStartState,
                perform: handlers.squashLastCommits,
                applyResult: applyResult,
                handleFailure: handleFailure
            )
        }
    }

    public static func projectHistoryCommandHandlers<Project, Commit, ResetMode>(
        for project: Project,
        handlers: ProjectHistoryProjectCommandHandlers<Project, Commit, ResetMode>
    ) -> ProjectHistoryCommandHandlers<Commit, ResetMode> {
        ProjectHistoryCommandHandlers(
            undoCommit: { commit in
                try await handlers.undoCommit(project, commit)
            },
            revertCommit: { commit in
                try await handlers.revertCommit(project, commit)
            },
            resetToCommit: { commit, mode in
                try await handlers.resetToCommit(project, commit, mode)
            },
            squashLastCommits: { validation in
                try await handlers.squashLastCommits(project, validation)
            }
        )
    }

    public static func performProjectHistoryCommand<Project, Commit, ResetMode>(
        command: ProjectHistoryCommand<Commit, ResetMode>,
        project: Project,
        handlers: ProjectHistoryProjectCommandHandlers<Project, Commit, ResetMode>,
        showValidationFailure: (String) async -> Void,
        applyStartState: (CompletionState) async -> Void,
        logUndoSuccess: (String) async -> Void,
        postUndoSuccess: (EventPayload) async -> Void,
        postUndoFailure: (EventPayload, Error) async -> Void,
        applyResult: (OperationResult) async -> Void,
        applyCompletionState: (CompletionState) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        await performProjectHistoryCommand(
            command: command,
            handlers: projectHistoryCommandHandlers(for: project, handlers: handlers),
            showValidationFailure: showValidationFailure,
            applyStartState: applyStartState,
            logUndoSuccess: logUndoSuccess,
            postUndoSuccess: postUndoSuccess,
            postUndoFailure: postUndoFailure,
            applyResult: applyResult,
            applyCompletionState: applyCompletionState,
            handleFailure: handleFailure
        )
    }

    public static func undoSuccessEventPayload(commitHash: String, parentHash: String) -> EventPayload {
        EventPayload(
            operation: undoCommitOperation,
            additionalInfo: [
                commitHashInfoKey: commitHash,
                parentHashInfoKey: parentHash
            ]
        )
    }

    public static func undoFailureEventPayload(commitHash: String) -> EventPayload {
        EventPayload(
            operation: undoCommitOperation,
            additionalInfo: [commitHashInfoKey: commitHash]
        )
    }

    public static func isCurrentProject(operationProjectPath: String, currentProjectPath: String?) -> Bool {
        operationProjectPath == currentProjectPath
    }

    @discardableResult
    public static func performCurrentProject<Project>(
        operationProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        perform: (Project) -> Void
    ) -> Bool {
        guard let currentProject,
              isCurrentProject(
                  operationProjectPath: operationProjectPath,
                  currentProjectPath: currentProjectPath(currentProject)
              ) else {
            return false
        }

        perform(currentProject)
        return true
    }

    public static func normalizedSquashMessage(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func canSquash(message: String) -> Bool {
        normalizedSquashMessage(message).isEmpty == false
    }

    public static func squashValidation(message: String, commitIndex: Int) -> SquashValidation {
        let normalizedMessage = normalizedSquashMessage(message)
        return SquashValidation(
            message: normalizedMessage,
            count: squashCountThroughHead(commitIndex: commitIndex),
            errorMessage: canSquash(message: normalizedMessage) ? nil : squashMessageRequiredMessage()
        )
    }

    public static func validationFailureMessage(for validation: SquashValidation) -> String? {
        validation.canProceed ? nil : validation.errorMessage
    }

    public static func performValidatedSquash(
        _ validation: SquashValidation,
        showValidationFailure: (String) -> Void,
        applyStartState: (CompletionState) -> Void
    ) -> Bool {
        if let failureMessage = validationFailureMessage(for: validation) {
            showValidationFailure(failureMessage)
            return false
        }

        applyStartState(startState(for: .squash))
        return true
    }

    public static func projectUnavailableMessage() -> String {
        String(localized: "Project unavailable", table: "GitCommit")
    }

    public static func operationError(message: String) -> NSError {
        NSError(domain: errorDomain, code: genericErrorCode, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }

    public static func projectUnavailableError() -> NSError {
        operationError(message: projectUnavailableMessage())
    }

    public static func requiredProject<Project>(_ project: Project?) throws -> Project {
        guard let project else {
            throw projectUnavailableError()
        }

        return project
    }

    @discardableResult
    public static func performRequiredProject<Project>(
        _ project: Project?,
        showUnavailable: (String) -> Void,
        perform: (Project) -> Void
    ) -> Bool {
        guard let project else {
            showUnavailable(projectUnavailableMessage())
            return false
        }

        perform(project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectHistoryOperation<Project>(
        project: Project?,
        operation: HistoryOperation,
        commitHash: String,
        resetMode: String? = nil,
        squashValidation: SquashValidation? = nil,
        showUnavailable: (String) -> Void,
        perform: (HistoryOperationRequest, Project) -> Void
    ) -> Bool {
        guard let project else {
            showUnavailable(projectUnavailableMessage())
            return false
        }

        perform(
            HistoryOperationRequest(
                operation: operation,
                commitHash: commitHash,
                resetMode: resetMode,
                squashValidation: squashValidation
            ),
            project
        )
        return true
    }

    @discardableResult
    public static func performRequiredProjectHistoryCommand<Project, Commit, ResetMode>(
        project: Project?,
        command: ProjectHistoryCommand<Commit, ResetMode>,
        showUnavailable: (String) -> Void,
        perform: (ProjectHistoryCommandRequest<Commit, ResetMode>, Project) -> Void
    ) -> Bool {
        guard let project else {
            showUnavailable(projectUnavailableMessage())
            return false
        }

        perform(ProjectHistoryCommandRequest(command: command), project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectUndoOperation<Project>(
        project: Project?,
        projectPath: (Project) -> String,
        commitHash: String,
        parentHashes: [String],
        showUnavailable: (String) -> Void,
        perform: (UndoProjectRequest) -> Void
    ) -> Bool {
        guard let project else {
            showUnavailable(projectUnavailableMessage())
            return false
        }

        perform(
            UndoProjectRequest(
                projectPath: projectPath(project),
                commitHash: commitHash,
                parentHashes: parentHashes
            )
        )
        return true
    }

    @discardableResult
    public static func performRequiredProjectUndoOperation<Project>(
        project: Project?,
        projectPath: (Project) -> String,
        commitHash: String,
        parentHashes: [String],
        showUnavailable: (String) -> Void,
        perform: (UndoProjectRequest, Project) -> Void
    ) -> Bool {
        guard let project else {
            showUnavailable(projectUnavailableMessage())
            return false
        }

        perform(
            UndoProjectRequest(
                projectPath: projectPath(project),
                commitHash: commitHash,
                parentHashes: parentHashes
            ),
            project
        )
        return true
    }

    public static func undoInitialCommitUnsupportedMessage() -> String {
        String(localized: "Undoing the initial commit is not supported", table: "GitCommit")
    }

    public static func squashMessageRequiredMessage() -> String {
        String(localized: "Commit message cannot be empty", table: "GitCommit")
    }

    public static func revertedMessage(hash: String) -> String {
        String(localized: "Reverted: \(shortHash(hash))", table: "GitCommit")
    }

    public static func resetMessage(hash: String, mode: String) -> String {
        String(localized: "Reset to: \(shortHash(hash)) (\(mode))", table: "GitCommit")
    }

    public static func squashedMessage(count: Int) -> String {
        String(localized: "Squashed \(count) commits", table: "GitCommit")
    }

    private static func shortHash(_ hash: String, length: Int = 8) -> String {
        String(hash.prefix(max(0, length)))
    }
}
