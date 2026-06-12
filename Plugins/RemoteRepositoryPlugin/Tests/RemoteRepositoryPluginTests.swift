@testable import RemoteRepositoryPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("RemoteRepositoryPlugin")
struct RemoteRepositoryPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(RemoteRepositoryPlugin.metadata.id == "RemoteRepositoryPlugin")
        #expect(RemoteRepositoryPlugin.metadata.iconName == "network")
        #expect(RemoteRepositoryPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(RemoteRepositoryPlugin.metadata.displayName.isEmpty == false)
        #expect(RemoteRepositoryPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), isGitRepository: true)
        #expect(!RemoteRepositoryPlugin.statusBarTrailingItems(context: context).isEmpty)
    }
}
