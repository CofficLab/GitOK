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

    @Test("刷新冲突状态时保留当前文件，避免列表闪烁")
    func refreshKeepsCurrentConflictFilesVisible() {
        let viewModel = GitConflictResolverViewModel()
        let projectURL = URL(fileURLWithPath: "/tmp/project")

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: ["README.md"],
            isOperationInProgress: true,
            isCherryPicking: false
        )
        viewModel.beginLoading(projectURL: projectURL)

        #expect(viewModel.isLoading)
        #expect(viewModel.conflictedFiles == ["README.md"])
        #expect(viewModel.isOperationInProgress)
        #expect(viewModel.hasLoadedSnapshot)
    }

    @Test("单个文件解决后显示待暂存状态")
    func resolvedFileIsShownSeparatelyFromUnresolvedFiles() {
        let viewModel = GitConflictResolverViewModel()
        let projectURL = URL(fileURLWithPath: "/tmp/project")

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: ["README.md", "Sources/App.swift"],
            isOperationInProgress: true,
            isCherryPicking: false,
            resolvedFiles: ["README.md"]
        )

        #expect(viewModel.conflictedFiles == ["README.md", "Sources/App.swift"])
        #expect(viewModel.resolvedConflictFiles == ["README.md"])
        #expect(viewModel.isConflictFileResolved("README.md"))
        #expect(!viewModel.isConflictFileResolved("Sources/App.swift"))

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: ["Sources/App.swift"],
            isOperationInProgress: true,
            isCherryPicking: false
        )

        #expect(viewModel.displayedConflictFiles == ["Sources/App.swift", "README.md"])
        #expect(viewModel.isConflictFileResolved("README.md"))
    }

    @Test("合并已无冲突但仍未完成时自动打开引导弹层")
    func pendingMergeWithoutConflictsPresentsResolver() {
        let viewModel = GitConflictResolverViewModel()
        let projectURL = URL(fileURLWithPath: "/tmp/project")

        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: [],
            isOperationInProgress: true,
            isCherryPicking: false
        )

        #expect(viewModel.isPresented)

        viewModel.dismiss()
        viewModel.update(
            projectURL: projectURL,
            conflictedFiles: [],
            isOperationInProgress: true,
            isCherryPicking: false
        )

        #expect(!viewModel.isPresented)
    }

    @Test("跨插件展示请求会打开冲突解决界面")
    func presentationRequestOpensResolver() {
        let viewModel = GitConflictResolverViewModel()
        viewModel.update(
            projectURL: URL(fileURLWithPath: "/tmp/project"),
            conflictedFiles: ["README.md"],
            isOperationInProgress: true,
            isCherryPicking: false
        )
        viewModel.dismiss()

        let presenter = GitConflictResolutionPresenter(
            viewModel: viewModel,
            requestReload: {}
        )
        presenter.requestPresentation()

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
