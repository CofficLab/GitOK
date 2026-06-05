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

    @Test("selected commit previous image source uses selected parent directly")
    func selectedCommitPreviousImageSourceUsesSelectedParentDirectly() {
        let source = GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: .commit(hash: "child"),
            selectedCommitParentHashes: ["parent", "second-parent"],
            headHash: "head"
        )

        #expect(source == .commit(hash: "parent"))
    }

    @Test("selected root commit previous image source is unavailable")
    func selectedRootCommitPreviousImageSourceIsUnavailable() {
        let source = GitDetailDiffDisplayRules.previousFileContentSource(
            currentSource: .commit(hash: "root"),
            selectedCommitParentHashes: [],
            headHash: "head"
        )

        #expect(source == .unavailable)
    }
}
