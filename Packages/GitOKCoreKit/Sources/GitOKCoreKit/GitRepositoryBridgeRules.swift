public enum GitRepositoryBridgeRules {
    public static let projectSelectionReason = "RepositoryImport"

    public static func projectExists(
        urlPath: String,
        exists: (String) -> Bool
    ) -> Bool {
        exists(urlPath)
    }

    public static func projectExists<URLValue>(
        url: URLValue,
        path: (URLValue) -> String,
        exists: (String) -> Bool
    ) -> Bool {
        projectExists(urlPath: path(url), exists: exists)
    }

    public static func performRepositoryImportCompletion<Project>(
        addProject: () -> Project?,
        selectProject: (Project, String) -> Void
    ) -> Bool {
        guard let project = addProject() else {
            return false
        }

        selectProject(project, projectSelectionReason)
        return true
    }

    public static func performRepositoryImportSuccessMessage(
        _ message: String,
        showInfo: (String) -> Void
    ) {
        showInfo(message)
    }
}
