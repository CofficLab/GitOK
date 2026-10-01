import SwiftUI
import Testing
@testable import ProviderProjectReadme

@MainActor
struct ProviderProjectReadmeTests {
    @Test("Mock provider makes readme view")
    func mockProviderMakesView() {
        let provider = MockReadmeProvider()
        let view = provider.makeReadmeView(for: URL(fileURLWithPath: "/tmp/repo"))
        #expect(type(of: view) == AnyView.self)
    }
}

@MainActor
private final class MockReadmeProvider: ProjectReadmeProviding {
    func makeReadmeView(for projectURL: URL) -> AnyView {
        AnyView(Text("README"))
    }
}
