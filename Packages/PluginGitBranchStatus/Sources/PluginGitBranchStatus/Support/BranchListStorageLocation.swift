import Foundation

/// 分支选择器自有数据目录与仓库键的统一来源。
enum BranchListStorageLocation {
    /// `StorageProviding` 未注入时的回退目录。
    static func defaultDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let bundleID = Bundle.main.bundleIdentifier ?? "com.coffic.gitok"
        return appSupport
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("com.coffic.gitok.plugin.git-branch-status", isDirectory: true)
    }

    static func repositoryKey(for repository: URL) -> String {
        repository
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }
}