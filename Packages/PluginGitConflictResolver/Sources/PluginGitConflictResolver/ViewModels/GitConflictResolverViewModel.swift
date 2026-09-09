import Foundation
import SwiftUI

/// 由 ConflictResolver 插件入口持有的冲突状态。
@MainActor
public final class GitConflictResolverViewModel: ObservableObject {
    @Published public private(set) var currentProjectURL: URL?
    @Published public private(set) var conflictedFiles: [String] = []
    @Published public private(set) var resolvedConflictFiles: [String] = []
    @Published public private(set) var isOperationInProgress = false
    @Published public private(set) var isCherryPicking = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var hasLoadedSnapshot = false
    @Published public private(set) var isPresented = false

    private var lastReportedOperationInProgress = false

    public init() {}

    func beginLoading(projectURL: URL) {
        let projectChanged = currentProjectURL != projectURL
        currentProjectURL = projectURL
        if projectChanged {
            // A different project must not inherit the previous project's state,
            // but refreshes within the same project should keep the current result
            // visible and actionable until the new snapshot is ready.
            conflictedFiles = []
            resolvedConflictFiles = []
            isOperationInProgress = false
            isCherryPicking = false
            lastReportedOperationInProgress = false
            hasLoadedSnapshot = false
        }
        isLoading = true
    }

    func update(
        projectURL: URL?,
        conflictedFiles: [String],
        isOperationInProgress: Bool,
        isCherryPicking: Bool,
        resolvedFiles: [String] = []
    ) {
        let projectChanged = currentProjectURL != projectURL
        let previousDisplayedFiles = Set(self.conflictedFiles).union(resolvedConflictFiles)
        // A merge can remain in progress after every conflict has been staged.
        // That state still needs the resolver surface: the next action is to
        // continue the merge and create the merge commit, not to sync again.
        let operationStarted = isOperationInProgress
            && (!lastReportedOperationInProgress || projectChanged)

        currentProjectURL = projectURL
        self.conflictedFiles = conflictedFiles
        if isOperationInProgress {
            let currentConflictedFiles = Set(conflictedFiles)
            let resolvedByContent = Set(resolvedFiles)
            let resolvedAfterStaging = previousDisplayedFiles.subtracting(currentConflictedFiles)
            resolvedConflictFiles = Array(resolvedByContent.union(resolvedAfterStaging)).sorted()
        } else {
            resolvedConflictFiles = []
        }
        self.isOperationInProgress = isOperationInProgress
        self.isCherryPicking = isCherryPicking
        isLoading = false
        hasLoadedSnapshot = true
        lastReportedOperationInProgress = isOperationInProgress

        if operationStarted {
            isPresented = true
        } else if !isOperationInProgress {
            isPresented = false
        }
    }

    /// 打开冲突解决弹层；状态栏入口和自动检测共用这条路径。
    public func present() {
        guard isOperationInProgress else { return }
        isPresented = true
    }

    /// 关闭冲突解决弹层，不影响 Git 正在进行的操作。
    public func dismiss() {
        isPresented = false
    }

    public var displayedConflictFiles: [String] {
        var files = conflictedFiles
        for file in resolvedConflictFiles where !files.contains(file) {
            files.append(file)
        }
        return files
    }

    public func isConflictFileResolved(_ file: String) -> Bool {
        resolvedConflictFiles.contains(file)
    }
}
