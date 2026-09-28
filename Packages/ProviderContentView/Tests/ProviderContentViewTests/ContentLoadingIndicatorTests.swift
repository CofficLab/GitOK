import SwiftUI
import Testing
@testable import ProviderContentView

@Suite("ContentLoadingIndicator")
struct ContentLoadingIndicatorTests {
    @Test("init creates view with message")
    func initCreatesView() {
        let view = ContentLoadingIndicator("Loading")
        #expect(view != nil)
    }

    @Test("init with custom control size")
    func initCustomSize() {
        let view = ContentLoadingIndicator("Loading", controlSize: .small)
        #expect(view != nil)
    }
}
