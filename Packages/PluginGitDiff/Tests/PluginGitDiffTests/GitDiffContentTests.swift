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

final class GitDiffContentExtraTests: XCTestCase {

    func testDetectsVideoAndOfficeKindsByExtension() {
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "clip/movie.mov"), .video)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "clip/clip.mp4"), .video)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "doc/document.doc"), .office)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "sheet.xls"), .office)
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "deck.pages"), .office)
        // Unknown extension -> nil.
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "readme.xyz"))
    }

    func testKindDataOverloadFallsBackToExtension() {
        // No PDF signature, not TS -> extension-based detection.
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "a.png", data: Data([1, 2, 3])), .image)
    }

    func testIsLikelyTextEdgeCases() {
        XCTAssertTrue(GitDiffContentDetector.isLikelyText(Data())) // empty
        XCTAssertFalse(GitDiffContentDetector.isLikelyText(Data([0x00, 0x01, 0x02]))) // contains null
        // Mostly printable but one control char below threshold.
        let printable = Data("hello\nworld".utf8)
        XCTAssertTrue(GitDiffContentDetector.isLikelyText(printable))
        // Many control bytes -> not text.
        var noisy = Data()
        for _ in 0..<20 { noisy.append(contentsOf: [0x01, 0x02]) }
        XCTAssertFalse(GitDiffContentDetector.isLikelyText(noisy))
    }

    func testMPEGTSVariantsAndRejections() {
        // 192-byte packet with 4-byte prefix.
        var ts192 = Data()
        ts192.append(Data([0, 0, 0, 0])) // 4-byte prefix
        for _ in 0..<5 {
            var packet = Data(repeating: 0, count: 192)
            packet[0] = 0x47
            packet[3] = 0x10
            ts192.append(packet)
        }
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "v.ts", data: ts192), .video)

        // 204-byte packet.
        var ts204 = Data()
        for _ in 0..<5 {
            var packet = Data(repeating: 0, count: 204)
            packet[0] = 0x47
            packet[3] = 0x10
            ts204.append(packet)
        }
        XCTAssertEqual(GitDiffContentDetector.kind(forPath: "v.ts", data: ts204), .video)

        // Too short -> not TS.
        let short = Data([0x47, 0x10])
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "v.ts", data: short))

        // Bad sync byte -> not TS.
        var badSync = Data(repeating: 0, count: 188 * 5)
        badSync[0] = 0x00
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "v.ts", data: badSync))

        // Reserved adaptation control (nibble == 0) -> rejected.
        var reserved = Data()
        for _ in 0..<5 {
            var packet = Data(repeating: 0, count: 188)
            packet[0] = 0x47
            packet[3] = 0x00
            reserved.append(packet)
        }
        XCTAssertNil(GitDiffContentDetector.kind(forPath: "v.ts", data: reserved))
    }

    func testPreviewErrorDescription() {
        let err = GitDiffPreviewError.fileTooLarge(1024 * 1024)
        XCTAssertTrue(err.errorDescription?.isEmpty == false)
    }

    func testLocalizationWrapper() {
        let s = GitDiffLocalization.string("any.key", bundle: .main, locale: Locale(identifier: "en"))
        XCTAssertFalse(s.isEmpty)
    }

    func testContentKindSystemImageAndTitle() {
        // 覆盖 systemImage / title 各分支。
        XCTAssertEqual(GitDiffContentKind.pdf.systemImage, "doc.richtext")
        XCTAssertEqual(GitDiffContentKind.image.systemImage, "photo")
        XCTAssertEqual(GitDiffContentKind.audio.systemImage, "waveform")
        XCTAssertEqual(GitDiffContentKind.video.systemImage, "film")
        XCTAssertEqual(GitDiffContentKind.office.systemImage, "doc")
        XCTAssertEqual(GitDiffContentKind.binary.systemImage, "doc.questionmark")
        XCTAssertEqual(GitDiffContentKind.pdf.title, "PDF Preview")
        XCTAssertEqual(GitDiffContentKind.binary.title, "Binary File")
    }
}
