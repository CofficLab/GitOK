import Foundation
import XCTest

final class GitOKSettingsUITests: GitOKUITestCase {
    /// LumiSettings 渲染的设置侧边栏条目不带 accessibility identifier，
    /// 测试按可见标题（英文环境）定位。macOS SwiftUI ScrollView 只暴露
    /// 可视行，因此清单取设置窗口打开时直接可见的条目（与 Cisum 基准一致）；
    /// 更靠下的注册条目（Diagnostics/About/Repository Settings/Network）
    /// 由 PluginFactory 与各插件单测覆盖。
    private let settingsEntryTitles = [
        "General",
        "Projects",
        "Appearance",
        "Plugin Management",
        "User Info",
        "Commit Style",
    ]

    private func settingsEntry(_ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    private func selectSettingsEntry(_ title: String) {
        let entry = settingsEntry(title)
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "Settings section \(title) is missing")
        XCTAssertTrue(entry.isHittable, "Settings section \(title) is not reachable")
        entry.click()
        XCTAssertTrue(entry.exists, "Settings section \(title) disappeared after selection")
    }

    func testToolbarButtonOpensSettingsWindow() {
        _ = openSettings()
        XCTAssertTrue(app.windows.count >= 2, "Opening settings should show a dedicated window")
    }

    func testSettingsSidebarContainsRegisteredSections() {
        _ = openSettings()

        for title in settingsEntryTitles {
            XCTAssertTrue(
                settingsEntry(title).waitForExistence(timeout: 2),
                "Settings sidebar is missing the \(title) section"
            )
        }
    }

    func testSettingsSectionsCanBeSelected() {
        _ = openSettings()

        for title in settingsEntryTitles {
            selectSettingsEntry(title)
        }
    }

    func testSettingsCommandOpensSettingsWindow() {
        let appMenu = app.menuBars.menuBarItems["GitOK"]
        XCTAssertTrue(appMenu.waitForExistence(timeout: 5), "GitOK application menu is missing")
        appMenu.click()
        let settingsCommand = app.menuItems["Settings..."]
        XCTAssertTrue(settingsCommand.waitForExistence(timeout: 5), "Settings command is missing from the app menu")
        settingsCommand.click()
        XCTAssertTrue(
            element(identifier: "gitok.settings.ready").waitForExistence(timeout: 10),
            "The Settings command did not open the settings window"
        )
    }
}
