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

    static func read(in projectURL: URL) throws -> String {
        try ProjectDocumentResolver.readLicenseContent(in: projectURL)
    }

    static func write(_ content: String, in projectURL: URL) throws {
        try content.write(to: fileURL(for: projectURL), atomically: true, encoding: .utf8)
    }
}
