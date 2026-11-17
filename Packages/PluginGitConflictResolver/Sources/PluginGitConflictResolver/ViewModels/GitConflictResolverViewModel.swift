import Foundation
import SwiftUI

/// 由 ConflictResolver 插件入口持有的冲突状态。
@MainActor
public final class GitConflictResolverViewModel: ObservableObject {
    @Published public private(set) var currentProjectURL: URL?
    @Published public private(set) var conflictedFiles: [String] = []
    @Published public private(set) var resolvedConflictFiles: [String] = []
    @Published public private(set) var autoResolvableConflictFiles: [String] = []
    @Published public private(set) var bothDeletedConflictFiles: [String] = []
    @Published public private(set) var isOperationInProgress = false
    @Published public private(set) var isCherryPicking = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var hasLoadedSnapshot = false
    @Published public private(set) var isPresented = false

    private var lastReportedOperationInProgress = false
    private var resolvedFileSet: Set<String> = []

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
            resolvedFileSet = []
            autoResolvableConflictFiles = []
            bothDeletedConflictFiles = []
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
        resolvedFiles: [String] = [],
        autoResolvableFiles: [String] = [],
        bothDeletedFiles: [String] = []
    ) {
        let projectChanged = currentProjectURL != projectURL
        // Only rows the user actually saw count as "staged"; mechanically
        // resolvable conflicts never enter the list and must not reappear as
        // phantom staged entries once they are gone from the index.
        let previousDisplayedFiles = Set(displayedConflictFiles)
        // A merge can remain in progress after every conflict has been staged.
        // That state still needs the resolver surface: the next action is to
        // continue the merge and create the merge commit, not to sync again.
        let operationStarted = isOperationInProgress
            && (!lastReportedOperationInProgress || projectChanged)

        currentProjectURL = projectURL
        self.conflictedFiles = conflictedFiles
        self.autoResolvableConflictFiles = autoResolvableFiles.sorted()
        self.bothDeletedConflictFiles = bothDeletedFiles.sorted()
        if isOperationInProgress {
            let currentConflictedFiles = Set(conflictedFiles)
            let resolvedByContent = Set(resolvedFiles)
            let resolvedAfterStaging = previousDisplayedFiles.subtracting(currentConflictedFiles)
            let resolved = resolvedByContent.union(resolvedAfterStaging).sorted()
            resolvedConflictFiles = resolved
            resolvedFileSet = Set(resolved)
        } else {
            resolvedConflictFiles = []
            resolvedFileSet = []
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
        // Files whose conflicts resolve mechanically stay out of the list; a
        // hundreds-of-rows merge should only show rows that need a decision.
        let autoFiles = Set(autoResolvableConflictFiles)
        var files = conflictedFiles.filter { !autoFiles.contains($0) }
        for file in resolvedConflictFiles where !files.contains(file) && !autoFiles.contains(file) {
            files.append(file)
        }
        return files
    }

    /// Files that can be staged without a manual edit: one-sided changes keep
    /// the surviving side, both-deleted entries just drop out of the index.
    public var autoStageFiles: [String] {
        let deletions = Set(bothDeletedConflictFiles)
        return autoResolvableConflictFiles.filter { !deletions.contains($0) }
    }

    public var autoDeletionFiles: [String] {
        bothDeletedConflictFiles
    }

    public var hasAutoResolvableConflicts: Bool {
        !autoResolvableConflictFiles.isEmpty
    }

    public func isConflictFileResolved(_ file: String) -> Bool {
        resolvedFileSet.contains(file)
    }

    /// 弹层正文区是否存在可展示的文件行。
    public var hasContentRows: Bool {
        !displayedConflictFiles.isEmpty
    }

    /// 正文区有文件行时，继续操作入口位于顶部操作栏；正文区为空时才由
    /// 正文里的圆形「继续」按钮提供入口，避免同一弹层出现两个相同入口。
    public var showsToolbarContinueAction: Bool {
        isOperationInProgress && hasContentRows
    }
}
