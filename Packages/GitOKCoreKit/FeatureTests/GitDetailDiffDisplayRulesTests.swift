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

    @Test("single file diff remains renderable")
    func singleFileDiffRemainsRenderable() {
        let diff = """
        diff --git a/README.md b/README.md
        index 1111111..2222222 100644
        --- a/README.md
        +++ b/README.md
        @@ -1 +1 @@
        -old
        +new
        """

        #expect(GitDetailDiffDisplayRules.diffFileCount(in: diff) == 1)
        #expect(GitDetailDiffDisplayRules.diffContentMode(diffText: diff) == .render)
    }

    @Test("multi-file diff skips rendering before view count explodes")
    func multiFileDiffSkipsRenderingBeforeViewCountExplodes() {
        let diff = (0...GitDetailDiffDisplayRules.maxRenderableDiffFiles).map { index in
            """
            diff --git a/File\(index).swift b/File\(index).swift
            index 1111111..2222222 100644
            --- a/File\(index).swift
            +++ b/File\(index).swift
            @@ -1 +1 @@
            -old
            +new
            """
        }.joined(separator: "\n")

        #expect(GitDetailDiffDisplayRules.diffFileCount(in: diff) == GitDetailDiffDisplayRules.maxRenderableDiffFiles + 1)
        #expect(GitDetailDiffDisplayRules.diffContentMode(diffText: diff) == .large)
    }
}
