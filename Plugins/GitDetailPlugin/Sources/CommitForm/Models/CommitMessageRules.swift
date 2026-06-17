import GitOKCoreKit
import Foundation
import ProjectRulesKit
import ProjectSupportKit

public enum CommitMessageRules {
    public static let fallbackSubject = "Auto Committed by GitOK"
    public static let fallbackCommitMessage = "自动提交"

    public enum Activity {
        case addingFiles
        case committing
        case pushing
    }

    public enum SubmitStep: Equatable, Sendable {
        case addAllFiles
        case commit
        case push
    }

    public struct FormAppearanceState: Equatable {
        public let subject: String
        public let style: CommitStyle

        public init(subject: String, style: CommitStyle) {
            self.subject = subject
            self.style = style
        }
    }

    public struct SubmitPlan: Equatable, Sendable {
        public let message: String
        public let addsAllFiles: Bool
        public let pushesAfterCommit: Bool

        public init(message: String, addsAllFiles: Bool, pushesAfterCommit: Bool) {
            self.message = message
            self.addsAllFiles = addsAllFiles
            self.pushesAfterCommit = pushesAfterCommit
        }
    }

    public struct SubmitSuccessState: Equatable, Sendable {
        public let message: String
        public let clearsActivityStatus: Bool

        public init(message: String, clearsActivityStatus: Bool) {
            self.message = message
            self.clearsActivityStatus = clearsActivityStatus
        }
    }

    public struct SubmitExecutionState: Equatable, Sendable {
        public let plan: SubmitPlan
        public let steps: [SubmitStep]

        public init(plan: SubmitPlan, steps: [SubmitStep]) {
            self.plan = plan
            self.steps = steps
        }
    }

    public struct SubmitRequest: Equatable, Sendable {
        public let message: String
        public let commitOnly: Bool

        public init(message: String, commitOnly: Bool) {
            self.message = message
            self.commitOnly = commitOnly
        }
    }

    public struct ProjectSubmitRequest<Project> {
        public let request: SubmitRequest
        public let project: Project

        public init(request: SubmitRequest, project: Project) {
            self.request = request
            self.project = project
        }
    }

    public struct SubmitOperationHandlers {
        public let hasStagedChanges: () async throws -> Bool
        public let addAllFiles: () async throws -> Void
        public let commit: (SubmitPlan) async throws -> Void
        public let push: () async throws -> Void

        public init(
            hasStagedChanges: @escaping () async throws -> Bool,
            addAllFiles: @escaping () async throws -> Void,
            commit: @escaping (SubmitPlan) async throws -> Void,
            push: @escaping () async throws -> Void
        ) {
            self.hasStagedChanges = hasStagedChanges
            self.addAllFiles = addAllFiles
            self.commit = commit
            self.push = push
        }
    }

    public struct ProjectSubmitOperationHandlers<Project> {
        public let hasStagedChanges: (Project) async throws -> Bool
        public let addAllFiles: (Project) async throws -> Void
        public let commit: (Project, SubmitPlan) async throws -> Void
        public let push: (Project) async throws -> Void

        public init(
            hasStagedChanges: @escaping (Project) async throws -> Bool,
            addAllFiles: @escaping (Project) async throws -> Void,
            commit: @escaping (Project, SubmitPlan) async throws -> Void,
            push: @escaping (Project) async throws -> Void
        ) {
            self.hasStagedChanges = hasStagedChanges
            self.addAllFiles = addAllFiles
            self.commit = commit
            self.push = push
        }
    }

    public struct AutocompleteState: Equatable, Sendable {
        public let userMentions: [String]
        public let issueReferences: [String]

        public init(userMentions: [String], issueReferences: [String]) {
            self.userMentions = userMentions
            self.issueReferences = issueReferences
        }
    }

    public struct ProjectAutocompleteLoadRequest<Project> {
        public let project: Project

        public init(project: Project) {
            self.project = project
        }
    }

    public struct ProjectAutocompleteLoadHandlers<Project, Branch> {
        public let loadLocalBranches: (Project) async throws -> [Branch]
        public let localBranchName: (Branch) -> String
        public let loadRemoteBranches: (Project) async throws -> [String]

