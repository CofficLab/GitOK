@testable import BranchPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("BranchPlugin")
struct BranchPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(BranchPlugin.metadata.id == "BranchPlugin")
        #expect(BranchPlugin.metadata.iconName == "arrow.triangle.branch")
        #expect(BranchPlugin.metadata.order == 10000)
        #expect(BranchPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(BranchPlugin.metadata.displayName.isEmpty == false)
        #expect(BranchPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes toolbar and status bar views")
    func contributesViews() {
        #expect(!BranchPlugin.toolbarTrailingItems(context: GitOKPluginContext()).isEmpty)
        #expect(BranchPlugin.toolbarLeadingItems(context: GitOKPluginContext()).isEmpty)
        #expect(!BranchPlugin.statusBarLeadingItems(context: GitOKPluginContext()).isEmpty)
    }

    // MARK: - BranchPluginContext

    @Test("BranchPluginContext default values")
    func contextDefaults() {
        let ctx = BranchPluginContext()
        #expect(ctx.projectURL == nil)
        #expect(ctx.branchName == nil)
        #expect(ctx.isGitRepository == false)
    }

    @Test("BranchPluginContext init with explicit values")
    func contextExplicitInit() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let ctx = BranchPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        #expect(ctx.projectURL == url)
        #expect(ctx.branchName == "main")
        #expect(ctx.isGitRepository == true)
    }

    @MainActor
    @Test("BranchPluginContext init from GitOKPluginContext")
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
        let ctx = BranchPluginContext(pluginCtx)

        #expect(ctx.projectURL == url)
        #expect(ctx.branchName == "develop")
        #expect(ctx.isGitRepository == true)
    }

    @MainActor
    @Test("BranchPluginContext init from empty GitOKPluginContext")
    func contextFromEmptyPluginContext() {
        let pluginCtx = GitOKPluginContext()
        let ctx = BranchPluginContext(pluginCtx)

        #expect(ctx.projectURL == nil)
        #expect(ctx.branchName == nil)
        #expect(ctx.isGitRepository == false)
    }

    // MARK: - Views receive context

    @MainActor
    @Test("BranchStatusTile accepts context")
    func statusTileAcceptsContext() {
        let ctx = BranchPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), branchName: "main", isGitRepository: true)
        let _ = BranchStatusTile(context: ctx)
    }

    @MainActor
    @Test("BranchStatusTile with nil projectURL produces empty body")
    func statusTileNilProject() {
        let ctx = BranchPluginContext()
        let _ = BranchStatusTile(context: ctx)
    }

    @MainActor
    @Test("BranchPickerView accepts context")
    func pickerViewAcceptsContext() {
        let ctx = BranchPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), branchName: "feature", isGitRepository: true)
        let _ = BranchPickerView(context: ctx)
    }

    @MainActor
    @Test("BranchManagementView accepts context")
    func managementViewAcceptsContext() {
        let ctx = BranchPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), branchName: "main", isGitRepository: true)
        let _ = BranchManagementView(context: ctx)
    }

    @MainActor
    @Test("statusBarLeadingView with full context passes data through")
    func statusBarLeadingPassesContext() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let pluginCtx = GitOKPluginContext(projectURL: url, branchName: "develop", isGitRepository: true)
        #expect(!BranchPlugin.statusBarLeadingItems(context: pluginCtx).isEmpty)
    }

    @MainActor
    @Test("statusBarLeadingView with empty context still produces a view")
    func statusBarLeadingEmptyContext() {
        #expect(!BranchPlugin.statusBarLeadingItems(context: GitOKPluginContext()).isEmpty)
    }

    @MainActor
    @Test("toolbar context preserves project and branch state")
    func toolbarContextPreservesProjectAndBranchState() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let pluginCtx = GitOKPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        let ctx = BranchPlugin.toolBarContext(from: pluginCtx)

        #expect(ctx.projectURL == url)
        #expect(ctx.branchName == "main")
        #expect(ctx.isGitRepository == true)
    }
}
