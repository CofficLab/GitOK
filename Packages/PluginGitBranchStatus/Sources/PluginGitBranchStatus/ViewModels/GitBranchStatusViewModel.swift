import Foundation
import SwiftUI

/// 由 GitBranchStatus 插件入口持有的当前分支展示状态。
@MainActor
public final class GitBranchStatusViewModel: ObservableObject {
    @Published public private(set) var currentProjectURL: URL?
    @Published public private(set) var currentBranch: String?
    @Published public private(set) var isLoading = false

    public init() {}

    func beginLoading(projectURL: URL) {
        currentProjectURL = projectURL
        isLoading = true
    }

    func update(projectURL: URL?, branch: String?) {
        currentProjectURL = projectURL
        currentBranch = branch
        isLoading = false
    }
}
