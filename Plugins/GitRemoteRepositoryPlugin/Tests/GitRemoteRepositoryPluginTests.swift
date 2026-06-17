@testable import GitRemoteRepositoryPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("GitRemoteRepositoryPlugin")
struct GitRemoteRepositoryPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitRemoteRepositoryPlugin.metadata.id == "GitRemoteRepositoryPlugin")
        #expect(GitRemoteRepositoryPlugin.metadata.iconName == "network")
        #expect(GitRemoteRepositoryPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(GitRemoteRepositoryPlugin.metadata.displayName.isEmpty == false)
        #expect(GitRemoteRepositoryPlugin.metadata.description.isEmpty == false)
    }

    @MainActor
    @Test("plugin contributes status bar trailing view")
    func statusBarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), isGitRepository: true)
        #expect(!GitRemoteRepositoryPlugin.statusBarTrailingItems(context: context).isEmpty)
    }
}
