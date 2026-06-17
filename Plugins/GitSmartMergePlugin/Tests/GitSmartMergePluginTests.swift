@testable import GitSmartMergePlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("GitSmartMergePlugin")
struct GitSmartMergePluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitSmartMergePlugin.metadata.id == "GitSmartMergePlugin")
        #expect(GitSmartMergePlugin.metadata.iconName == "arrow.merge")
        #expect(GitSmartMergePlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitSmartMergePlugin.metadata.displayName.isEmpty == false)
        #expect(GitSmartMergePlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(!GitSmartMergePlugin.statusBarTrailingItems(context: context).isEmpty)
    }
}
