import Foundation
import Testing
@testable import KitGit

@Suite("GitProcessRunner")
struct GitProcessRunnerTests {
    @Test("drains large stdout before waiting for git")
    func handlesLargeOutput() throws {
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }

        for index in 0..<4_000 {
            let directory = repository.appendingPathComponent("Sources/Module\(index / 100)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let file = directory.appendingPathComponent("File\(index).swift")
            try Data("let value = \(index)\n".utf8).write(to: file)
        }
        try runGit(["add", "."], in: repository)
        try runGit(["commit", "-qm", "large fixture"], in: repository)

        let output = try GitProcessRunner.run(
            ["ls-tree", "-r", "--name-only", "-z", "HEAD"],
            in: repository
        )

        #expect(output.utf8.count > 64 * 1024)
        #expect(output.split(separator: "\0", omittingEmptySubsequences: true).count == 4_000)
    }

    private func makeRepository() throws -> URL {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitProcessRunnerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try runGit(["init", "-q"], in: repository)
        try runGit(["config", "user.email", "test@example.com"], in: repository)
        try runGit(["config", "user.name", "Test"], in: repository)
        return repository
    }

    @discardableResult
    private func runGit(_ arguments: [String], in repository: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = repository

        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()

        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "GitProcessRunnerTests",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: String(decoding: data, as: UTF8.self)]
            )
        }
        return String(decoding: data, as: UTF8.self)
    }
}
