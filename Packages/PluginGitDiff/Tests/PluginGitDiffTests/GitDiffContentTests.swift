import Foundation
import XCTest
@testable import PluginGitDiff

final class GitDiffContentTests: XCTestCase {
    func testDetectsPreviewableFileKinds() {
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "docs/spec.pdf"), .pdf)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "assets/icon.png"), .image)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "recordings/demo.m4a"), .audio)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "slides/deck.pptx"), .office)
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "Sources/App.swift"))
    }

    func testPDFSignatureWinsWhenExtensionIsUnexpected() {
        let pdf = Data("%PDF-1.7\n".utf8)
        XCTAssertEqual(
            GitDiffContentDetector.kind(forPath: "downloaded.bin", data: pdf),
            .pdf
        )
    }

    func testTypeScriptExtensionUsesContentDetection() {
        let source = Data("export const language = 'en'\n".utf8)

        XCTAssertTrue(GitDiffContentDetector.needsContentInspection(forPath: "src/language.ts"))
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "src/language.ts"))
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "src/language.ts", data: source))
        XCTAssertTrue(GitDiffContentDetector.isLikelyText(source))
    }

    func testMPEGTransportStreamWithTypeScriptExtensionRemainsVideo() {
        let packetSize = 188
        var transportStream = Data()
        for _ in 0..<5 {
            var packet = Data(repeating: 0, count: packetSize)
            packet[0] = 0x47
            packet[3] = 0x10 // payload-only adaptation field control
            transportStream.append(packet)
        }

        XCTAssertEqual(
            GitDiffContentDetector.kind(forPath: "recordings/video.ts", data: transportStream),
            .video
        )
        XCTAssertFalse(GitDiffContentDetector.isLikelyText(transportStream))
    }
}
