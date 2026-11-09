import XCTest
@testable import FactoryGitOK

/// `ExternalOpenRequest` 的 URL 编解码测试。
///
/// CLI 脚本 `gitok <path>` 与 App 侧必须使用同一套编解码规则，
/// 否则路径中的空格、中文、`#`、`&` 等字符会在传输中损坏。
final class ExternalOpenRequestTests: XCTestCase {

    func testResolveDirectoryFromGitokURL() throws {
        let url = try XCTUnwrap(
            URL(string: "gitok://open?path=%2FUsers%2Fme%2Fproject")
        )
        XCTAssertEqual(
            ExternalOpenRequest.resolveDirectory(from: url),
            "/Users/me/project"
        )
    }

    func testResolveDirectoryDecodesPercentEncodedSpecialCharacters() throws {
        // 路径含空格、中文、# 与 &：这些字符必须在 query 中被编码。
        let url = try XCTUnwrap(
            URL(string: "gitok://open?path=%2Ftmp%2Fgitok%20%E6%B5%8B%E8%AF%95%20%231%26two")
        )
        XCTAssertEqual(
            ExternalOpenRequest.resolveDirectory(from: url),
            "/tmp/gitok 测试 #1&two"
        )
    }

    func testResolveDirectoryFromFileURL() throws {
        let url = try XCTUnwrap(URL(fileURLWithPath: "/tmp/a folder"))
        XCTAssertEqual(
            ExternalOpenRequest.resolveDirectory(from: url),
            "/tmp/a folder"
        )
    }

    func testResolveDirectoryRejectsUnsupportedURL() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/open?path=%2Ftmp"))
        XCTAssertNil(ExternalOpenRequest.resolveDirectory(from: url))
    }

    func testResolveDirectoryRejectsWrongHost() throws {
        let url = try XCTUnwrap(URL(string: "gitok://other?path=%2Ftmp"))
        XCTAssertNil(ExternalOpenRequest.resolveDirectory(from: url))
    }

    func testResolveDirectoryRejectsMissingPathParameter() throws {
        let url = try XCTUnwrap(URL(string: "gitok://open"))
        XCTAssertNil(ExternalOpenRequest.resolveDirectory(from: url))
    }

    func testResolveDirectoryRejectsEmptyPathParameter() throws {
        let url = try XCTUnwrap(URL(string: "gitok://open?path="))
        XCTAssertNil(ExternalOpenRequest.resolveDirectory(from: url))
    }

    func testMakeURLRoundTripsThroughResolve() throws {
        let path = "/tmp/gitok 项目 #1"
        let url = try XCTUnwrap(ExternalOpenRequest.makeURL(forDirectory: path))
        XCTAssertEqual(url.scheme, "gitok")
        XCTAssertEqual(
            ExternalOpenRequest.resolveDirectory(from: url),
            path
        )
    }

    func testMakeURLUsesPercentEncodingForSpecialCharacters() throws {
        let url = try XCTUnwrap(
            ExternalOpenRequest.makeURL(forDirectory: "/tmp/a b")
        )
        // 空格必须是 %20 而不是 '+'，否则 '+' 自身会被误解。
        XCTAssertTrue(
            url.absoluteString.contains("%20"),
            "unexpected URL: \(url.absoluteString)"
        )
        XCTAssertFalse(url.absoluteString.contains("+"))
    }
}
