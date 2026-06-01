@_exported import LibGit2Swift

public enum GitRuntime {
    public static func initialize() {
        LibGit2.initialize()
    }

    public static func versionString() -> String {
        LibGit2.versionString()
    }
}
