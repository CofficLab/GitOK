import Testing
@testable import KitGitOKSupport

@Suite("KitGitOKSupport")
struct MagicBackgroundGroupTests {
    @Test("restores the legacy gradient catalog")
    func restoresLegacyGradientCatalog() {
        #expect(MagicBackgroundGroup.all.count == 54)
        #expect(MagicBackgroundGroup.all.contains(.blue2white_center))
        #expect(MagicBackgroundGroup.GradientName.blue2cyan.displayName == "blue → cyan")
    }

    @Test("maps legacy numeric background IDs")
    func mapsLegacyBackgroundIDs() {
        #expect(MagicBackgroundGroup.gradientName(for: "1") == .blue2cyan)
        #expect(MagicBackgroundGroup.gradientName(for: "2") == .blue2purple_l2r)
        #expect(MagicBackgroundGroup.gradientName(for: "3") == .orange2yellow_tl2br)
        #expect(MagicBackgroundGroup.gradientName(for: "unknown") == .blue2cyan)
    }
}
