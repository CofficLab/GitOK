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

fileprivate enum CommitFormBackgroundLoader {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
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
        let projectTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: command.project)
        let hasStagedChangesTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: hasStagedChanges)
        let addAllFilesTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: addAllFiles)
        let commitTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: commit)
        let pushTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: push)
        let setActivityStatusTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: setActivityStatus)
        let eventHandlerTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: eventHandler)
        let message = command.request.message
        let commitOnly = command.request.commitOnly

        Task.detached(priority: .userInitiated) {
            var shouldClearActivityStatus = true

            do {
                let executionState = try await CommitMessageRules.submitExecutionState(
                    message: message,
                    commitOnly: commitOnly,
                    hasStagedChanges: {
                        try await hasStagedChangesTransfer.value(projectTransfer.value)
                    }
                )

                for step in executionState.steps {
                    await MainActor.run {
                        setActivityStatusTransfer.value(CommitMessageRules.activityStatus(for: step))
                    }
                    switch step {
                    case .addAllFiles:
                        try await addAllFilesTransfer.value(projectTransfer.value)
                    case .commit:
                        try await commitTransfer.value(projectTransfer.value, executionState.plan)
                    case .push:
                        try await pushTransfer.value(projectTransfer.value)
                    }
                }

                let successState = CommitMessageRules.submitSuccessState(commitOnly: commitOnly)
                shouldClearActivityStatus = successState.clearsActivityStatus
                await MainActor.run {
                    eventHandlerTransfer.value(.showInfoMessage(successState.message))
                }
            } catch {
                await MainActor.run {
                    eventHandlerTransfer.value(.submitFailure(error))
                    eventHandlerTransfer.value(.showError(error))
                }
            }

            if shouldClearActivityStatus {
                await MainActor.run {
                    setActivityStatusTransfer.value(nil)
                }
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
        let loadCoAuthorsTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: loadCoAuthors)
        let loadLocalBranchesTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: loadLocalBranches)
        let localBranchNameTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: localBranchName)
        let loadRemoteBranchesTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: loadRemoteBranches)
        guard let project else {
            Task.detached(priority: .utility) {
                let namesAndEmails = CommitMessageRules.autocompleteNameEmailPairs(
                    coAuthors: loadCoAuthorsTransfer.value()
                )
                let state = CommitMessageRules.autocompleteInitialState(namesAndEmails: namesAndEmails)
                await MainActor.run {
                    CommitMessageRules.performAutocompleteState(
                        state,
                        setUserMentions: { userMentions = $0 },
                        setIssueReferences: { issueReferences = $0 }
                    )
                }
            }
            return
        }
        let projectTransfer = CommitFormBackgroundLoader.UnsafeTransfer(value: project)

        Task.detached(priority: .utility) {
            let namesAndEmails = CommitMessageRules.autocompleteNameEmailPairs(
                coAuthors: loadCoAuthorsTransfer.value()
            )
            let initialState = CommitMessageRules.autocompleteInitialState(namesAndEmails: namesAndEmails)
            await MainActor.run {
                CommitMessageRules.performAutocompleteState(
                    initialState,
                    setUserMentions: { userMentions = $0 },
                    setIssueReferences: { issueReferences = $0 }
                )
            }

            let localBranches = (try? await loadLocalBranchesTransfer.value(projectTransfer.value)) ?? []
            let remoteBranches = (try? await loadRemoteBranchesTransfer.value(projectTransfer.value)) ?? []
            let state = CommitMessageRules.autocompleteState(
                namesAndEmails: namesAndEmails,
                localBranches: localBranches,
                localBranchName: localBranchNameTransfer.value,
                remoteBranches: remoteBranches
            )
            await MainActor.run {
                CommitMessageRules.performAutocompleteState(
                    state,
                    setUserMentions: { userMentions = $0 },
                    setIssueReferences: { issueReferences = $0 }
                )
            }
        }
    }
}
