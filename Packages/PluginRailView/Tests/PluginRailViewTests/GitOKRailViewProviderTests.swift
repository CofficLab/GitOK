import Combine
import Foundation
import KernelCore
import ProviderDocsView
import ProviderRailView
import SwiftUI
import Testing
@testable import PluginRailView

// MARK: - Test doubles

/// 可控的 Rail 宽度偏好存储。
@MainActor
private final class WidthStoreSpy: RailViewWidthStoring {
    private(set) var saved: [(width: CGFloat, ownerID: String)] = []
    private(set) var removedOwnerIDs: [String] = []
    var storedWidth: CGFloat?

    func loadWidth(ownerID: String) -> CGFloat? { storedWidth }
    func saveWidth(_ width: CGFloat, ownerID: String) {
        saved.append((width, ownerID))
        storedWidth = width
    }
    func removeWidth(ownerID: String) {
        removedOwnerIDs.append(ownerID)
    }
}

// MARK: - Tests

/// `GitOKRailViewProvider` 的状态管理覆盖。
@Suite("GitOKRailViewProvider")
@MainActor
struct GitOKRailViewProviderTests {

    private func makeTab(
        id: String,
        category: RailViewCategory = .project,
        order: Int = 10
    ) -> RailTabItem {
        RailTabItem(
            id: id,
            category: category,
            title: id,
            systemImage: "folder",
            order: order
        ) { Text(id) }
    }

    @Test("注册 tab 后按 order 排序并选中首个可见 tab")
    func registerTabsSortsAndSelectsFirst() {
        let provider = GitOKRailViewProvider()

        provider.registerTabs([
            makeTab(id: "b", order: 20),
            makeTab(id: "a", order: 10),
        ])

        #expect(provider.tabs.map(\.id) == ["a", "b"])
        #expect(provider.activeTabID == "a")
        #expect(provider.hasVisibleTabs)
        #expect(provider.isRailVisible)
    }

    @Test("分类过滤只保留匹配分类的 tab")
    func visibleCategoriesFilterTabs() {
        let provider = GitOKRailViewProvider()

        provider.registerTabs([
            makeTab(id: "project", category: .project),
            makeTab(id: "chat", category: .chat),
        ])

        provider.setVisibleCategories([.chat])

        #expect(provider.visibleTabs.map(\.id) == ["chat"])
        #expect(provider.activeTabID == "chat")
    }

    @Test("指定可见 tab 会过滤掉其它 tab")
    func visibleTabIDFiltersToSingleTab() {
        let provider = GitOKRailViewProvider()

        provider.registerTabs([
            makeTab(id: "a"),
            makeTab(id: "b"),
        ])
        provider.setVisibleTabID("b")

        #expect(provider.visibleTabs.map(\.id) == ["b"])
        #expect(provider.activeTabID == "b")
    }

    @Test("从 tab 过滤模式切回分类模式会清除残留的 tab id")
    func switchingBackToCategoryModeClearsTabID() {
        let provider = GitOKRailViewProvider()

        provider.registerTabs([
            makeTab(id: "a", category: .project),
            makeTab(id: "b", category: .chat),
        ])
        provider.setVisibleTabID("b")
        #expect(provider.visibleTabs.map(\.id) == ["b"])

        provider.setVisibleCategories([.project, .chat])

        #expect(provider.visibleTabID == nil)
        #expect(provider.visibleTabs.map(\.id) == ["a", "b"])
    }

    @Test("分类过滤掉所有 tab 时清空选中项")
    func filteringOutAllTabsClearsActiveTab() {
        let provider = GitOKRailViewProvider()

        provider.registerTabs([makeTab(id: "a", category: .project)])
        #expect(provider.activeTabID == "a")

        provider.setVisibleCategories([.chat])

        #expect(provider.visibleTabs.isEmpty)
        #expect(provider.activeTabID == nil)
        #expect(!provider.hasVisibleTabs)
    }

