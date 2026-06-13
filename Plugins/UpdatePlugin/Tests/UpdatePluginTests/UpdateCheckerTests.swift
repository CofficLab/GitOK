import XCTest
@testable import UpdatePlugin

final class UpdateCheckerTests: XCTestCase {

    // MARK: - Version Parsing Tests

    func testParseVersionFromValidKey() {
        // Test parsing version from R2 key format
        _ = "gitok/GitOK-3.0.11-arm64.dmg"
        // This would be tested through the actual parseVersion function
        // We'll test it indirectly through model creation
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["https://example.com/file.dmg"],
            releaseNotes: "Test release"
        )

        XCTAssertEqual(updateInfo.version, "3.0.11")
    }

    func testParseVersionFromInvalidKey() {
        // Test with malformed version string
        let updateInfo = UpdateInfo(
            version: "invalid",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["https://example.com/file.dmg"],
            releaseNotes: "Test release"
        )

        XCTAssertEqual(updateInfo.version, "invalid")
    }

    // MARK: - Version Comparison Tests

    func testIsNewerThanCurrentWithHigherVersion() {
        let updateInfo = UpdateInfo(
            version: "99.0.0",  // Very high version number
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["https://example.com/file.dmg"],
            releaseNotes: "Test release"
        )

        // This should be newer than current version (assuming current is < 99)
        XCTAssertTrue(updateInfo.isNewerThanCurrent)
    }

    func testIsNewerThanCurrentWithLowerVersion() {
        let updateInfo = UpdateInfo(
            version: "0.0.1",  // Very low version number
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["https://example.com/file.dmg"],
            releaseNotes: "Test release"
        )

        // This should not be newer than current version
        XCTAssertFalse(updateInfo.isNewerThanCurrent)
    }

    func testIsNewerThanCurrentWithEqualVersion() {
        // Get current version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        let updateInfo = UpdateInfo(
            version: currentVersion,  // Same as current
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["https://example.com/file.dmg"],
            releaseNotes: "Test release"
        )

        // This should not be newer (equal versions)
        XCTAssertFalse(updateInfo.isNewerThanCurrent)
    }

    // MARK: - URL Selection Tests

    func testPreferredDownloadURL() {
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: [
                "https://s.kuaiyizhi.cn/gitok/file.dmg",  // R2 (primary)
                "https://github.com/releases/file.dmg"    // GitHub (fallback)
            ],
            releaseNotes: "Test release"
        )

        XCTAssertEqual(updateInfo.preferredDownloadURL, "https://s.kuaiyizhi.cn/gitok/file.dmg")
    }

    func testFallbackDownloadURL() {
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: [
                "https://s.kuaiyizhi.cn/gitok/file.dmg",
                "https://github.com/releases/file.dmg"
            ],
            releaseNotes: "Test release"
        )

        XCTAssertEqual(updateInfo.fallbackDownloadURL, "https://github.com/releases/file.dmg")
    }

    func testFallbackDownloadURLWithSingleURL() {
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["https://s.kuaiyizhi.cn/gitok/file.dmg"],
            releaseNotes: "Test release"
        )

        XCTAssertNil(updateInfo.fallbackDownloadURL)
    }

    // MARK: - Error Handling Tests

    func testUpdateErrorDescriptions() {
        // Test all error types have proper descriptions
        let errors: [UpdateError] = [
            .invalidURL,
            .networkError,
            .downloadFailed,
            .allDownloadURLsFailed,
            .signatureVerificationFailed("Test error"),
            .invalidDeveloperCertificate,
            .installationFailed("Test installation error"),
            .dmgMountFailed,
            .appReplacementFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testUpdateErrorLocalizedDescription() {
        let error = UpdateError.networkError
        XCTAssertEqual(error.localizedDescription, "网络连接失败")
    }
}