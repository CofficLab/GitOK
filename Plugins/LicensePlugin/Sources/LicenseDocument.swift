import Foundation
import ProjectSupportKit
import GitOKCoreKit

enum LicenseDocument {
    static func fileURL(for projectURL: URL) -> URL {
        projectURL.appendingPathComponent("LICENSE")
    }

    static func exists(in projectURL: URL) -> Bool {
        (try? ProjectDocumentResolver.readLicenseContent(in: projectURL)) != nil
    }

    static func existsAsync(in projectURL: URL) async -> Bool {
        await Task.detached(priority: .utility) {
            exists(in: projectURL)
        }.value
    }

    static func read(in projectURL: URL) throws -> String {
        try ProjectDocumentResolver.readLicenseContent(in: projectURL)
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
