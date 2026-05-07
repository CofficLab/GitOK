import Foundation

struct ConflictResolutionState: Equatable {
    let isMerging: Bool
    let mergeFiles: [GitMergeFile]

    var hasStagedResolutions: Bool {
        mergeFiles.contains { $0.state == .staged }
    }

    var hasPendingUnstagedResolutions: Bool {
        mergeFiles.contains { $0.state == .pendingStage }
    }

    var hasUnresolvedFiles: Bool {
        mergeFiles.contains { $0.state == .unresolved }
    }

    var canContinueMerge: Bool {
        isMerging && !mergeFiles.isEmpty && hasStagedResolutions && mergeFiles.allSatisfy { $0.state == .staged }
    }

    var statusSubtitle: String {
        if !isMerging {
            return "没有正在进行的冲突流程。"
        }
        if hasUnresolvedFiles {
            return "先在编辑器中解决冲突，再将文件标记为已解决。"
        }
        if hasPendingUnstagedResolutions {
            return "冲突标记已移除，但还有文件尚未暂存。"
        }
        if canContinueMerge {
            return "所有合并文件都已暂存，可以继续完成合并。"
        }
        return "合并仍在进行中。"
    }

    var continueHint: String {
        if hasUnresolvedFiles {
            return "Resolve conflicts before continue"
        }
        if hasPendingUnstagedResolutions {
            return "Stage resolved files before continue"
        }
        if canContinueMerge {
            return "Ready to continue merge"
        }
        return isMerging ? "Merge in progress" : "No merge in progress"
    }
}
