import ProviderWorkspaceScene
import SwiftUI
import Testing
@testable import ProviderStatusBar

@Suite("ProviderStatusBar")
@MainActor
struct ProviderStatusBarTests {
    @Test("状态栏项按工作场景过滤")
    func filtersStatusBarItemsByWorkspaceScene() {
        let scene = DefaultWorkspaceSceneProvider()
        let provider = DefaultStatusBarProviding()
        provider.bindWorkspaceSceneProvider(scene)
        provider.registerStatusBarItems([
            StatusBarItem(id: "git", title: "Git", sceneScope: .scene(.git)) { Text("Git") },
            StatusBarItem(id: "banner", title: "Banner", sceneScope: .scene(.banner)) { Text("Banner") },
        ])

        #expect(provider.visibleStatusBarItems.map(\.id) == ["git"])
        scene.selectScene(.banner)
        #expect(provider.visibleStatusBarItems.map(\.id) == ["banner"])
    }
}