    @Test("activateTab 忽略未知 id，nil 会清空选中项")
    func activateTabHandlesUnknownAndNil() {
        let provider = GitOKRailViewProvider()
        provider.registerTabs([makeTab(id: "a")])

        provider.activateTab(id: "missing")
        #expect(provider.activeTabID == "a")

        provider.activateTab(id: "a")
        #expect(provider.activeTabID == "a")

        provider.activateTab(id: nil)
        #expect(provider.activeTabID == nil)
    }

    @Test("区块注册、追加与撤回")
    func sectionsCanBeRegisteredMergedAndRemoved() {
        let provider = GitOKRailViewProvider()

        provider.registerSections([
            RailSectionItem(id: "second", order: 20) { Text("second") },
            RailSectionItem(id: "first", order: 10) { Text("first") },
        ])
        #expect(provider.sections.map(\.id) == ["first", "second"])
        #expect(provider.hasVisibleSections)

        // 同 id 追加不会产生重复项。
        provider.addSections([RailSectionItem(id: "first", order: 99) { Text("dup") }])
        #expect(provider.sections.map(\.id) == ["first", "second"])

        provider.addSections([RailSectionItem(id: "third", order: 30) { Text("third") }])
        #expect(provider.sections.map(\.id) == ["first", "second", "third"])

        provider.removeSections(ids: ["second"])
        #expect(provider.sections.map(\.id) == ["first", "third"])
    }

    @Test("宽度配置按 owner 恢复并夹紧到合法区间")
    func widthProfileRestoresAndClampsWidth() {
        let store = WidthStoreSpy()
        store.storedWidth = 999
        let provider = GitOKRailViewProvider(widthStore: store)

        provider.activateWidthProfile(
            ownerID: "owner-a",
            recommended: RailViewWidth.standard,
            store: store
        )

        #expect(provider.railWidth.idealWidth == RailViewWidth.standard.maxWidth)
        #expect(provider.railWidth.idealWidth <= provider.railWidth.maxWidth)
    }

    @Test("空 ownerID 不会激活宽度配置")
    func emptyOwnerIDIsIgnored() {
        let provider = GitOKRailViewProvider()

        provider.activateWidthProfile(
            ownerID: "",
            recommended: RailViewWidth.standard,
            store: nil
        )

        #expect(provider.railWidth == RailViewWidth.standard)
    }

    @Test("停用宽度配置：当前 owner 反而是空操作，换成别的 owner 才复位")
    func deactivateWidthProfileHasInvertedGuard() {
        let store = WidthStoreSpy()
        let provider = GitOKRailViewProvider(widthStore: store)

        provider.activateWidthProfile(
            ownerID: "owner-a",
            recommended: RailViewWidth(minWidth: 100, idealWidth: 200, maxWidth: 300),
            store: store
        )
        #expect(provider.railWidth.idealWidth != RailViewWidth.standard.idealWidth)

        // 实现现状：ownerID 与当前 owner 相同时直接 return。
        // LumiProviders 的 DefaultRailViewProviding 与 ProviderChatSection 的
        // DefaultChatSectionProviding 都用 `activeWidthOwnerID == ownerID` 判断，
        // 此处符号相反，详见提交信息中的「实现与文档不一致」记录。
        provider.deactivateWidthProfile(ownerID: "owner-a")
        #expect(provider.railWidth.idealWidth != RailViewWidth.standard.idealWidth)

        // 传入不同 ownerID 时反而会清空当前宽度配置并回到标准宽度。
        provider.deactivateWidthProfile(ownerID: "owner-b")
        #expect(provider.railWidth == RailViewWidth.standard)
    }

    @Test("未激活宽度配置时保存宽度是空操作")
    func saveCurrentWidthIsNoopWithoutActiveOwner() {
        let store = WidthStoreSpy()
        let provider = GitOKRailViewProvider(widthStore: store)

        provider.saveCurrentWidth(300)

        #expect(store.saved.isEmpty)
        #expect(provider.railWidth == RailViewWidth.standard)
    }

