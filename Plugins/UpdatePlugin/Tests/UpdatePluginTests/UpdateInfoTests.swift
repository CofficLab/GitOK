import XCTest
@testable import UpdatePlugin

final class UpdateInfoTests: XCTestCase {

    // MARK: - JSON Decoding Tests

    func testDecodeOfficialAPIResponse() {
        let json = """
        {
            "version": "3.0.11",
            "buildNumber": 123456,
            "releaseDate": "2026-06-13T00:00:00Z",
            "downloadUrls": [
                "https://s.kuaiyizhi.cn/gitok/GitOK-3.0.11-arm64.dmg",
                "https://github.com/CofficLab/GitOK/releases/download/v3.0.11/GitOK-3.0.11-arm64.dmg"
            ],
            "releaseNotes": "New features and bug fixes",
            "minimumSystemVersion": "14.0",
            "architecture": "arm64",
            "fileSize": 22261802
        }
        """.data(using: .utf8)!

        do {
            let response = try JSONDecoder().decode(OfficialAPIResponse.self, from: json)

            XCTAssertEqual(response.version, "3.0.11")
            XCTAssertEqual(response.buildNumber, 123456)
            XCTAssertEqual(response.downloadUrls.count, 2)
            XCTAssertEqual(response.minimumSystemVersion, "14.0")
            XCTAssertEqual(response.architecture, "arm64")
            XCTAssertEqual(response.fileSize, 22261802)
        } catch {
            XCTFail("Failed to decode: \(error)")
        }
    }

    func testDecodeGitHubAPIResponse() {
        let json = """
        {
            "tag_name": "v3.0.11",
            "id": 123456789,
            "published_at": "2026-06-13T00:00:00Z",
            "body": "Release notes content",
            "assets": [
                {
                    "name": "GitOK-3.0.11-arm64.dmg",
                    "browser_download_url": "https://github.com/CofficLab/GitOK/releases/download/v3.0.11/GitOK-3.0.11-arm64.dmg",
                    "size": 22261802
                },
                {
                    "name": "GitOK-3.0.11-x86_64.dmg",
                    "browser_download_url": "https://github.com/CofficLab/GitOK/releases/download/v3.0.11/GitOK-3.0.11-x86_64.dmg",
                    "size": 22261802
                }
            ]
        }
        """.data(using: .utf8)!

        do {
            let response = try JSONDecoder().decode(GitHubReleaseResponse.self, from: json)

            XCTAssertEqual(response.tag_name, "v3.0.11")
            XCTAssertEqual(response.id, 123456789)
            XCTAssertEqual(response.assets.count, 2)
            XCTAssertTrue(response.assets[0].name.contains("arm64"))
            XCTAssertEqual(response.assets[0].size, 22261802)
        } catch {
            XCTFail("Failed to decode: \(error)")
        }
    }

    // MARK: - UpdateInfo Model Tests

    func testUpdateInfoEquality() {
        let info1 = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url1"],
            releaseNotes: "notes"
        )

        let info2 = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url1"],
            releaseNotes: "notes"
        )

        let info3 = UpdateInfo(
            version: "3.0.12",
            buildNumber: 123457,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url1"],
            releaseNotes: "notes"
        )

        XCTAssertEqual(info1, info2)
        XCTAssertNotEqual(info1, info3)
    }

    func testUpdateInfoInitialization() {
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url1", "url2"],
            releaseNotes: "Test notes",
            minimumSystemVersion: "14.0",
            fileSize: 12345
        )

        XCTAssertEqual(updateInfo.version, "3.0.11")
        XCTAssertEqual(updateInfo.buildNumber, 123456)
        XCTAssertEqual(updateInfo.releaseDate, "2026-06-13T00:00:00Z")
        XCTAssertEqual(updateInfo.downloadUrls.count, 2)
        XCTAssertEqual(updateInfo.releaseNotes, "Test notes")
        XCTAssertEqual(updateInfo.minimumSystemVersion, "14.0")
        XCTAssertEqual(updateInfo.fileSize, 12345)
    }

    func testUpdateInfoDefaultValues() {
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url"],
            releaseNotes: "Test"
        )

        XCTAssertEqual(updateInfo.minimumSystemVersion, "14.0")  // Default value
        XCTAssertNil(updateInfo.fileSize)  // Optional, should be nil
    }
}