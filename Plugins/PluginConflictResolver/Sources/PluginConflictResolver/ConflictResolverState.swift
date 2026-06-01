import GitOKCoreKit

public struct ConflictResolutionState: Equatable {
    public let isMerging: Bool
    public let mergeFiles: [GitMergeFile]

    public init(isMerging: Bool, mergeFiles: [GitMergeFile]) {
        self.isMerging = isMerging
        self.mergeFiles = mergeFiles
    }

    public var hasStagedResolutions: Bool {
        mergeFiles.contains { $0.state == .staged }
    }

    public var hasPendingUnstagedResolutions: Bool {
        mergeFiles.contains { $0.state == .pendingStage }
    }

    public var hasUnresolvedFiles: Bool {
        mergeFiles.contains { $0.state == .unresolved }
    }

    public var canContinueMerge: Bool {
        isMerging && !mergeFiles.isEmpty && hasStagedResolutions && mergeFiles.allSatisfy { $0.state == .staged }
    }

    public var statusSubtitle: String {
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

    public var continueHint: String {
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

public enum ConflictResolverStateBuilder {
    public static func mergeFiles(
        unresolvedPaths: Set<String>,
        statusEntries: [GitStatusEntry]
    ) -> [GitMergeFile] {
        let unstagedPaths = Set(statusEntries.filter { $0.workTreeStatus != " " }.map(\.path))
        let stagedPaths = Set(statusEntries.filter { $0.indexStatus != " " }.map(\.path))
        let allPaths = unresolvedPaths.union(unstagedPaths).union(stagedPaths).sorted()

        return allPaths.map { path in
            if unresolvedPaths.contains(path) {
                return GitMergeFile(path: path, state: .unresolved)
            }

            if unstagedPaths.contains(path) {
                return GitMergeFile(path: path, state: .pendingStage)
            }

            return GitMergeFile(path: path, state: .staged)
        }
    }
}
