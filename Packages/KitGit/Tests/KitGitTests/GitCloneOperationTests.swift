import Foundation
import Testing
@testable import KitGit

@Suite("GitCloneOperation")
struct GitCloneOperationTests {

    @Test("defaultRepositoryName 解析 https / ssh / 带 .git 后缀")
    func repositoryNameParsing() {
        #expect(GitCloneOperation.defaultRepositoryName(from: "https://github.com/owner/repo.git") == "repo")
        #expect(GitCloneOperation.defaultRepositoryName(from: "git@github.com:owner/my-app.git") == "my-app")
        #expect(GitCloneOperation.defaultRepositoryName(from: "https://host/group/sub/repo") == "repo")
        #expect(GitCloneOperation.defaultRepositoryName(from: "   ") == nil)
    }

    @Test("validateDestination 拒绝非空目录与已有 git 仓库")
    func validateDestinationRules() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitCloneTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }

        // 非空目录
        let nonEmpty = base.appendingPathComponent("nonempty")
        try FileManager.default.createDirectory(at: nonEmpty, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: nonEmpty.appendingPathComponent("a.txt"))
        #expect(throws: GitCloneError.self) {
            try GitCloneOperation.validateDestination(nonEmpty)
        }

        // 已存在 git 仓库
        let gitRepo = base.appendingPathComponent("existing")
        try FileManager.default.createDirectory(at: gitRepo.appendingPathComponent(".git"), withIntermediateDirectories: true)
        #expect(throws: GitCloneError.self) {
            try GitCloneOperation.validateDestination(gitRepo)
        }

        // 不存在的路径合法
        let fresh = base.appendingPathComponent("fresh")
        try GitCloneOperation.validateDestination(fresh)
    }

    @Test("clone 真实克隆本地仓库")
    func cloneLocalRepository() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitCloneE2E-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }

        // 源仓库
        let source = base.appendingPathComponent("source")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        _ = try GitProcessRunner.run(["init"], in: source)
        try Data("hello".utf8).write(to: source.appendingPathComponent("readme.txt"))
        _ = try GitProcessRunner.run(["add", "."], in: source)
        _ = try GitProcessRunner.run(["commit", "-m", "init"], in: source)

        // 克隆
        let destination = base.appendingPathComponent("cloned")
        let cloned = try GitCloneOperation.clone(remoteURL: source.path, destination: destination)
        #expect(cloned == destination)
        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("readme.txt").path))

        // 已是 git 仓库不可再克隆到该处
        #expect(throws: GitCloneError.self) {
            try GitCloneOperation.clone(remoteURL: source.path, destination: destination)
        }
    }
}
