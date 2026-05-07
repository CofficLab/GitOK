import XCTest

final class BannerTemplateCatalogTests: XCTestCase {
    func testDefaultTemplateRulesMatchCurrentContract() {
        XCTAssertEqual(BannerTemplateCatalog.defaultTemplateID, "classic")
        XCTAssertEqual(BannerTemplateCatalog.defaultTemplateIDs, ["classic", "minimal"])
        XCTAssertTrue(BannerTemplateCatalog.containsTemplateID("classic", in: BannerTemplateCatalog.defaultTemplateIDs))
        XCTAssertFalse(BannerTemplateCatalog.containsTemplateID("unknown", in: BannerTemplateCatalog.defaultTemplateIDs))
    }

    func testRegisterTemplateIDAppendsOnlyWhenMissing() {
        var ids = ["classic", "minimal"]

        BannerTemplateCatalog.registerTemplateID("poster", into: &ids)
        BannerTemplateCatalog.registerTemplateID("minimal", into: &ids)

        XCTAssertEqual(ids, ["classic", "minimal", "poster"])
    }
}
