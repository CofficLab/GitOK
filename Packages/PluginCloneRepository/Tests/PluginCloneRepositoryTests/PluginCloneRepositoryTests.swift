import Foundation
import KernelCore
import ProviderCloneRepository
import SwiftUI
import Testing
@testable import PluginCloneRepository

@Suite("PluginCloneRepository")
@MainActor
struct PluginCloneRepositoryTests {

    @Test("插件元数据符合规范")
    func pluginMetadata() {
        let plugin = CloneRepositoryPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.clone-repository")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .required)
        #expect(plugin.metadata.stage == .stable)
        #expect(plugin.order == -10)
    }

    @Test("CloneTaskStatus.isActive reflects lifecycle")
    func taskStatusIsActive() {
        #expect(CloneTaskStatus.queued.isActive)
        #expect(CloneTaskStatus.cloning.isActive)
        #expect(CloneTaskStatus.cancelling.isActive)
        #expect(!CloneTaskStatus.completed.isActive)
        #expect(!CloneTaskStatus.failed.isActive)
        #expect(!CloneTaskStatus.cancelled.isActive)
    }

    @Test("CloneTaskStatus.title covers all cases")
    func taskStatusTitles() {
        #expect(!CloneTaskStatus.queued.title.isEmpty)
        #expect(!CloneTaskStatus.cloning.title.isEmpty)
        #expect(!CloneTaskStatus.cancelling.title.isEmpty)
        #expect(!CloneTaskStatus.completed.title.isEmpty)
        #expect(!CloneTaskStatus.failed.title.isEmpty)
        #expect(!CloneTaskStatus.cancelled.title.isEmpty)
    }

    @Test("CloneTaskStatus.icon covers all cases")
    func taskStatusIcons() {
        #expect(!CloneTaskStatus.queued.icon.isEmpty)
        #expect(!CloneTaskStatus.cloning.icon.isEmpty)
        #expect(!CloneTaskStatus.cancelling.icon.isEmpty)
        #expect(!CloneTaskStatus.completed.icon.isEmpty)
        #expect(!CloneTaskStatus.failed.icon.isEmpty)
        #expect(!CloneTaskStatus.cancelled.icon.isEmpty)
    }

    @Test("CloneTaskStatus.color is non-nil for all cases")
    func taskStatusColors() {
        // Color values are SwiftUI; just exercise the switch to cover all branches.
        _ = CloneTaskStatus.queued.color
        _ = CloneTaskStatus.cloning.color
        _ = CloneTaskStatus.cancelling.color
        _ = CloneTaskStatus.completed.color
        _ = CloneTaskStatus.failed.color
        _ = CloneTaskStatus.cancelled.color
    }

    @Test("CloneRepositoryError descriptions are non-empty")
    func errorDescriptions() {
        let dest = URL(fileURLWithPath: "/tmp/repo")
        #expect(!CloneRepositoryError.taskAlreadyExists(destination: dest).errorDescription!.isEmpty)
        #expect(!CloneRepositoryError.taskNotFound(UUID()).errorDescription!.isEmpty)
        #expect(!CloneRepositoryError.invalidRetryStatus(.queued).errorDescription!.isEmpty)
    }

    @Test("CloneTask round-trips through Codable")
    func taskCodableRoundTrip() throws {
        let task = CloneTask(
            remoteURL: "https://example.com/repo.git",
            destination: URL(fileURLWithPath: "/tmp/repo"),
            repositoryName: "repo",
            status: .cloning,
            fractionCompleted: 0.5
        )
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(CloneTask.self, from: data)
        #expect(decoded == task)
    }
}
