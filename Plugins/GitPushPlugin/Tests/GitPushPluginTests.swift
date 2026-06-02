@testable import GitPushPlugin
import Foundation
import GitOKCoreKit
import Testing

@Suite("GitPushPlugin")
struct GitPushPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitPushPlugin.metadata.id == "GitPushPlugin")
        #expect(GitPushPlugin.metadata.iconName == "arrow.triangle.2.circlepath")
        #expect(GitPushPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized display name resolves")
    func localizedDisplayName() {
        #expect(GitPushPlugin.metadata.displayName.isEmpty == false)
    }

    @Test("localization catalog contains active translations")
    func localizationCatalog() throws {
        let url = try #require(GitPushPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        let data = try Data(contentsOf: url)
        let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = try #require(catalog?["strings"] as? [String: Any])

        #expect(strings["根据分支状态执行 Fetch、Pull 或 Push"] == nil)

        let fetchOrigin = try #require(strings["Fetch origin"] as? [String: Any])
        #expect(fetchOrigin["extractionState"] == nil)

        let localizations = try #require(fetchOrigin["localizations"] as? [String: Any])
        let simplified = try #require(localizations["zh-Hans"] as? [String: Any])
        let stringUnit = try #require(simplified["stringUnit"] as? [String: Any])
        #expect(stringUnit["value"] as? String == "获取 origin")
    }

    @Test("plugin contributes toolbar trailing view")
    @MainActor
    func toolbarTrailingView() {
        let context = GitOKPluginContext(
            projectURL: URL(fileURLWithPath: "/tmp/test"),
            isGitRepository: true
        )
        #expect(GitPushPlugin.shared.toolBarTrailingView(context: context) != nil)
    }

    @Test("plugin hides toolbar view outside git repositories")
    @MainActor
    func hidesOutsideGitRepository() {
        let context = GitOKPluginContext(
            projectURL: URL(fileURLWithPath: "/tmp/test"),
            isGitRepository: false
        )
        #expect(GitPushPlugin.shared.toolBarTrailingView(context: context) == nil)
    }

    @Test("primary action follows remote tracking state")
    func primaryAction() {
        #expect(GitPushPrimaryAction.primaryAction(for: .init(ahead: 0, behind: 0, hasUpstream: true)) == .fetch)
        #expect(GitPushPrimaryAction.primaryAction(for: .init(ahead: 0, behind: 1, hasUpstream: true)) == .pull)
        #expect(GitPushPrimaryAction.primaryAction(for: .init(ahead: 1, behind: 0, hasUpstream: true)) == .push)
        #expect(GitPushPrimaryAction.primaryAction(for: .init(ahead: 0, behind: 0, hasUpstream: false)) == .push)
    }

    @Test("badge text summarizes ahead behind status")
    func badgeText() {
        #expect(GitPushPrimaryAction.badgeText(for: .init(ahead: 0, behind: 0, hasUpstream: true)) == nil)
        #expect(GitPushPrimaryAction.badgeText(for: .init(ahead: 2, behind: 0, hasUpstream: true)) == "↑2")
        #expect(GitPushPrimaryAction.badgeText(for: .init(ahead: 0, behind: 3, hasUpstream: true)) == "↓3")
        #expect(GitPushPrimaryAction.badgeText(for: .init(ahead: 2, behind: 3, hasUpstream: true)) == "↑2 ↓3")
        #expect(GitPushPrimaryAction.badgeText(for: .init(ahead: 2, behind: 3, hasUpstream: false)) == nil)
    }
}
