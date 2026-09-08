import Foundation
import SwiftUI

/// 由 ConflictResolver 插件入口持有的冲突状态。
@MainActor
public final class GitConflictResolverViewModel: ObservableObject {
    @Published public private(set) var currentProjectURL: URL?
    @Published public private(set) var conflictedFiles: [String] = []
    @Published public private(set) var isOperationInProgress = false
    @Published public private(set) var isCherryPicking = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var isPresented = false

    private var lastReportedOperationInProgress = false

    public init() {}

    func beginLoading(projectURL: URL) {
        currentProjectURL = projectURL
        conflictedFiles = []
        isOperationInProgress = false
        isCherryPicking = false
        isLoading = true
    }

    func update(
        projectURL: URL?,
        conflictedFiles: [String],
        isOperationInProgress: Bool,
        isCherryPicking: Bool
    ) {
        let projectChanged = currentProjectURL != projectURL
        // A merge can remain in progress after every conflict has been staged.
        // That state still needs the resolver surface: the next action is to
        // continue the merge and create the merge commit, not to sync again.
        let operationStarted = isOperationInProgress
            && (!lastReportedOperationInProgress || projectChanged)

        currentProjectURL = projectURL
        self.conflictedFiles = conflictedFiles
        self.isOperationInProgress = isOperationInProgress
        self.isCherryPicking = isCherryPicking
        isLoading = false
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
}
