import Testing
@testable import PluginRailView

@Test func railViewPluginExists() async throws {
    let plugin = RailViewPlugin()
    #expect(plugin.id == "com.coffic.gitok.plugin.rail-view")
    #expect(plugin.order == 6)
}

@Test func gitOKRailViewProviderInitializes() async throws {
    let provider = GitOKRailViewProvider()
    #expect(provider.tabs.isEmpty)
    #expect(provider.sections.isEmpty)
    #expect(!provider.hasVisibleTabs)
    #expect(!provider.hasVisibleSections)
}
