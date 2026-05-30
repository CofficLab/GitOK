import Foundation

public enum CommitTagRules {
    public enum TagOperation: Equatable, Sendable {
        case createLightweight
        case createAnnotated
        case deleteLocal
        case push
        case deleteRemote
    }

    public enum TagPrompt: Equatable, Sendable {
        case lightweight
        case annotated
    }

    public enum ReloadEvent: Equatable, Sendable {
        case refsChanged(eventProjectPath: String, currentProjectPath: String?)
        case appWillBecomeActive
        case commitSuccess
    }

    public struct CompletionState: Equatable, Sendable {
        public let isCreatingTag: Bool
        public let isCreatingAnnotatedTag: Bool
        public let isDeletingTag: Bool
        public let isDeletingRemoteTag: Bool
        public let isPushingTag: Bool
        public let clearsLightweightTagName: Bool
        public let clearsAnnotatedTagFields: Bool
        public let closesCreateTagAlert: Bool
        public let closesCreateAnnotatedTagAlert: Bool
        public let closesDeleteTagConfirmation: Bool
        public let closesDeleteRemoteTagConfirmation: Bool
        public let reloadsTag: Bool
    }

    public struct TagNameValidation: Equatable, Sendable {
        public let normalizedName: String
        public let errorMessage: String?

        public var canProceed: Bool {
            errorMessage == nil
        }

        public init(normalizedName: String, errorMessage: String?) {
            self.normalizedName = normalizedName
            self.errorMessage = errorMessage
        }
    }

    public struct AnnotatedTagValidation: Equatable, Sendable {
        public let normalizedName: String
        public let normalizedMessage: String
        public let errorMessage: String?

        public var canProceed: Bool {
            errorMessage == nil
        }

        public init(normalizedName: String, normalizedMessage: String, errorMessage: String?) {
            self.normalizedName = normalizedName
            self.normalizedMessage = normalizedMessage
            self.errorMessage = errorMessage
        }
    }

    public struct TagOperationRequest: Equatable, Sendable {
        public let operation: TagOperation
        public let tagName: String
        public let tagMessage: String?
        public let errorMessage: String?
        public let startState: CompletionState
        public let successMessage: String

        public var canPerform: Bool {
            errorMessage == nil
        }

        public init(
            operation: TagOperation,
            tagName: String,
            tagMessage: String?,
            errorMessage: String?,
            startState: CompletionState,
            successMessage: String
        ) {
            self.operation = operation
            self.tagName = tagName
            self.tagMessage = tagMessage
            self.errorMessage = errorMessage
            self.startState = startState
            self.successMessage = successMessage
        }
    }

    public struct ProjectTagCommandRequest<Project> {
        public let request: TagOperationRequest
        public let project: Project
        public let commitHash: String

        public init(request: TagOperationRequest, project: Project, commitHash: String) {
            self.request = request
            self.project = project
            self.commitHash = commitHash
        }
    }

    public struct ProjectVisibleTagLoadRequest<Project> {
        public let project: Project
        public let commitHash: String

        public init(project: Project, commitHash: String) {
            self.project = project
            self.commitHash = commitHash
        }
    }

    public struct TagOperationResult: Equatable, Sendable {
        public let completionState: CompletionState
        public let successMessage: String?

        public init(completionState: CompletionState, successMessage: String?) {
            self.completionState = completionState
            self.successMessage = successMessage
        }
    }

    public struct ProjectTagCommandHandlers<Project> {
        public let createLightweight: (Project, String, String) async throws -> Void
        public let createAnnotated: (Project, String, String, String) async throws -> Void
        public let deleteLocal: (Project, String) async throws -> Void
        public let push: (Project, String) async throws -> Void
        public let deleteRemote: (Project, String) async throws -> Void

        public init(
            createLightweight: @escaping (Project, String, String) async throws -> Void,
            createAnnotated: @escaping (Project, String, String, String) async throws -> Void,
            deleteLocal: @escaping (Project, String) async throws -> Void,
            push: @escaping (Project, String) async throws -> Void,
            deleteRemote: @escaping (Project, String) async throws -> Void
        ) {
            self.createLightweight = createLightweight
            self.createAnnotated = createAnnotated
            self.deleteLocal = deleteLocal
            self.push = push
            self.deleteRemote = deleteRemote
        }
    }

