import SwiftUI
import XCTest
@testable import GitOKCoreKit

private struct SamplePlugin: GitOKPlugin {
    static let shared = SamplePlugin()
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

    func testDefaultInstanceLabelUsesMetadataId() {
        XCTAssertEqual(SamplePlugin.shared.instanceLabel, "Sample")
    }

    @MainActor
    func testDefaultStatusBarLeadingViewIsNil() {
        XCTAssertNil(SamplePlugin.shared.statusBarLeadingView(context: GitOKPluginContext()))
    }

    @MainActor
    func testDefaultStatusBarCenterViewIsNil() {
        XCTAssertNil(SamplePlugin.shared.statusBarCenterView(context: GitOKPluginContext()))
    }
}
