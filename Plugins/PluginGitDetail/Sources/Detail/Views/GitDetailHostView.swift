import SwiftUI

public struct GitDetailHostView<Project, Commit, CommitInfoContent: View, FileListContent: View, FileDetailContent: View, EmptyContent: View, NotGitContent: View, CommitFormContent: View>: View {
    private let project: Project?
    private let selectedCommit: Commit?
    private let isClean: Bool
    private let projectIsGitRepository: (Project) -> Bool
    private let commitMessage: (Commit) -> String
    private let commitBodyText: (Commit) -> String
    private let commitAuthor: (Commit) -> String
    private let commitDate: (Commit) -> Date
    private let commitHash: (Commit) -> String
    private let projectChangeToken: Int
    private let appWillBecomeActiveToken: Int
    private let commitInfoContent: (GitDetailPresentationRules.CommitInfoPresentationState<Date>) -> CommitInfoContent
    private let fileListContent: () -> FileListContent
    private let fileDetailContent: () -> FileDetailContent
    private let emptyContent: () -> EmptyContent
    private let notGitContent: () -> NotGitContent
    private let commitFormContent: () -> CommitFormContent

    @State private var isGitProject = false

    public init(
        project: Project?,
        selectedCommit: Commit?,
        isClean: Bool,
        projectIsGitRepository: @escaping (Project) -> Bool,
        commitMessage: @escaping (Commit) -> String,
        commitBodyText: @escaping (Commit) -> String,
        commitAuthor: @escaping (Commit) -> String,
        commitDate: @escaping (Commit) -> Date,
        commitHash: @escaping (Commit) -> String,
        projectChangeToken: Int = 0,
        appWillBecomeActiveToken: Int = 0,
        @ViewBuilder commitInfoContent: @escaping (GitDetailPresentationRules.CommitInfoPresentationState<Date>) -> CommitInfoContent,
        @ViewBuilder fileListContent: @escaping () -> FileListContent,
        @ViewBuilder fileDetailContent: @escaping () -> FileDetailContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder notGitContent: @escaping () -> NotGitContent,
        @ViewBuilder commitFormContent: @escaping () -> CommitFormContent
    ) {
        self.project = project
        self.selectedCommit = selectedCommit
        self.isClean = isClean
        self.projectIsGitRepository = projectIsGitRepository
        self.commitMessage = commitMessage
        self.commitBodyText = commitBodyText
        self.commitAuthor = commitAuthor
        self.commitDate = commitDate
        self.commitHash = commitHash
        self.projectChangeToken = projectChangeToken
        self.appWillBecomeActiveToken = appWillBecomeActiveToken
        self.commitInfoContent = commitInfoContent
        self.fileListContent = fileListContent
        self.fileDetailContent = fileDetailContent
        self.emptyContent = emptyContent
        self.notGitContent = notGitContent
        self.commitFormContent = commitFormContent
    }

    public var body: some View {
        GitDetailShellView(
            presentationState: presentationState,
            commitInfoContent: {
                commitInfoView()
            },
            fileListContent: fileListContent,
            fileDetailContent: fileDetailContent,
            emptyContent: emptyContent,
            notGitContent: notGitContent,
            commitFormContent: commitFormContent
        )
        .onAppear(perform: onAppear)
        .onChange(of: projectChangeToken) {
            onProjectChange()
        }
        .onChange(of: appWillBecomeActiveToken) {
            onAppWillBecomeActive()
        }
    }
}

private extension GitDetailHostView {
    var presentationState: GitDetailPresentationRules.PresentationState {
        GitDetailPresentationRules.presentationState(
            project: project,
            isGitProject: isGitProject,
            selectedCommit: selectedCommit,
            isClean: isClean
        )
    }

    @ViewBuilder
    func commitInfoView() -> some View {
        if let state = GitDetailPresentationRules.commitInfoPresentationState(
            selectedCommit: selectedCommit,
            message: commitMessage,
            bodyText: commitBodyText,
            author: commitAuthor,
            date: commitDate,
            hash: commitHash
        ) {
            commitInfoContent(state)
        }
    }

    func updateIsGitProject() {
        GitDetailPresentationRules.performGitProjectStateCommand(
            project: project,
            projectIsGitRepository: { projectIsGitRepository($0.project) },
            setIsGitProject: { isGitProject = $0 }
        )
    }

    func onAppWillBecomeActive() {
        GitDetailPresentationRules.performApplicationWillBecomeActive(
            updateGitProjectState: updateIsGitProject
        )
    }

    func onAppear() {
        GitDetailPresentationRules.performAppear(
            updateGitProjectState: updateIsGitProject
        )
    }

    func onProjectChange() {
        GitDetailPresentationRules.performProjectChange(
            updateGitProjectState: updateIsGitProject
        )
    }
}
