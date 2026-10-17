import Foundation
import Testing

@testable import PluginGitIgnore

/// 创建一个仅含指定条目的临时目录，并在测试结束后清理。
private func makeTempDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("PluginGitIgnoreTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Suite("GitIgnoreFile")
struct GitIgnoreFileTests {

    @Test("定位仓库根目录下的 .gitignore 路径")
    func resolvesURL() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = GitIgnoreFile(repositoryRoot: root)

        #expect(file.url?.lastPathComponent == ".gitignore")
        #expect(file.url?.deletingLastPathComponent() == root)
    }

    @Test("无仓库根目录时路径为 nil")
    func urlIsNilWithoutRoot() {
        #expect(GitIgnoreFile(repositoryRoot: nil).url == nil)
    }

    @Test("文件存在时 exists 为 true")
    func existsWhenFilePresent() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try "#build/\n*.log".write(
            to: root.appendingPathComponent(".gitignore"),
            atomically: true,
            encoding: .utf8
        )

        #expect(GitIgnoreFile(repositoryRoot: root).exists)
    }

    @Test("文件缺失时 exists 为 false")
    func notExistsWhenFileMissing() {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(GitIgnoreFile(repositoryRoot: root).exists == false)
    }

    @Test("无仓库根目录时 exists 为 false")
    func notExistsWithoutRoot() {
        #expect(GitIgnoreFile(repositoryRoot: nil).exists == false)
    }

    @Test("读取存在的 .gitignore 内容")
    func readsContent() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let expected = "# Build\nbuild/\n.DS_Store\n"
        try expected.write(
            to: root.appendingPathComponent(".gitignore"),
            atomically: true,
            encoding: .utf8
        )

        #expect(GitIgnoreFile(repositoryRoot: root).read() == expected)
    }

    @Test("文件缺失时读取回退为空字符串")
    func readsEmptyWhenMissing() {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(GitIgnoreFile(repositoryRoot: root).read() == "")
    }

    @Test("无仓库根目录时读取回退为空字符串")
    func readsEmptyWithoutRoot() {
        #expect(GitIgnoreFile(repositoryRoot: nil).read() == "")
    }

    @Test("非 UTF-8 内容读取失败时回退为空字符串")
    func readsEmptyOnEncodingFailure() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        // 非法 UTF-8 字节序列，`String(contentsOf:encoding:.utf8)` 必然抛错。
        let invalid = Data([0xFF, 0xFE, 0xFD, 0xC0])
        try invalid.write(to: root.appendingPathComponent(".gitignore"))

        #expect(GitIgnoreFile(repositoryRoot: root).read() == "")
    }
}
