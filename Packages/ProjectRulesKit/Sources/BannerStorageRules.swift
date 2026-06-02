import Foundation

public enum BannerStorageRules {
    public static func bannerDirectoryURL(projectPath: String, storagePath: String) -> URL {
        URL(fileURLWithPath: projectPath).appendingPathComponent(storagePath)
    }

    public static func newBannerFileName(now: Date) -> String {
        "banner_\(Int(now.timeIntervalSince1970)).json"
    }

    public static func relativeProjectPath(for absoluteURL: URL, projectPath: String) -> String {
        absoluteURL.relativePath.replacingOccurrences(of: projectPath, with: "")
    }
}
