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
}
