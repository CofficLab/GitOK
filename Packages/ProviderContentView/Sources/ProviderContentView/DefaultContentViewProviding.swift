import SwiftUI

/// `ContentViewProviding` 的默认实现：持有多个内容块。
///
/// 插件通过 `addContentView(_:id:order:)` 注册自己的内容块（如提交表单、
/// commit 详情），`makeContentView()` 按 `order` 升序自上而下组成 VStack 返回。
/// 未注册任何内容块时返回占位提示。
@MainActor
public final class DefaultContentViewProviding: ContentViewProviding, ObservableObject {
    fileprivate struct Entry: Identifiable {
        let id: String
        let order: Int
        let view: AnyView
    }

    @Published fileprivate var entries: [Entry] = []

    /// 已注册内容块的 id 列表（按 order 升序）。仅供模块内测试断言使用。
    internal var registeredIDs: [String] { entries.map(\.id) }

    public init() {}

    public func addContentView(_ view: AnyView, id: String, order: Int) {
        var updated = entries.filter { $0.id != id }
        updated.append(Entry(id: id, order: order, view: view))
        // 保持 order 升序，确保 VStack 自上而下稳定（同一 id 重复注册取新值）。
        updated.sort { $0.order < $1.order }
        entries = updated
    }

    public func removeContentView(id: String) {
        guard entries.contains(where: { $0.id == id }) else { return }
        entries.removeAll { $0.id == id }
    }

    public func removeAllContentView() {
        guard !entries.isEmpty else { return }
        entries.removeAll()
    }

    public func makeContentView() -> AnyView {
        AnyView(ContentHostView(provider: self))
    }

    fileprivate var visibleEntries: [Entry] { entries }

    internal var visibleIDs: [String] {
        visibleEntries.map(\.id)
    }
}

/// 稳定挂在 RootView 中并观察 Provider；后续 `addContentView` / `removeContentView`
/// 会直接刷新内容区。
private struct ContentHostView: View {
    @ObservedObject var provider: DefaultContentViewProviding

    var body: some View {
        Group {
            if provider.visibleEntries.isEmpty {
                ContentPlaceholderView()
            } else {
                VStack(spacing: 0) {
                    ForEach(provider.visibleEntries) { entry in
                        entry.view
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 内容区占位视图。
private struct ContentPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "macwindow")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(LumiPluginLocalization.string("No plugin view registered", bundle: .module))
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(LumiPluginLocalization.string("A plugin must register a main content view for this workspace.", bundle: .module))
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
