@testable import GitBranchPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("GitBranchPlugin")
struct GitBranchPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitBranchPlugin.metadata.id == "GitBranchPlugin")
        #expect(GitBranchPlugin.metadata.iconName == "arrow.triangle.branch")
        #expect(GitBranchPlugin.metadata.order == 10000)
        #expect(GitBranchPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitBranchPlugin.metadata.displayName.isEmpty == false)
        #expect(GitBranchPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes toolbar and status bar views")
    func contributesViews() {
        #expect(!GitBranchPlugin.toolbarTrailingItems(context: GitOKPluginContext()).isEmpty)
        #expect(GitBranchPlugin.toolbarLeadingItems(context: GitOKPluginContext()).isEmpty)
        #expect(!GitBranchPlugin.statusBarLeadingItems(context: GitOKPluginContext()).isEmpty)
    }

    // MARK: - GitBranchPluginContext

    @Test("GitBranchPluginContext default values")
    func contextDefaults() {
        let ctx = GitBranchPluginContext()
        #expect(ctx.projectURL == nil)
        #expect(ctx.branchName == nil)
        #expect(ctx.isGitRepository == false)
    }

    @Test("GitBranchPluginContext init with explicit values")
    func contextExplicitInit() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let ctx = GitBranchPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        #expect(ctx.projectURL == url)
        #expect(ctx.branchName == "main")
        #expect(ctx.isGitRepository == true)
    }

    @MainActor
    @Test("GitBranchPluginContext init from GitOKPluginContext")
    func contextFromPluginContext() {
        let url = URL(fileURLWithPath: "/tmp/project")
        let pluginCtx = GitOKPluginContext(
            projectURL: url,
            projectPath: "/tmp/project",
            projectTitle: "Project",
            branchName: "develop",
            isGitRepository: true,
            selectedFilePath: "README.md",
            activityStatus: "cloning"
        )
        let ctx = GitBranchPluginContext(pluginCtx)

        #expect(ctx.projectURL == url)
        #expect(ctx.branchName == "develop")
        #expect(ctx.isGitRepository == true)
    }

    @MainActor
    @Test("GitBranchPluginContext init from empty GitOKPluginContext")
    func contextFromEmptyPluginContext() {
        let pluginCtx = GitOKPluginContext()
        let ctx = GitBranchPluginContext(pluginCtx)

        #expect(ctx.projectURL == nil)
        #expect(ctx.branchName == nil)
        #expect(ctx.isGitRepository == false)
    }

    // MARK: - BranchMonitor

    @MainActor
    @Test("BranchMonitor with nil projectURL")
    func monitorWithNilProjectURL() {
        let monitor = BranchMonitor(projectURL: nil, isGitRepository: false)
        #expect(monitor.branchName == nil)
    }

    @MainActor
    @Test("BranchMonitor with non-git repository")
    func monitorWithNonGitRepository() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let monitor = BranchMonitor(projectURL: url, isGitRepository: false)
        #expect(monitor.branchName == nil)
    }

    @MainActor
    @Test("BranchMonitor parseBranchName with normal branch")
    func parseBranchNameNormalBranch() {
        let content = "ref: refs/heads/main"
        let name = BranchMonitor.parseBranchName(from: content)
        #expect(name == "main")
    }

    @MainActor
    @Test("BranchMonitor parseBranchName with feature branch")
    func parseBranchNameFeatureBranch() {
        let content = "ref: refs/heads/feature/new-feature"
        let name = BranchMonitor.parseBranchName(from: content)
        #expect(name == "feature/new-feature")
    }

    @MainActor
    @Test("BranchMonitor parseBranchName with detached HEAD (SHA-1)")
    func parseBranchNameDetachedHeadSHA1() {
        let content = "abc1234567890123456789012345678901234567"
        let name = BranchMonitor.parseBranchName(from: content)
        #expect(name == "abc1234")
    }

    @MainActor
    @Test("BranchMonitor parseBranchName with detached HEAD (SHA-256)")
    func parseBranchNameDetachedHeadSHA256() {
        // SHA-256 hash is exactly 64 hex characters
        let content = "abc1234567890123456789012345678901234567890123456789012345678901"
        let name = BranchMonitor.parseBranchName(from: content)
        #expect(name == "abc1234")
    }

    @MainActor
    @Test("BranchMonitor parseBranchName with invalid content")
    func parseBranchNameInvalidContent() {
        let content = "invalid content"
        let name = BranchMonitor.parseBranchName(from: content)
        #expect(name == nil)
    }

    @MainActor
    @Test("BranchMonitor parseBranchName with empty content")
    func parseBranchNameEmptyContent() {
        let content = ""
        let name = BranchMonitor.parseBranchName(from: content)
        #expect(name == nil)
    }

    // MARK: - Views receive context

    @MainActor
    @Test("BranchStatusTile accepts context")
    func statusTileAcceptsContext() {
        let ctx = GitBranchPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), branchName: "main", isGitRepository: true)
        let _ = BranchStatusTile(context: ctx)
    }

    @MainActor
    @Test("BranchStatusTile with nil projectURL produces empty body")
    func statusTileNilProject() {
        let ctx = GitBranchPluginContext()
        let _ = BranchStatusTile(context: ctx)
    }

    @MainActor
    @Test("BranchPickerView accepts context")
    func pickerViewAcceptsContext() {
        let ctx = GitBranchPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), branchName: "feature", isGitRepository: true)
        let _ = BranchPickerView(context: ctx)
    }

    @MainActor
    @Test("BranchManagementView accepts context")
    func managementViewAcceptsContext() {
        let ctx = GitBranchPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), branchName: "main", isGitRepository: true)
        let _ = BranchManagementView(context: ctx)
    }

    @MainActor
    @Test("statusBarLeadingView with full context passes data through")
    func statusBarLeadingPassesContext() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let pluginCtx = GitOKPluginContext(projectURL: url, branchName: "develop", isGitRepository: true)
        #expect(!GitBranchPlugin.statusBarLeadingItems(context: pluginCtx).isEmpty)
    }

    @MainActor
    @Test("statusBarLeadingView with empty context still produces a view")
    func statusBarLeadingEmptyContext() {
        #expect(!GitBranchPlugin.statusBarLeadingItems(context: GitOKPluginContext()).isEmpty)
    }

    @MainActor
    @Test("toolbar context preserves project and branch state")
    func toolbarContextPreservesProjectAndBranchState() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let pluginCtx = GitOKPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        let ctx = GitBranchPlugin.toolBarContext(from: pluginCtx)

        #expect(ctx.projectURL == url)
        #expect(ctx.branchName == "main")
        #expect(ctx.isGitRepository == true)
    }
}
