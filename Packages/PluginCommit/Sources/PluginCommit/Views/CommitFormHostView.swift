import ProjectSupportKit
import SwiftUI

public enum CommitFormHostEvent {
    case showInfoMessage(String)
    case showError(Error)
    case submitFailure(Error)
}

public struct CommitFormHostView<Project, Branch, UserContent: View>: View {
    private let project: Project?
    private let projectStyle: (Project) -> CommitStyle
    private let saveProjectStyle: (Project, CommitStyle) -> Void
    private let loadCoAuthors: () -> [CoAuthor]
    private let loadLocalBranches: (Project) async throws -> [Branch]
    private let localBranchName: (Branch) -> String
    private let loadRemoteBranches: (Project) async throws -> [String]
    private let hasStagedChanges: (Project) async throws -> Bool
    private let addAllFiles: (Project) async throws -> Void
    private let commit: (Project, CommitMessageRules.SubmitPlan) async throws -> Void
    private let push: (Project) async throws -> Void
    private let setActivityStatus: (String?) -> Void
    private let eventHandler: (CommitFormHostEvent) -> Void
    private let commitResetToken: Int
    private let autocompleteRefreshToken: Int
    private let userContent: () -> UserContent

    @State private var text = ""
    @State private var category: CommitCategory = .Chore
    @State private var selectedCoAuthors: [CoAuthor] = []
    @State private var commitStyle: CommitStyle = .emoji
    @State private var issueReferences: [String] = []
    @State private var userMentions: [String] = []

    public init(
        project: Project?,
        projectStyle: @escaping (Project) -> CommitStyle,
        saveProjectStyle: @escaping (Project, CommitStyle) -> Void,
        loadCoAuthors: @escaping () -> [CoAuthor],
        loadLocalBranches: @escaping (Project) async throws -> [Branch],
        localBranchName: @escaping (Branch) -> String,
        loadRemoteBranches: @escaping (Project) async throws -> [String],
        hasStagedChanges: @escaping (Project) async throws -> Bool,
        addAllFiles: @escaping (Project) async throws -> Void,
        commit: @escaping (Project, CommitMessageRules.SubmitPlan) async throws -> Void,
        push: @escaping (Project) async throws -> Void,
        setActivityStatus: @escaping (String?) -> Void,
        eventHandler: @escaping (CommitFormHostEvent) -> Void = { _ in },
        commitResetToken: Int = 0,
        autocompleteRefreshToken: Int = 0,
        @ViewBuilder userContent: @escaping () -> UserContent
    ) {
        self.project = project
        self.projectStyle = projectStyle
        self.saveProjectStyle = saveProjectStyle
        self.loadCoAuthors = loadCoAuthors
        self.loadLocalBranches = loadLocalBranches
        self.localBranchName = localBranchName
        self.loadRemoteBranches = loadRemoteBranches
        self.hasStagedChanges = hasStagedChanges
        self.addAllFiles = addAllFiles
        self.commit = commit
        self.push = push
        self.setActivityStatus = setActivityStatus
        self.eventHandler = eventHandler
        self.commitResetToken = commitResetToken
        self.autocompleteRefreshToken = autocompleteRefreshToken
        self.userContent = userContent
    }

    public var body: some View {
        CommitFormLayout(
            text: $text,
            category: $category,
            selectedCoAuthors: $selectedCoAuthors,
            commitStyle: $commitStyle,
            issueReferences: issueReferences,
            userMentions: userMentions,
            onCommitStyleSelectionChange: saveCommitStyle,
            onCommitOnly: {
                performCommitAndPush(commitOnly: true)
            },
            onCommitAndPush: {
                performCommitAndPush(commitOnly: false)
            },
            userContent: userContent
        )
        .onChange(of: category, onCategoryDidChange)
        .onChange(of: commitStyle, onCommitStyleDidChange)
        .onChange(of: commitResetToken) {
            onProjectDidCommit()
        }
        .onChange(of: autocompleteRefreshToken) {
            refreshAutocompleteCandidates()
        }
        .onAppear(perform: onAppear)
    }
}

private extension CommitFormHostView {
    var commitMessage: String {
        CommitMessageRules.formattedMessage(
            subject: text,
            category: category,
            style: commitStyle,
            coAuthors: selectedCoAuthors
        )
    }

