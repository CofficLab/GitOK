@testable import BannerPlugin
import Foundation
import Testing

@Suite("BannerPlugin")
struct BannerPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(BannerPlugin.metadata.id == "BannerPlugin")
        #expect(BannerPlugin.metadata.iconName == "puzzlepiece.extension")
        #expect(BannerPlugin.metadata.order == 2)
        #expect(BannerPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(BannerPlugin.metadata.displayName.isEmpty == false)
    }

    @Test("oversized preview image is skipped")
    func oversizedPreviewImageIsSkipped() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageURL = directory.appendingPathComponent("large.png")
        try Data(repeating: 0, count: BannerImageLoadingRules.maxPreviewImageBytes + 1).write(to: imageURL)

        #expect(BannerImageLoadingRules.previewImage(at: imageURL) == nil)
    }
}
