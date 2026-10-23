import Combine
import Foundation
import ProviderGit
import XCTest
@testable import PluginCommitDetail

/// 工作区内容归属（变更列表 / 干净概览）在 ViewModel 上的流转。
///
/// 归属判定必须由 Provider 统一广播，两块内容共用同一份结论；否则变更列表与
/// 干净概览可能同时「不占布局」，主内容区整块塌陷。
@MainActor
final class CommitDetailWorktreeOwnerTests: XCTestCase {
    func testWorktreeOwnerStartsPending() {
        let viewModel = CommitDetailViewModel()

        XCTAssertEqual(viewModel.worktreeOwner, .pending)
    }

    func testWorktreeOwnerAppliesProviderBroadcast() {
        let viewModel = CommitDetailViewModel()

        viewModel.handleWorktreeOwnerChanged(.changes)
        XCTAssertEqual(viewModel.worktreeOwner, .changes)

        viewModel.handleWorktreeOwnerChanged(.clean)
        XCTAssertEqual(viewModel.worktreeOwner, .clean)
    }

    /// 归属变化必须真正驱动界面刷新：ViewModel 是 ObservableObject，
    /// 视图通过 `@ObservedObject` 订阅 `worktreeOwner`。
    func testWorktreeOwnerChangeEmitsObjectWillChange() {
        let viewModel = CommitDetailViewModel()
        var changeCount = 0
        let observation = viewModel.objectWillChange.sink { _ in changeCount += 1 }
        defer { observation.cancel() }

        viewModel.handleWorktreeOwnerChanged(.changes)
        // 相同的归属不应重复刷新界面。
        viewModel.handleWorktreeOwnerChanged(.changes)

        XCTAssertEqual(changeCount, 1)
    }
}
