import Foundation
import Testing

@Suite("BannerStorageRulesTests")
struct BannerStorageRulesTests {
    @Test("Builds banner directory under project storage path")
    func buildsBannerDirectoryUnderProjectStoragePath() {
        let url = BannerStorageRules.bannerDirectoryURL(
            projectPath: "/tmp/repo",
            storagePath: ".gitok/banners"
        )

        #expect(url.path == "/tmp/repo/.gitok/banners")
    }

    @Test("New banner file name uses integer unix timestamp")
    func newBannerFileNameUsesIntegerUnixTimestamp() {
        let date = Date(timeIntervalSince1970: 1_715_079_200.9)
        #expect(BannerStorageRules.newBannerFileName(now: date) == "banner_1715079200.json")
    }

    @Test("Relative project path strips project prefix only")
    func relativeProjectPathStripsProjectPrefixOnly() {
        let fileURL = URL(fileURLWithPath: "/tmp/repo/.gitok/banners/images/demo.png")
        #expect(
            BannerStorageRules.relativeProjectPath(for: fileURL, projectPath: "/tmp/repo") ==
                "/.gitok/banners/images/demo.png"
        )
    }
}
