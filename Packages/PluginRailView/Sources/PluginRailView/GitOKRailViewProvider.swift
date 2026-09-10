import Combine
import LumiUI
import ProviderRailView
import SwiftUI

/// `RailViewProviding` 的 GitOK 实现：持有注入的 `RailTabItem`，
/// 渲染为「顶部标签栏 + 内容区」的侧边栏（与旧版 `FactoryCore.RailView` 视觉一致）。
///
/// 点击 tab 切换选中项并展示对应内容。
@MainActor
public final class GitOKRailViewProvider: RailViewProviding, ObservableObject {
    @Published public private(set) var tabs: [RailTabItem] = []
    @Published public private(set) var visibleCategories: Set<RailViewCategory>
    @Published public private(set) var visibleTabID: String?
    @Published public private(set) var activeTabID: String?
    @Published public private(set) var hasVisibleTabs = false
    @Published public private(set) var sections: [RailSectionItem] = []
    @Published public private(set) var railWidth: RailViewWidth

    private var allSections: [RailSectionItem] = []

    private let defaultWidthStore: (any RailViewWidthStoring)?
    private var activeWidthStore: (any RailViewWidthStoring)?
    private var activeWidthOwnerID: String?

    public var hasVisibleSections: Bool { !sections.isEmpty }

    public var railVisibilityPublisher: AnyPublisher<Bool, Never> {
        $hasVisibleTabs.combineLatest($sections.map { !$0.isEmpty })
            .map { $0 || $1 }
            .eraseToAnyPublisher()
    }

    public init(
        visibleCategories: Set<RailViewCategory> = Set(RailViewCategory.allCases),
        visibleTabID: String? = nil,
        widthStore: (any RailViewWidthStoring)? = nil
    ) {
        self.visibleCategories = visibleCategories
        self.visibleTabID = visibleTabID
        self.railWidth = .standard
        self.defaultWidthStore = widthStore
        self.activeWidthStore = nil
    }

    public func registerTabs(_ tabs: [RailTabItem]) {
        self.tabs = tabs.sorted { $0.order < $1.order }
        reconcileActiveTab()
        updateVisibleTabState()
    }

    // MARK: - Sections

    public func registerSections(_ newSections: [RailSectionItem]) {
        allSections = newSections.sorted { $0.order < $1.order }
        sections = allSections
    }

    public func addSections(_ newSections: [RailSectionItem]) {
        var merged = allSections
        for section in newSections where !merged.contains(where: { $0.id == section.id }) {
            merged.append(section)
        }
        registerSections(merged)
    }

    public func removeSections(ids: Set<String>) {
        registerSections(allSections.filter { !ids.contains($0.id) })
    }

    public func activateTab(id: String?) {
        guard let id else {
            activeTabID = nil
            return
        }
        guard visibleTabs.contains(where: { $0.id == id }) else { return }
        activeTabID = id
    }

    public func setVisibleCategories(_ categories: Set<RailViewCategory>) {
        guard visibleCategories != categories || visibleTabID != nil else { return }
        visibleCategories = categories
        // 分类过滤和指定 tab 过滤是两种互斥的显示模式；切换回分类模式时，
        // 必须清除上一个插件留下的 tab id，否则可能把分类内所有 tab 都过滤掉。
        visibleTabID = nil
        reconcileActiveTab()
        updateVisibleTabState()
    }

    public func setVisibleTabID(_ id: String?) {
        guard visibleTabID != id else { return }
        visibleTabID = id
        reconcileActiveTab()
        updateVisibleTabState()
    }

    public func activateWidthProfile(
        ownerID: String,
        recommended: RailViewWidth,
        store: (any RailViewWidthStoring)?
    ) {
        guard !ownerID.isEmpty else { return }
        activeWidthOwnerID = ownerID
        let activeWidthStore = store ?? defaultWidthStore
        self.activeWidthStore = activeWidthStore
        let restoredWidth = activeWidthStore?.loadWidth(ownerID: ownerID) ?? recommended.idealWidth
        let resolvedWidth = recommended.withIdealWidth(recommended.clamped(restoredWidth))
        if railWidth != resolvedWidth {
            railWidth = resolvedWidth
        }
    }

    public func deactivateWidthProfile(ownerID: String) {
        guard activeWidthOwnerID != ownerID else { return }
        activeWidthOwnerID = nil
        activeWidthStore = nil
        if railWidth != .standard {
            railWidth = .standard
        }
    }

    public func saveCurrentWidth(_ width: CGFloat) {
        guard let activeWidthOwnerID else { return }
        let resolvedWidth = railWidth.clamped(width)
        activeWidthStore?.saveWidth(resolvedWidth, ownerID: activeWidthOwnerID)
        let updatedWidth = railWidth.withIdealWidth(resolvedWidth)
        if railWidth != updatedWidth {
            railWidth = updatedWidth
        }
    }

    public func makeRailView() -> AnyView {
        AnyView(RailView(provider: self))
    }

    fileprivate var visibleTabs: [RailTabItem] {
        tabs.filter { tab in
            visibleCategories.contains(tab.category)
                && (visibleTabID == nil || tab.id == visibleTabID)
        }
    }

    private func updateVisibleTabState() {
        hasVisibleTabs = !visibleTabs.isEmpty
    }

    private func reconcileActiveTab() {
        guard !visibleTabs.isEmpty else {
            activeTabID = nil
            return
        }
        if let activeTabID, visibleTabs.contains(where: { $0.id == activeTabID }) {
            return
        }
        activeTabID = visibleTabs[0].id
    }
}
