import BannerCoreKit
import XCTest

final class BannerRecordTests: XCTestCase {
    func testIdentityMatchesPath() {
        let record = BannerRecord(path: "/tmp/banner.json")
        XCTAssertEqual(record.id, "/tmp/banner.json")
    }

    func testCodableRoundTripPreservesPathAndDocument() throws {
        let record = BannerRecord(
            path: "/tmp/banner.json",
            document: BannerDocument(
                templateData: ["classic": "{\"title\":\"Classic\"}"],
                lastSelectedTemplateId: "classic"
            )
        )

        let data = try JSONEncoder().encode(record)
        let restored = try JSONDecoder().decode(BannerRecord.self, from: data)

        XCTAssertEqual(restored, record)
    }
}
