import Foundation
import KitGit
import Testing
@testable import PluginGitLibGit2

@Suite("PluginGitLibGit2")
struct PluginGitLibGit2Tests {
    @Test("LibGit2 插件作为内置必需后端并使用固定版本")
    @MainActor
    func metadata() {
        let plugin = GitLibGit2Plugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-libgit2")
        #expect(plugin.metadata.policy == .required)
    }

    @Test("cancellable list reads stop before entering LibGit2Swift")
    func cancellableListReadHonorsCancellation() {
        let cancellation = GitProcessCancellation()
        cancellation.cancel()
        let repository = URL(fileURLWithPath: "/missing/project")
        let backend = GitLibGit2Backend()

        #expect(throws: CancellationError.self) {
            try backend.loadCommits(
                in: repository,
                limit: 50,
                offset: 0,
                cancellation: cancellation
            )
        }
    }
}
