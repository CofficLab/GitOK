import Foundation

enum GitIgnoreDocument {
    static func fileURL(for projectURL: URL) -> URL {
        projectURL.appendingPathComponent(".gitignore")
    }

    static func exists(in projectURL: URL) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: projectURL).path)
    }

    static func read(in projectURL: URL) throws -> String {
        try String(contentsOf: fileURL(for: projectURL), encoding: .utf8)
    }

    static func write(_ content: String, in projectURL: URL) throws {
        try content.write(to: fileURL(for: projectURL), atomically: true, encoding: .utf8)
    }
}
