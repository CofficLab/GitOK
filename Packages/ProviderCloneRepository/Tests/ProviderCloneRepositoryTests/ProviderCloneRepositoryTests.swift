import Foundation
import Testing
@testable import ProviderCloneRepository

struct ProviderCloneRepositoryTests {
    @Test("CloneTask 保留可持久化的基本任务信息")
    func cloneTaskRoundTrip() throws {
        let task = CloneTask(
            remoteURL: "https://example.com/repository.git",
            destination: URL(fileURLWithPath: "/tmp/repository"),
            repositoryName: "repository",
            status: .cloning,
            phase: .receivingObjects,
            fractionCompleted: 0.42,
            detail: "Receiving objects"
        )

        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(CloneTask.self, from: data)

        #expect(decoded == task)
        #expect(CloneTaskStatus.cloning.isActive)
        #expect(!CloneTaskStatus.completed.isActive)
    }
}
