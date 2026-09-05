import Foundation
import Testing
@testable import PluginBanner

@Suite("PluginBanner")
struct PluginBannerTests {
    @MainActor
    @Test("exports standard banners using the shared render view")
    func exportsStandardBanners() throws {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginBannerExport-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let configuration = BannerRenderConfiguration(
            templateID: BannerTemplateID.classic,
            title: "Demo",
            subTitle: "Ship it",
            features: ["Fast", "Native"],
            backgroundID: "2"
        )
        try BannerExporter.exportStandardPNG(configuration: configuration, to: folderURL)

        let files = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        )
        #expect(files.count == BannerExporter.standardDevices.count)
        #expect(files.contains { $0.lastPathComponent.contains("iPhoneBig") })
        #expect((try? Data(contentsOf: files[0]))?.count ?? 0 > 100)
    }

    @Test("template data keeps the legacy classic and minimal IDs")
    func templateDataRoundTrips() throws {
        var banner = BannerFile(path: "/tmp/banner.json", projectURL: URL(fileURLWithPath: "/tmp/project"))
        banner.classicData = ClassicBannerData(
            title: "Demo",
            subTitle: "Ship it",
            selectedDevice: BannerExportDevice.MacBook.rawValue
        )
        banner.minimalData = MinimalBannerData(title: "Minimal")

        #expect(banner.classicData?.title == "Demo")
        #expect(banner.classicData?.selectedDevice == BannerExportDevice.MacBook.rawValue)
        #expect(banner.minimalData?.title == "Minimal")
        #expect(banner.templateData.keys.sorted() == [BannerTemplateID.classic, BannerTemplateID.minimal])
    }

    @Test("creates and reloads a banner using the legacy project path")
    func createsAndReloadsBanner() throws {
        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginBanner-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: projectURL) }

        let repository = BannerRepository()
        let created = try repository.createBanner(
            in: projectURL,
            now: Date(timeIntervalSince1970: 1_715_079_200)
        )
        var updated = created
        updated.lastSelectedTemplateId = "minimal"
        updated.setTemplateData("minimal", data: "{\"title\":\"Demo\"}")
        try repository.save(updated)

        let loaded = repository.getBanners(from: projectURL)
        #expect(loaded.count == 1)
        #expect(loaded[0].lastSelectedTemplateId == "minimal")
        #expect(loaded[0].getTemplateData("minimal") == "{\"title\":\"Demo\"}")
        #expect(loaded[0].path.hasSuffix(".gitok/banners/banner_1715079200.json"))
    }

    @Test("imports banner images into project-owned storage")
    func importsBannerImage() throws {
        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginBannerImage-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: projectURL) }

        let sourceURL = projectURL.deletingLastPathComponent().appendingPathComponent("source-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: sourceURL) }
        try Data([0, 1, 2, 3]).write(to: sourceURL)

        let repository = BannerRepository()
        let imageID = try repository.importImage(from: sourceURL, for: projectURL)
        let storedURL = repository.imageURL(for: imageID, in: projectURL)

        #expect(imageID.hasPrefix(".gitok/banners/images/"))
        #expect(FileManager.default.fileExists(atPath: storedURL.path))
        #expect(repository.imageURL(for: "/\(imageID)", in: projectURL).path == storedURL.path)
    }

    @Test("skips malformed JSON and deletes a banner")
    func skipsMalformedJSONAndDeletesBanner() throws {
        let projectURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginBanner-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: projectURL) }

        let repository = BannerRepository()
        let directoryURL = BannerRepository.bannerDirectoryURL(for: projectURL)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(
            to: directoryURL.appendingPathComponent("broken.json")
        )

        let banner = try repository.createBanner(in: projectURL)
        #expect(repository.getBanners(from: projectURL).count == 1)

        try repository.delete(banner)
        #expect(repository.getBanners(from: projectURL).isEmpty)
    }
}
