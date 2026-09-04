import Foundation
import XCTest
@testable import KitOpenIn

final class KitOpenInTests: XCTestCase {
    func testRemoteWebURLConversion() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "git@github.com:user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "https://github.com/user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "ssh://git@github.com/user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
    }

    func testRemoteTargetAlwaysAvailable() {
        XCTAssertTrue(OpenTarget.remote.isAlwaysAvailable)
        XCTAssertFalse(OpenTarget.vscode.isAlwaysAvailable)
    }

    func testAllTargetsHaveDisplayNameAndSystemImage() {
        for target in OpenTarget.allCases {
            XCTAssertFalse(target.displayName.isEmpty)
            XCTAssertFalse(target.systemImage.isEmpty)
        }
    }

    /// 真实图标解析：系统必装应用（Finder/Terminal）应能取到真实图标；
    /// Remote 使用默认浏览器图标（任何安装了浏览器的 macOS 都应有 https handler）。
    func testInstalledTargetsResolveRealIcon() {
        XCTAssertNotNil(AppLauncher.iconImage(for: .finder))
        XCTAssertNotNil(AppLauncher.iconImage(for: .terminal))
        XCTAssertNotNil(AppLauncher.iconImage(for: .remote))
    }
}