        public init(
            loadLocalBranches: @escaping (Project) async throws -> [Branch],
            localBranchName: @escaping (Branch) -> String,
            loadRemoteBranches: @escaping (Project) async throws -> [String]
        ) {
            self.loadLocalBranches = loadLocalBranches
            self.localBranchName = localBranchName
            self.loadRemoteBranches = loadRemoteBranches
        }
    }

    public struct ProjectStyleSaveRequest<Project> {
        public let project: Project
        public let style: CommitStyle

        public init(project: Project, style: CommitStyle) {
            self.project = project
            self.style = style
        }
    }

    public static func defaultMessage(for category: CommitCategory, style: CommitStyle) -> String {
        let baseMessage = category.defaultMessage

        if style.isLowercase {
            return lowercasedFirst(baseMessage)
        }

        return baseMessage
    }

    public static func initialSubject(category: CommitCategory, style: CommitStyle) -> String {
        defaultMessage(for: category, style: style)
    }

    public static func formAppearanceState(
        category: CommitCategory,
        currentStyle: CommitStyle,
        projectStyle: CommitStyle?
    ) -> FormAppearanceState {
        let style = projectStyle ?? currentStyle
        return FormAppearanceState(
            subject: initialSubject(category: category, style: style),
            style: style
        )
    }

    public static func formAppearanceState<Project>(
        category: CommitCategory,
        currentStyle: CommitStyle,
        project: Project?,
        projectStyle: (Project) -> CommitStyle
    ) -> FormAppearanceState {
        formAppearanceState(
            category: category,
            currentStyle: currentStyle,
            projectStyle: project.map(projectStyle)
        )
    }

    public static func performFormAppearanceState(
        _ state: FormAppearanceState,
        setSubject: (String) -> Void,
        setStyle: (CommitStyle) -> Void
    ) {
        setSubject(state.subject)
        setStyle(state.style)
    }

    public static func performFormAppear(
        appearanceState: FormAppearanceState,
        setSubject: (String) -> Void,
        setStyle: (CommitStyle) -> Void,
        loadAutocomplete: () -> Void
    ) {
        performFormAppearanceState(
            appearanceState,
            setSubject: setSubject,
            setStyle: setStyle
        )
        loadAutocomplete()
    }

    public static func performAutocompleteRefreshTrigger(loadAutocomplete: () -> Void) {
        loadAutocomplete()
    }

    @discardableResult
    public static func performProjectStyleSave<Project>(
        _ project: Project?,
        style: CommitStyle,
        save: (Project, CommitStyle) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        save(project, style)
        return true
    }

    @discardableResult
    public static func performProjectStyleSaveCommand<Project>(
        project: Project?,
        style: CommitStyle,
        save: (ProjectStyleSaveRequest<Project>) -> Void
    ) -> Bool {
        performProjectStyleSave(project, style: style) { project, style in
            save(ProjectStyleSaveRequest(project: project, style: style))
        }
    }

    public static func subjectAfterCategoryChange(category: CommitCategory, style: CommitStyle) -> String {
        defaultMessage(for: category, style: style)
    }

    public static func performSubjectReset(
        category: CommitCategory,
        style: CommitStyle,
        setSubject: (String) -> Void
    ) {
        setSubject(subjectAfterCategoryChange(category: category, style: style))
    }

    public static func performProjectDidCommit(
        category: CommitCategory,
        style: CommitStyle,
        setSubject: (String) -> Void
    ) {
        performSubjectReset(category: category, style: style, setSubject: setSubject)
    }

    public static func performCategoryDidChange(
        category: CommitCategory,
        style: CommitStyle,
        setSubject: (String) -> Void
    ) {
        performSubjectReset(category: category, style: style, setSubject: setSubject)
    }

    public static func subjectAfterStyleChange(
        currentSubject: String,
        category: CommitCategory,
        newStyle: CommitStyle
    ) -> String? {
        guard shouldReplaceSubjectOnStyleChange(currentSubject: currentSubject, category: category) else {
            return nil
        }

        return defaultMessage(for: category, style: newStyle)
    }

