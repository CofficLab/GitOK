@testable import PluginConflictResolver
import GitCoreKit
import Testing

@Suite("PluginConflictResolver")
struct ConflictResolverPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(ConflictResolverPlugin.metadata.id == "ConflictResolverPlugin")
        #expect(ConflictResolverPlugin.metadata.iconName == "exclamationmark.triangle")
        #expect(ConflictResolverPlugin.metadata.allowUserToggle == false)
        #expect(ConflictResolverPlugin.metadata.defaultEnabled == true)
        #expect(ConflictResolverPlugin.metadata.tableName == "GitConflictResolver")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(ConflictResolverPlugin.metadata.displayName.isEmpty == false)
        #expect(ConflictResolverPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        #expect(ConflictResolverPlugin.shared.statusBarTrailingView(context: GitOKPluginContext()) != nil)
    }

    @Test("state builder prioritizes unresolved files")
    func stateBuilder() {
        let files = ConflictResolverStateBuilder.mergeFiles(
            unresolvedPaths: ["a.txt"],
            statusEntries: [
                GitStatusEntry(path: "a.txt", indexStatus: " ", workTreeStatus: "M"),
                GitStatusEntry(path: "b.txt", indexStatus: "M", workTreeStatus: " ")
            ]
        )

        #expect(files == [
            GitMergeFile(path: "a.txt", state: .unresolved),
            GitMergeFile(path: "b.txt", state: .staged)
        ])
    }
}
