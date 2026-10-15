import Foundation

/// 冲突解决弹层的派生展示状态。
///
/// 「哪些文件待暂存 / 已暂存」「头部副标题该描述哪个状态」「各操作是否可用」
/// 这些判断分支多且容易互相影响，却完全不依赖 SwiftUI。集中在这里之后，
/// View 只负责按状态渲染，文案分支可以在单元测试里逐个覆盖。
struct ConflictResolverPresentation: Equatable {
    /// 头部副标题要描述的状态。
    ///
    /// 用枚举而非直接返回文案，是为了避免测试与本地化字符串耦合：
    /// 这里断言的是「该描述哪个状态」，具体措辞交给 `localizedSummary`。
    enum Summary: Equatable {
        /// 全部冲突已解决但仍需暂存。
        case resolvedPendingStage(count: Int)
        /// 部分已解决待暂存，其余仍未解决。
        case unresolvedAndPendingStage(unresolved: Int, resolved: Int)
        /// 部分仍未解决，其余已暂存。
        case unresolvedAndStaged(unresolved: Int, staged: Int)
        /// 全部仍未解决。
        case conflicted(total: Int)
        /// 冲突已全部暂存，可以继续。
        case stagedReadyToContinue(staged: Int)
        /// Git 操作进行中且已无待处理冲突。
        case operationReadyToContinue(isCherryPicking: Bool)
        /// 没有冲突，也没有进行中的操作。
        case noConflicts
    }

    let conflictedFiles: [String]
    let resolvedFiles: [String]
    let isOperationInProgress: Bool
    let isCherryPicking: Bool
    let isActionRunning: Bool

    init(
        conflictedFiles: [String],
        resolvedFiles: [String],
        isOperationInProgress: Bool,
        isCherryPicking: Bool,
        isActionRunning: Bool
    ) {
        self.conflictedFiles = conflictedFiles
        self.resolvedFiles = resolvedFiles
        self.isOperationInProgress = isOperationInProgress
        self.isCherryPicking = isCherryPicking
        self.isActionRunning = isActionRunning
    }

    /// 从 ViewModel 派生。ViewModel 是 `@MainActor`，因此该构造也是主线程隔离。
    @MainActor
    init(viewModel: GitConflictResolverViewModel, isActionRunning: Bool = false) {
        self.init(
            conflictedFiles: viewModel.conflictedFiles,
            resolvedFiles: viewModel.resolvedConflictFiles,
            isOperationInProgress: viewModel.isOperationInProgress,
            isCherryPicking: viewModel.isCherryPicking,
            isActionRunning: isActionRunning
        )
    }

    // MARK: - 文件分组

    /// 已解决但尚未暂存：下一步动作是暂存。
    var pendingStageFiles: [String] {
        resolvedFiles.filter { conflictedFiles.contains($0) }
    }

    /// 已从冲突列表中消失（已暂存）：下一步动作是继续合并。
    var stagedResolvedFiles: [String] {
        resolvedFiles.filter { !conflictedFiles.contains($0) }
    }

    // MARK: - 操作可用性

    /// 是否可以继续合并 / 继续 cherry-pick。
    ///
    /// 顶部操作栏的按钮只在 `isOperationInProgress` 为真时出现，因此
    /// 这里带上这项判断对顶部按钮而言是等价但更严格的表述。
    var canContinue: Bool {
        isOperationInProgress && conflictedFiles.isEmpty && !isActionRunning
    }

    /// 是否可以暂存已解决的文件。
    var canStage: Bool {
        !pendingStageFiles.isEmpty && !isActionRunning
    }

    /// 是否可以中止当前的合并 / cherry-pick。
    var canAbort: Bool {
        isOperationInProgress && !isActionRunning
    }

    /// 「继续」是否应作为主操作呈现。
    ///
    /// 还有文件待暂存时，主操作是「暂存已解决文件」，继续入口退为次要样式，
    /// 避免两个主按钮争夺注意力。
    var isContinuePrimaryAction: Bool {
        pendingStageFiles.isEmpty
    }

    // MARK: - 头部副标题

    var summary: Summary {
        if !conflictedFiles.isEmpty {
            if !pendingStageFiles.isEmpty {
                if pendingStageFiles.count == conflictedFiles.count {
                    return .resolvedPendingStage(count: pendingStageFiles.count)
                }
                return .unresolvedAndPendingStage(
                    unresolved: conflictedFiles.count - pendingStageFiles.count,
                    resolved: pendingStageFiles.count
                )
            }
            if !stagedResolvedFiles.isEmpty {
                return .unresolvedAndStaged(
                    unresolved: conflictedFiles.count,
                    staged: stagedResolvedFiles.count
                )
            }
            return .conflicted(total: conflictedFiles.count)
        }
        // conflictedFiles 为空时 pendingStageFiles 必然为空（它取自两者的交集），
        // 因此这里只需判断已暂存的部分。
        if !stagedResolvedFiles.isEmpty {
            return .stagedReadyToContinue(staged: stagedResolvedFiles.count)
        }
        if isOperationInProgress {
            return .operationReadyToContinue(isCherryPicking: isCherryPicking)
        }
        return .noConflicts
    }

    var localizedSummary: String {
        switch summary {
        case .resolvedPendingStage(let count):
            return String(
                format: pluginLocalization.string("%lld resolved; stage to continue"),
                count
            )
        case .unresolvedAndPendingStage(let unresolved, let resolved):
            return unresolvedDescription(unresolved) + " · " + String(
                format: pluginLocalization.string("%lld resolved; stage to continue"),
                resolved
            )
        case .unresolvedAndStaged(let unresolved, let staged):
            return unresolvedDescription(unresolved) + " · " + String(
                format: pluginLocalization.string("%lld staged"),
                staged
            )
        case .conflicted(let total):
            return unresolvedDescription(total)
        case .stagedReadyToContinue(let staged):
            return String(
                format: pluginLocalization.string("%lld resolved; ready to continue"),
                staged
            )
        case .operationReadyToContinue(let isCherryPicking):
            return pluginLocalization.string(
                isCherryPicking ? "Cherry-pick is ready to continue" : "Merge is ready to continue"
            )
        case .noConflicts:
            return pluginLocalization.string("No conflicted files")
        }
    }

    private func unresolvedDescription(_ count: Int) -> String {
        String(
            format: pluginLocalization.string("%lld conflicted file(s) remaining"),
            count
        )
    }
}
