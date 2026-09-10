import Foundation
import Testing
@testable import PluginProjectLanguages

@Suite("RepositoryLanguageAnalyzer")
struct RepositoryLanguageAnalyzerTests {
    @Test("counts recognized tracked text files by byte size")
    func countsRecognizedFiles() throws {
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }
        try write("let value = 1\n", to: repository.appendingPathComponent("Sources/App.swift"))
        try write("# Title\n", to: repository.appendingPathComponent("README.md"))
        try write("ignored", to: repository.appendingPathComponent("node_modules/package.js"))
        try commit(repository)

        let snapshot = try RepositoryLanguageAnalyzer().analyze(repository: repository)

        #expect(snapshot.languages.map(\.id) == ["swift", "markdown"])
        #expect(snapshot.languages[0].byteCount > snapshot.languages[1].byteCount)
    }

    @Test("ignores binary files and generated directories")
    func ignoresBinaryAndGeneratedFiles() throws {
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }
        try write("source", to: repository.appendingPathComponent("main.swift"))
        try Data([0, 1, 2, 3]).write(to: repository.appendingPathComponent("image.json"))
        try write("generated", to: repository.appendingPathComponent("build/generated.swift"))
        try commit(repository)

        let snapshot = try RepositoryLanguageAnalyzer().analyze(repository: repository)

        #expect(snapshot.languages.map(\.id) == ["swift"])
    }

    private func makeRepository() throws -> URL {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectLanguagesTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try runGit(["init", "-q"], in: repository)
        try runGit(["config", "user.email", "test@example.com"], in: repository)
        try runGit(["config", "user.name", "Test"], in: repository)
        return repository
    }

    private func write(_ content: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func commit(_ repository: URL) throws {
        try runGit(["add", "."], in: repository)
        try runGit(["commit", "-qm", "test"], in: repository)
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
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "RepositoryLanguageAnalyzerTests", code: Int(process.terminationStatus))
        }
        return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }
}
