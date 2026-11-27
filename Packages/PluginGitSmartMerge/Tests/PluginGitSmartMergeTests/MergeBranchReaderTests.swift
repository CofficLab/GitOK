import Foundation
import KitGit
import Testing
@testable import PluginGitSmartMerge

@Suite("MergeBranchReader")
struct MergeBranchReaderTests {
    private let repository = URL(fileURLWithPath: "/tmp/merge-branch-reader-repo")

    @Test("CLI 可用且成功时使用 CLI 结果，不触发兜底")
    func prefersCLIWhenAvailable() throws {
        let fallbackCalls = Counter()
        let reader = MergeBranchReader(
            isCLIAvailable: { true },
            loadWithCLI: { _ in
                [GitBranchSummary(name: "main", isRemote: false, isCurrent: true)]
            },
            loadWithFallback: { _ in
                fallbackCalls.increment()
                return [GitBranchSummary(name: "dev", isRemote: false, isCurrent: true)]
            }
        )

        let branches = try reader.loadLocalBranches(in: repository)

        #expect(branches.map(\.name) == ["main"])
        #expect(fallbackCalls.count == 0)
    }

    @Test("CLI 不可用时回退后端")
    func fallsBackWhenCLIUnavailable() throws {
        let cliCalls = Counter()
        let reader = MergeBranchReader(
            isCLIAvailable: { false },
            loadWithCLI: { _ in
                cliCalls.increment()
                return [GitBranchSummary(name: "main", isRemote: false, isCurrent: true)]
            },
            loadWithFallback: { _ in
                [GitBranchSummary(name: "dev", isRemote: false, isCurrent: true)]
            }
        )

        let branches = try reader.loadLocalBranches(in: repository)

        #expect(branches.map(\.name) == ["dev"])
        #expect(cliCalls.count == 0)
    }

    @Test("CLI 执行失败时回退后端")
    func fallsBackWhenCLIThrows() throws {
        let reader = MergeBranchReader(
            isCLIAvailable: { true },
            loadWithCLI: { _ in throw GitProcessRunner.Error.gitUnavailable("missing") },
            loadWithFallback: { _ in
                [GitBranchSummary(name: "dev", isRemote: false, isCurrent: true)]
            }
        )

        let branches = try reader.loadLocalBranches(in: repository)

        #expect(branches.map(\.name) == ["dev"])
    }

    @Test("CLI 返回空列表时回退后端")
    func fallsBackWhenCLIReturnsEmpty() throws {
        let reader = MergeBranchReader(
            isCLIAvailable: { true },
            loadWithCLI: { _ in [] },
            loadWithFallback: { _ in
                [GitBranchSummary(name: "dev", isRemote: false, isCurrent: true)]
            }
        )

        let branches = try reader.loadLocalBranches(in: repository)

        #expect(branches.map(\.name) == ["dev"])
    }

    @Test("CLI 与后端都失败时抛出后端的错误")
    func propagatesFallbackError() {
        struct Failure: Error {}
        let reader = MergeBranchReader(
            isCLIAvailable: { true },
            loadWithCLI: { _ in throw GitProcessRunner.Error.gitUnavailable("missing") },
            loadWithFallback: { _ in throw Failure() }
        )

        #expect(throws: Failure.self) {
            _ = try reader.loadLocalBranches(in: repository)
        }
    }

    @Test("CLI 读取真实仓库的本地分支并标记当前分支")
    func cliLoaderReadsRealRepositoryBranches() throws {
        try #require(GitProcessRunner.isAvailable)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MergeBranchReader-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try GitProcessRunner.run(["init", "-q", "-b", "main"], in: directory)
        _ = try GitProcessRunner.run(
            ["-c", "user.name=GitOK Test", "-c", "user.email=test@example.com", "commit", "--allow-empty", "-m", "init"],
            in: directory
        )
        _ = try GitProcessRunner.run(["branch", "dev"], in: directory)

        let reader = MergeBranchReader.live(git: GitSmartMergeDoubles.Git())
        let branches = try reader.loadWithCLI(directory)

        #expect(branches == [
            GitBranchSummary(name: "dev", isRemote: false, isCurrent: false),
            GitBranchSummary(name: "main", isRemote: false, isCurrent: true),
        ])
    }

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0

        func increment() {
            lock.lock()
            value += 1
            lock.unlock()
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
    }
}