import GitCoreKit
import ProjectSupportKit

public typealias ConflictResolutionState = ProjectSupportKit.ConflictResolutionState

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