    @discardableResult
    public static func performSubjectAfterStyleChange(
        currentSubject: String,
        category: CommitCategory,
        newStyle: CommitStyle,
        setSubject: (String) -> Void
    ) -> Bool {
        guard let newSubject = subjectAfterStyleChange(
            currentSubject: currentSubject,
            category: category,
            newStyle: newStyle
        ) else {
            return false
        }

        setSubject(newSubject)
        return true
    }

    public static func formattedMessage(
        subject: String,
        category: CommitCategory,
        style: CommitStyle,
        coAuthors: [CoAuthor]
    ) -> String {
        let normalizedSubject = subject.isEmpty ? fallbackSubject : subject
        var message = "\(category.text(style: style)) \(normalizedSubject)"

        if coAuthors.isEmpty == false {
            message += "\n\n" + coAuthors.map(\.coAuthoredByLine).joined(separator: "\n")
        }

        return message
    }

    public static func submitMessage(_ message: String) -> String {
        message.isEmpty ? fallbackCommitMessage : message
    }

    public static func submitPlan(
        message: String,
        hasStagedChanges: Bool,
        commitOnly: Bool
    ) -> SubmitPlan {
        SubmitPlan(
            message: submitMessage(message),
            addsAllFiles: hasStagedChanges == false,
            pushesAfterCommit: commitOnly == false
        )
    }

    public static func submitSteps(for plan: SubmitPlan) -> [SubmitStep] {
        var steps: [SubmitStep] = []
        if plan.addsAllFiles {
            steps.append(.addAllFiles)
        }
        steps.append(.commit)
        if plan.pushesAfterCommit {
            steps.append(.push)
        }
        return steps
    }

    public static func submitExecutionState(
        message: String,
        hasStagedChanges: Bool,
        commitOnly: Bool
    ) -> SubmitExecutionState {
        let plan = submitPlan(
            message: message,
            hasStagedChanges: hasStagedChanges,
            commitOnly: commitOnly
        )
        return SubmitExecutionState(
            plan: plan,
            steps: submitSteps(for: plan)
        )
    }

