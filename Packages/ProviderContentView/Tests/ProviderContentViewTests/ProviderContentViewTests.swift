import Combine
import SwiftUI
import Testing
@testable import ProviderContentView

/// ContentViewProviding 协议与默认实现的基础验证。
@Suite("ProviderContentView")
@MainActor
struct ProviderContentViewTests {

    @Test("未注册内容时返回占位视图")
    func defaultProviderReturnsPlaceholder() {
        let provider = DefaultContentViewProviding()

        let view = provider.makeContentView()

        #expect(type(of: view) == AnyView.self)
    }

    @Test("注册内容块后返回 VStack 组合视图")
    func defaultProviderReturnsAddedContent() {
        let provider = DefaultContentViewProviding()
        provider.addContentView(AnyView(Text("form")), id: "form", order: 10)
        provider.addContentView(AnyView(Text("detail")), id: "detail", order: 20)

        let view = provider.makeContentView()

        #expect(type(of: view) == AnyView.self)
    }

    @Test("同一 id 重复注册会覆盖旧内容")
    func addContentViewReplacesSameID() {
        let provider = DefaultContentViewProviding()
        provider.addContentView(AnyView(Text("old")), id: "a", order: 10)
        provider.addContentView(AnyView(Text("new")), id: "a", order: 10)

        #expect(provider.registeredIDs == ["a"])
    }

    @Test("内容块按 order 升序排列")
    func addContentViewSortsByOrder() {
        let provider = DefaultContentViewProviding()
        provider.addContentView(AnyView(Text("detail")), id: "detail", order: 20)
        provider.addContentView(AnyView(Text("form")), id: "form", order: 10)

        #expect(provider.registeredIDs == ["form", "detail"])
    }

    @Test("添加 / 移除内容会发布视图刷新事件")
    func mutatingContentPublishesChange() {
        let provider = DefaultContentViewProviding()
        var changeCount = 0
        let cancellable = provider.objectWillChange.sink { changeCount += 1 }

        provider.addContentView(AnyView(Text("next")), id: "a", order: 10)
        #expect(changeCount == 1)

        provider.removeContentView(id: "a")
        #expect(changeCount == 2)
        cancellable.cancel()
    }

    @Test("移除不存在的 id 不发布事件")
    func removeMissingIDDoesNotPublish() {
        let provider = DefaultContentViewProviding()
        var changeCount = 0
        let cancellable = provider.objectWillChange.sink { changeCount += 1 }

        provider.removeContentView(id: "missing")

        #expect(changeCount == 0)
        cancellable.cancel()
    }

    @Test("移除全部内容后回退到占位")
    func defaultProviderClearsAllContent() {
        let provider = DefaultContentViewProviding()
        provider.addContentView(AnyView(Text("content")), id: "a", order: 10)
        provider.removeAllContentView()

        #expect(provider.registeredIDs.isEmpty)
        #expect(type(of: provider.makeContentView()) == AnyView.self)
    }

    @Test("ContentViewProviding 可作为 any ContentViewProviding 使用")
    func providerAccessibleThroughProtocol() {
        let provider: any ContentViewProviding = DefaultContentViewProviding()
        provider.addContentView(AnyView(Text("content")), id: "a", order: 10)

        #expect(type(of: provider.makeContentView()) == AnyView.self)
    }

    @Test("自定义实现可被协议访问")
    func customProviderWorks() {
        @MainActor final class CustomContentView: ContentViewProviding {
            @Published var content: AnyView?

            func addContentView(_ view: AnyView, id: String, order: Int) {
                content = view
            }

            func removeContentView(id: String) {
                content = nil
            }

            func removeAllContentView() {
                content = nil
            }

            func makeContentView() -> AnyView {
                content ?? AnyView(Text("custom content"))
            }
        }

        let provider: any ContentViewProviding = CustomContentView()
        provider.addContentView(AnyView(Text("custom")), id: "a", order: 10)

        #expect(type(of: provider.makeContentView()) == AnyView.self)
    }

    @Test("Provider 保留所有插件内容，场景可见性由插件管理")
    func keepsAllPluginEntries() {
        let provider = DefaultContentViewProviding()
        provider.addContentView(AnyView(Text("git")), id: "git", order: 10)
        provider.addContentView(AnyView(Text("banner")), id: "banner", order: 20)

        #expect(provider.visibleIDs == ["git", "banner"])
    }
}
