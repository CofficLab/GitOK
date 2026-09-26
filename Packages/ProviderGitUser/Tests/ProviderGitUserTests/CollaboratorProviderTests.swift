import Foundation
import Testing
@testable import ProviderGitUser

@Suite("ProviderGitUser - Collaborator")
@MainActor
struct CollaboratorProviderTests {

    private func makeDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CollaboratorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("空存储返回空列表")
    func emptyStore() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        #expect(provider.loadCollaborators().isEmpty)
        #expect(provider.findDefault() == nil)
    }

    @Test("首个协作者自动成为默认")
    func firstIsDefault() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)

        let a = provider.addCollaborator(name: "Alice", email: "alice@example.com")
        let b = provider.addCollaborator(name: "Bob", email: "bob@example.com")

        #expect(provider.loadCollaborators().count == 2)
        #expect(a.isDefault == true)
        #expect(b.isDefault == false)
        #expect(provider.findDefault()?.id == a.id)
    }

    @Test("updateCollaborator 按 id 更新，未知 id 为空操作")
    func updateCollaborator() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        let a = provider.addCollaborator(name: "Alice", email: "old@example.com")

        var updated = a
        updated.email = "new@example.com"
        provider.updateCollaborator(updated)
        #expect(provider.loadCollaborators().first?.email == "new@example.com")

        // 未知 id 不影响。
        provider.updateCollaborator(Collaborator(name: "Ghost", email: "g@example.com"))
        #expect(provider.loadCollaborators().count == 1)
    }

    @Test("setDefault 切换唯一默认")
    func setDefaultIsUnique() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        let a = provider.addCollaborator(name: "Alice", email: "a@example.com")
        let b = provider.addCollaborator(name: "Bob", email: "b@example.com")

        provider.setDefault(b)
        #expect(provider.findDefault()?.id == b.id)
        #expect(provider.loadCollaborators().first { $0.id == a.id }?.isDefault == false)
    }

    @Test("删除默认后剩余第一条接任默认")
    func deleteDefaultHandsOver() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        let a = provider.addCollaborator(name: "Alice", email: "a@example.com")
        let b = provider.addCollaborator(name: "Bob", email: "b@example.com")

        provider.deleteCollaborator(id: a.id)
        let remaining = provider.loadCollaborators()
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == b.id)
        #expect(remaining.first?.isDefault == true)
        #expect(provider.findDefault()?.id == b.id)
    }

    @Test("删除非默认不影响默认")
    func deleteNonDefaultKeepsDefault() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        let a = provider.addCollaborator(name: "Alice", email: "a@example.com")
        let b = provider.addCollaborator(name: "Bob", email: "b@example.com")

        provider.deleteCollaborator(id: b.id)
        #expect(provider.loadCollaborators().count == 1)
        #expect(provider.findDefault()?.id == a.id)
    }

    @Test("clearAllDefaults 清除默认标记")
    func clearAllDefaults() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        provider.addCollaborator(name: "Alice", email: "a@example.com")
        provider.clearAllDefaults()
        // findDefault 退回第一条。
        #expect(provider.findDefault()?.name == "Alice")
        #expect(provider.loadCollaborators().allSatisfy { !$0.isDefault })
    }

    @Test("持久化后跨实例恢复")
    func persistenceAcrossInstances() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let first = DefaultCollaboratorProvider(directory: dir)
        first.addCollaborator(name: "Alice", email: "a@example.com")
        first.addCollaborator(name: "Bob", email: "b@example.com")

        let second = DefaultCollaboratorProvider(directory: dir)
        #expect(second.loadCollaborators().count == 2)
    }

    @Test("观察者在变更时收到通知，取消后不再收到")
    func observerNotifications() throws {
        let dir = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let provider = DefaultCollaboratorProvider(directory: dir)
        var count = 0
        let handle = provider.addObserver { event in
            if case .collaboratorsChanged = event { count += 1 }
        }
        provider.addCollaborator(name: "Alice", email: "a@example.com")
        #expect(count == 1)
        handle.cancel()
        provider.addCollaborator(name: "Bob", email: "b@example.com")
        #expect(count == 1)
    }

    @Test("标题优先姓名，为空时退回邮箱")
    func collaboratorTitle() {
        #expect(Collaborator(name: "Alice", email: "a@example.com").title == "Alice")
        #expect(Collaborator(name: "", email: "a@example.com").title == "a@example.com")
        #expect(GitUserPreset(name: "Alice", email: "a@example.com").title == "Alice")
        #expect(GitUserPreset(name: "", email: "a@example.com").title == "a@example.com")
    }
}
