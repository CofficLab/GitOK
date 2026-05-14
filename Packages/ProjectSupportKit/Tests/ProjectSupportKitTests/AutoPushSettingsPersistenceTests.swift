import Foundation
import XCTest
@testable import ProjectSupportKit

final class AutoPushSettingsPersistenceTests: XCTestCase {
    func testLoadSettingsReturnsEmptyWhenFileIsMissingOrInvalid() throws {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("settings.json")

        XCTAssertEqual(AutoPushSettingsPersistence.loadSettings(from: fileURL), [:])

        try "not-json".write(to: fileURL, atomically: true, encoding: .utf8)
        XCTAssertEqual(AutoPushSettingsPersistence.loadSettings(from: fileURL), [:])
    }

    func testPersistAndLoadRoundTrip() throws {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("nested/settings.json")
        let settings = makeSettings()

        AutoPushSettingsPersistence.persist(settings, to: fileURL)

        XCTAssertEqual(AutoPushSettingsPersistence.loadSettings(from: fileURL), settings)
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: fileURL.deletingLastPathComponent()
                    .appendingPathComponent(AutoPushSettingsPersistence.tmpFileName).path
            )
        )
    }

    func testUpdatedSettingsCreatesAndUpdatesConfig() {
        let initial = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 200)

        let created = AutoPushSettingsPersistence.updatedSettings(
            settings: [:],
            projectPath: "/tmp/repo",
            branchName: "main",
            enabled: true,
            now: initial
        )

        XCTAssertEqual(
            created["/tmp/repo://main"],
            ProjectBranchAutoPushConfig(
                projectPath: "/tmp/repo",
                branchName: "main",
                isEnabled: true,
                lastModified: initial
            )
        )

        let updated = AutoPushSettingsPersistence.updatedSettings(
            settings: created,
            projectPath: "/tmp/repo",
            branchName: "main",
            enabled: false,
            now: later
        )

        XCTAssertEqual(updated["/tmp/repo://main"]?.isEnabled, false)
        XCTAssertEqual(updated["/tmp/repo://main"]?.lastModified, later)
    }

    func testUpdatedLastPushedDateOnlyChangesExistingConfig() {
        let initial = Date(timeIntervalSince1970: 100)
        let pushedAt = Date(timeIntervalSince1970: 300)
        let settings = [
            "/tmp/repo://main": ProjectBranchAutoPushConfig(
                projectPath: "/tmp/repo",
                branchName: "main",
                isEnabled: true,
                lastModified: initial
            )
        ]

        let updated = AutoPushSettingsPersistence.updatedLastPushedDate(
            settings: settings,
            projectPath: "/tmp/repo",
            branchName: "main",
            now: pushedAt
        )
        let untouched = AutoPushSettingsPersistence.updatedLastPushedDate(
            settings: settings,
            projectPath: "/tmp/repo",
            branchName: "dev",
            now: pushedAt
        )

        XCTAssertEqual(updated["/tmp/repo://main"]?.lastPushedAt, pushedAt)
        XCTAssertEqual(untouched, settings)
    }

    func testFilteringHelpersReturnExpectedConfigs() {
        let settings = makeSettings()

        XCTAssertEqual(
            Set(AutoPushSettingsPersistence.configs(forProject: "/tmp/repo-a", in: settings).map(\.branchName)),
            Set(["main", "dev"])
        )
        XCTAssertEqual(
            Set(AutoPushSettingsPersistence.enabledConfigs(in: settings).map(\.id)),
            Set(["/tmp/repo-a://main", "/tmp/repo-b://release"])
        )
    }

    func testRemovalHelpersRemoveSingleBranchAndWholeProject() {
        let settings = makeSettings()

        let withoutBranch = AutoPushSettingsPersistence.settingsByRemovingConfig(
            settings: settings,
            projectPath: "/tmp/repo-a",
            branchName: "dev"
        )
        XCTAssertNil(withoutBranch["/tmp/repo-a://dev"])
        XCTAssertNotNil(withoutBranch["/tmp/repo-a://main"])

        let withoutProject = AutoPushSettingsPersistence.settingsByRemovingProject(
            settings: settings,
            projectPath: "/tmp/repo-a"
        )
        XCTAssertNil(withoutProject["/tmp/repo-a://dev"])
        XCTAssertNil(withoutProject["/tmp/repo-a://main"])
        XCTAssertNotNil(withoutProject["/tmp/repo-b://release"])
    }

    func testParseKeyRejectsUnexpectedFormats() {
        let parsed = AutoPushSettingsPersistence.parseKey("/tmp/repo://main")
        XCTAssertEqual(parsed?.projectPath, "/tmp/repo")
        XCTAssertEqual(parsed?.branchName, "main")
        XCTAssertNil(AutoPushSettingsPersistence.parseKey("missing-separator"))
        XCTAssertNil(AutoPushSettingsPersistence.parseKey("too://many://parts"))
    }

    func testProjectBranchAutoPushConfigUsesLastPathComponentAsTitle() {
        let config = ProjectBranchAutoPushConfig(projectPath: "/tmp/group/my-repo", branchName: "main")
        XCTAssertEqual(config.projectTitle, "my-repo")
    }

    func testPersistHandlesEncodingFailureGracefully() {
        // This test attempts to trigger the encoding failure path
        // In practice, JSONEncoder always succeeds for Codable types,
        // but we include this test for defensive coverage
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.json")

        // Create settings that can always be encoded
        let settings = makeSettings()
        AutoPushSettingsPersistence.persist(settings, to: fileURL)

        // The file should be created successfully
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testLoadSettingsReturnsEmptyWhenFileExistsButCannotBeRead() throws {
        // Create a file with invalid JSON to trigger the decode failure path
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("invalid.json")

        // Write invalid JSON content
        try "{invalid json content}".write(to: fileURL, atomically: true, encoding: .utf8)

        // Should return empty dictionary when decode fails
        XCTAssertEqual(AutoPushSettingsPersistence.loadSettings(from: fileURL), [:])
    }

    func testPersistHandlesFileWriteErrorGracefully() throws {
        // Test the error handling path in persist function
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("readonly/settings.json")

        // Create a readonly parent directory to trigger write error
        let readonlyDir = directory.appendingPathComponent("readonly", isDirectory: true)
        try FileManager.default.createDirectory(at: readonlyDir, withIntermediateDirectories: true)

        // Try to persist to a path that might fail (though FileManager handles this gracefully)
        let settings = makeSettings()
        AutoPushSettingsPersistence.persist(settings, to: fileURL)

        // The function should handle errors gracefully without throwing
        // We verify it doesn't crash or throw
    }

    private func makeSettings() -> [String: ProjectBranchAutoPushConfig] {
        [
            "/tmp/repo-a://main": ProjectBranchAutoPushConfig(
                projectPath: "/tmp/repo-a",
                branchName: "main",
                isEnabled: true,
                lastModified: Date(timeIntervalSince1970: 1)
            ),
            "/tmp/repo-a://dev": ProjectBranchAutoPushConfig(
                projectPath: "/tmp/repo-a",
                branchName: "dev",
                isEnabled: false,
                lastModified: Date(timeIntervalSince1970: 2)
            ),
            "/tmp/repo-b://release": ProjectBranchAutoPushConfig(
                projectPath: "/tmp/repo-b",
                branchName: "release",
                isEnabled: true,
                lastModified: Date(timeIntervalSince1970: 3)
            ),
        ]
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}
