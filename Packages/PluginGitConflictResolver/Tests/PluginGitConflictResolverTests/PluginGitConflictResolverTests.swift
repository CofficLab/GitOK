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

    @Test("present 在操作未进行中时不打开弹层")
    func presentNoOpWhenOperationNotInProgress() {
        let viewModel = GitConflictResolverViewModel()
        viewModel.present()
        #expect(!viewModel.isPresented)
    }

    @Test("切换项目时清空旧冲突状态")
    func projectChangeResetsState() {
        let viewModel = GitConflictResolverViewModel()
        let a = URL(fileURLWithPath: "/tmp/project-a")
        let b = URL(fileURLWithPath: "/tmp/project-b")

        viewModel.update(projectURL: a, conflictedFiles: ["X.swift"], isOperationInProgress: true, isCherryPicking: false)
        #expect(viewModel.isPresented)

        viewModel.beginLoading(projectURL: b)
        #expect(viewModel.conflictedFiles.isEmpty)
        #expect(viewModel.resolvedConflictFiles.isEmpty)
        #expect(!viewModel.isOperationInProgress)
        #expect(!viewModel.isCherryPicking)
        #expect(!viewModel.hasLoadedSnapshot)
        #expect(viewModel.isLoading)
    }

    @Test("cherry-pick 操作标记 isCherryPicking")
    func cherryPickingFlagPropagates() {
        let viewModel = GitConflictResolverViewModel()
        viewModel.update(
            projectURL: URL(fileURLWithPath: "/tmp/p"),
            conflictedFiles: ["F"],
            isOperationInProgress: true,
            isCherryPicking: true
        )
        #expect(viewModel.isCherryPicking)
    }

    @Test("操作结束时清空 resolved 文件列表")
    func resolvedFilesClearedWhenOperationEnds() {
        let viewModel = GitConflictResolverViewModel()
        let p = URL(fileURLWithPath: "/tmp/p")
        viewModel.update(projectURL: p, conflictedFiles: ["A"], isOperationInProgress: true, isCherryPicking: false, resolvedFiles: ["A"])
        #expect(viewModel.resolvedConflictFiles == ["A"])
        viewModel.update(projectURL: p, conflictedFiles: [], isOperationInProgress: false, isCherryPicking: false)
        #expect(viewModel.resolvedConflictFiles.isEmpty)
    }

    @Test("正文区有文件行时继续入口移到顶部操作栏")
    func toolbarContinueActionAppearsWhenContentRowsExist() {
        let viewModel = GitConflictResolverViewModel()
        let p = URL(fileURLWithPath: "/tmp/p")

        // 还有未解决文件：正文区有内容，但还不能继续。
        viewModel.update(projectURL: p, conflictedFiles: ["A"], isOperationInProgress: true, isCherryPicking: false)
        #expect(viewModel.hasContentRows)
        #expect(viewModel.showsToolbarContinueAction)

        // 已解决但尚未暂存：仍然是正文区的文件行，继续入口留在操作栏。
        viewModel.update(
            projectURL: p,
            conflictedFiles: ["A"],
            isOperationInProgress: true,
            isCherryPicking: false,
            resolvedFiles: ["A"]
        )
        #expect(viewModel.hasContentRows)
        #expect(viewModel.showsToolbarContinueAction)
    }

    @Test("全部暂存后正文区为空，改由圆形按钮提供继续入口")
    func circularContinueButtonOnlyWhenContentRowsAreEmpty() {
        let viewModel = GitConflictResolverViewModel()
        let p = URL(fileURLWithPath: "/tmp/p")

        viewModel.update(projectURL: p, conflictedFiles: ["A"], isOperationInProgress: true, isCherryPicking: false)
        viewModel.update(projectURL: p, conflictedFiles: [], isOperationInProgress: true, isCherryPicking: false)

        // 上一轮的 resolved 文件仍作为「已暂存」行留在正文区。
        #expect(viewModel.displayedConflictFiles == ["A"])
        #expect(viewModel.showsToolbarContinueAction)

        // 新一轮快照不再报告该文件时，正文区清空，圆形按钮接管。
        let fresh = GitConflictResolverViewModel()
        fresh.update(projectURL: p, conflictedFiles: [], isOperationInProgress: true, isCherryPicking: false)
        #expect(!fresh.hasContentRows)
        #expect(!fresh.showsToolbarContinueAction)

        // 操作结束后不再提供继续入口。
        fresh.update(projectURL: p, conflictedFiles: [], isOperationInProgress: false, isCherryPicking: false)
        #expect(!fresh.showsToolbarContinueAction)
    }
}