    func performCommitAndPush(commitOnly: Bool) {
        CommitMessageRules.performRequiredProjectSubmitCommand(
            project: project,
            message: commitMessage,
            commitOnly: commitOnly,
            perform: performCommitAndPush
        )
    }

    func performCommitAndPush(_ command: CommitMessageRules.ProjectSubmitRequest<Project>) {
        // Extract project value before Task to avoid Sendable crossing
        nonisolated(unsafe) let project = command.project

        Task(priority: .userInitiated) { @MainActor in
            var clearsActivityStatusAfterCompletion = true

            do {
                let executionState = try await CommitMessageRules.submitExecutionState(
                    message: command.request.message,
                    hasStagedChanges: hasStagedChanges(project),
                    commitOnly: command.request.commitOnly
                )

                for step in executionState.steps {
                    setActivityStatus(CommitMessageRules.activityStatus(for: step))
                    switch step {
                    case .addAllFiles:
                        try await addAllFiles(project)
                    case .commit:
                        try await commit(project, executionState.plan)
                    case .push:
                        try await push(project)
                    }
                }

                let successState = CommitMessageRules.submitSuccessState(commitOnly: command.request.commitOnly)
                clearsActivityStatusAfterCompletion = successState.clearsActivityStatus
                eventHandler(.showInfoMessage(successState.message))
            } catch {
                eventHandler(.submitFailure(error))
                eventHandler(.showError(error))
            }

            if clearsActivityStatusAfterCompletion {
                setActivityStatus(nil)
            }
        }
    }

    @MainActor
    func setText(_ newValue: String) {
        text = newValue
    }

    @MainActor
    func setCommitStyle(_ newValue: CommitStyle) {
        commitStyle = newValue
    }

    @MainActor
    func saveCommitStyle(_ newValue: CommitStyle) {
        CommitMessageRules.performProjectStyleSaveCommand(project: project, style: newValue) { request in
            saveProjectStyle(request.project, request.style)
        }
    }

    func onProjectDidCommit() {
        CommitMessageRules.performProjectDidCommit(
            category: category,
            style: commitStyle,
            setSubject: setText
        )
    }

    func onCategoryDidChange() {
        CommitMessageRules.performCategoryDidChange(
            category: category,
            style: commitStyle,
            setSubject: setText
        )
    }

    func onCommitStyleDidChange() {
        CommitMessageRules.performSubjectAfterStyleChange(
            currentSubject: text,
            category: category,
            newStyle: commitStyle,
            setSubject: setText
        )
    }

    func onAppear() {
        let appearanceState = CommitMessageRules.formAppearanceState(
            category: category,
            currentStyle: commitStyle,
            project: project,
            projectStyle: projectStyle
        )
        CommitMessageRules.performFormAppear(
            appearanceState: appearanceState,
            setSubject: setText,
            setStyle: setCommitStyle,
            loadAutocomplete: loadAutocompleteCandidates
        )
    }

    func refreshAutocompleteCandidates() {
        CommitMessageRules.performAutocompleteRefreshTrigger(
            loadAutocomplete: loadAutocompleteCandidates
        )
    }

    func loadAutocompleteCandidates() {
        let namesAndEmails = CommitMessageRules.autocompleteNameEmailPairs(
            coAuthors: loadCoAuthors()
        )
        guard let project else {
            Task(priority: .utility) { @MainActor in
                CommitMessageRules.performAutocompleteState(
                    CommitMessageRules.autocompleteInitialState(namesAndEmails: namesAndEmails),
                    setUserMentions: { userMentions = $0 },
                    setIssueReferences: { issueReferences = $0 }
                )
            }
            return
        }
        nonisolated(unsafe) let _project = project

        Task(priority: .utility) { @MainActor in
            CommitMessageRules.performAutocompleteState(
                CommitMessageRules.autocompleteInitialState(namesAndEmails: namesAndEmails),
                setUserMentions: { userMentions = $0 },
                setIssueReferences: { issueReferences = $0 }
            )

            let localBranches = (try? await loadLocalBranches(_project)) ?? []
            let remoteBranches = (try? await loadRemoteBranches(_project)) ?? []
            let state = CommitMessageRules.autocompleteState(
                namesAndEmails: namesAndEmails,
                localBranches: localBranches,
                localBranchName: localBranchName,
                remoteBranches: remoteBranches
            )
            CommitMessageRules.performAutocompleteState(
                state,
                setUserMentions: { userMentions = $0 },
                setIssueReferences: { issueReferences = $0 }
            )
        }
    }
}
