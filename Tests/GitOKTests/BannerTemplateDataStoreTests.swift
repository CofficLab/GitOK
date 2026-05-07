import Foundation
import XCTest

final class BannerTemplateDataStoreTests: XCTestCase {
    func testDecodeReturnsNilForMissingOrInvalidTemplateData() {
        XCTAssertNil(
            BannerTemplateDataStore.decode(
                SampleBannerTemplatePayload.self,
                templateID: "classic",
                from: [:]
            )
        )

        XCTAssertNil(
            BannerTemplateDataStore.decode(
                SampleBannerTemplatePayload.self,
                templateID: "classic",
                from: ["classic": "not-json"]
            )
        )
    }

    func testUpdateEncodedStoresJSONThatCanRoundTrip() {
        var templateData: [String: String] = [:]
        let payload = SampleBannerTemplatePayload(title: "Hello", opacity: 0.8)

        BannerTemplateDataStore.updateEncoded(payload, templateID: "minimal", in: &templateData)

        let restored = BannerTemplateDataStore.decode(
            SampleBannerTemplatePayload.self,
            templateID: "minimal",
            from: templateData
        )

        XCTAssertEqual(restored, payload)
        XCTAssertNotNil(templateData["minimal"])
    }

    func testUpdateEncodedRemovesEntryWhenValueIsNil() {
        var templateData = ["classic": "{\"title\":\"Old\",\"opacity\":1}"]

        BannerTemplateDataStore.updateEncoded(
            Optional<SampleBannerTemplatePayload>.none,
            templateID: "classic",
            in: &templateData
        )

        XCTAssertNil(templateData["classic"])
    }

    func testUpdateEncodedOnlyTouchesRequestedTemplateID() {
        var templateData = [
            "classic": "{\"title\":\"Classic\",\"opacity\":1}",
            "minimal": "{\"title\":\"Minimal\",\"opacity\":0.5}"
        ]

        BannerTemplateDataStore.updateEncoded(
            SampleBannerTemplatePayload(title: "Updated", opacity: 0.9),
            templateID: "classic",
            in: &templateData
        )

        let classic = BannerTemplateDataStore.decode(
            SampleBannerTemplatePayload.self,
            templateID: "classic",
            from: templateData
        )
        let minimal = BannerTemplateDataStore.decode(
            SampleBannerTemplatePayload.self,
            templateID: "minimal",
            from: templateData
        )

        XCTAssertEqual(classic, SampleBannerTemplatePayload(title: "Updated", opacity: 0.9))
        XCTAssertEqual(minimal, SampleBannerTemplatePayload(title: "Minimal", opacity: 0.5))
    }
}

private struct SampleBannerTemplatePayload: Codable, Equatable {
    let title: String
    let opacity: Double
}
