import Foundation
import KitGit
import Testing
@testable import PluginGitSmartMerge

@Suite("MergeBranchSelectionResolver")
struct MergeBranchSelectionResolverTests {
    private var branches: [GitBranchSummary] {
        [
            GitBranchSummary(name: "main", isRemote: false, isCurrent: true),
            GitBranchSummary(name: "dev", isRemote: false, isCurrent: false),
            GitBranchSummary(name: "feature", isRemote: false, isCurrent: false),
        ]
    }

    @Test("默认源取非当前分支，目标取当前分支")
    func defaultsToNonCurrentSourceAndCurrentTarget() {
        let resolved = MergeBranchSelectionResolver.resolve(branches: branches, saved: nil)

        #expect(resolved.source?.name == "dev")
        #expect(resolved.target?.name == "main")
    }

    @Test("上次保存的选择仍存在时优先使用")
    func prefersSavedSelection() {
        let saved = MergeSelection(sourceBranchName: "feature", targetBranchName: "dev")

        let resolved = MergeBranchSelectionResolver.resolve(branches: branches, saved: saved)

        #expect(resolved.source?.name == "feature")
        #expect(resolved.target?.name == "dev")
    }

    @Test("刷新时保留用户当前已选且仍存在的分支")
    func keepsCurrentPicksAcrossRefresh() {
        let saved = MergeSelection(sourceBranchName: "feature", targetBranchName: "dev")

        let resolved = MergeBranchSelectionResolver.resolve(
            branches: branches,
            saved: saved,
            keeping: branches[2],
            currentTarget: branches[0]
        )

        #expect(resolved.source?.name == "feature")
        #expect(resolved.target?.name == "main")
    }

    @Test("已选分支被删除时回退到保存值或默认值")
    func fallsBackWhenBranchesDisappear() {
        let saved = MergeSelection(sourceBranchName: "deleted", targetBranchName: "gone")

        let resolved = MergeBranchSelectionResolver.resolve(
            branches: branches,
            saved: saved,
            keeping: GitBranchSummary(name: "deleted", isRemote: false, isCurrent: false),
            currentTarget: GitBranchSummary(name: "gone", isRemote: false, isCurrent: false)
        )

        #expect(resolved.source?.name == "dev")
        #expect(resolved.target?.name == "main")
    }

    @Test("多个分支时避免源与目标相同")
    func avoidsIdenticalSelection() {
        let saved = MergeSelection(sourceBranchName: "main", targetBranchName: "main")

        let resolved = MergeBranchSelectionResolver.resolve(branches: branches, saved: saved)

        #expect(resolved.target?.name == "main")
        #expect(resolved.source?.name != resolved.target?.name)
    }

    @Test("仅有一个分支时源与目标都指向它")
    func singleBranchSelectsBothSides() {
        let only = [GitBranchSummary(name: "main", isRemote: false, isCurrent: true)]

        let resolved = MergeBranchSelectionResolver.resolve(branches: only, saved: nil)

        #expect(resolved.source?.name == "main")
        #expect(resolved.target?.name == "main")
    }

    @Test("空分支列表不产生选择")
    func emptyListYieldsNoSelection() {
        let resolved = MergeBranchSelectionResolver.resolve(branches: [], saved: nil)

        #expect(resolved.source == nil)
        #expect(resolved.target == nil)
    }
}