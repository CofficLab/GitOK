import Foundation

enum BannerStorageRules {
    static func bannerDirectoryURL(projectPath: String, storagePath: String) -> URL {
        URL(fileURLWithPath: projectPath).appendingPathComponent(storagePath)
    }

    static func newBannerFileName(now: Date) -> String {
        "banner_\(Int(now.timeIntervalSince1970)).json"
    }

    static func relativeProjectPath(for absoluteURL: URL, projectPath: String) -> String {
        absoluteURL.relativePath.replacingOccurrences(of: projectPath, with: "")
    }
}
