import Foundation
import XCTest

final class GitOKWorkspaceUITests: GitOKUITestCase {
    func testScenePickerListsGitBannerAndIconWorkspaces() {
        let switcher = element(identifier: "gitok.workspace.scene.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        switcher.click()

        for scene in ["git", "banner", "icon"] {
            XCTAssertTrue(
                element(identifier: "gitok.workspace.scene.option.\(scene)").waitForExistence(timeout: 5),
                "Scene picker is missing the \(scene) workspace"
            )
        }
    }

    func testSelectingSceneUpdatesToolbarAndClosesPicker() {
        element(identifier: "gitok.workspace.scene.switcher").click()

        let banner = element(identifier: "gitok.workspace.scene.option.banner")
        XCTAssertTrue(banner.waitForExistence(timeout: 5), "Banner workspace option is missing")
        banner.click()
        XCTAssertTrue(
            app.staticTexts["Banner Editor"].waitForExistence(timeout: 10),
            "The Banner workspace did not show its editor"
        )

        let switcher = element(identifier: "gitok.workspace.scene.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        XCTAssertTrue(switcher.label.localizedCaseInsensitiveContains("Banner"))

        switcher.click()
        let icon = element(identifier: "gitok.workspace.scene.option.icon")
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        icon.click()
        XCTAssertTrue(
            app.staticTexts["Icon Editor"].waitForExistence(timeout: 10),
            "The Icon workspace did not show its editor"
        )
        XCTAssertTrue(
            element(identifier: "gitok.workspace.scene.switcher").label.localizedCaseInsensitiveContains("Icon")
        )
    }

    /// 场景隔离：切到非 Git 场景后，Git 工作台（分支选择器 / 提交表单）
    /// 必须整体隐藏，不能残留上一个场景的控件。
    func testSwitchingAwayFromGitSceneHidesGitWorkbench() {
        XCTAssertTrue(
            element(identifier: "gitok.git.branch.switcher").waitForExistence(timeout: 20),
            "The Git branch switcher should be visible in the Git scene"
        )
        XCTAssertTrue(
            element(identifier: "gitok.commit.subject").waitForExistence(timeout: 20),
            "The commit form should be visible in the Git scene"
        )

        let switcher = element(identifier: "gitok.workspace.scene.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        switcher.click()

        let banner = element(identifier: "gitok.workspace.scene.option.banner")
        XCTAssertTrue(banner.waitForExistence(timeout: 5), "Banner workspace option is missing")
        banner.click()
        XCTAssertTrue(
            app.staticTexts["Banner Editor"].waitForExistence(timeout: 10),
            "The Banner workspace did not show its editor"
        )

        XCTAssertFalse(
            element(identifier: "gitok.git.branch.switcher").exists,
            "The Git branch switcher is still visible outside the Git scene"
        )
        XCTAssertFalse(
            element(identifier: "gitok.commit.subject").exists,
            "The commit form is still visible outside the Git scene"
        )
    }
}
import Foundation
import XCTest
