import Foundation
import Testing
@testable import PluginBanner

@Suite("PluginBanner")
struct PluginBannerTests {
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
