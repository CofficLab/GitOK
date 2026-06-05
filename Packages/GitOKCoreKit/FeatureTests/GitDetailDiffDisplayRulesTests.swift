@testable import GitOKCoreFeatures
import Testing

@Suite("GitDetailDiffDisplayRules")
struct GitDetailDiffDisplayRulesTests {
    @Test("image preview too large message includes measured and limit sizes")
    func imagePreviewTooLargeMessageIncludesSizes() {
        let message = GitDetailDiffDisplayRules.imagePreviewTooLargeMessage(
            byteCount: 21 * 1024 * 1024,
            maxBytes: 20 * 1024 * 1024
        )

        #expect(message.contains("21 MB"))
        #expect(message.contains("20 MB"))
    }
}
