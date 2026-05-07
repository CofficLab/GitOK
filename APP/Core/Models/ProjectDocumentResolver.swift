import Foundation

enum ProjectDocumentResolver {
    static let readmeCandidates = ["README.md", "readme.md", "Readme.md", "README.MD"]
    static let licenseCandidates = ["LICENSE", "LICENSE.txt", "License", "license"]

    static func readReadmeContent(in repositoryURL: URL) throws -> String {
        let fileURL = try firstExistingFileURL(in: repositoryURL, candidates: readmeCandidates)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    static func readGitignoreContent(in repositoryURL: URL) throws -> String {
        let fileURL = repositoryURL.appendingPathComponent(".gitignore")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw notFoundError(message: ".gitignore file not found")
        }
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    static func readLicenseContent(in repositoryURL: URL) throws -> String {
        let fileURL = try firstExistingFileURL(in: repositoryURL, candidates: licenseCandidates)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    private static func firstExistingFileURL(in repositoryURL: URL, candidates: [String]) throws -> URL {
        for candidate in candidates {
            let fileURL = repositoryURL.appendingPathComponent(candidate)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }

        if candidates == readmeCandidates {
            throw notFoundError(message: "README.md file not found")
        }
        throw notFoundError(message: "LICENSE file not found")
    }

    private static func notFoundError(message: String) -> NSError {
        NSError(
            domain: "ProjectError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
