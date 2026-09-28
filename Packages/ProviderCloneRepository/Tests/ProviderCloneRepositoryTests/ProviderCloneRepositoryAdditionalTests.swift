import Foundation
import Testing
@testable import ProviderCloneRepository

@Suite("CloneRepository Additional Coverage")
struct ProviderCloneRepositoryAdditionalTests {

    @Test("CloneTaskStatus isActive covers all cases")
    func allStatuses() {
        #expect(CloneTaskStatus.queued.isActive)
        #expect(CloneTaskStatus.cloning.isActive)
        #expect(CloneTaskStatus.cancelling.isActive)
        #expect(!CloneTaskStatus.completed.isActive)
        #expect(!CloneTaskStatus.failed.isActive)
        #expect(!CloneTaskStatus.cancelled.isActive)
    }

    @Test("CloneRepositoryError descriptions")
    func errorDescriptions() {
        let url = URL(fileURLWithPath: "/tmp/repo")
        #expect(CloneRepositoryError.taskAlreadyExists(destination: url).errorDescription?.contains("/tmp/repo") == true)
        let id = UUID()
        #expect(CloneRepositoryError.taskNotFound(id).errorDescription?.contains(id.uuidString) == true)
        #expect(CloneRepositoryError.invalidRetryStatus(.cloning).errorDescription?.contains("cloning") == true)
    }

    @Test("CloneTask init defaults updatedAt to createdAt")
    func initDefaults() {
        let now = Date()
        let task = CloneTask(
            remoteURL: "https://example.com/repo.git",
            destination: URL(fileURLWithPath: "/tmp/repo"),
            repositoryName: "repo",
            createdAt: now
        )
        #expect(task.updatedAt == now)
        #expect(task.startedAt == nil)
        #expect(task.finishedAt == nil)
    }

    @Test("CloneTask Codable round trip with optional fields")
    func optionalFieldsRoundTrip() throws {
        let task = CloneTask(
            remoteURL: "https://example.com/repo.git",
            destination: URL(fileURLWithPath: "/tmp/repo"),
            repositoryName: "repo",
            status: .failed,
            phase: .completed,
            fractionCompleted: 1.0,
            detail: "Done",
            errorMessage: "boom",
            startedAt: Date(),
            finishedAt: Date()
        )
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(CloneTask.self, from: data)
        #expect(decoded == task)
    }
}
