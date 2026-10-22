import Foundation
import KitGit
import XCTest
@testable import PluginGitDiff

/// `GitDiffContentLoader` 的边界场景测试。
///
/// 重点覆盖「补丁文本里出现 `@@` 但并非 hunk 头」这类误判：
/// git 的 diff 文本会带上文件路径，若路径本身含 `@@`，仅用
/// `contains("@@")` 判断是否存在 hunk 就会失准。
final class GitDiffContentLoaderEdgeTests: XCTestCase {
    private let repository = URL(fileURLWithPath: "/tmp/gitok-diff-loader-edge")

    private func loader(
        _ capability: ScriptedDiffContentCapability
    ) -> GitDiffContentLoader {
        GitDiffContentLoader(capability: capability)
    }

    /// 路径本身含 `@@` 时，补丁里有 `@@` 却没有 hunk 头。
    ///
    /// 期望：仍然判定为「无文本差异」，而不是把文件头当成 hunk 去渲染。
    func testPathContainingAtSignIsNotMistakenForHunk() throws {
        let capability = ScriptedDiffContentCapability()
        // 这是一个「文件被删除且原文件为空」的补丁：没有 `@@ -1,0 +0,0 @@`
        // 这样的 hunk 头，只有文件路径里带 `@@`。
        capability.diffs["commit1:notes@@draft.md"] = """
        diff --git a/notes@@draft.md b/notes@@draft.md
        deleted file mode 100644
        index e69de29..0000000
        --- a/notes@@draft.md
        +++ /dev/null
        """

        let content = try loader(capability).load(
            path: "notes@@draft.md",
            commit: DiffTestFixtures.commit(hash: "commit1"),
            repository: repository,
            cancellation: nil
        )

        XCTAssertEqual(
            content,
            .noTextDiff,
            "a path containing @@ must not be mistaken for a hunk header"
        )
    }

    /// 对照组：真正的 hunk 头存在时，即使路径也含 `@@`，仍应返回文本 diff。
    func testRealHunkSurvivesPathContainingAtSign() throws {
        let capability = ScriptedDiffContentCapability()
        capability.diffs["commit1:notes@@draft.md"] = """
        diff --git a/notes@@draft.md b/notes@@draft.md
        deleted file mode 100644
        index 1234567..0000000
        --- a/notes@@draft.md
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -alpha
        -beta
        """

        let content = try loader(capability).load(
            path: "notes@@draft.md",
            commit: DiffTestFixtures.commit(hash: "commit1"),
            repository: repository,
            cancellation: nil
        )

        guard case let .text(diffText) = content else {
            return XCTFail("a real hunk must still yield a text diff, got \(content)")
        }
        XCTAssertTrue(diffText.contains("@@ -1,2 +0,0 @@"))
    }

    /// 补丁文本为空（文件无变更）时应返回「无文本差异」。
    func testEmptyPatchYieldsNoTextDiff() throws {
        let capability = ScriptedDiffContentCapability()
        capability.diffs["commit1:unchanged.txt"] = ""

        let content = try loader(capability).load(
            path: "unchanged.txt",
            commit: DiffTestFixtures.commit(hash: "commit1"),
            repository: repository,
            cancellation: nil
        )

        XCTAssertEqual(content, .noTextDiff)
    }

    // MARK: - PDF 预览 identity

    /// 从「被删除的 PDF」切到「修改过的 PDF」时，identity 必须不同。
    ///
    /// 否则 `GitPDFComparisonPreview` 的 `@State showingPrevious` 会被沿用，
    /// 新文件会继续展示旧版本。
    func testPDFPreviewIdentityDiffersWhenVersionAvailabilityChanges() {
        let deleted = PDFPreviewIdentity(path: "docs/spec.pdf", hasCurrent: false, hasPrevious: true)
        let modified = PDFPreviewIdentity(path: "docs/spec.pdf", hasCurrent: true, hasPrevious: true)

        XCTAssertNotEqual(
            deleted,
            modified,
            "the identity must change when version availability changes"
        )
    }

    /// 同一文件、同样版本可用性时 identity 保持稳定（避免无谓重建）。
    func testPDFPreviewIdentityIsStableForSameContent() {
        let first = PDFPreviewIdentity(path: "docs/spec.pdf", hasCurrent: true, hasPrevious: true)
        let second = PDFPreviewIdentity(path: "docs/spec.pdf", hasCurrent: true, hasPrevious: true)

        XCTAssertEqual(first, second)
    }

    /// 不同文件即使版本可用性相同，identity 也必须不同。
    func testPDFPreviewIdentityDiffersAcrossFiles() {
        let first = PDFPreviewIdentity(path: "docs/a.pdf", hasCurrent: true, hasPrevious: true)
        let second = PDFPreviewIdentity(path: "docs/b.pdf", hasCurrent: true, hasPrevious: true)

        XCTAssertNotEqual(first, second)
    }
}
