import SwiftUI
import Testing
@testable import GitOKAutomationKit

@Suite("GitOKAutomationViewExtensionsTests")
struct GitOKAutomationViewExtensionsTests {
    @Test("Semantic modifiers can be composed")
    @MainActor
    func semanticModifiersCanBeComposed() {
        let view = Text("GitOK")
            .onMockCommitSelected { _ in }
            .onMockWorkingTreeSelected {}
            .onMockFileSelected { _ in }
            .onMockProjectSelected { _ in }

        #expect(String(describing: type(of: view)).isEmpty == false)
    }
}
