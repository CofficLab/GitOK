import Testing
@testable import ProviderGitConflictResolver

@MainActor
private final class MockResolver: GitConflictResolutionProviding {
    var didRequestPresentation = false
    func requestPresentation() { didRequestPresentation = true }
}

@Suite("GitConflictResolutionProviding")
@MainActor
struct GitConflictResolutionProvidingTests {
    @Test("mock conforms and responds to requestPresentation")
    func mockResponds() {
        let resolver = MockResolver()
        resolver.requestPresentation()
        #expect(resolver.didRequestPresentation)
    }
}
