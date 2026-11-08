import Foundation
import XCTest
@testable import KitGitOKCLI

/// CLI 脚本与 App 端 URL 编解码的一致性测试。
///
/// 脚本用 perl 做百分号编码，App 用 `URLComponents` 解析；
/// 两者必须对同一路径产出可互相还原的结果，否则含特殊字符的目录
/// 在传输中会损坏。
final class CLIEncodingConsistencyTests: XCTestCase {

    /// 覆盖路径中可能出现的各类字符。
    private let samplePaths = [
        "/tmp/plain",
        "/tmp/with space",
        "/tmp/中文目录",
        "/tmp/with#hash",
        "/tmp/with&ampersand",
        "/tmp/with+plus",
        "/tmp/with'quote",
        "/tmp/with(paren)",
        "/tmp/with=equals:colon@at",
        "/tmp/100%percent",
        "/tmp/with~tilde",
        "/tmp/with-underscore.dot",
    ]

    /// 脚本的百分号编码：与 `CLIScriptBuilder` 中脚本内的 perl 调用一致。
    private func perlEncode(_ path: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [
            "-MURI::Escape", "-ne",
            "chomp; print uri_escape($_, \"^A-Za-z0-9\\\\-._~\")",
        ]
        let outputPipe = Pipe()
        let inputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardInput = inputPipe
        try process.run()

        inputPipe.fileHandleForWriting.write(Data((path + "\n").utf8))
        inputPipe.fileHandleForWriting.closeFile()
        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        process.waitUntilExit()
        return output
    }

    /// App 端解析：从 `gitok://open?path=...` 还原出目录路径。
    private func appResolve(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "path" }?
            .value
    }

    func testScriptEncodingIsReversibleByApp() throws {
        for path in samplePaths {
            let encoded = try perlEncode(path)
            let restored = appResolve("gitok://open?path=\(encoded)")
            XCTAssertEqual(
                restored,
                path,
                "path \(path) was encoded as \(encoded) but restored to \(restored ?? "<nil>")"
            )
        }
    }

    func testAppEncodingIsReversibleByApp() throws {
        // App 自己构造的 URL 也必须能被自己解析回来（往返一致）。
        for path in samplePaths {
            var components = URLComponents()
            components.scheme = "gitok"
            components.host = "open"
            components.path = "/open"
            components.queryItems = [URLQueryItem(name: "path", value: path)]
            guard let url = components.url else {
                XCTFail("failed to build URL for \(path)")
                continue
            }
            XCTAssertEqual(
                appResolve(url.absoluteString),
                path,
                "round trip failed for \(path)"
            )
        }
    }

    func testScriptEncodingIsAcceptedByURLComponents() throws {
        // 脚本产出的百分号编码必须是合法的 URL query，
        // 否则 App 侧的 `URL(string:)` 会解析失败。
        for path in samplePaths {
            let encoded = try perlEncode(path)
            XCTAssertNotNil(
                URL(string: "gitok://open?path=\(encoded)"),
                "script produced an unparsable URL for \(path): \(encoded)"
            )
        }
    }
}
