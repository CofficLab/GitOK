import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

class GitProvider: NSObject, ObservableObject, SuperLog {
    // MARK: - Properties
    
    static let shared = GitProvider()
    
    @Published private(set) var branches: [Branch] = []
    @Published var branch: Branch? = nil
    @Published private(set) var commit: GitCommit? = nil
    @Published private(set) var file: File? = nil
    @Published var project: Project?

    static let emoji = "🐝"
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * 获取当前分支
     * @return 当前分支，如果获取失败则返回nil
     */
    var currentBranch: Branch? {
        guard let project = project else {
            return nil
        }

        do {
            return try GitShell.getCurrentBranch(project.path)
        } catch _ {
            return nil
        }
    }
    
    override init() {
        super.init()
        self.refreshBranches(reason: "GitProvider.Init")
        self.setupEventListeners()
    }
}

// MARK: - Action

extension GitProvider {
    /**
     * 切换到指定分支
     * @param branch 要切换到的分支
     * @throws Git操作异常
     */
    func setBranch(_ branch: Branch?) throws {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Branch to \(branch?.name ?? "-")")
        }

        guard let project = project, let branch = branch else {
            return
        }

        if branch.name == currentBranch?.name {
            return
        }

        try GitShell.setBranch(branch, project.path, verbose: true)
    }
    
    /**
     * 刷新分支列表
     * @param reason 刷新原因
     */
    func refreshBranches(reason: String) {
        let verbose = true

        guard let project = project else {
            return
        }

        if verbose {
            os_log("\(self.t)Refresh(\(reason))")
        }

        branches = (try? GitShell.getBranches(project.path)) ?? []
        branch = branches.first(where: {
            $0.name == self.currentBranch?.name
        })
    }
}

// MARK: - Event

extension GitProvider {
    /**
     * 设置事件监听器
     */
    private func setupEventListeners() {
        // 监听分支变更事件
        NotificationCenter.default.publisher(for: .gitBranchChanged)
            .sink { [weak self] notification in
                self?.handleBranchChanged(notification)
            }
            .store(in: &cancellables)

        // 监听提交成功事件
        NotificationCenter.default.publisher(for: .gitCommitSuccess)
            .sink { [weak self] notification in
                self?.handleGitOperationSuccess(notification)
            }
            .store(in: &cancellables)

        // 监听推送成功事件
        NotificationCenter.default.publisher(for: .gitPushSuccess)
            .sink { [weak self] notification in
                self?.handleGitOperationSuccess(notification)
            }
            .store(in: &cancellables)

        // 监听拉取成功事件
        NotificationCenter.default.publisher(for: .gitPullSuccess)
            .sink { [weak self] notification in
                self?.handleGitOperationSuccess(notification)
            }
            .store(in: &cancellables)
    }

    /**
     * 处理分支变更事件
     */
    private func handleBranchChanged(_ notification: Notification) {
        refreshBranches(reason: "Branch Changed Event")
    }

    /**
     * 处理Git操作成功事件
     */
    private func handleGitOperationSuccess(_ notification: Notification) {
        refreshBranches(reason: "Git Operation Success")
    }

    /**
     * 处理Project变更事件
     */
    private func handleProjectChanged() {
        refreshBranches(reason: "Project Changed")
    }
}

// MARK: - Previews

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
