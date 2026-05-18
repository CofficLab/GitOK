import GitCoreKit
import XCTest

final class CloneRepositoryValidationTests: XCTestCase {
    func testNormalizesGitHubShortcutRemote() {
        XCTAssertEqual(
            CloneRepositoryValidation.normalizedRemoteURL(from: "owner/repo"),
            "https://github.com/owner/repo.git"
        )
    }

    func testLeavesStandardRemoteUntouched() {
        XCTAssertEqual(
            CloneRepositoryValidation.normalizedRemoteURL(from: "git@github.com:owner/repo.git"),
            "git@github.com:owner/repo.git"
        )
    }

    func testInfersRepositoryNameFromHTTPSRemote() {
        XCTAssertEqual(
            CloneRepositoryValidation.inferredRepositoryName(from: "https://github.com/owner/repo.git"),
            "repo"
        )
    }

    func testInfersRepositoryNameFromShortcut() {
        XCTAssertEqual(
            CloneRepositoryValidation.inferredRepositoryName(from: "owner/repo"),
            "repo"
        )
    }

    func testCredentialHostSupportsHTTPSRemoteAndShortcut() {
        XCTAssertEqual(
            CloneRepositoryValidation.credentialHost(from: "https://github.com/owner/repo.git"),
            "github.com"
        )
        XCTAssertEqual(
            CloneRepositoryValidation.credentialHost(from: "owner/repo"),
            "github.com"
        )
    }

    func testCredentialHostIgnoresSSHRemote() {
        XCTAssertNil(
            CloneRepositoryValidation.credentialHost(from: "git@github.com:owner/repo.git")
        )
    }

    func testRejectsInvalidRepositoryName() {
        XCTAssertNotNil(CloneRepositoryValidation.validateRepositoryName("bad/name"))
        XCTAssertNotNil(CloneRepositoryValidation.validateRepositoryName(".."))
        XCTAssertNil(CloneRepositoryValidation.validateRepositoryName("repo-name"))
    }

    func testDestinationStateTreatsHiddenFilesAsNonEmpty() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let hiddenFile = directory.appendingPathComponent(".env")
        try "TOKEN=1\n".write(to: hiddenFile, atomically: true, encoding: .utf8)

        XCTAssertEqual(
            CloneRepositoryValidation.destinationState(for: directory, projectExists: false),
            .existingNonEmptyDirectory
        )
    }
}
