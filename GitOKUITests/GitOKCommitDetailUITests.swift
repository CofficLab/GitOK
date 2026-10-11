import AppKit
import XCTest

/// Commit 详情头部「点击 commit id 复制」的端到端验证。
///
/// 覆盖本次改动：详情头部的短哈希胶囊可点击，点击后剪贴板得到
/// 完整 40 位 hash（而非界面上显示的短 id），按钮给出 "Copied"
/// 反馈并在约 1.5 秒后自动复原。
final class GitOKCommitDetailUITests: GitOKUITestCase {
    func testClickingCommitIdCopiesFullHashToPasteboard() throws {
        let fullHash = try gitOutput(["rev-parse", "HEAD"])
        XCTAssertEqual(fullHash.count, 40, "fixture HEAD 应是完整 40 位 hash")

        // 1. 在 commit 列表中选中 fixture 唯一的 commit。
        let commitRow = app.buttons
            .matching(NSPredicate(format: "label CONTAINS %@", "Initial fixture commit"))
            .firstMatch
        XCTAssertTrue(commitRow.waitForExistence(timeout: 20), "commit 列表缺少 fixture commit 行")
        commitRow.click()

        // 2. 详情头部展示可点击的 commit id。
        let hashCopy = element(identifier: "gitok.commit.detail.hash-copy")
        XCTAssertTrue(
            hashCopy.waitForExistence(timeout: 15),
            "选中 commit 后详情头部未展示 commit id"
        )

        // 3. 点击前清空剪贴板，再点击复制。
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        hashCopy.click()

        // 4. 剪贴板应得到完整 hash（而非界面上显示的短 id）。
        let deadline = Date().addingTimeInterval(5)
        var copied: String?
        while Date() < deadline {
            copied = pasteboard.string(forType: .string)
            if copied == fullHash { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(copied, fullHash, "点击 commit id 应复制完整 40 位 hash")
        XCTAssertNotEqual(copied, String(fullHash.prefix(7)), "不应只复制界面显示的短 id")

        // 5. 复制后按钮给出 "Copied" 反馈。
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "label == %@", "Copied"), on: hashCopy, timeout: 3),
            "复制成功后按钮未给出 Copied 反馈"
        )

        // 6. 反馈约 1.5 秒后自动复原为可复制状态。
        XCTAssertTrue(
            waitForPredicate(
                NSPredicate(format: "label == %@", "Copy full hash"),
                on: hashCopy,
                timeout: 5
            ),
            "Copied 反馈未自动复原"
        )
    }
}
