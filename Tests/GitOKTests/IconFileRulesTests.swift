import Foundation
import Testing

@Suite("IconFileRulesTests")
struct IconFileRulesTests {
    @Test("Supported image detection is case insensitive and filters known formats")
    func supportedImageDetectionIsCaseInsensitiveAndFiltersKnownFormats() {
        #expect(IconFileRules.isSupportedImageFile("logo.PNG"))
        #expect(IconFileRules.isSupportedImageFile("brand.SvG"))
        #expect(!IconFileRules.isSupportedImageFile("notes.txt"))
        #expect(!IconFileRules.isSupportedImageFile("folder"))
    }

    @Test("Image URL mapping and count keep only supported files")
    func imageURLMappingAndCountKeepOnlySupportedFiles() {
        let directory = URL(fileURLWithPath: "/tmp/icons")
        let entries = ["a.png", "b.svg", "c.txt", "README", "d.JPEG"]
        let urls = IconFileRules.imageFileURLs(in: directory, entries: entries)

        #expect(urls.map(\.lastPathComponent) == ["a.png", "b.svg", "d.JPEG"])
        #expect(IconFileRules.iconCount(in: entries) == 3)
    }

    @Test("Preferred lookup candidates keep direct name first then extension fallbacks")
    func preferredLookupCandidatesKeepDirectNameFirstThenExtensionFallbacks() {
        #expect(IconFileRules.preferredLookupCandidates(for: "hash.png") == ["hash.png"])
        #expect(
            IconFileRules.preferredLookupCandidates(for: "hash") ==
                ["hash", "hash.png", "hash.svg", "hash.jpg", "hash.jpeg", "hash.gif", "hash.webp"]
        )
    }
}