    public struct TagPromptState: Equatable, Sendable {
        public let showsPrompt: Bool
        public let tagName: String
        public let tagMessage: String

        public init(showsPrompt: Bool, tagName: String, tagMessage: String) {
            self.showsPrompt = showsPrompt
            self.tagName = tagName
            self.tagMessage = tagMessage
        }
    }

    public struct TagConfirmationPromptState: Equatable, Sendable {
        public let showsPrompt: Bool

        public init(showsPrompt: Bool) {
            self.showsPrompt = showsPrompt
        }
    }

    public struct TagPromptApplicationState: Equatable, Sendable {
        public let lightweightTagName: String?
        public let annotatedTagName: String?
        public let annotatedTagMessage: String?
        public let showsLightweightPrompt: Bool
        public let showsAnnotatedPrompt: Bool

        public init(
            lightweightTagName: String?,
            annotatedTagName: String?,
            annotatedTagMessage: String?,
            showsLightweightPrompt: Bool,
            showsAnnotatedPrompt: Bool
        ) {
            self.lightweightTagName = lightweightTagName
            self.annotatedTagName = annotatedTagName
            self.annotatedTagMessage = annotatedTagMessage
            self.showsLightweightPrompt = showsLightweightPrompt
            self.showsAnnotatedPrompt = showsAnnotatedPrompt
        }
    }

    public static func normalizedTagName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func normalizedTagMessage(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func visibleTag(from tags: [String]) -> String {
        tags.first ?? ""
    }

    public static func createLightweightPromptState() -> TagPromptState {
        TagPromptState(showsPrompt: true, tagName: "", tagMessage: "")
    }

    public static func createAnnotatedPromptState() -> TagPromptState {
        TagPromptState(showsPrompt: true, tagName: "", tagMessage: "")
    }

    public static func promptState(for prompt: TagPrompt) -> TagPromptState {
        switch prompt {
        case .lightweight:
            return createLightweightPromptState()
        case .annotated:
            return createAnnotatedPromptState()
        }
    }

    public static func deleteLocalPromptState() -> TagConfirmationPromptState {
        TagConfirmationPromptState(showsPrompt: true)
    }

    public static func deleteRemotePromptState() -> TagConfirmationPromptState {
        TagConfirmationPromptState(showsPrompt: true)
    }

    public static func performConfirmationPromptState(
        _ state: TagConfirmationPromptState,
        setPresented: (Bool) -> Void
    ) {
        setPresented(state.showsPrompt)
    }

    public static func performDeleteLocalPrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(deleteLocalPromptState(), setPresented: setPresented)
    }

    public static func performDeleteRemotePrompt(setPresented: (Bool) -> Void) {
        performConfirmationPromptState(deleteRemotePromptState(), setPresented: setPresented)
    }

    public static func promptApplicationState(
        state: TagPromptState,
        prompt: TagPrompt
    ) -> TagPromptApplicationState {
        switch prompt {
        case .lightweight:
            return TagPromptApplicationState(
                lightweightTagName: state.tagName,
                annotatedTagName: nil,
                annotatedTagMessage: nil,
                showsLightweightPrompt: state.showsPrompt,
                showsAnnotatedPrompt: false
            )
        case .annotated:
            return TagPromptApplicationState(
                lightweightTagName: nil,
                annotatedTagName: state.tagName,
                annotatedTagMessage: state.tagMessage,
                showsLightweightPrompt: false,
                showsAnnotatedPrompt: state.showsPrompt
            )
        }
    }

    public static func performPromptApplicationState(
        _ state: TagPromptApplicationState,
        setLightweightTagName: (String) -> Void,
        setAnnotatedTagName: (String) -> Void,
        setAnnotatedTagMessage: (String) -> Void,
        setLightweightPromptPresented: (Bool) -> Void,
        setAnnotatedPromptPresented: (Bool) -> Void
    ) {
        if let lightweightTagName = state.lightweightTagName {
            setLightweightTagName(lightweightTagName)
            setLightweightPromptPresented(state.showsLightweightPrompt)
        }
        if let annotatedTagName = state.annotatedTagName {
            setAnnotatedTagName(annotatedTagName)
        }
        if let annotatedTagMessage = state.annotatedTagMessage {
            setAnnotatedTagMessage(annotatedTagMessage)
            setAnnotatedPromptPresented(state.showsAnnotatedPrompt)
        }
    }

