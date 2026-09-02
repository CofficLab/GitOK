import XCTest
@testable import FactoryGitOK
import KitGit
import ProviderCommit
import ProviderProjects
import ProviderToast
import PluginCommitStatusBar
import PluginCommitToast
import PluginToast

/// 真实内核装配集成测试：验证启动后所有 commit 消费方拿到同一个
/// `CommitDetailProviding` 实例（toast 包装实现），点击 commit 时状态栏
/// 观察的 provider 会同步更新。
@MainActor
final class KernelBootIntegrationTests: XCTestCase {
    func testBootResolvesUnifiedCommitProvider() throws {
        let kernel = try KernelFactory.makeKernel()

        // 1) CommitToastPlugin（order 15）应已把宿主默认实现替换为 toast 包装。
        let detail = kernel.resolveProvider((any CommitDetailProviding).self)
        XCTAssertTrue(
            detail is ToastCommitDetailProvider,
            "CommitDetailProviding should be replaced by ToastCommitDetailProvider, got \(String(describing: type(of: detail)))"
        )

        // 2) ToastProviding 应已是真实状态机（非 no-op）。
        let toast = kernel.resolveProvider((any ToastProviding).self)
        XCTAssertTrue(toast is ToastCenter, "ToastProviding should be ToastCenter, got \(String(describing: type(of: toast)))")

        // 3) 模拟 commit 列表点击：selectCommit 后，同一 provider 上应能读到新选择。
        let commit = GitCommit(
            hash: String(repeating: "a", count: 40),
            shortHash: "aaaaaaa",
            message: "fix: demo",
            author: "tester",
            date: Date()
        )
        let url = URL(fileURLWithPath: "/tmp/fake-repo")
        detail?.selectCommit(commit, in: url)

        XCTAssertEqual(detail?.selectedCommit?.shortHash, "aaaaaaa", "status bar reads selectedCommit from the same provider")
        XCTAssertEqual(detail?.selectedProjectURL, url)

        // 4) toast 状态机应收到通知。
        if let center = toast as? ToastCenter {
            XCTAssertEqual(center.currentToast?.style, .info)
            XCTAssertTrue(center.currentToast?.detail?.contains("aaaaaaa") == true)
        }
    }
}
