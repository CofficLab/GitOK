public enum GitDetailPresentationRules {
    public enum RootContentMode: Equatable, Sendable {
        case hidden
        case notGitProject
        case gitProject
    }

    public enum HeaderContentMode: Equatable, Sendable {
        case none
        case commitInfo
        case commitForm
    }

    public struct ContentVisibility: Equatable, Sendable {
        public let showsHeader: Bool
        public let showsFileSplit: Bool

        public init(showsHeader: Bool, showsFileSplit: Bool) {
            self.showsHeader = showsHeader
            self.showsFileSplit = showsFileSplit
        }
    }

    public struct PresentationState: Equatable, Sendable {
        public let rootContentMode: RootContentMode
        public let headerContentMode: HeaderContentMode
        public let contentVisibility: ContentVisibility

        public init(
            rootContentMode: RootContentMode,
            headerContentMode: HeaderContentMode,
            contentVisibility: ContentVisibility
        ) {
            self.rootContentMode = rootContentMode
            self.headerContentMode = headerContentMode
            self.contentVisibility = contentVisibility
        }
    }

    public struct CommitInfoPresentationState<DateValue: Equatable & Sendable>: Equatable, Sendable {
        public let message: String
        public let bodyText: String
        public let author: String
        public let date: DateValue
        public let hash: String

        public init(message: String, bodyText: String, author: String, date: DateValue, hash: String) {
            self.message = message
            self.bodyText = bodyText
            self.author = author
            self.date = date
            self.hash = hash
        }
    }

    public struct ProjectGitStateRequest<Project> {
        public let project: Project

        public init(project: Project) {
            self.project = project
        }
    }

    public static func rootContentMode(hasProject: Bool, isGitProject: Bool) -> RootContentMode {
        guard hasProject else {
            return .hidden
        }

        return isGitProject ? .gitProject : .notGitProject
    }

    public static func gitProjectState(hasProject: Bool, projectIsGitRepository: Bool) -> Bool {
        hasProject && projectIsGitRepository
    }

    public static func gitProjectState<Project>(project: Project?, projectIsGitRepository: Bool) -> Bool {
        gitProjectState(hasProject: project != nil, projectIsGitRepository: projectIsGitRepository)
    }

    public static func performGitProjectState<Project>(
        project: Project?,
        projectIsGitRepository: Bool,
        setIsGitProject: (Bool) -> Void
    ) {
        setIsGitProject(gitProjectState(
            project: project,
            projectIsGitRepository: projectIsGitRepository
        ))
    }

    public static func performGitProjectState<Project>(
        project: Project?,
        projectIsGitRepository: (Project) -> Bool,
        setIsGitProject: (Bool) -> Void
    ) {
        guard let project else {
            setIsGitProject(false)
            return
        }

        performGitProjectState(
            project: project,
            projectIsGitRepository: projectIsGitRepository(project),
            setIsGitProject: setIsGitProject
        )
    }

    public static func performGitProjectStateCommand<Project>(
        project: Project?,
        projectIsGitRepository: (ProjectGitStateRequest<Project>) -> Bool,
        setIsGitProject: (Bool) -> Void
    ) {
        performGitProjectState(
            project: project,
            projectIsGitRepository: { project in
                projectIsGitRepository(ProjectGitStateRequest(project: project))
            },
            setIsGitProject: setIsGitProject
        )
    }

    public static func performAppear(updateGitProjectState: () -> Void) {
        updateGitProjectState()
    }

    public static func performProjectChange(updateGitProjectState: () -> Void) {
        updateGitProjectState()
    }

    public static func performApplicationWillBecomeActive(updateGitProjectState: () -> Void) {
        updateGitProjectState()
    }

    public static func headerContentMode(hasSelectedCommit: Bool, isClean: Bool) -> HeaderContentMode {
        if hasSelectedCommit {
            return .commitInfo
        }

        if isClean == false {
            return .commitForm
        }

        return .none
    }

    public static func contentVisibility(hasSelectedCommit: Bool, isClean: Bool) -> ContentVisibility {
        ContentVisibility(
            showsHeader: hasSelectedCommit || isClean == false,
            showsFileSplit: isClean == false || hasSelectedCommit
        )
    }

    public static func presentationState(
        hasProject: Bool,
        isGitProject: Bool,
        hasSelectedCommit: Bool,
        isClean: Bool
    ) -> PresentationState {
        PresentationState(
            rootContentMode: rootContentMode(
                hasProject: hasProject,
                isGitProject: isGitProject
            ),
            headerContentMode: headerContentMode(
                hasSelectedCommit: hasSelectedCommit,
                isClean: isClean
            ),
            contentVisibility: contentVisibility(
                hasSelectedCommit: hasSelectedCommit,
                isClean: isClean
            )
        )
    }

    public static func presentationState<Project, Commit>(
        project: Project?,
        isGitProject: Bool,
        selectedCommit: Commit?,
        isClean: Bool
    ) -> PresentationState {
        presentationState(
            hasProject: project != nil,
            isGitProject: isGitProject,
            hasSelectedCommit: selectedCommit != nil,
            isClean: isClean
        )
    }

    public static func commitInfoPresentationState<Commit, DateValue: Equatable & Sendable>(
        selectedCommit: Commit?,
        message: (Commit) -> String,
        bodyText: (Commit) -> String,
        author: (Commit) -> String,
        date: (Commit) -> DateValue,
        hash: (Commit) -> String
    ) -> CommitInfoPresentationState<DateValue>? {
        guard let selectedCommit else {
            return nil
        }

        return CommitInfoPresentationState(
            message: message(selectedCommit),
            bodyText: bodyText(selectedCommit),
            author: author(selectedCommit),
            date: date(selectedCommit),
            hash: hash(selectedCommit)
        )
    }
}
