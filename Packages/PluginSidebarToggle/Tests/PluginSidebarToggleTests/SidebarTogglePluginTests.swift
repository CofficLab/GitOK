import XCTest

@testable import PluginSidebarToggle

final class SidebarTogglePluginTests: XCTestCase {
    func testPluginMetadata() {
        let plugin = SidebarTogglePlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.sidebar-toggle")
        XCTAssertEqual(SidebarTogglePlugin.toolbarItemID, "com.coffic.gitok.plugin.sidebar-toggle.toggleSidebar")
    }
}
