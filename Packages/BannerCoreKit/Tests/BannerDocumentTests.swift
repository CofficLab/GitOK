import BannerCoreKit
import XCTest

final class BannerDocumentTests: XCTestCase {
    func testTemplateDataHelpersReadAndWriteValues() {
        var document = BannerDocument()

        XCTAssertNil(document.templateDataValue(for: "classic"))

        document.setTemplateDataValue("{\"title\":\"Hello\"}", for: "classic")

        XCTAssertEqual(document.templateDataValue(for: "classic"), "{\"title\":\"Hello\"}")
    }

    func testCodableRoundTripPreservesStoredFields() throws {
        let document = BannerDocument(
            templateData: [
                "classic": "{\"title\":\"Classic\"}",
                "minimal": "{\"title\":\"Minimal\"}",
            ],
            lastSelectedTemplateId: "minimal"
        )

        let data = try JSONEncoder().encode(document)
        let restored = try JSONDecoder().decode(BannerDocument.self, from: data)

        XCTAssertEqual(restored, document)
    }
}
