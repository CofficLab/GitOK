import Foundation
import Testing

@testable import PluginGitIgnore

private func makeTempDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("PluginGitIgnoreViewerTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Suite("GitIgnoreViewerModel")
@MainActor
struct GitIgnoreViewerModelTests {

    @Test("初始状态为加载中且内容为空")
    func startsLoading() {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = GitIgnoreViewerModel(file: GitIgnoreFile(repositoryRoot: root))

        #expect(model.isLoading)
        #expect(model.content == "")
    }

    @Test("加载成功后结束加载态并填充内容")
    func loadPopulatesContent() async throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try "*.log\n.DS_Store\n".write(
            to: root.appendingPathComponent(".gitignore"),
            atomically: true,
            encoding: .utf8
        )
        let model = GitIgnoreViewerModel(file: GitIgnoreFile(repositoryRoot: root))

        await model.load()

        #expect(model.isLoading == false)
        #expect(model.content == "*.log\n.DS_Store\n")
    }

    @Test("文件缺失时也结束加载态，内容为空")
    func loadFinishesWhenMissing() async {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = GitIgnoreViewerModel(file: GitIgnoreFile(repositoryRoot: root))

        await model.load()

        #expect(model.isLoading == false)
        #expect(model.content == "")
    }

    @Test("无仓库根目录时也结束加载态，内容为空")
    func loadFinishesWithoutRoot() async {
        let model = GitIgnoreViewerModel(file: GitIgnoreFile(repositoryRoot: nil))

        await model.load()

        #expect(model.isLoading == false)
        #expect(model.content == "")
    }

    @Test("重复加载是幂等的，不会残留加载态")
    func repeatedLoadIsIdempotent() async throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = GitIgnoreViewerModel(file: GitIgnoreFile(repositoryRoot: root))

        await model.load()
        try "*.tmp".write(
            to: root.appendingPathComponent(".gitignore"),
            atomically: true,
            encoding: .utf8
        )
        await model.load()

        #expect(model.isLoading == false)
        #expect(model.content == "*.tmp")
    }
}