    public static func shouldReloadTagOnRefsChanged(isCurrentProject: Bool) -> Bool {
        isCurrentProject
    }

    public static func shouldReloadTagOnRefsChanged(eventProjectPath: String, currentProjectPath: String?) -> Bool {
        shouldReloadTagOnRefsChanged(isCurrentProject: eventProjectPath == currentProjectPath)
    }

    public static func shouldReloadTagOnRefsChanged<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String
    ) -> Bool {
        shouldReloadTagOnRefsChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath)
        )
    }

    @discardableResult
    public static func performRefsChangedReload(
        eventProjectPath: String,
        currentProjectPath: String?,
        reloadTag: () -> Void
    ) -> Bool {
        guard shouldReloadTagOnRefsChanged(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProjectPath
        ) else {
            return false
        }

        reloadTag()
        return true
    }

    @discardableResult
    public static func performRefsChangedReload<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        reloadTag: () -> Void
    ) -> Bool {
        performRefsChangedReload(
            eventProjectPath: eventProjectPath,
            currentProjectPath: currentProject.map(currentProjectPath),
            reloadTag: reloadTag
        )
    }

    public static func performAppWillBecomeActiveReload(reloadTag: () -> Void) {
        reloadTag()
    }

    public static func performCommitSuccessReload(reloadTag: () -> Void) {
        reloadTag()
    }

    public static func shouldReloadTag(for event: ReloadEvent) -> Bool {
        switch event {
        case let .refsChanged(eventProjectPath, currentProjectPath):
            return shouldReloadTagOnRefsChanged(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProjectPath
            )
        case .appWillBecomeActive, .commitSuccess:
            return true
        }
    }

    @discardableResult
    public static func performReloadEvent(
        _ event: ReloadEvent,
        reloadTag: () -> Void
    ) -> Bool {
        guard shouldReloadTag(for: event) else {
            return false
        }

        reloadTag()
        return true
    }

    @discardableResult
    public static func performRefsChangedReloadEvent<Project>(
        eventProjectPath: String,
        currentProject: Project?,
        currentProjectPath: (Project) -> String,
        reloadTag: () -> Void
    ) -> Bool {
        performReloadEvent(
            .refsChanged(
                eventProjectPath: eventProjectPath,
                currentProjectPath: currentProject.map(currentProjectPath)
            ),
            reloadTag: reloadTag
        )
    }

    public static func canCreateLightweightTag(name: String) -> Bool {
        normalizedTagName(name).isEmpty == false
    }

    public static func canCreateAnnotatedTag(name: String, message: String) -> Bool {
        normalizedTagName(name).isEmpty == false &&
            normalizedTagMessage(message).isEmpty == false
    }

    public static func tagNameValidation(_ name: String) -> TagNameValidation {
        let normalizedName = normalizedTagName(name)
        return TagNameValidation(
            normalizedName: normalizedName,
            errorMessage: normalizedName.isEmpty ? tagNameRequiredMessage() : nil
        )
    }

    public static func annotatedTagValidation(name: String, message: String) -> AnnotatedTagValidation {
        let normalizedName = normalizedTagName(name)
        let normalizedMessage = normalizedTagMessage(message)
        let errorMessage: String?

        if normalizedName.isEmpty {
            errorMessage = tagNameRequiredMessage()
        } else if normalizedMessage.isEmpty {
            errorMessage = tagMessageRequiredMessage()
        } else {
            errorMessage = nil
        }

        return AnnotatedTagValidation(
            normalizedName: normalizedName,
            normalizedMessage: normalizedMessage,
            errorMessage: errorMessage
        )
    }

    public static func createLightweightRequest(name: String) -> TagOperationRequest {
        let validation = tagNameValidation(name)
        return TagOperationRequest(
            operation: .createLightweight,
            tagName: validation.normalizedName,
            tagMessage: nil,
            errorMessage: validation.errorMessage,
            startState: startState(for: .createLightweight),
            successMessage: createdMessage(tagName: validation.normalizedName)
        )
    }

    public static func createAnnotatedRequest(name: String, message: String) -> TagOperationRequest {
        let validation = annotatedTagValidation(name: name, message: message)
        return TagOperationRequest(
            operation: .createAnnotated,
            tagName: validation.normalizedName,
            tagMessage: validation.normalizedMessage,
            errorMessage: validation.errorMessage,
            startState: startState(for: .createAnnotated),
            successMessage: createdMessage(tagName: validation.normalizedName)
        )
    }

    public static func tagRequest(
        for operation: TagOperation,
        tagName: String,
        tagMessage: String = ""
    ) -> TagOperationRequest {
        switch operation {
        case .createLightweight:
            return createLightweightRequest(name: tagName)
        case .createAnnotated:
            return createAnnotatedRequest(name: tagName, message: tagMessage)
        case .deleteLocal:
            return deleteLocalRequest(tagName: tagName)
        case .push:
            return pushRequest(tagName: tagName)
        case .deleteRemote:
            return deleteRemoteRequest(tagName: tagName)
        }
    }

    public static func deleteLocalRequest(tagName: String) -> TagOperationRequest {
        existingTagRequest(operation: .deleteLocal, tagName: tagName)
    }

    public static func pushRequest(tagName: String) -> TagOperationRequest {
        existingTagRequest(operation: .push, tagName: tagName)
    }

    public static func deleteRemoteRequest(tagName: String) -> TagOperationRequest {
        existingTagRequest(operation: .deleteRemote, tagName: tagName)
    }

    public static func validationFailureMessage(for request: TagOperationRequest) -> String? {
        request.canPerform ? nil : request.errorMessage
    }

    public static func performValidatedRequest(
        _ request: TagOperationRequest,
        showValidationFailure: (String) -> Void,
        applyStartState: (CompletionState) -> Void
    ) -> Bool {
        if let failureMessage = validationFailureMessage(for: request) {
            showValidationFailure(failureMessage)
            return false
        }

        applyStartState(request.startState)
        return true
    }

    @discardableResult
    public static func performRequiredProjectTagRequest<Project>(
        project: Project?,
        request: TagOperationRequest,
        projectUnavailableMessage: String,
        showUnavailable: (String) -> Void,
        perform: (TagOperationRequest, Project) -> Void
    ) -> Bool {
        guard let project else {
            showUnavailable(projectUnavailableMessage)
            return false
        }

        perform(request, project)
        return true
    }

    @discardableResult
    public static func performRequiredProjectTagRequest<Project>(
        project: Project?,
        operation: TagOperation,
        tagName: String,
        tagMessage: String = "",
        projectUnavailableMessage: String,
        showUnavailable: (String) -> Void,
        perform: (TagOperationRequest, Project) -> Void
    ) -> Bool {
        performRequiredProjectTagRequest(
            project: project,
            request: tagRequest(for: operation, tagName: tagName, tagMessage: tagMessage),
            projectUnavailableMessage: projectUnavailableMessage,
            showUnavailable: showUnavailable,
            perform: perform
        )
    }

    @discardableResult
    public static func performRequiredProjectTagCommand<Project>(
        project: Project?,
        operation: TagOperation,
        tagName: String,
        tagMessage: String = "",
        commitHash: String,
        projectUnavailableMessage: String,
        showUnavailable: (String) -> Void,
        perform: (ProjectTagCommandRequest<Project>) -> Void
    ) -> Bool {
        performRequiredProjectTagRequest(
            project: project,
            operation: operation,
            tagName: tagName,
            tagMessage: tagMessage,
            projectUnavailableMessage: projectUnavailableMessage,
            showUnavailable: showUnavailable
        ) { request, project in
            perform(ProjectTagCommandRequest(
                request: request,
                project: project,
                commitHash: commitHash
            ))
        }
    }

    public static func performProjectTagCommand<Project>(
        project: Project,
        request: TagOperationRequest,
        commitHash: String,
        handlers: ProjectTagCommandHandlers<Project>
    ) async throws {
        switch request.operation {
        case .createLightweight:
            try await handlers.createLightweight(project, request.tagName, commitHash)
        case .createAnnotated:
            try await handlers.createAnnotated(project, request.tagName, commitHash, request.tagMessage ?? "")
        case .deleteLocal:
            try await handlers.deleteLocal(project, request.tagName)
        case .push:
            try await handlers.push(project, request.tagName)
        case .deleteRemote:
            try await handlers.deleteRemote(project, request.tagName)
        }
    }

    private static func existingTagRequest(operation: TagOperation, tagName: String) -> TagOperationRequest {
        let validation = tagNameValidation(tagName)
        let successMessage: String
        switch operation {
        case .createLightweight, .createAnnotated:
            successMessage = createdMessage(tagName: validation.normalizedName)
        case .deleteLocal:
            successMessage = deletedMessage(tagName: validation.normalizedName)
        case .push:
            successMessage = pushedMessage(tagName: validation.normalizedName)
        case .deleteRemote:
            successMessage = remoteDeletedMessage(tagName: validation.normalizedName)
        }

        return TagOperationRequest(
            operation: operation,
            tagName: validation.normalizedName,
            tagMessage: nil,
            errorMessage: validation.errorMessage,
            startState: startState(for: operation),
            successMessage: successMessage
        )
    }

    public static func tagNameRequiredMessage() -> String {
        String(localized: "Tag name cannot be empty", table: "GitCommit")
    }

    public static func tagMessageRequiredMessage() -> String {
        String(localized: "Tag message cannot be empty", table: "GitCommit")
    }

    public static func createdMessage(tagName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "Tag created: %@", table: "GitCommit"),
            tagName
        )
    }

    public static func deletedMessage(tagName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "Tag deleted: %@", table: "GitCommit"),
            tagName
        )
    }

    public static func pushedMessage(tagName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "Tag pushed: %@", table: "GitCommit"),
            tagName
        )
    }

    public static func remoteDeletedMessage(tagName: String) -> String {
        String.localizedStringWithFormat(
            String(localized: "Remote tag deleted: %@", table: "GitCommit"),
            tagName
        )
    }

    public static func shortHash(_ hash: String, length: Int = 8) -> String {
        String(hash.prefix(max(0, length)))
    }

    public static func completionState(for operation: TagOperation, succeeded: Bool) -> CompletionState {
        CompletionState(
            isCreatingTag: false,
            isCreatingAnnotatedTag: false,
            isDeletingTag: false,
            isDeletingRemoteTag: false,
            isPushingTag: false,
            clearsLightweightTagName: succeeded && operation == .createLightweight,
            clearsAnnotatedTagFields: succeeded && operation == .createAnnotated,
            closesCreateTagAlert: succeeded && operation == .createLightweight,
            closesCreateAnnotatedTagAlert: succeeded && operation == .createAnnotated,
            closesDeleteTagConfirmation: succeeded && operation == .deleteLocal,
            closesDeleteRemoteTagConfirmation: succeeded && operation == .deleteRemote,
            reloadsTag: succeeded && (operation == .createLightweight || operation == .createAnnotated || operation == .deleteLocal)
        )
    }

    public static func operationResult(request: TagOperationRequest, succeeded: Bool) -> TagOperationResult {
        TagOperationResult(
            completionState: completionState(for: request.operation, succeeded: succeeded),
            successMessage: succeeded ? request.successMessage : nil
        )
    }

    public static func performOperationResult(
        _ result: TagOperationResult,
        applyCompletionState: (CompletionState) -> Void,
        showSuccessMessage: (String) -> Void
    ) {
        applyCompletionState(result.completionState)
        if let successMessage = result.successMessage {
            showSuccessMessage(successMessage)
        }
    }

    public static func performTagOperation(
        request: TagOperationRequest,
        operation: (TagOperationRequest) async throws -> Void,
        applyResult: (TagOperationResult) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        guard request.canPerform else {
            return
        }

        do {
            try await operation(request)
            await applyResult(operationResult(request: request, succeeded: true))
        } catch {
            await applyResult(operationResult(request: request, succeeded: false))
            await handleFailure(error)
        }
    }

    public static func performValidatedTagOperation(
        request: TagOperationRequest,
        showValidationFailure: (String) async -> Void,
        applyStartState: (CompletionState) async -> Void,
        operation: (TagOperationRequest) async throws -> Void,
        applyResult: (TagOperationResult) async -> Void,
        handleFailure: (Error) async -> Void
    ) async {
        if let failureMessage = validationFailureMessage(for: request) {
            await showValidationFailure(failureMessage)
            return
        }

        await applyStartState(request.startState)
        await performTagOperation(
            request: request,
            operation: operation,
            applyResult: applyResult,
            handleFailure: handleFailure
        )
    }

    public static func performVisibleTagLoad(
        loadTags: () async throws -> [String],
        setTag: (String) async -> Void
    ) async {
        do {
            await setTag(visibleTag(from: try await loadTags()))
        } catch {
            await setTag("")
        }
    }

    public static func performOptionalVisibleTagLoad(
        loadTags: (() async throws -> [String])?,
        setTag: (String) async -> Void
    ) async {
        guard let loadTags else {
            await setTag("")
            return
        }

        await performVisibleTagLoad(
            loadTags: loadTags,
            setTag: setTag
        )
    }

    public static func performOptionalVisibleTagLoad(
        commitHash: String,
        loadTags: ((String) async throws -> [String])?,
        setTag: (String) async -> Void
    ) async {
        guard let loadTags else {
            await setTag("")
            return
        }

        await performVisibleTagLoad(
            loadTags: {
                try await loadTags(commitHash)
            },
            setTag: setTag
        )
    }

    public static func performProjectVisibleTagLoad<Project>(
        project: Project?,
        commitHash: String,
        loadTags: @escaping (Project, String) async throws -> [String],
        setTag: (String) async -> Void
    ) async {
        await performOptionalVisibleTagLoad(
            commitHash: commitHash,
            loadTags: project.map { project in
                { hash in
                    try await loadTags(project, hash)
                }
            },
            setTag: setTag
        )
    }

    public static func performProjectVisibleTagLoadCommand<Project>(
        project: Project?,
        commitHash: String,
        loadTags: @escaping (ProjectVisibleTagLoadRequest<Project>) async throws -> [String],
        setTag: (String) async -> Void
    ) async {
        await performOptionalVisibleTagLoad(
            commitHash: commitHash,
            loadTags: project.map { project in
                { hash in
                    try await loadTags(ProjectVisibleTagLoadRequest(project: project, commitHash: hash))
                }
            },
            setTag: setTag
        )
    }

    public static func performCompletionState(
        _ state: CompletionState,
        setCreatingTag: (Bool) -> Void,
        setCreatingAnnotatedTag: (Bool) -> Void,
        setDeletingTag: (Bool) -> Void,
        setDeletingRemoteTag: (Bool) -> Void,
        setPushingTag: (Bool) -> Void,
        clearLightweightTagName: () -> Void,
        clearAnnotatedTagFields: () -> Void,
        closeCreateTagAlert: () -> Void,
        closeCreateAnnotatedTagAlert: () -> Void,
        closeDeleteTagConfirmation: () -> Void,
        closeDeleteRemoteTagConfirmation: () -> Void,
        reloadTag: () -> Void
    ) {
        setCreatingTag(state.isCreatingTag)
        setCreatingAnnotatedTag(state.isCreatingAnnotatedTag)
        setDeletingTag(state.isDeletingTag)
        setDeletingRemoteTag(state.isDeletingRemoteTag)
        setPushingTag(state.isPushingTag)

        if state.clearsLightweightTagName {
            clearLightweightTagName()
        }
        if state.clearsAnnotatedTagFields {
            clearAnnotatedTagFields()
        }
        if state.closesCreateTagAlert {
            closeCreateTagAlert()
        }
        if state.closesCreateAnnotatedTagAlert {
            closeCreateAnnotatedTagAlert()
        }
        if state.closesDeleteTagConfirmation {
            closeDeleteTagConfirmation()
        }
        if state.closesDeleteRemoteTagConfirmation {
            closeDeleteRemoteTagConfirmation()
        }
        if state.reloadsTag {
            reloadTag()
        }
    }

    public static func startState(for operation: TagOperation) -> CompletionState {
        CompletionState(
            isCreatingTag: operation == .createLightweight,
            isCreatingAnnotatedTag: operation == .createAnnotated,
            isDeletingTag: operation == .deleteLocal,
            isDeletingRemoteTag: operation == .deleteRemote,
            isPushingTag: operation == .push,
            clearsLightweightTagName: false,
            clearsAnnotatedTagFields: false,
            closesCreateTagAlert: false,
            closesCreateAnnotatedTagAlert: false,
            closesDeleteTagConfirmation: false,
            closesDeleteRemoteTagConfirmation: false,
            reloadsTag: false
        )
    }
}
