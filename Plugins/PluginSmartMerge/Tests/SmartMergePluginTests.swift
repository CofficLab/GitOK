@testable import PluginSmartMerge
import Foundation
import GitOKCoreKit
import Testing

@Suite("PluginSmartMerge")
struct SmartMergePluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(SmartMergePlugin.metadata.id == "SmartMergePlugin")
        #expect(SmartMergePlugin.metadata.iconName == "arrow.merge")
        #expect(SmartMergePlugin.metadata.allowUserToggle == true)
        #expect(SmartMergePlugin.metadata.defaultEnabled == true)
        #expect(SmartMergePlugin.metadata.tableName == "GitMerge")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(SmartMergePlugin.metadata.displayName.isEmpty == false)
        #expect(SmartMergePlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(SmartMergePlugin.shared.statusBarTrailingView(context: context) != nil)
    }
}
