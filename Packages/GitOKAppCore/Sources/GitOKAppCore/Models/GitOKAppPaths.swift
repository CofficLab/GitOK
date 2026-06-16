import Foundation

public enum GitOKAppPaths {
    public static func getAppName() -> String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "GitOK"
    }

    public static func getCurrentAppSupportDir() -> URL {
        let fileManager = FileManager.default
        let baseDirectory =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
        let appDirectory = baseDirectory.appendingPathComponent(getAppName(), isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory
    }
}
