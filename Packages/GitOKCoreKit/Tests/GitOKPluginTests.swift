import SwiftUI
import XCTest
@testable import GitOKCoreKit

private enum SamplePlugin: GitOKPlugin {
    static let metadata = GitOKPluginMetadata(
        id: "Sample",
        displayName: "Sample",
        description: "Sample plugin",
        tableName: "Sample"
    )
}

final class GitOKPluginTests: XCTestCase {
    func testMetadataDefaultsAreStable() {
        let metadata = SamplePlugin.metadata

        XCTAssertEqual(metadata.id, "Sample")
        XCTAssertEqual(metadata.iconName, "puzzlepiece.extension")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Sample")
        XCTAssertEqual(metadata.policy, .disabled)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
    }

    func testPolicyValuesDeriveRegistrationAndEnablement() {
        XCTAssertTrue(GitOKPluginPolicy.alwaysOn.shouldRegister)
        XCTAssertFalse(GitOKPluginPolicy.alwaysOn.allowUserToggle)
        XCTAssertTrue(GitOKPluginPolicy.alwaysOn.defaultEnabled)

        XCTAssertTrue(GitOKPluginPolicy.optOut.shouldRegister)
        XCTAssertTrue(GitOKPluginPolicy.optOut.allowUserToggle)
        XCTAssertTrue(GitOKPluginPolicy.optOut.defaultEnabled)

        XCTAssertTrue(GitOKPluginPolicy.optIn.shouldRegister)
        XCTAssertTrue(GitOKPluginPolicy.optIn.allowUserToggle)
        XCTAssertFalse(GitOKPluginPolicy.optIn.defaultEnabled)

        XCTAssertFalse(GitOKPluginPolicy.disabled.shouldRegister)
        XCTAssertFalse(GitOKPluginPolicy.disabled.allowUserToggle)
        XCTAssertFalse(GitOKPluginPolicy.disabled.defaultEnabled)
    }

    @MainActor
    func testDefaultStatusBarLeadingItemsIsEmpty() {
        XCTAssertEqual(SamplePlugin.statusBarLeadingItems(context: GitOKPluginContext()), [])
    }

    @MainActor
    func testDefaultStatusBarCenterItemsIsEmpty() {
        XCTAssertEqual(SamplePlugin.statusBarCenterItems(context: GitOKPluginContext()), [])
    }
}
