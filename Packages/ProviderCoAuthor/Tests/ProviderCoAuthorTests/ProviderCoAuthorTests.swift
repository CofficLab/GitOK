import Foundation
import Testing
@testable import ProviderCoAuthor

@Suite("ProviderCoAuthor")
@MainActor
struct ProviderCoAuthorTests {
    @Test("DefaultCoAuthorProvider persists authors to JSON file")
    func testPersistence() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProviderCoAuthorTests-\(UUID().uuidString)")
        let provider = DefaultCoAuthorProvider(directory: tempDir)

        // Initially empty
        #expect(provider.loadAuthors().isEmpty)

        // Add an author
        let author = provider.addAuthor(name: "Alice", email: "alice@example.com")
        #expect(author != nil)
        #expect(author?.name == "Alice")
        #expect(author?.email == "alice@example.com")

        // Load and verify
        let loaded = provider.loadAuthors()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Alice")

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("DefaultCoAuthorProvider does not add duplicate emails")
    func testDuplicateEmail() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProviderCoAuthorTests-\(UUID().uuidString)")
        let provider = DefaultCoAuthorProvider(directory: tempDir)

        let first = provider.addAuthor(name: "Alice", email: "alice@example.com")
        #expect(first != nil)

        let second = provider.addAuthor(name: "Alice Smith", email: "alice@example.com")
        #expect(second == nil)

        #expect(provider.loadAuthors().count == 1)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("DefaultCoAuthorProvider notifies observers on change")
    func testObserver() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProviderCoAuthorTests-\(UUID().uuidString)")
        let provider = DefaultCoAuthorProvider(directory: tempDir)

        var eventCount = 0
        let handle = provider.addObserver { _ in
            eventCount += 1
        }

        _ = provider.addAuthor(name: "Bob", email: "bob@example.com")
        #expect(eventCount == 1)

        handle.cancel()
        _ = provider.addAuthor(name: "Charlie", email: "charlie@example.com")
        #expect(eventCount == 1) // Should not increment after cancel

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }
}
