import Foundation
import Testing
@testable import PluginGitConflictResolver

/// 冲突弹层派生展示状态的分支覆盖。
///
/// `ConflictResolverPresentation` 集中了头部副标题的选择、各操作的可用性
/// 与主次样式判断。它替代了原先埋在 `ConflictResolverList` 里的一段嵌套
/// 分支，这些用例逐个覆盖那些分支组合。
@MainActor
@Suite("ConflictResolverPresentation")
struct ConflictResolverPresentationTests {

    private func make(
        conflicted: [String] = [],
        resolved: [String] = [],
        isOperationInProgress: Bool = false,
        isCherryPicking: Bool = false,
        isActionRunning: Bool = false
    ) -> ConflictResolverPresentation {
        ConflictResolverPresentation(
            conflictedFiles: conflicted,
            resolvedFiles: resolved,
            isOperationInProgress: isOperationInProgress,
            isCherryPicking: isCherryPicking,
            isActionRunning: isActionRunning
        )
    }

    // MARK: - 文件分组

    @Test("已解决且仍在冲突列表中的文件属于待暂存")
    func pendingStageFilesAreStillConflicted() {
        let state = make(conflicted: ["a.txt", "b.txt"], resolved: ["a.txt"])
        #expect(state.pendingStageFiles == ["a.txt"])
        #expect(state.stagedResolvedFiles.isEmpty)
    }

    @Test("已从冲突列表中消失的文件属于已暂存")
    func stagedFilesLeftTheConflictedList() {
        let state = make(conflicted: ["b.txt"], resolved: ["a.txt"])
        #expect(state.pendingStageFiles.isEmpty)
        #expect(state.stagedResolvedFiles == ["a.txt"])
    }

    @Test("同一文件不会同时算作待暂存和已暂存")
    func groupsAreDisjoint() {
        let state = make(conflicted: ["a.txt", "b.txt"], resolved: ["a.txt", "c.txt"])
        let overlap = Set(state.pendingStageFiles).intersection(state.stagedResolvedFiles)
        #expect(overlap.isEmpty, "两个分组不应重叠：\(overlap)")
    }

    // MARK: - 操作可用性

    @Test("存在未解决冲突时不能继续")
    func cannotContinueWhileConflictsRemain() {
        let state = make(conflicted: ["a.txt"], isOperationInProgress: true)
        #expect(!state.canContinue)
    }

    @Test("没有操作进行中时不能继续")
    func cannotContinueWithoutOperation() {
        let state = make(conflicted: [], isOperationInProgress: false)
        #expect(!state.canContinue)
    }

    @Test("冲突已清空且操作进行中时可以继续")
    func canContinueWhenOperationIsReady() {
        let state = make(conflicted: [], isOperationInProgress: true)
        #expect(state.canContinue)
    }

    @Test("动作执行中所有按钮都禁用")
    func runningActionDisablesEverything() {
        let state = make(
            conflicted: [],
            resolved: ["a.txt"],
            isOperationInProgress: true,
            isActionRunning: true
        )
        #expect(!state.canContinue)
        #expect(!state.canAbort)
        #expect(!state.canStage)
    }

    @Test("没有待暂存文件时不显示暂存入口")
    func cannotStageWithoutPendingFiles() {
        let state = make(conflicted: [], resolved: ["a.txt"], isOperationInProgress: true)
        #expect(!state.canStage)
        #expect(state.stagedResolvedFiles == ["a.txt"])
    }

    @Test("有文件待暂存时可以暂存")
    func canStageWithPendingFiles() {
        let state = make(conflicted: ["a.txt"], resolved: ["a.txt"], isOperationInProgress: true)
        #expect(state.canStage)
    }

    @Test("操作进行中时可以中止")
    func canAbortDuringOperation() {
        let state = make(conflicted: ["a.txt"], isOperationInProgress: true)
        #expect(state.canAbort)
    }

