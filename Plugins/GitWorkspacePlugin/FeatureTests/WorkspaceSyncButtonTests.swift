@testable import GitWorkspaceCore
import Testing

@Suite("WorkspaceSyncButton")
struct WorkspaceSyncButtonTests {
    @Test("primary action follows remote tracking state")
    func primaryAction() {
        #expect(WorkspaceSyncPrimaryAction.primaryAction(for: .init(ahead: 0, behind: 0, hasUpstream: true)) == .fetch)
        #expect(WorkspaceSyncPrimaryAction.primaryAction(for: .init(ahead: 0, behind: 1, hasUpstream: true)) == .pull)
        #expect(WorkspaceSyncPrimaryAction.primaryAction(for: .init(ahead: 1, behind: 0, hasUpstream: true)) == .push)
        #expect(WorkspaceSyncPrimaryAction.primaryAction(for: .init(ahead: 0, behind: 0, hasUpstream: false)) == .push)
    }

    @Test("badge text summarizes ahead behind status")
    func badgeText() {
        #expect(WorkspaceSyncPrimaryAction.badgeText(for: .init(ahead: 0, behind: 0, hasUpstream: true)) == nil)
        #expect(WorkspaceSyncPrimaryAction.badgeText(for: .init(ahead: 2, behind: 0, hasUpstream: true)) == "↑2")
        #expect(WorkspaceSyncPrimaryAction.badgeText(for: .init(ahead: 0, behind: 3, hasUpstream: true)) == "↓3")
        #expect(WorkspaceSyncPrimaryAction.badgeText(for: .init(ahead: 2, behind: 3, hasUpstream: true)) == "↑2 ↓3")
        #expect(WorkspaceSyncPrimaryAction.badgeText(for: .init(ahead: 2, behind: 3, hasUpstream: false)) == nil)
    }

    @Test("primary title distinguishes unpublished branches")
    func primaryTitle() {
        #expect(WorkspaceSyncPrimaryAction.title(for: .init(ahead: 1, behind: 0, hasUpstream: true)) == "Push origin")
        #expect(WorkspaceSyncPrimaryAction.title(for: .init(ahead: 0, behind: 0, hasUpstream: false)) == "Publish branch")
    }
}
