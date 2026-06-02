import GitOKCoreKit
import XCTest
@testable import LicensePlugin

final class LicensePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = LicensePlugin.metadata

        XCTAssertEqual(metadata.id, "LicensePlugin")
        XCTAssertEqual(metadata.iconName, "doc.on.doc")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(LicensePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(LicensePluginLocalization.string("License").isEmpty)
        XCTAssertFalse(LicensePluginLocalization.string("LICENSE entry in status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/test"))
        XCTAssertNotNil(LicensePlugin.shared.statusBarTrailingView(context: context))
    }

    @MainActor
    func testStatusBarContributionReturnsNilWithoutProject() {
        let context = GitOKPluginContext()
        XCTAssertNil(LicensePlugin.shared.statusBarTrailingView(context: context))
    }

    func testLicenseDocumentWritesCanonicalLicenseFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try LicenseDocument.write("MIT\n", in: directory)

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("LICENSE").path))
        XCTAssertEqual(try LicenseDocument.read(in: directory), "MIT\n")
        XCTAssertEqual(try ProjectDocumentResolver.readLicenseContent(in: directory), "MIT\n")
    }

    func testTemplatesAreAvailable() {
        XCTAssertEqual(LicenseTemplate.allCases.count, 3)
        XCTAssertTrue(LicenseTemplate.mit.content.contains("MIT License"))
        XCTAssertTrue(LicenseTemplate.apache2.content.contains("Apache License"))
        XCTAssertTrue(LicenseTemplate.gpl3.content.contains("GNU GENERAL PUBLIC LICENSE"))
    }
}