    @Test("无操作进行中时不能中止")
    func cannotAbortWithoutOperation() {
        let state = make(conflicted: [], isOperationInProgress: false)
        #expect(!state.canAbort)
    }

    // MARK: - 主次样式

    @Test("还有文件待暂存时继续入口退为次要")
    func continueIsSecondaryWhilePendingStage() {
        let state = make(conflicted: ["a.txt"], resolved: ["a.txt"], isOperationInProgress: true)
        #expect(!state.isContinuePrimaryAction)
    }

    @Test("无待暂存文件时继续入口为主操作")
    func continueIsPrimaryWithoutPendingStage() {
        let state = make(conflicted: [], resolved: ["a.txt"], isOperationInProgress: true)
        #expect(state.isContinuePrimaryAction)
    }

    // MARK: - 头部副标题分支

    @Test("全部冲突尚未解决")
    func summaryWhenNothingResolved() {
        let state = make(conflicted: ["a.txt", "b.txt", "c.txt"], isOperationInProgress: true)
        #expect(state.summary == .conflicted(total: 3))
    }

    @Test("全部已解决但都还没暂存")
    func summaryWhenAllResolvedPendingStage() {
        let state = make(conflicted: ["a.txt", "b.txt"], resolved: ["a.txt", "b.txt"], isOperationInProgress: true)
        #expect(state.summary == .resolvedPendingStage(count: 2))
    }

    @Test("部分已解决、其余仍未解决")
    func summaryWhenPartiallyResolved() {
        let state = make(conflicted: ["a.txt", "b.txt", "c.txt"], resolved: ["a.txt"], isOperationInProgress: true)
        #expect(state.summary == .unresolvedAndPendingStage(unresolved: 2, resolved: 1))
    }

    @Test("同时存在待暂存与已暂存时优先报告待暂存")
    func pendingStageWinsOverStaged() {
        // 先解决并暂存了 c.txt，随后 a.txt 又出现冲突被解决但还没暂存。
        // 此时两个分组都非空，副标题必须指向「待暂存」——那是用户下一步
        // 要做的动作。若两个分支顺序颠倒，这里会退化成「已暂存」。
        let state = make(conflicted: ["a.txt", "b.txt"], resolved: ["a.txt", "c.txt"], isOperationInProgress: true)
        #expect(state.pendingStageFiles == ["a.txt"])
        #expect(state.stagedResolvedFiles == ["c.txt"])
        #expect(state.summary == .unresolvedAndPendingStage(unresolved: 1, resolved: 1))
    }

    @Test("部分仍未解决、其余已暂存")
    func summaryWhenSomeStaged() {
        // 已暂存的文件必须完全不在冲突列表里：只要它还在 conflicted 中，
        // 就算「已解决待暂存」，会走更靠前的分支。
        let state = make(conflicted: ["a.txt", "b.txt"], resolved: ["c.txt"], isOperationInProgress: true)
        #expect(state.pendingStageFiles.isEmpty)
        #expect(state.stagedResolvedFiles == ["c.txt"])
        #expect(state.summary == .unresolvedAndStaged(unresolved: 2, staged: 1))
    }

    @Test("冲突已全部暂存，等待继续")
    func summaryWhenAllStaged() {
        let state = make(conflicted: [], resolved: ["a.txt", "b.txt"], isOperationInProgress: true)
        #expect(state.summary == .stagedReadyToContinue(staged: 2))
    }

    @Test("合并进行中且无待处理冲突")
    func summaryWhenMergeReady() {
        let state = make(conflicted: [], isOperationInProgress: true, isCherryPicking: false)
        #expect(state.summary == .operationReadyToContinue(isCherryPicking: false))
    }

    @Test("cherry-pick 进行中且无待处理冲突")
    func summaryWhenCherryPickingReady() {
        let state = make(conflicted: [], isOperationInProgress: true, isCherryPicking: true)
        #expect(state.summary == .operationReadyToContinue(isCherryPicking: true))
    }

