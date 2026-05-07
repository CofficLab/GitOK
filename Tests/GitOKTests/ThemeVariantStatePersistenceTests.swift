import Foundation
import Testing

@Suite("ThemeVariantStatePersistenceTests")
struct ThemeVariantStatePersistenceTests {
    @Test("Load returns nil for missing or invalid plist")
    func loadReturnsNilForMissingOrInvalidPlist() throws {
        let rootURL = try makeTemporaryDirectory()
        let fileURL = rootURL.appendingPathComponent("theme_state.plist")

        #expect(ThemeVariantStatePersistence.loadString(forKey: "theme", fileURL: fileURL) == nil)

        try Data("bad".utf8).write(to: fileURL)
        #expect(ThemeVariantStatePersistence.loadString(forKey: "theme", fileURL: fileURL) == nil)
    }

    @Test("Save round-trips and preserves unrelated keys")
    func saveRoundTripsAndPreservesUnrelatedKeys() throws {
        let rootURL = try makeTemporaryDirectory()
        let fileURL = rootURL.appendingPathComponent("theme_state.plist")

        ThemeVariantStatePersistence.saveString(
            "dark",
            forKey: "appearance",
            fileURL: fileURL,
            settingsDirURL: rootURL,
            tmpFileName: "theme_state.tmp"
        )
        ThemeVariantStatePersistence.saveString(
            "minimal",
            forKey: "banner",
            fileURL: fileURL,
            settingsDirURL: rootURL,
            tmpFileName: "theme_state.tmp"
        )

        #expect(ThemeVariantStatePersistence.loadString(forKey: "appearance", fileURL: fileURL) == "dark")
        #expect(ThemeVariantStatePersistence.loadString(forKey: "banner", fileURL: fileURL) == "minimal")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
