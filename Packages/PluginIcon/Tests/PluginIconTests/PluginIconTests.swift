import Foundation
import Testing
@testable import PluginIcon

@Suite("PluginIcon")
struct PluginIconTests {
    @Test("project image source provider scans supported image files")
    func scansProjectImageSource() async throws {
        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginIconSources-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: projectURL) }
        let directory = projectURL.appendingPathComponent(".gitok/images", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data([0, 1]).write(to: directory.appendingPathComponent("a.png"))
        try Data([0, 1]).write(to: directory.appendingPathComponent("ignored.txt"))

        let provider = DefaultIconSourceProvider()
        let assets = try await provider.assets(for: IconSourceID.projectImages, in: projectURL)
        #expect(assets.map(\.title) == ["a"])
        #expect(assets.first?.sourceID == IconSourceID.projectImages)
    }

    @Test("generated source exposes the legacy MagicAsset set")
    func exposesGeneratedAssets() async throws {
        let provider = DefaultIconSourceProvider()
        let assets = try await provider.assets(
            for: IconSourceID.generatedAssets,
            in: FileManager.default.temporaryDirectory
        )
        #expect(assets.count == 9)
        #expect(assets.allSatisfy { $0.sourceID == IconSourceID.generatedAssets })
        #expect(assets.contains { $0.title == "Camera" })
    }

    @Test("bundled source scans category folders when provided")
    func scansBundledSource() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginIconBundled-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let category = root.appendingPathComponent("Abstract", isDirectory: true)
        try FileManager.default.createDirectory(at: category, withIntermediateDirectories: true)
        try Data([0, 1]).write(to: category.appendingPathComponent("asset.svg"))

        let provider = DefaultIconSourceProvider(bundledIconsURL: root)
        let assets = try await provider.assets(for: IconSourceID.bundledIcons, in: root)
        #expect(provider.sources.first?.id == IconSourceID.bundledIcons)
        #expect(assets.first?.category == "Abstract")
    }

    @Test("source assets retain categories for filtering")
    func retainsSourceCategories() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginIconCategories-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        for category in ["Abstract", "Business"] {
            let directory = root.appendingPathComponent(category, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data([0, 1]).write(to: directory.appendingPathComponent("asset-\(category).svg"))
        }

        let provider = DefaultIconSourceProvider(bundledIconsURL: root)
        let assets = try await provider.assets(for: IconSourceID.bundledIcons, in: root)
        #expect(Set(assets.compactMap(\.category)) == ["Abstract", "Business"])
    }

    @Test("legacy icon JSON accepts integer icon IDs")
    func acceptsIntegerIconID() throws {
        let data = Data(#"{"title":"Demo","iconId":7,"backgroundId":"3"}"#.utf8)
        let decoder = JSONDecoder()
        let icon = try decoder.decode(IconData.self, from: data)

        #expect(icon.iconId == "7")
        #expect(icon.opacity == 1)
        #expect(icon.padding == 0.12)
    }

    @Test("creates, reloads, imports and deletes project icon data")
    func repositoryRoundTrip() throws {
        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginIcon-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: projectURL) }

        let repository = IconRepository()
        let icon = try repository.createIcon(in: projectURL, title: "Demo")
        #expect(repository.getIcons(from: projectURL).map(\.title) == ["Demo"])

        let sourceURL = projectURL.appendingPathComponent("source.png")
        try Data([0, 1, 2]).write(to: sourceURL)
        let importedURL = try repository.importImage(sourceURL, for: projectURL)
        #expect(importedURL.pathExtension == "png")
        #expect(FileManager.default.fileExists(atPath: importedURL.path))

        try repository.delete(icon)
        #expect(repository.getIcons(from: projectURL).isEmpty)
    }
}
