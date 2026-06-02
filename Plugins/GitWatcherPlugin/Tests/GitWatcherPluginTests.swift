import Foundation
@testable import GitWatcherPlugin
import Testing

@Suite("GitWatcherPlugin")
struct GitWatcherPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitWatcherPlugin.metadata.id == "GitWatcherPlugin")
        #expect(GitWatcherPlugin.metadata.iconName == "dot.radiowaves.left.and.right")
        #expect(GitWatcherPlugin.metadata.order == 23)
        #expect(GitWatcherPlugin.metadata.allowUserToggle == false)
        #expect(GitWatcherPlugin.metadata.defaultEnabled == false)
        #expect(GitWatcherPlugin.metadata.tableName == "GitWatcher")
    }

    @Test("change kind reports single or multiple changes")
    func changeKind() {
        #expect(GitWatcherCoordinator.changeKind(headChanged: true, indexChanged: false, stashChanged: false, refsChanged: false) == "head")
        #expect(GitWatcherCoordinator.changeKind(headChanged: false, indexChanged: true, stashChanged: false, refsChanged: false) == "index")
        #expect(GitWatcherCoordinator.changeKind(headChanged: true, indexChanged: true, stashChanged: false, refsChanged: false) == "multiple")
    }

    @Test("resolves direct git directory")
    func resolvesDirectGitDirectory() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let gitDirectory = root.appendingPathComponent(".git", isDirectory: true)
        try FileManager.default.createDirectory(at: gitDirectory, withIntermediateDirectories: true)

        #expect(try GitDirectoryResolver.resolveGitDirectory(for: root).standardizedFileURL == gitDirectory.standardizedFileURL)
    }

    @Test("resolves gitfile directory")
    func resolvesGitFileDirectory() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let realGitDirectory = root.appendingPathComponent("../linked-git", isDirectory: true).standardizedFileURL
        try FileManager.default.createDirectory(at: realGitDirectory, withIntermediateDirectories: true)
        try "gitdir: ../linked-git\n".write(to: root.appendingPathComponent(".git"), atomically: true, encoding: .utf8)

        #expect(try GitDirectoryResolver.resolveGitDirectory(for: root).standardizedFileURL == realGitDirectory)
    }

    @Test("reads symbolic head")
    func readsSymbolicHead() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let gitDirectory = root.appendingPathComponent(".git", isDirectory: true)
        let headsDirectory = gitDirectory.appendingPathComponent("refs/heads", isDirectory: true)
        try FileManager.default.createDirectory(at: headsDirectory, withIntermediateDirectories: true)
        try "ref: refs/heads/main\n".write(to: gitDirectory.appendingPathComponent("HEAD"), atomically: true, encoding: .utf8)
        try "abc123\n".write(to: headsDirectory.appendingPathComponent("main"), atomically: true, encoding: .utf8)

        #expect(GitDirectoryResolver.readHeadHash(gitDirectory: gitDirectory) == "abc123")
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitWatcherPluginTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
