import Foundation
import KernelCore
import Testing
@testable import PluginGitBranchStatus

@Suite("PluginGitBranchStatus")
@MainActor
struct PluginGitBranchStatusTests {

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitBranchStatusPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-branch-status")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }

    @Test("切换项目开始加载时清除旧分支名")
    func beginLoadingClearsPreviousBranch() {
        let viewModel = GitBranchStatusViewModel()
        viewModel.update(projectURL: URL(fileURLWithPath: "/tmp/old-project"), branch: "main")

        viewModel.beginLoading(projectURL: URL(fileURLWithPath: "/tmp/new-project"))

        #expect(viewModel.currentProjectURL?.path == "/tmp/new-project")
        #expect(viewModel.currentBranch == nil)
        #expect(viewModel.isLoading)
    }
}
