import XCTest
@testable import ProviderSidebar

@MainActor
final class ProviderSidebarTests: XCTestCase {
    func testRegisterAndActivate() {
        let provider = DefaultSidebarProvider()
        let items = [
            SidebarItem(id: "a", title: "A", systemImage: "folder", order: 2),
            SidebarItem(id: "b", title: "B", systemImage: "folder", order: 1),
        ]
        provider.registerItems(items)

        XCTAssertEqual(provider.items.map(\.id), ["b", "a"], "应按 order 升序排序")
        XCTAssertEqual(provider.activeItemID, "b", "默认激活首个入口")

        provider.activateItem(id: "a")
        XCTAssertEqual(provider.activeItemID, "a")

        provider.activateItem(id: "unknown")
        XCTAssertEqual(provider.activeItemID, "a", "未知 id 应忽略")
    }

    func testAddAndRemoveItems() {
        let provider = DefaultSidebarProvider()
        provider.registerItems([SidebarItem(id: "a", title: "A", systemImage: "folder")])
        provider.addItems([SidebarItem(id: "b", title: "B", systemImage: "folder")])
        provider.addItems([SidebarItem(id: "a", title: "A2", systemImage: "folder")])

        XCTAssertEqual(provider.items.map(\.id), ["a", "b"], "重复 id 应去重保留先注册者")
        XCTAssertEqual(provider.items.first?.title, "A")

        provider.removeItems(ids: ["a"])
        XCTAssertEqual(provider.items.map(\.id), ["b"])
    }

    func testMakeSidebarView() {
        let provider = DefaultSidebarProvider()
        provider.registerItems([SidebarItem(id: "a", title: "A", systemImage: "folder")])
        let view = provider.makeSidebarView()
        XCTAssertNotNil(view)
    }

    func testItemsAreKeptForPluginManagedVisibility() {
        let provider = DefaultSidebarProvider()
        provider.registerItems([
            SidebarItem(id: "git", title: "Git", systemImage: "folder"),
            SidebarItem(id: "banner", title: "Banner", systemImage: "photo"),
        ])

        XCTAssertEqual(provider.visibleItems.map(\.id), ["git", "banner"])
        XCTAssertEqual(provider.activeItemID, "git")
    }
}
