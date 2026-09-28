import Foundation
import XCTest

final class GitOKSettingsUITests: GitOKUITestCase {
    private let settingsEntryIDs = [
        "general",
        "projects",
        "appearance",
        "plugin-manager",
        "userInfo",
        "commitStyle",
    ]

    private func selectSettingsEntry(_ entryID: String) {
        let entry = element(identifier: "settings.entry.\(entryID)")
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "Settings section \(entryID) is missing")

        // Walk the settings sidebar as rows move below the visible part of the window.
        let settingsWindow = app.windows.element(boundBy: 1)
        for _ in 0..<8 where !entry.isHittable {
            let sidebar = settingsWindow.scrollViews.firstMatch
            guard sidebar.exists else { break }
            sidebar.swipeUp()
        }
        XCTAssertTrue(entry.isHittable, "Settings section \(entryID) is not reachable")
        entry.click()
        XCTAssertTrue(
            element(identifier: "settings.detail.\(entryID)").waitForExistence(timeout: 5),
            "Settings detail for \(entryID) did not load after selection"
        )
    }

    func testToolbarButtonOpensSettingsWindow() {
        _ = openSettings()
        XCTAssertTrue(app.windows.count >= 2, "Opening settings should show a dedicated window")
    }

    func testSettingsSidebarContainsRegisteredSections() {
        _ = openSettings()

        for entryID in settingsEntryIDs {
            XCTAssertTrue(
                element(identifier: "settings.entry.\(entryID)").waitForExistence(timeout: 5),
                "Settings sidebar is missing the \(entryID) section"
            )
        }
    }

    func testSettingsSectionsCanBeSelected() {
        _ = openSettings()

        for entryID in settingsEntryIDs {
            selectSettingsEntry(entryID)
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
import Foundation
import XCTest
