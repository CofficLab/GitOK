import XCTest
@testable import ProviderSidebar

@MainActor
final class DefaultSidebarProviderAdditionalTests: XCTestCase {
    func testActivationChangedCallbacks() {
        var activatedIDs: [String] = []
        var deactivatedIDs: [String] = []

        let itemA = SidebarItem(
            id: "a", title: "A", systemImage: "folder", order: 1,
            onActivationChanged: { state in
                switch state {
                case .activated: activatedIDs.append("a")
                case .deactivated: deactivatedIDs.append("a")
                }
            }
        )
        let itemB = SidebarItem(
            id: "b", title: "B", systemImage: "folder", order: 2,
            onActivationChanged: { state in
                switch state {
                case .activated: activatedIDs.append("b")
                case .deactivated: deactivatedIDs.append("b")
                }
            }
        )

        let provider = DefaultSidebarProvider()
        provider.registerItems([itemA, itemB])
        // 注册后默认激活第一个（a）。
        XCTAssertEqual(activatedIDs, ["a"])

        provider.activateItem(id: "b")
        XCTAssertEqual(deactivatedIDs, ["a"])
        XCTAssertEqual(activatedIDs, ["a", "b"])
    }

    func testActivateNilClearsSelection() {
        let provider = DefaultSidebarProvider()
        provider.registerItems([SidebarItem(id: "a", title: "A", systemImage: "folder")])
        XCTAssertEqual(provider.activeItemID, "a")

        provider.activateItem(id: nil)
        XCTAssertNil(provider.activeItemID)
    }
}
