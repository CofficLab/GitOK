@testable import GitMergePlugin
import Foundation
import KitGitOKCore
import Testing

@Suite("GitMergePlugin")
struct GitMergePluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitMergePlugin.metadata.id == "GitMergePlugin")
        #expect(GitSmartMergePlugin.metadata.iconName == "arrow.merge")
        #expect(GitSmartMergePlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitMergePlugin.metadata.displayName.isEmpty == false)
        #expect(GitMergePlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(!GitMergePlugin.statusBarTrailingItems(context: context).isEmpty)
    }
}
