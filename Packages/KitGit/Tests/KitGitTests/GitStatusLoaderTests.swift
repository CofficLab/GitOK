import Foundation
import Testing
@testable import KitGit

@Suite("GitStatusLoader")
struct GitStatusLoaderTests {
    @Test("honors pre-cancelled status requests")
    func honorsPreCancelledRequest() {
        let cancellation = GitProcessCancellation()
        cancellation.cancel()

        #expect(throws: CancellationError.self) {
            try GitStatusLoader.loadStatus(
                in: URL(fileURLWithPath: "/missing/repository"),
                cancellation: cancellation
            )
        }
    }

    @Test("does not discover a parent repository for a nested non-repository directory")
    func rejectsNestedDirectory() throws {
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitStatusLoaderTests-\(UUID().uuidString)")
        let nested = parent.appendingPathComponent("nested", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: parent) }

        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try runGit(["init", "-q"], in: parent)

        do {
            _ = try GitStatusLoader.loadStatus(in: nested)
            Issue.record("A nested directory must not use a parent repository.")
        } catch let error as GitStatusLoader.Error {
            #expect(error == .notARepository(nested.standardizedFileURL))
        }
    }

    @discardableResult
    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "GitStatusLoaderTests",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: String(decoding: data, as: UTF8.self)]
            )
        }
        return String(decoding: data, as: UTF8.self)
    }
}
