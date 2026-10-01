import Combine
import ProviderRailView
import SwiftUI
import Testing
@testable import PluginRailView

/// Rail 只负责管理 tab / section；项目可用性由 RootView 统一门控。
@Suite("PluginRailView")
@MainActor
struct RailViewPluginTests {
    @Test("插件元数据符合 Lumi 插件规范")
    func pluginMetadata() {
        let plugin = RailViewPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.rail-view")
        #expect(plugin.order == 6)
        #expect(plugin.metadata.category == .core)
        #expect(plugin.metadata.policy == .required)
    }

    @Test("provider 初始状态无内容")
    func providerInitialState() {
        let provider = GitOKRailViewProvider()
        #expect(provider.tabs.isEmpty)
        #expect(provider.sections.isEmpty)
        #expect(!provider.hasVisibleTabs)
        #expect(!provider.hasVisibleSections)
        #expect(!provider.isRailVisible)
    }

    @Test("section 注册后 Rail 可见")
    func sectionMakesRailVisible() {
        let provider = GitOKRailViewProvider()
        provider.registerSections([
            RailSectionItem(id: "test.section", order: 10) { Text("section") },
        ])

        #expect(provider.hasVisibleSections)
        #expect(provider.isRailVisible)
    }

    @Test("railVisibilityPublisher 跟随 section 状态发布")
    func visibilityPublisherFollowsSections() {
        let provider = GitOKRailViewProvider()
        var values: [Bool] = []
        let cancellable = provider.railVisibilityPublisher.sink { values.append($0) }
        #expect(values == [false])

        provider.registerSections([
            RailSectionItem(id: "test.section", order: 10) { Text("section") },
        ])
        #expect(values == [false, true])

        provider.removeSections(ids: ["test.section"])
        #expect(values == [false, true, false])

        cancellable.cancel()
    }
}

extension RailViewPluginTests {
    @Test("registerTabs sorts by order and activates first visible tab")
    func registerTabsSortsAndActivates() {
        let provider = GitOKRailViewProvider()
        provider.registerTabs([
            RailTabItem(id: "beta", category: .project, title: "B", systemImage: "b", order: 20) { Text("b") },
            RailTabItem(id: "alpha", category: .project, title: "A", systemImage: "a", order: 10) { Text("a") },
        ])
        #expect(provider.tabs.map(\.id) == ["alpha", "beta"])
        #expect(provider.activeTabID == "alpha")
        #expect(provider.hasVisibleTabs)
    }

    @Test("activateTab only activates known visible tabs")
    func activateTabValidates() {
        let provider = GitOKRailViewProvider()
        provider.registerTabs([
            RailTabItem(id: "a", category: .project, title: "A", systemImage: "a", order: 10) { Text("a") },
        ])
        provider.activateTab(id: "a")
        #expect(provider.activeTabID == "a")
        provider.activateTab(id: "nonexistent")
        #expect(provider.activeTabID == "a")
        provider.activateTab(id: nil)
        #expect(provider.activeTabID == nil)
    }

    @Test("addSections dedupes by id")
    func addSectionsDedupes() {
        let provider = GitOKRailViewProvider()
        provider.registerSections([RailSectionItem(id: "s1", order: 10) { Text("1") }])
        provider.addSections([
            RailSectionItem(id: "s1", order: 10) { Text("1") },
            RailSectionItem(id: "s2", order: 20) { Text("2") },
        ])
        #expect(provider.sections.count == 2)
    }

    @Test("setVisibleTabID filters visible tabs")
    func setVisibleTabIDFilters() {
        let provider = GitOKRailViewProvider()
        provider.registerTabs([
            RailTabItem(id: "a", category: .project, title: "A", systemImage: "a", order: 10) { Text("a") },
            RailTabItem(id: "b", category: .chat, title: "B", systemImage: "b", order: 20) { Text("b") },
        ])
        provider.setVisibleTabID("a")
        #expect(provider.visibleTabs.map(\.id) == ["a"])
        #expect(provider.activeTabID == "a")
    }
}