    public static func submitExecutionState(
        message: String,
        commitOnly: Bool,
        hasStagedChanges: () async throws -> Bool
    ) async throws -> SubmitExecutionState {
        try await submitExecutionState(
            message: message,
            hasStagedChanges: hasStagedChanges(),
            commitOnly: commitOnly
        )
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
    public static func performRequiredProjectSubmit<Project>(
        project: Project?,
        message: String,
        commitOnly: Bool,
        perform: (SubmitRequest, Project) -> Void
    ) -> Bool {
        guard let project else {
            return false
        }

        perform(
            SubmitRequest(message: message, commitOnly: commitOnly),
            project
        )
        return true
    }

    @discardableResult
    public static func performRequiredProjectSubmitCommand<Project>(
        project: Project?,
        message: String,
        commitOnly: Bool,
        perform: (ProjectSubmitRequest<Project>) -> Void
    ) -> Bool {
        performRequiredProjectSubmit(
            project: project,
            message: message,
            commitOnly: commitOnly
        ) { request, project in
            perform(ProjectSubmitRequest(request: request, project: project))
        }
    }

    public static func autocompleteUserMentions(namesAndEmails: [(name: String, email: String)]) -> [String] {
        CommitAutocompleteRules.userMentionCandidates(namesAndEmails: namesAndEmails)
    }

    public static func autocompleteNameEmailPairs(coAuthors: [CoAuthor]) -> [(name: String, email: String)] {
        coAuthors.map { (name: $0.name, email: $0.email) }
    }

    public static func autocompleteBranchNames(localBranches: [String], remoteBranches: [String]) -> [String] {
        localBranches + remoteBranches
    }

    public static func autocompleteIssueReferences(branchNames: [String]) -> [String] {
        CommitAutocompleteRules.issueReferences(from: branchNames)
    }

    public static func autocompleteState(
        namesAndEmails: [(name: String, email: String)],
        localBranches: [String],
        remoteBranches: [String]
    ) -> AutocompleteState {
        AutocompleteState(
            userMentions: autocompleteUserMentions(namesAndEmails: namesAndEmails),
            issueReferences: autocompleteIssueReferences(
                branchNames: autocompleteBranchNames(
                    localBranches: localBranches,
                    remoteBranches: remoteBranches
                )
            )
        )
    }

    public static func autocompleteState<Branch>(
        namesAndEmails: [(name: String, email: String)],
        localBranches: [Branch],
        localBranchName: (Branch) -> String,
        remoteBranches: [String]
    ) -> AutocompleteState {
        autocompleteState(
            namesAndEmails: namesAndEmails,
            localBranches: localBranches.map(localBranchName),
            remoteBranches: remoteBranches
        )
    }

    public static func autocompleteInitialState(
        namesAndEmails: [(name: String, email: String)]
    ) -> AutocompleteState {
        autocompleteState(
            namesAndEmails: namesAndEmails,
            localBranches: [],
            remoteBranches: []
        )
    }

    public static func performAutocompleteState(
        _ state: AutocompleteState,
        setUserMentions: ([String]) -> Void,
        setIssueReferences: ([String]) -> Void
    ) {
        setUserMentions(state.userMentions)
        setIssueReferences(state.issueReferences)
    }

    public static func performAutocompleteInitialState(
        _ state: AutocompleteState,
        hasProject: Bool,
        setUserMentions: ([String]) -> Void,
        setIssueReferences: ([String]) -> Void
    ) {
        setUserMentions(state.userMentions)

        if hasProject == false {
            setIssueReferences(state.issueReferences)
        }
    }

    public static func shouldLoadProjectAutocomplete(hasProject: Bool) -> Bool {
        hasProject
    }

    public static func performProjectAutocompleteLoad(
        namesAndEmails: [(name: String, email: String)],
        loadLocalBranchNames: () async throws -> [String],
        loadRemoteBranches: () async throws -> [String],
        setAutocomplete: (AutocompleteState) async -> Void
    ) async {
        let localBranches = (try? await loadLocalBranchNames()) ?? []
        let remoteBranches = (try? await loadRemoteBranches()) ?? []
        let state = autocompleteState(
            namesAndEmails: namesAndEmails,
            localBranches: localBranches,
            remoteBranches: remoteBranches
        )

        await setAutocomplete(state)
    }

    public static func performAutocompleteLoadOperation(
        namesAndEmails: [(name: String, email: String)],
        hasProject: Bool,
        loadLocalBranchNames: (() async throws -> [String])?,
        loadRemoteBranches: (() async throws -> [String])?,
        setUserMentions: ([String]) async -> Void,
        setIssueReferences: ([String]) async -> Void
    ) async {
        let initialState = autocompleteInitialState(namesAndEmails: namesAndEmails)
        await setUserMentions(initialState.userMentions)

        guard shouldLoadProjectAutocomplete(hasProject: hasProject),
              let loadLocalBranchNames,
              let loadRemoteBranches else {
            await setIssueReferences(initialState.issueReferences)
            return
        }

        await performProjectAutocompleteLoad(
            namesAndEmails: namesAndEmails,
            loadLocalBranchNames: loadLocalBranchNames,
            loadRemoteBranches: loadRemoteBranches,
            setAutocomplete: { state in
                await setUserMentions(state.userMentions)
                await setIssueReferences(state.issueReferences)
            }
        )
    }

    public static func performProjectAutocompleteLoadCommand<Project, Branch>(
        namesAndEmails: [(name: String, email: String)],
        project: Project?,
        loadLocalBranches: @escaping (ProjectAutocompleteLoadRequest<Project>) async throws -> [Branch],
        localBranchName: @escaping (Branch) -> String,
        loadRemoteBranches: @escaping (ProjectAutocompleteLoadRequest<Project>) async throws -> [String],
        setAutocomplete: (AutocompleteState) async -> Void
    ) async {
        let initialState = autocompleteInitialState(namesAndEmails: namesAndEmails)
        await setAutocomplete(initialState)

        guard let project else {
            return
        }

        let request = ProjectAutocompleteLoadRequest(project: project)
        await performProjectAutocompleteLoad(
            namesAndEmails: namesAndEmails,
            loadLocalBranchNames: {
                try await loadLocalBranches(request).map(localBranchName)
            },
            loadRemoteBranches: {
                try await loadRemoteBranches(request)
            },
            setAutocomplete: setAutocomplete
        )
    }

    public static func performProjectAutocompleteLoadCommand<Project, Branch>(
        namesAndEmails: [(name: String, email: String)],
        project: Project?,
        handlers: ProjectAutocompleteLoadHandlers<Project, Branch>,
        setAutocomplete: (AutocompleteState) async -> Void
    ) async {
        await performProjectAutocompleteLoadCommand(
            namesAndEmails: namesAndEmails,
            project: project,
            loadLocalBranches: { request in
                try await handlers.loadLocalBranches(request.project)
            },
            localBranchName: handlers.localBranchName,
            loadRemoteBranches: { request in
                try await handlers.loadRemoteBranches(request.project)
            },
            setAutocomplete: setAutocomplete
        )
    }

    public static func performProjectAutocompleteLoadOperation<Project, Branch>(
        namesAndEmails: [(name: String, email: String)],
        project: Project?,
        loadLocalBranches: @escaping (Project) async throws -> [Branch],
        localBranchName: @escaping (Branch) -> String,
        loadRemoteBranches: @escaping (Project) async throws -> [String],
        setAutocomplete: (AutocompleteState) async -> Void
    ) async {
        let initialState = autocompleteInitialState(namesAndEmails: namesAndEmails)
        await setAutocomplete(initialState)

        guard let project else {
            return
        }

        await performProjectAutocompleteLoad(
            namesAndEmails: namesAndEmails,
            loadLocalBranchNames: {
                try await loadLocalBranches(project).map(localBranchName)
            },
            loadRemoteBranches: {
                try await loadRemoteBranches(project)
            },
            setAutocomplete: setAutocomplete
        )
    }

    public static func performProjectAutocompleteLoadOperation<Project, Branch>(
        namesAndEmails: [(name: String, email: String)],
        project: Project?,
        loadLocalBranches: @escaping (Project) async throws -> [Branch],
        localBranchName: @escaping (Branch) -> String,
        loadRemoteBranches: @escaping (Project) async throws -> [String],
        setUserMentions: ([String]) async -> Void,
        setIssueReferences: ([String]) async -> Void
    ) async {
        await performAutocompleteLoadOperation(
            namesAndEmails: namesAndEmails,
            hasProject: project != nil,
            loadLocalBranchNames: project.map { project in
                {
                    try await loadLocalBranches(project).map(localBranchName)
                }
            },
            loadRemoteBranches: project.map { project in
                {
                    try await loadRemoteBranches(project)
                }
            },
            setUserMentions: setUserMentions,
            setIssueReferences: setIssueReferences
        )
    }

    public static func shouldReplaceSubjectOnStyleChange(
        currentSubject: String,
        category: CommitCategory
    ) -> Bool {
        if currentSubject.isEmpty {
            return true
        }

        return CommitStyle.allCases.contains { style in
            currentSubject == defaultMessage(for: category, style: style)
        }
    }

    public static func activityStatus(_ activity: Activity) -> String {
        switch activity {
        case .addingFiles:
            return CommitLocalization.string("添加文件中…")
        case .committing:
            return CommitLocalization.string("提交中…")
        case .pushing:
            return CommitLocalization.string("推送中…")
        }
    }

    public static func activityStatus(for step: SubmitStep) -> String {
        switch step {
        case .addAllFiles:
            return activityStatus(.addingFiles)
        case .commit:
            return activityStatus(.committing)
        case .push:
            return activityStatus(.pushing)
        }
    }

    public static func submitFailureLogMessage(errorDescription: String) -> String {
        "❌ 提交或推送失败: \(errorDescription)"
    }

    public static func performSubmitStep(
        _ step: SubmitStep,
        onAddAllFiles: () async throws -> Void,
        onCommit: () async throws -> Void,
        onPush: () async throws -> Void
    ) async throws {
        switch step {
        case .addAllFiles:
            try await onAddAllFiles()
        case .commit:
            try await onCommit()
        case .push:
            try await onPush()
        }
    }

    public static func performSubmitExecutionState(
        _ state: SubmitExecutionState,
        setStatus: (String) async -> Void,
        onAddAllFiles: () async throws -> Void,
        onCommit: () async throws -> Void,
        onPush: () async throws -> Void
    ) async throws {
        for step in state.steps {
            await setStatus(activityStatus(for: step))
            try await performSubmitStep(
                step,
                onAddAllFiles: onAddAllFiles,
                onCommit: onCommit,
                onPush: onPush
            )
        }
    }

    public static func performSubmitOperation(
        message: String,
        commitOnly: Bool,
        hasStagedChanges: () async throws -> Bool,
        setStatus: (String) async -> Void,
        onAddAllFiles: () async throws -> Void,
        onCommit: (SubmitPlan) async throws -> Void,
        onPush: () async throws -> Void,
        showSuccessMessage: (String) async -> Void,
        handleFailure: (Error) async -> Void,
        clearStatus: () async -> Void
    ) async {
        var clearsActivityStatusAfterCompletion = true
        do {
            let executionState = try await submitExecutionState(
                message: message,
                commitOnly: commitOnly,
                hasStagedChanges: hasStagedChanges
            )

            try await performSubmitExecutionState(
                executionState,
                setStatus: setStatus,
                onAddAllFiles: onAddAllFiles,
                onCommit: {
                    try await onCommit(executionState.plan)
                },
                onPush: onPush
            )

            let successState = submitSuccessState(commitOnly: commitOnly)
            clearsActivityStatusAfterCompletion = successState.clearsActivityStatus
            await showSuccessMessage(successState.message)
        } catch {
            await handleFailure(error)
        }

        if clearsActivityStatusAfterCompletion {
            await clearStatus()
        }
    }

    public static func performSubmitOperation(
        request: SubmitRequest,
        handlers: SubmitOperationHandlers,
        setStatus: (String) async -> Void,
        showSuccessMessage: (String) async -> Void,
        handleFailure: (Error) async -> Void,
        clearStatus: () async -> Void
    ) async {
        await performSubmitOperation(
            message: request.message,
            commitOnly: request.commitOnly,
            hasStagedChanges: handlers.hasStagedChanges,
            setStatus: setStatus,
            onAddAllFiles: handlers.addAllFiles,
            onCommit: handlers.commit,
            onPush: handlers.push,
            showSuccessMessage: showSuccessMessage,
            handleFailure: handleFailure,
            clearStatus: clearStatus
        )
    }

    public static func submitOperationHandlers<Project>(
        for project: Project,
        handlers: ProjectSubmitOperationHandlers<Project>
    ) -> SubmitOperationHandlers {
        SubmitOperationHandlers(
            hasStagedChanges: {
                try await handlers.hasStagedChanges(project)
            },
            addAllFiles: {
                try await handlers.addAllFiles(project)
            },
            commit: { plan in
                try await handlers.commit(project, plan)
            },
            push: {
                try await handlers.push(project)
            }
        )
    }

    public static func performSubmitOperation<Project>(
        command: ProjectSubmitRequest<Project>,
        handlers: ProjectSubmitOperationHandlers<Project>,
        setStatus: (String) async -> Void,
        showSuccessMessage: (String) async -> Void,
        handleFailure: (Error) async -> Void,
        clearStatus: () async -> Void
    ) async {
        await performSubmitOperation(
            request: command.request,
            handlers: submitOperationHandlers(for: command.project, handlers: handlers),
            setStatus: setStatus,
            showSuccessMessage: showSuccessMessage,
            handleFailure: handleFailure,
            clearStatus: clearStatus
        )
    }

    public static func successMessage(commitOnly: Bool) -> String {
        if commitOnly {
            return CommitLocalization.string("提交成功")
        }

        return CommitLocalization.string("提交并推送成功")
    }

    public static func submitSuccessState(commitOnly: Bool) -> SubmitSuccessState {
        SubmitSuccessState(
            message: successMessage(commitOnly: commitOnly),
            clearsActivityStatus: true
        )
    }

    private static func lowercasedFirst(_ string: String) -> String {
        guard let first = string.first else {
            return string
        }

        return first.lowercased() + string.dropFirst()
    }
}
