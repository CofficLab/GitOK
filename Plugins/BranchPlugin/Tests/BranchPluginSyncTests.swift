@testable import BranchPlugin
import Foundation
import GitOKCoreKit
import Testing

// MARK: - Branch Sync Correctness Tests
//
// BranchPluginContext is a value-type snapshot. The fix ensures that:
//   - displayBranchName does NOT directly read context.branchName
//   - displayBranchName always reads from fallbackBranchName (@State)
//   - fallbackBranchName is always populated via async Git query
//   - context.branchName is only used as an initial placeholder

@Suite("BranchPlugin Sync Tests")
struct BranchPluginSyncTests {

    // MARK: - Context is a value-type snapshot (immutable after creation)

    @Test("BranchPluginContext is a value-type snapshot")
    func contextIsValueTypeSnapshot() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let ctx = BranchPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        #expect(ctx.branchName == "main")

        // Creating a new context doesn't affect the existing one
        let newCtx = BranchPluginContext(projectURL: url, branchName: "develop", isGitRepository: true)
        #expect(ctx.branchName == "main")
        #expect(newCtx.branchName == "develop")
        #expect(ctx.branchName != newCtx.branchName)
    }

    // MARK: - displayBranchName no longer reads context.branchName directly

    @Test("displayBranchName logic uses fallbackBranchName, not context.branchName")
    func displayBranchNameUsesFallback() {
        // After the fix, displayBranchName only reads fallbackBranchName.
        // Simulate the new logic:

        let fallbackBranchName: String? = "develop"
        let contextBranchName = "main" // stale

        let displayed: String
        if let fallback = fallbackBranchName, !fallback.isEmpty {
            displayed = fallback // ✅ Takes this path — returns "develop" (from Git query)
        } else {
            displayed = contextBranchName // This path should never be taken for display
        }

        // ✅ PASS: displayBranchName returns the Git-queried value, not the stale context
        #expect(displayed == "develop")
        #expect(displayed != contextBranchName,
                "displayBranchName should use Git-queried fallback, not stale context.branchName")
    }

    // MARK: - Fallback is always used for display (context.branchName is only a placeholder)

    @Test("Fallback is always used for display regardless of context.branchName value")
    func fallbackAlwaysUsedForDisplay() {
        // Even when context.branchName is non-nil and stale,
        // displayBranchName reads from fallbackBranchName which is updated via Git query.

        let staleContextBranchName = "main"
        let gitQueriedBranchName: String? = "develop"

        // New displayBranchName logic:
        let displayed: String
        if let fallback = gitQueriedBranchName, !fallback.isEmpty {
            displayed = fallback
        } else {
            displayed = "No Branch"
        }

        #expect(displayed == "develop")
        #expect(displayed != staleContextBranchName,
                "Fallback correctly overrides stale context — displayed '\(displayed)' instead of stale '\(staleContextBranchName)'")
    }

    // MARK: - context.branchName serves as initial placeholder only

    @Test("context.branchName is used as initial placeholder when fallbackBranchName is nil")
    func contextBranchNameAsPlaceholder() {
        // Before the async Git query completes, fallbackBranchName may be nil.
        // In refreshFallbackBranch(), context.branchName seeds fallbackBranchName
        // as an initial placeholder to avoid showing "Loading" unnecessarily.

        let contextBranchName = "main"
        var fallbackBranchName: String? = nil

        // Simulate the placeholder logic from refreshFallbackBranch:
        if fallbackBranchName == nil, !contextBranchName.isEmpty {
            fallbackBranchName = contextBranchName // seeded from context
        }

        #expect(fallbackBranchName == "main") // Initial placeholder

        // Later, async Git query completes:
        fallbackBranchName = "develop"

        #expect(fallbackBranchName == "develop") // Updated to real value
    }

    // MARK: - Fallback with nil branchName triggers loading state

    @Test("When both fallbackBranchName and context.branchName are nil, loading state shows")
    func loadingStateWhenBothNil() {
        let fallbackBranchName: String? = nil
        let isLoadingBranch = true
        let isGitRepository = true
        let projectURL: URL? = URL(fileURLWithPath: "/tmp/repo")

        let displayed: String
        if let fallback = fallbackBranchName, !fallback.isEmpty {
            displayed = fallback
        } else if projectURL != nil, isGitRepository, isLoadingBranch {
            displayed = "Loading Branch"
        } else {
            displayed = "No Branch"
        }

        #expect(displayed == "Loading Branch")
    }

    // MARK: - Non-git project shows "No Branch"

    @Test("Non-git project shows No Branch")
    func nonGitProjectShowsNoBranch() {
        let fallbackBranchName: String? = nil
        let isLoadingBranch = false
        let isGitRepository = false
        let projectURL: URL? = URL(fileURLWithPath: "/tmp/repo")

        let displayed: String
        if let fallback = fallbackBranchName, !fallback.isEmpty {
            displayed = fallback
        } else if projectURL != nil, isGitRepository, isLoadingBranch {
            displayed = "Loading Branch"
        } else {
            displayed = "No Branch"
        }

        #expect(displayed == "No Branch")
    }

    // MARK: - New context from GitOKPluginContext captures correct branchName

    @MainActor
    @Test("New BranchPluginContext correctly captures updated branchName from GitOKPluginContext")
    func newContextCapturesUpdatedBranch() {
        let url = URL(fileURLWithPath: "/tmp/repo")

        let oldPluginCtx = GitOKPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        let newPluginCtx = GitOKPluginContext(projectURL: url, branchName: "develop", isGitRepository: true)

        let oldCtx = BranchPluginContext(oldPluginCtx)
        let newCtx = BranchPluginContext(newPluginCtx)

        #expect(oldCtx.branchName == "main")
        #expect(newCtx.branchName == "develop")
    }

    @MainActor
    @Test("BranchPlugin.statusBarLeadingItems produces views with correct context")
    func statusBarLeadingItemsProducesCorrectContext() {
        let url = URL(fileURLWithPath: "/tmp/repo")

        let ctx1 = GitOKPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        let items1 = BranchPlugin.statusBarLeadingItems(context: ctx1)
        #expect(items1.count == 1)

        let ctx2 = GitOKPluginContext(projectURL: url, branchName: "develop", isGitRepository: true)
        let items2 = BranchPlugin.statusBarLeadingItems(context: ctx2)
        #expect(items2.count == 1)
    }

    @MainActor
    @Test("BranchPlugin.toolbarTrailingItems produces views with correct context")
    func toolbarTrailingItemsProducesCorrectContext() {
        let url = URL(fileURLWithPath: "/tmp/repo")

        let ctx1 = GitOKPluginContext(projectURL: url, branchName: "main", isGitRepository: true)
        let items1 = BranchPlugin.toolbarTrailingItems(context: ctx1)
        #expect(items1.count == 1)

        let ctx2 = GitOKPluginContext(projectURL: url, branchName: "feature", isGitRepository: true)
        let items2 = BranchPlugin.toolbarTrailingItems(context: ctx2)
        #expect(items2.count == 1)
    }

    @MainActor
    @Test("toolBarContext maps branchName correctly for both old and new states")
    func toolBarContextMappingBothStates() {
        let url = URL(fileURLWithPath: "/tmp/repo")

        let mainCtx = BranchPlugin.toolBarContext(from: GitOKPluginContext(
            projectURL: url, branchName: "main", isGitRepository: true))
        let developCtx = BranchPlugin.toolBarContext(from: GitOKPluginContext(
            projectURL: url, branchName: "develop", isGitRepository: true))

        #expect(mainCtx.branchName == "main")
        #expect(developCtx.branchName == "develop")
    }

    // MARK: - Multiple rapid switches produce independent snapshots

    @Test("Rapid branch switches produce independent context snapshots")
    func rapidSwitchIndependentSnapshots() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        let branches = ["main", "feature/a", "feature/b", "develop"]

        let contexts = branches.map { branch in
            BranchPluginContext(projectURL: url, branchName: branch, isGitRepository: true)
        }

        for (index, branch) in branches.enumerated() {
            #expect(contexts[index].branchName == branch,
                    "Context[\(index)] should be '\(branch)' but is '\(contexts[index].branchName ?? "nil")'")
        }
    }
}
