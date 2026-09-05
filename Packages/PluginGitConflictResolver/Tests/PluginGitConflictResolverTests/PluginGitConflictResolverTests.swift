import Foundation
import KernelCore
import Testing
@testable import PluginGitConflictResolver

@Suite("PluginGitConflictResolver")
@MainActor
struct PluginGitConflictResolverTests {

    @Test("检测到新的合并操作时自动打开，关闭后不会重复打扰")
    func conflictPresentationLifecycle() {
        let viewModel = GitConflictResolverViewModel()
        let projectURL = URL(fileURLWithPath: "/tmp/project")

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: ["README.md"],
            isOperationInProgress: true,
            isCherryPicking: false
        )
        #expect(viewModel.isPresented)

        viewModel.dismiss()
        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: ["README.md"],
            isOperationInProgress: true,
            isCherryPicking: false
        )
        #expect(!viewModel.isPresented)

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: [],
            isOperationInProgress: false,
            isCherryPicking: false
        )
        #expect(!viewModel.isPresented)
    }

    @Test("冲突全部暂存后保持弹层，允许继续合并")
    func resolvedFilesKeepPresentationUntilOperationEnds() {
        let viewModel = GitConflictResolverViewModel()
        let projectURL = URL(fileURLWithPath: "/tmp/project")

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: ["README.md"],
            isOperationInProgress: true,
            isCherryPicking: false
        )
        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: [],
            isOperationInProgress: true,
            isCherryPicking: false
        )

        #expect(viewModel.isPresented)
    }

    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = GitConflictResolverPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.git-conflict-resolver")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .alwaysOn)
    }
}
