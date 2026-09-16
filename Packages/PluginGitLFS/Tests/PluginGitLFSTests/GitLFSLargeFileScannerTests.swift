import Foundation
import Testing
@testable import PluginGitLFS

@Suite("Git LFS large-file scanner")
struct GitLFSLargeFileScannerTests {
    @Test("cancellation stops the scan before returning files")
    func cancellationStopsScan() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("large".utf8).write(to: root.appendingPathComponent("large.bin"))

        let files = GitLFSLargeFileScanner.scan(
            in: root,
            thresholdBytes: 0,
            shouldCancel: { true }
        )

        #expect(files.isEmpty)
    }

    @Test("scan returns large files relative to the project root")
    func returnsRelativePaths() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("large".utf8).write(to: root.appendingPathComponent("large.bin"))

        let files = GitLFSLargeFileScanner.scan(
            in: root,
            thresholdBytes: 0,
            shouldCancel: { false }
        )

        #expect(files == ["large.bin"])
    }
}
