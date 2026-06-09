@testable import IconPlugin
import Foundation
import Testing

@Suite("IconPlugin")
struct IconPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(IconPlugin.metadata.id == "IconPlugin")
        #expect(IconPlugin.metadata.iconName == "photo")
        #expect(IconPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized strings resolve")
    func localizedStringsResolve() {
        #expect(IconPlugin.metadata.displayName.isEmpty == false)
        #expect(IconPlugin.metadata.description.isEmpty == false)
    }

    @Test("oversized local preview image is skipped")
    func oversizedLocalPreviewImageIsSkipped() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let imageURL = directory.appendingPathComponent("large.png")
        try Data(repeating: 0, count: IconImageLoadingRules.maxPreviewImageBytes + 1).write(to: imageURL)

        #expect(IconImageLoadingRules.localImage(at: imageURL) == nil)
        #expect(IconImageLoadingRules.decodedImage(from: Data(repeating: 0, count: IconImageLoadingRules.maxPreviewImageBytes + 1)) == nil)
    }
}