    @Test("激活宽度配置后保存宽度会写入存储并夹紧")
    func saveCurrentWidthWritesToStore() {
        let store = WidthStoreSpy()
        let provider = GitOKRailViewProvider(widthStore: store)
        provider.activateWidthProfile(
            ownerID: "owner-a",
            recommended: RailViewWidth.standard,
            store: store
        )

        provider.saveCurrentWidth(1000)

        #expect(store.saved.count == 1)
        #expect(store.saved.first?.ownerID == "owner-a")
        #expect(store.saved.first?.width == RailViewWidth.standard.maxWidth)
        #expect(provider.railWidth.idealWidth == RailViewWidth.standard.maxWidth)
    }

    @Test("makeRailView 返回 AnyView")
    func makeRailViewReturnsAnyView() {
        let provider = GitOKRailViewProvider()

        let view = provider.makeRailView()

        #expect(type(of: view) == AnyView.self)
    }

    @Test("可见性发布器跟随 tab 与区块状态")
    func visibilityPublisherFollowsState() {
        let provider = GitOKRailViewProvider()
        var values: [Bool] = []
        let cancellable = provider.railVisibilityPublisher.sink { values.append($0) }
        #expect(values == [false])

        provider.registerTabs([makeTab(id: "a")])

        #expect(values == [false, true])

        cancellable.cancel()
    }
}

/// `RailViewPlugin` 的生命周期接线覆盖。
@Suite("RailViewPlugin 接线")
@MainActor
struct RailViewPluginWiringTests {

    private func makeKernel(withDocs: Bool = false) throws -> (
        kernel: KernelCoreContainer,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, docs)
    }

    @Test("onBoot 用插件自有实现替换默认 RailViewProviding")
    func bootReplacesDefaultProvider() throws {
        let (kernel, _) = try makeKernel()
        let plugin = RailViewPlugin()
        try kernel.registerProvider((any RailViewProviding).self, DefaultRailViewProviding())

        try plugin.onBoot(kernel: kernel)

        let resolved = kernel.resolveProvider((any RailViewProviding).self)
        #expect(resolved === plugin.provider)
    }

    @Test("onShutdown 恢复默认 RailViewProviding")
    func shutdownRestoresDefaultProvider() throws {
        let (kernel, _) = try makeKernel()
        let plugin = RailViewPlugin()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        let resolved = kernel.resolveProvider((any RailViewProviding).self)
        #expect(resolved != nil)
        #expect(resolved !== plugin.provider)
    }

    @Test("onRegister 挂载「关于」条目，onUnregister 撤回")
    func registerAndUnregisterAboutEntry() throws {
        let (kernel, docs) = try makeKernel(withDocs: true)
        let plugin = RailViewPlugin()

        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        #expect(!docs.aboutEntries.contains { $0.id == plugin.id })
    }

    @Test("关于条目可以构造出视图")
    func aboutEntryBuildsView() throws {
        let (kernel, docs) = try makeKernel(withDocs: true)
        let plugin = RailViewPlugin()

        try plugin.onRegister(kernel: kernel)

        let entry = try #require(docs.aboutEntries.first { $0.id == plugin.id })
        let view = entry.makeView()
        #expect(type(of: view) == AnyView.self)
    }

    @Test("没有文档提供方时 onRegister / onUnregister 也不抛错")
    func registerWithoutDocsProvider() throws {
        let (kernel, _) = try makeKernel(withDocs: false)
        let plugin = RailViewPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    @Test("可通过 kernel.start 启动并替换默认实现")
    func startViaKernel() throws {
        let (kernel, _) = try makeKernel()
        let plugin = RailViewPlugin()
        try kernel.registerProvider((any RailViewProviding).self, DefaultRailViewProviding())

        try kernel.start(plugins: [plugin])

        #expect(kernel.isPluginRegistered(id: plugin.id))
        #expect(kernel.resolveProvider((any RailViewProviding).self) === plugin.provider)
        try kernel.stop()
    }
}
