import SwiftUI
import Testing
@testable import ProviderStatusBar

@Suite("ProviderStatusBar")
@MainActor
struct ProviderStatusBarTests {
    @Test("状态栏保留所有插件项，场景可见性由插件管理")
    func keepsAllStatusBarItems() {
        let implementation = DefaultStatusBarProviding()
        let provider: any StatusBarProviding = implementation
        provider.registerStatusBarItems([
            StatusBarItem(id: "git", title: "Git") { Text("Git") },
            StatusBarItem(id: "banner", title: "Banner") { Text("Banner") },
        ])

        #expect(implementation.visibleStatusBarItems.map(\.id) == ["git", "banner"])
    }
}
