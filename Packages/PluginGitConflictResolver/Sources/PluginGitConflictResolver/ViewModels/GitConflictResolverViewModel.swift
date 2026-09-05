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
        currentProjectURL = projectURL
        self.conflictedFiles = conflictedFiles
        self.isOperationInProgress = isOperationInProgress
        self.isCherryPicking = isCherryPicking
        isLoading = false
    }
}
