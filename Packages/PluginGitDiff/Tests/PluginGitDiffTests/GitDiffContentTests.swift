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
}