    @Test("既无冲突也无操作")
    func summaryWhenNothingToDo() {
        let state = make(conflicted: [], isOperationInProgress: false)
        #expect(state.summary == .noConflicts)
    }

    @Test("已解决但全部已暂存时优先报告暂存完成，而非继续入口")
    func stagedWinsOverOperationReady() {
        // stagedResolvedFiles 非空时文案要说明「已暂存、可继续」，
        // 不能退回到笼统的「合并已就绪」。
        let state = make(conflicted: [], resolved: ["a.txt"], isOperationInProgress: true)
        #expect(state.summary == .stagedReadyToContinue(staged: 1))
    }

    // MARK: - 本地化文案

    @Test("每种状态都能渲染出非空文案")
    func everySummaryRendersText() {
        let states: [ConflictResolverPresentation] = [
            make(conflicted: ["a.txt"], isOperationInProgress: true),
            make(conflicted: ["a.txt"], resolved: ["a.txt"], isOperationInProgress: true),
            make(conflicted: ["a.txt", "b.txt"], resolved: ["a.txt"], isOperationInProgress: true),
            make(conflicted: ["a.txt"], resolved: ["b.txt"], isOperationInProgress: true),
            make(conflicted: [], resolved: ["a.txt"], isOperationInProgress: true),
            make(conflicted: [], isOperationInProgress: true),
            make(conflicted: [], isOperationInProgress: true, isCherryPicking: true),
            make(conflicted: [], isOperationInProgress: false),
        ]
        for state in states {
            #expect(!state.localizedSummary.isEmpty, "\(state.summary) 渲染出了空文案")
        }
    }

    @Test("数量会体现在文案中")
    func summaryTextIncludesCounts() {
        let state = make(conflicted: ["a.txt", "b.txt", "c.txt"], isOperationInProgress: true)
        #expect(state.localizedSummary.contains("3"), "文案未包含冲突数量：\(state.localizedSummary)")
    }

    @Test("合并与 cherry-pick 的文案不同")
    func mergeAndCherryPickDiffer() {
        let merge = make(conflicted: [], isOperationInProgress: true, isCherryPicking: false)
        let cherryPick = make(conflicted: [], isOperationInProgress: true, isCherryPicking: true)
        #expect(merge.localizedSummary != cherryPick.localizedSummary)
    }

    // MARK: - 与 ViewModel 的一致性

    @Test("从 ViewModel 构造时读取一致的字段")
    func initFromViewModelReadsState() {
        let viewModel = GitConflictResolverViewModel()
        let url = URL(fileURLWithPath: "/tmp/presentation")
        viewModel.update(
            projectURL: url,
            conflictedFiles: ["a.txt", "b.txt"],
            isOperationInProgress: true,
            isCherryPicking: false,
            resolvedFiles: ["a.txt"]
        )

        let state = ConflictResolverPresentation(viewModel: viewModel)
        #expect(state.conflictedFiles == ["a.txt", "b.txt"])
        #expect(state.pendingStageFiles == ["a.txt"])
        #expect(state.canStage)
        #expect(!state.canContinue)
        #expect(state.canAbort)
    }

    @Test("isActionRunning 会透传到操作可用性")
    func actionRunningIsForwarded() {
        let viewModel = GitConflictResolverViewModel()
        let url = URL(fileURLWithPath: "/tmp/presentation-running")
        viewModel.update(
            projectURL: url,
            conflictedFiles: [],
            isOperationInProgress: true,
            isCherryPicking: false
        )

        let idle = ConflictResolverPresentation(viewModel: viewModel)
        #expect(idle.canContinue)

        let running = ConflictResolverPresentation(viewModel: viewModel, isActionRunning: true)
        #expect(!running.canContinue)
        #expect(!running.canAbort)
    }
}
