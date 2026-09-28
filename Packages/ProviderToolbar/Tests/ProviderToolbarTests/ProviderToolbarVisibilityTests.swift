import Combine
import SwiftUI
import Testing
@testable import ProviderToolbar

@Suite("ProviderToolbar category visibility")
@MainActor
struct ProviderToolbarVisibilityTests {

    private func makeItem(id: String, category: ToolbarItemCategory) -> ProviderToolbar.ToolbarItem {
        ProviderToolbar.ToolbarItem(id: id, title: id, placement: .leading, category: category) { Text(id) }
    }

    @Test("visibleToolbarItems filters by visible categories")
    func visibleItemsFilterByCategory() {
        let provider = DefaultToolbarProviding()
        provider.registerToolbarItems([
            makeItem(id: "global", category: .global),
            makeItem(id: "chat", category: .chat),
        ])
        #expect(provider.visibleToolbarItems.map(\.id) == ["global", "chat"])
    }

    @Test("setHiddenCategories removes items from a source")
    func setHiddenCategories() {
        let provider = DefaultToolbarProviding()
        provider.registerToolbarItems([
            makeItem(id: "global", category: .global),
            makeItem(id: "chat", category: .chat),
        ])
        provider.setHiddenCategories([.chat], for: "plugin-a")
        #expect(provider.visibleToolbarItems.map(\.id) == ["global"])
    }

    @Test("clearing hidden categories restores items")
    func clearingHiddenRestores() {
        let provider = DefaultToolbarProviding()
        provider.registerToolbarItems([
            makeItem(id: "global", category: .global),
            makeItem(id: "chat", category: .chat),
        ])
        provider.setHiddenCategories([.chat], for: "plugin-a")
        #expect(provider.visibleToolbarItems.map(\.id) == ["global"])
        provider.setHiddenCategories([], for: "plugin-a")
        #expect(provider.visibleToolbarItems.map(\.id) == ["global", "chat"])
    }

    @Test("setVisibleCategories updates base categories")
    func setVisibleCategories() {
        let provider = DefaultToolbarProviding()
        provider.setVisibleCategories([.global])
        #expect(provider.visibleCategories == [.global])
    }
}
