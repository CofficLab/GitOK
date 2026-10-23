import Foundation
import KitGit
import ProviderGit
import Testing
@testable import PluginCommitDetail

@Suite("WorktreeChangesContentPolicy")
struct WorktreeChangesContentPolicyTests {
    private func entry(_ path: String) -> GitStatusEntry {
        GitStatusEntry(path: path, stagedStatus: " ", worktreeStatus: "M")
    }

    /// 复现：扫描尚未出结果时，变更列表必须展示加载占位（占满高度），
    /// 绝不能塌陷成「不占布局」——否则主内容区只剩提交表单，表单被垂直居中，
    /// 详情区整块留白。
    @Test("A pending owner renders the loading placeholder instead of collapsing")
    func pendingOwnerRendersLoading() {
        let content = WorktreeChangesContentPolicy.resolve(
            owner: .pending,
            entries: [],
            loadError: nil
        )

        #expect(content == .loading)
    }

    /// 有归属结论但本地条目还没落地时，同样展示加载占位，不塌陷。
    @Test("Changes owner without local entries still renders the loading placeholder")
    func changesOwnerWithoutEntriesRendersLoading() {
        let content = WorktreeChangesContentPolicy.resolve(
            owner: .changes,
            entries: [],
            loadError: nil
        )

        #expect(content == .loading)
    }

    /// 项目切换时本地可能已有上一份快照（缓存）：立即展示缓存内容，
    /// 不退回加载占位（stale-while-revalidate）。
    @Test("A pending owner with cached entries renders the cached list")
    func pendingOwnerWithCachedEntriesRendersList() {
        let entries = [entry("App/Info.plist")]
        let content = WorktreeChangesContentPolicy.resolve(
            owner: .pending,
            entries: entries,
            loadError: nil
        )

        #expect(content == .changes(entries))
    }

    @Test("A clean owner renders the clean state")
    func cleanOwnerRendersClean() {
        let content = WorktreeChangesContentPolicy.resolve(
            owner: .clean,
            entries: [],
            loadError: nil
        )

        #expect(content == .clean)
    }

    @Test("A changes owner with entries renders the file list")
    func changesOwnerWithEntriesRendersList() {
        let entries = [entry("App/Info.plist"), entry("App/Shared.xcconfig")]
        let content = WorktreeChangesContentPolicy.resolve(
            owner: .changes,
            entries: entries,
            loadError: nil
        )

        #expect(content == .changes(entries))
    }

    @Test("A load error is surfaced as the failure state")
    func loadErrorRendersFailure() {
        let content = WorktreeChangesContentPolicy.resolve(
            owner: .pending,
            entries: [],
            loadError: "git failed"
        )

        #expect(content == .failed("git failed"))
    }

    /// 回归防线：无论归属处于哪个状态，变更列表要么展示内容、要么展示加载占位，
    /// 只有「确认工作区干净」才允许不占布局。加载占位与错误态都占满高度，
    /// 因此主内容区不会出现空洞。
    @Test("Only a confirmed clean owner lets the block collapse")
    func onlyCleanOwnerCollapses() {
        let entries = [entry("App/Info.plist")]
        let states: [WorktreeContentOwner] = [.pending, .changes, .clean]

        for owner in states {
            let content = WorktreeChangesContentPolicy.resolve(
                owner: owner,
                entries: owner == .clean ? [] : entries,
                loadError: nil
            )
            switch owner {
            case .clean:
                #expect(content == .clean)
            case .pending, .changes:
                #expect(content != .clean, "归属为 \(owner) 时不允许塌陷成不占布局")
            }
        }
    }
}
