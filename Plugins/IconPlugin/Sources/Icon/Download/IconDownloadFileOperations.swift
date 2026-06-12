import Foundation

enum IconDownloadFileOperations {
    static func createDirectory(_ url: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }.value
    }
}
