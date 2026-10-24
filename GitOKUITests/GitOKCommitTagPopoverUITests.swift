import Foundation
import XCTest

/// 覆盖 commit 行里 tag 胶囊的展开弹层。
///
/// 行内宽度有限，tag 名经常被截断（`backup/dev-…`）；点击胶囊应弹出详情弹层，
/// 展示完整 tag 名、tag 类型、指向的提交，以及该提交上的全部 tag。
final class GitOKCommitTagPopoverUITests: GitOKUITestCase {
    private let annotatedTag = "release/2026.10.24-bookletmaker"
    private let lightweightTag = "backup/dev-fixture"

    override func seedAdditionalUIState() throws {
        // 夹具仓库建好、App 启动之前打上两个 tag（附注 + 轻量），
        // 用来验证弹层既能展示完整 tag 名，也能区分 tag 类型。
        try gitOutput(["tag", "-a", annotatedTag, "-m", "Release note for the fixture", "HEAD"])
        try gitOutput(["tag", lightweightTag])
    }

    func testClickingTagChipShowsUntruncatedTagName() {
        let row = commitRow()
        openTagPopover(in: row)

        let name = element(identifier: "gitok.git.commit.tag.popover.name")
        XCTAssertTrue(name.waitForExistence(timeout: 10), "Clicking the tag chip did not open the detail popover")

        let shown = displayedText(of: name)
        XCTAssertTrue(
            shown == annotatedTag || shown == lightweightTag,
            "The popover must show the complete tag name, but it showed '\(shown)'"
        )
    }

    func testPopoverShowsTagDetailsAndAllTagsOfTheCommit() {
        let row = commitRow()
        openTagPopover(in: row)

        let name = element(identifier: "gitok.git.commit.tag.popover.name")
        XCTAssertTrue(name.waitForExistence(timeout: 10), "The detail popover did not open")
        let selected = displayedText(of: name)

        // 类型必须与被点开的那个 tag 一致（附注 tag / 轻量 tag）。
        let expectedType = selected == annotatedTag ? "Annotated tag" : "Lightweight tag"
        let type = element(identifier: "gitok.git.commit.tag.popover.type")
        XCTAssertTrue(
            type.waitForExistence(timeout: 10),
            "The popover did not load the tag details (no type row)"
        )
        XCTAssertEqual(
            displayedText(of: type),
            expectedType,
            "The popover must show the '\(expectedType)' type of the selected tag"
        )

        // 该提交上的全部 tag 都要列出来（行内最多只显示两个）。
        for tag in [annotatedTag, lightweightTag] {
            let sibling = element(identifier: "gitok.git.commit.tag.popover.sibling.\(tag)")
            XCTAssertTrue(
                sibling.waitForExistence(timeout: 10),
                "The popover did not list the '\(tag)' tag of the same commit"
            )
            XCTAssertEqual(
                displayedText(of: sibling),
                tag,
                "The popover must list the complete tag name"
            )
        }
    }

    // MARK: - Helpers

    /// 夹具仓库只有一条提交，按提交标题定位它所在的行。
    private func commitRow() -> XCUIElement {
        let row = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", "Initial fixture commit"))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 20), "The commit row is missing from the history list")
        return row
    }

    /// 点击行内的 tag 胶囊。
    ///
    /// 行本身是一个 Button（`AppListRow`），SwiftUI 会把行内的胶囊压平成行按钮的
    /// 辅助功能元素——胶囊拿不到独立 identifier，只能按行内坐标点击：胶囊固定排在
    /// 第一行的行尾，点击行尾往里 30pt、往下 20pt 即落在胶囊上。
    private func openTagPopover(in row: XCUIElement) {
        let target = row.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: row.frame.width - 30, dy: 20))
        target.click()
    }

    /// 读取元素上显示的文本（SwiftUI 的 Text 在 AX 树里可能暴露为 label 或 value）。
    private func displayedText(of element: XCUIElement) -> String {
        if !element.label.isEmpty { return element.label }
        return element.value as? String ?? ""
    }
}
