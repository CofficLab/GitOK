import Foundation

enum GitIgnoreDocument {
    static func fileURL(for projectURL: URL) -> URL {
        projectURL.appendingPathComponent(".gitignore")
    }

    static func exists(in projectURL: URL) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: projectURL).path)
    }

    static func existsAsync(in projectURL: URL) async -> Bool {
        await Task.detached(priority: .utility) {
            exists(in: projectURL)
        }.value
    }

    static func read(in projectURL: URL) throws -> String {
        try String(contentsOf: fileURL(for: projectURL), encoding: .utf8)
    }

    static func readAsync(in projectURL: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try read(in: projectURL)
        }.value
    }

    static func write(_ content: String, in projectURL: URL) throws {
        try content.write(to: fileURL(for: projectURL), atomically: true, encoding: .utf8)
    }

    static func writeAsync(_ content: String, in projectURL: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            try write(content, in: projectURL)
        }.value
    }
}
