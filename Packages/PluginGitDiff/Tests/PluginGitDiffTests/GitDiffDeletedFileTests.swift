import Foundation
import KitGit
import XCTest
@testable import PluginGitDiff

/// 删除文件的 diff 展示回归测试。
///
/// 覆盖三类「文件被删除」的场景：
/// 1. 空文件被删除 —— git 不产生 `@@` hunk，视图不能渲染成空白面板；
/// 2. 二进制文件（图片）被删除 —— 当前 commit 无 blob，应回退到父提交；
/// 3. PDF 被删除 —— 应能展示删除前的版本，而不是「PDF Preview Unavailable」。
final class GitDiffDeletedFileTests: XCTestCase {
    private let repository = URL(fileURLWithPath: "/tmp/gitok-deleted-file-repo")

    private func makeLoader(
        _ capability: ScriptedDiffContentCapability
    ) -> GitDiffContentLoader {
        GitDiffContentLoader(capability: capability)
    }

    // MARK: - Bug 1: 空文件被删除

    /// git 对 0 字节文件的删除只输出 `deleted file mode`，没有 `@@` hunk。
    ///
    /// `MagicDiffView` 的解析器要求文本含 `@@`，否则产出空 diffItems；
    /// 若加载器仍返回 `.text`，面板会渲染成一块什么都没有的空白区域，
    /// 而不是明确的「No Text Diff」空状态。
    func testDeletedEmptyTextFileYieldsNoTextDiffInsteadOfBlankPanel() throws {
        let capability = ScriptedDiffContentCapability()
        capability.diffs["commit1:empty.txt"] = """
        diff --git a/empty.txt b/empty.txt
        deleted file mode 100644
        index e69de29..0000000
        """

        let content = try makeLoader(capability).load(
            path: "empty.txt",
            commit: DiffTestFixtures.commit(hash: "commit1"),
            repository: repository,
            cancellation: nil
        )

        XCTAssertEqual(
            content,
            .noTextDiff,
            "a deleted empty file has no hunk and should show the No Text Diff state"
        )
    }

    /// 对照组：非空文本文件被删除时有 `@@` hunk，应正常返回文本 diff。
    func testDeletedNonEmptyTextFileYieldsTextDiff() throws {
        let capability = ScriptedDiffContentCapability()
        capability.diffs["commit1:notes.txt"] = """
        diff --git a/notes.txt b/notes.txt
        deleted file mode 100644
        index 1234567..0000000
        --- a/notes.txt
        +++ /dev/null
        @@ -1,3 +0,0 @@
        -alpha
        -beta
        -gamma
        """

        let content = try makeLoader(capability).load(
            path: "notes.txt",
            commit: DiffTestFixtures.commit(hash: "commit1"),
            repository: repository,
            cancellation: nil
        )

        guard case let .text(diffText) = content else {
            return XCTFail("a deleted non-empty text file should yield a text diff, got \(content)")
        }
        XCTAssertTrue(diffText.contains("@@ -1,3 +0,0 @@"))
        XCTAssertTrue(diffText.contains("-alpha"))
    }

    // MARK: - Bug 2: 二进制文件被删除

    /// 被删除的图片在当前 commit 里没有 blob（`git cat-file blob` 退出码 128）。
    ///
    /// 加载器应回退到父提交取 blob 展示被删掉的内容，而不是把 git 错误
    /// 直接抛给用户看「Unable to Load Diff」。
    func testDeletedBinaryFileFallsBackToParentCommitBlob() throws {
        let capability = ScriptedDiffContentCapability()
        // 当前 commit 无该文件；父提交有。
        capability.blobs["parent1:assets/logo.png"] = Data([0x89, 0x50, 0x4E, 0x47])

        let content = try makeLoader(capability).load(
            path: "assets/logo.png",
            commit: DiffTestFixtures.commit(hash: "commit1", parents: ["parent1"]),
            repository: repository,
            cancellation: nil
        )

        guard case let .binary(kind, data) = content else {
            return XCTFail("a deleted image should fall back to the parent commit blob, got \(content)")
        }
        XCTAssertEqual(kind, .image)
        XCTAssertEqual(data, Data([0x89, 0x50, 0x4E, 0x47]))
    }

    /// 未被删除的二进制文件仍应读当前 commit 的 blob，不受影响。
    func testExistingBinaryFileStillReadsCurrentCommitBlob() throws {
        let capability = ScriptedDiffContentCapability()
        capability.blobs["commit1:assets/logo.png"] = Data([0x01, 0x02])

        let content = try makeLoader(capability).load(
            path: "assets/logo.png",
            commit: DiffTestFixtures.commit(hash: "commit1", parents: ["parent1"]),
            repository: repository,
            cancellation: nil
        )

        guard case let .binary(_, data) = content else {
            return XCTFail("got \(content)")
        }
        XCTAssertEqual(data, Data([0x01, 0x02]))
    }

    // MARK: - Bug 3: PDF 被删除

    /// 被删除的 PDF：当前 commit 无 blob，父提交有。
    ///
    /// 加载结果必须带上父提交数据，视图才能展示删除前的版本。
    func testDeletedPDFCarriesPreviousVersionData() throws {
        let capability = ScriptedDiffContentCapability()
        let pdfData = Data("%PDF-1.7\n%parent\n".utf8)
        capability.blobs["parent1:docs/spec.pdf"] = pdfData

        let content = try makeLoader(capability).load(
            path: "docs/spec.pdf",
            commit: DiffTestFixtures.commit(hash: "commit1", parents: ["parent1"]),
            repository: repository,
            cancellation: nil
        )

        guard case let .pdfComparison(current, previous) = content else {
            return XCTFail("a deleted PDF should use the comparison preview, got \(content)")
        }
        XCTAssertNil(current, "a deleted PDF has no content in the current commit")
        XCTAssertEqual(previous, pdfData, "the parent version must be carried for display")
    }

    /// 只有「删除前」一个版本时，PDF 预览的默认展示版本必须是它。
    ///
    /// 旧实现里 `showingPrevious` 默认 false，且版本切换 Picker 只在
    /// 「两个版本都存在」时渲染，导致删除场景永远显示
    /// 「PDF Preview Unavailable」且用户无法切换到旧版本。
    func testPDFComparisonWithOnlyPreviousVersionShowsPreviousByDefault() {
        let state = GitPDFComparisonState(current: nil, previous: Data([0x01]))

        XCTAssertTrue(
            state.showsPreviousByDefault,
            "with only the parent version, that version should be shown by default"
        )
        XCTAssertTrue(
            state.showsVersionSwitcher,
            "the switcher should be available even with a single version"
        )
    }

    /// 两个版本都存在时，默认展示新版本。
    func testPDFComparisonWithBothVersionsShowsCurrentByDefault() {
        let state = GitPDFComparisonState(current: Data([0x01]), previous: Data([0x02]))

        XCTAssertFalse(state.showsPreviousByDefault)
        XCTAssertTrue(state.showsVersionSwitcher)
    }
}
