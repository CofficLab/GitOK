@testable import PluginBranch
import Testing

@Suite("PluginBranch")
struct BranchPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(BranchPlugin.metadata.id == "BranchPlugin")
        #expect(BranchPlugin.metadata.iconName == "arrow.triangle.branch")
        #expect(BranchPlugin.metadata.allowUserToggle == true)
        #expect(BranchPlugin.metadata.defaultEnabled == true)
        #expect(BranchPlugin.metadata.order == 22)
        #expect(BranchPlugin.metadata.tableName == "GitBranch")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(BranchPlugin.metadata.displayName.isEmpty == false)
        #expect(BranchPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes toolbar and status bar views")
    func contributesViews() {
        #expect(BranchPlugin.shared.toolBarTrailingView() != nil)
        #expect(BranchPlugin.shared.statusBarLeadingView(context: GitOKPluginContext()) != nil)
    }
}
