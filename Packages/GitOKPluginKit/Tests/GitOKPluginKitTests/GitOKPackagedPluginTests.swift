import SwiftUI
import XCTest
@testable import GitOKPluginKit

private struct SamplePlugin: GitOKPackagedPlugin {
    static let shared = SamplePlugin()
    static let metadata = GitOKPluginMetadata(
        id: "Sample",
        displayName: "Sample",
        description: "Sample plugin",
        tableName: "Sample"
    )
}

final class GitOKPackagedPluginTests: XCTestCase {
    func testMetadataDefaultsAreStable() {
        let metadata = SamplePlugin.metadata

        XCTAssertEqual(metadata.id, "Sample")
        XCTAssertEqual(metadata.iconName, "puzzlepiece.extension")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Sample")
    }

    func testDefaultInstanceLabelUsesMetadataId() {
        XCTAssertEqual(SamplePlugin.shared.instanceLabel, "Sample")
    }

    @MainActor
    func testDefaultStatusBarLeadingViewIsNil() {
        XCTAssertNil(SamplePlugin.shared.statusBarLeadingView())
    }

    @MainActor
    func testDefaultStatusBarCenterViewIsNil() {
        XCTAssertNil(SamplePlugin.shared.statusBarCenterView())
    }

    func testProjectURLEnvironmentDefaultIsNil() {
        XCTAssertNil(EnvironmentValues().gitOKProjectURL)
    }

    func testActivityStatusEnvironmentDefaultIsNil() {
        XCTAssertNil(EnvironmentValues().gitOKActivityStatus)
    }

    func testFileInfoEnvironmentDefaultsAreNil() {
        XCTAssertNil(EnvironmentValues().gitOKSelectedFilePath)
        XCTAssertNil(EnvironmentValues().gitOKProjectPath)
    }
}
