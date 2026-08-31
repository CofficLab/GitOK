import Foundation

public enum CommitRowLoadRules {
    public struct ProjectTagLoadHandlers<Project> {
        public let loadTags: (Project, String) async throws -> [String]

        public init(loadTags: @escaping (Project, String) async throws -> [String]) {
            self.loadTags = loadTags
        }
    }

    public static func performAppear(loadInitialState: () -> Void) {
        loadInitialState()
    }

    public static func performInitialLoad(
        author: String,
        message: String,
        loadTags: (() async throws -> [String])?,
        logAvatarStart: () async -> Void,
        logAvatarCoAuthors: (Int) async -> Void,
        setAvatarUsers: ([AvatarUser]) async -> Void,
        setTag: (String) async -> Void
    ) async {
        await CommitAuthorParser.performAvatarUsersLoad(
            author: author,
            message: message,
            logStart: logAvatarStart,
            logCoAuthors: logAvatarCoAuthors,
            setUsers: setAvatarUsers
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            loadTags: loadTags,
            setTag: setTag
        )
    }

    public static func performInitialLoad(
        author: String,
        message: String,
        commitHash: String,
        loadTags: ((String) async throws -> [String])?,
        logAvatarStart: () async -> Void,
        logAvatarCoAuthors: (Int) async -> Void,
        setAvatarUsers: ([AvatarUser]) async -> Void,
        setTag: (String) async -> Void
    ) async {
        await CommitAuthorParser.performAvatarUsersLoad(
            author: author,
            message: message,
            logStart: logAvatarStart,
            logCoAuthors: logAvatarCoAuthors,
            setUsers: setAvatarUsers
        )
        await CommitTagRules.performOptionalVisibleTagLoad(
            commitHash: commitHash,
            loadTags: loadTags,
            setTag: setTag
        )
    }

    public static func performInitialLoad<Project>(
        author: String,
        message: String,
        commitHash: String,
        project: Project?,
        loadTags: @escaping (Project, String) async throws -> [String],
        logAvatarStart: () async -> Void,
        logAvatarCoAuthors: (Int) async -> Void,
        setAvatarUsers: ([AvatarUser]) async -> Void,
        setTag: (String) async -> Void
    ) async {
        await performInitialLoad(
            author: author,
            message: message,
            commitHash: commitHash,
            loadTags: project.map { project in
                { hash in
                    try await loadTags(project, hash)
                }
            },
            logAvatarStart: logAvatarStart,
            logAvatarCoAuthors: logAvatarCoAuthors,
            setAvatarUsers: setAvatarUsers,
            setTag: setTag
        )
    }

    public static func performInitialLoad<Project>(
        author: String,
        message: String,
        commitHash: String,
        project: Project?,
        handlers: ProjectTagLoadHandlers<Project>,
        logAvatarStart: () async -> Void,
        logAvatarCoAuthors: (Int) async -> Void,
        setAvatarUsers: ([AvatarUser]) async -> Void,
        setTag: (String) async -> Void
    ) async {
        await performInitialLoad(
            author: author,
            message: message,
            commitHash: commitHash,
            project: project,
            loadTags: handlers.loadTags,
            logAvatarStart: logAvatarStart,
            logAvatarCoAuthors: logAvatarCoAuthors,
            setAvatarUsers: setAvatarUsers,
            setTag: setTag
        )
    }
}
