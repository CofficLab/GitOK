import XCTest
@testable import GitCoreKit

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

    func testDestinationValidationMessageReturnsNilForAvailableAndEmptyDirectory() {
        XCTAssertNil(CloneRepositoryValidation.destinationValidationMessage(for: .available))
        XCTAssertNil(CloneRepositoryValidation.destinationValidationMessage(for: .existingEmptyDirectory))
    }

    func testDestinationValidationMessageReturnsExpectedMessages() {
        XCTAssertEqual(
            CloneRepositoryValidation.destinationValidationMessage(for: .existingProject),
            "该目录已经在项目列表中"
        )
        XCTAssertEqual(
            CloneRepositoryValidation.destinationValidationMessage(for: .existingNonEmptyDirectory),
            "目标目录已存在且不为空，请更换目录或仓库名称"
        )
        XCTAssertEqual(
            CloneRepositoryValidation.destinationValidationMessage(for: .existingFile),
            "目标路径已存在同名文件"
        )
    }

    func testDestinationStateReturnsAvailableForNonexistentPath() {
        let nonexistentPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        XCTAssertEqual(
            CloneRepositoryValidation.destinationState(for: nonexistentPath, projectExists: false),
            .available
        )
    }

    func testDestinationStateReturnsExistingProjectWhenProjectExists() {
        let path = FileManager.default.temporaryDirectory
        XCTAssertEqual(
            CloneRepositoryValidation.destinationState(for: path, projectExists: true),
            .existingProject
        )
    }

    func testDestinationStateReturnsExistingFileForFile() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try "content".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: file) }

        XCTAssertEqual(
            CloneRepositoryValidation.destinationState(for: file, projectExists: false),
            .existingFile
        )
    }

    func testDestinationStateReturnsExistingEmptyDirectory() throws {
        let emptyDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: emptyDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: emptyDirectory) }

        XCTAssertEqual(
            CloneRepositoryValidation.destinationState(for: emptyDirectory, projectExists: false),
            .existingEmptyDirectory
        )
    }

    func testValidateRepositoryNameReturnsMessageForEmptyString() {
        XCTAssertEqual(
            CloneRepositoryValidation.validateRepositoryName(""),
            "请输入仓库名称"
        )
        XCTAssertEqual(
            CloneRepositoryValidation.validateRepositoryName("   "),
            "请输入仓库名称"
        )
    }
}
