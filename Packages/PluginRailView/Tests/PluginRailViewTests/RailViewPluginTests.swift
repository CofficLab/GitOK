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
