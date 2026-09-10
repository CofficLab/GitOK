import Foundation
import Testing
@testable import ProviderProjectLanguages

@MainActor
@Suite("ProviderProjectLanguages")
struct ProjectLanguagesProvidingTests {
    @Test("sorts languages and calculates percentages")
    func sortsLanguagesAndCalculatesPercentages() {
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [
                ProjectLanguage(id: "markdown", name: "Markdown", byteCount: 20),
                ProjectLanguage(id: "swift", name: "Swift", byteCount: 80),
            ]
        )

        #expect(snapshot.languages.map(\.id) == ["swift", "markdown"])
        #expect(snapshot.totalByteCount == 100)
        #expect(snapshot.percentage(for: snapshot.languages[0]) == 0.8)
    }

    @Test("publishes snapshot and loading events")
    func publishesEvents() {
        let provider = DefaultProjectLanguagesProvider()
        var events: [ProjectLanguagesEvent] = []
        let handle = provider.addObserver { events.append($0) }
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: "/tmp/repo",
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
        )

        provider.setLoading(true)
        provider.setSnapshot(snapshot)
        provider.setLoading(false)

        #expect(provider.currentSnapshot == snapshot)
        #expect(provider.isLoading == false)
        #expect(events.count == 3)
        handle.cancel()
    }
}
