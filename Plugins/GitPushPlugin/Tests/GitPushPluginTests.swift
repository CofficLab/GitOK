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
        #expect(GitPushPlugin.metadata.allowUserToggle == false)
        #expect(GitPushPlugin.metadata.defaultEnabled == false)
        #expect(GitPushPlugin.metadata.tableName == "GitPush")
    }

    @Test("localized display name resolves")
    func localizedDisplayName() {
        #expect(GitPushPlugin.metadata.displayName.isEmpty == false)
    }

    @Test("plugin contributes toolbar trailing view")
    @MainActor
    func toolbarTrailingView() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        #expect(GitPushPlugin.shared.toolBarTrailingView(context: context) != nil)
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
