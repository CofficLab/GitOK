import GitOKCoreKit
import XCTest
@testable import FileInfoPlugin

final class FileInfoPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = FileInfoPlugin.metadata

        XCTAssertEqual(metadata.id, "SmartFilePlugin")
        XCTAssertEqual(metadata.displayName, "FileInfo")
        XCTAssertEqual(metadata.iconName, "doc.text")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(FileInfoPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(FileInfoPluginLocalization.string("File Actions").isEmpty)
        XCTAssertFalse(FileInfoPluginLocalization.string("Copy Path").isEmpty)
    }

    @MainActor
    func testStatusBarLeadingContributionIsAvailable() {
        let context = GitOKPluginContext(
            projectPath: "/tmp/GitOK",
            selectedFilePath: "Sources/App/main.swift"
        )

        XCTAssertNotNil(FileInfoPlugin.shared.statusBarLeadingView(context: context))
    }

    func testPathComponents() {
        XCTAssertEqual(FileInfoPathPresentation.components(for: "Sources/App/main.swift"), ["Sources", "App", "main.swift"])
        XCTAssertEqual(FileInfoPathPresentation.displayComponents(for: ""), [""])
    }

    func testTargetURLBuildsRelativePathAgainstProject() {
        let url = FileInfoPathPresentation.targetURL(
            projectPath: "/tmp/GitOK",
            filePath: "Sources/App/main.swift"
        )

        XCTAssertEqual(url?.path, "/tmp/GitOK/Sources/App/main.swift")
    }
}
