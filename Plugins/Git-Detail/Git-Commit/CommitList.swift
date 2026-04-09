import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// Git 提交列表视图组件
/// 显示项目的提交历史记录，支持分页加载和刷新
struct CommitList: View, SuperThread, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🖥️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    /// 单例实例
    static var shared = CommitList()

    /// 环境对象：应用提供者
    @EnvironmentObject var app: AppVM

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 提交列表数据
    @State private var commits: [GitCommit] = []

    /// 是否正在加载数据
    @State private var loading = false

    /// 是否还有更多提交可以加载
    @State private var hasMoreCommits = true

    /// 当前页码
    @State private var currentPage = 0

    /// 每页加载的提交数量
    @State private var pageSize: Int = 50

    /// 未推送提交的哈希集合（由 CommitList 统一管理，避免竞争条件）
    @State private var unpushedCommits: Set<String> = []

    /// 是否已调度加载更多操作（防止快速连续触发）
    @State private var isLoadingMoreScheduled = false

    /// 当前刷新任务
    @State private var currentRefreshTask: Task<Void, Never>? = nil
    /// 后台刷新工作任务
    @State private var currentRefreshWorkerTask: Task<([GitCommit], Set<String>), Error>? = nil

    /// Git 提交仓库，用于存储和恢复提交选择状态
    private let commitRepo = GitCommitRepo.shared

    var body: some View {
        ZStack {
            if vm.project != nil {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if loading && commits.isEmpty {
                            Text("正在加载", tableName: "GitCommit")
                                .inMagicHStackCenter()
                                .inMagicVStackCenter()
                        } else {
                            WorkingStateView(isRefreshing: $loading)
                            commitListView
                        }
                    }
                    .onAppear {
                        onGeometryAppear(geometry)
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: vm.project, onProjectChange)
        .onProjectDidChangeBranch(perform: onBranchChanged)
        .onProjectDidCommit(perform: onCommitSuccess)
        .onProjectDidPull(perform: onPullSuccess)
        .onProjectDidPush(perform: onPushSuccess)
        .onApplicationWillBecomeActive(perform: onAppWillBecomeActive)
    }
}

// MARK: - View

extension CommitList {
    /// 提交列表视图：包含滚动视图和所有提交项
    private var commitListView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                Divider()

                ForEach(Array(commits.enumerated()), id: \.element.hash) { index, commit in
                    let isUnpushed = unpushedCommits.contains(commit.hash)
                    CommitRow(commit: commit, isUnpushed: isUnpushed)
                        .onAppear {
                            // 只在最后几个 commit 出现时触发加载更多
                            let threshold = max(commits.count - 10, Int(Double(commits.count) * 0.8))

                            if index >= threshold && hasMoreCommits && !loading && !isLoadingMoreScheduled {
                                isLoadingMoreScheduled = true

                                if Self.verbose {
                                    os_log("\(self.t)👁️ Commit \(index) appeared, scheduling loadMore")
                                }

                                // 延迟 100ms，避免快速连续触发
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.isLoadingMoreScheduled = false
                                    if Self.verbose {
                                        os_log("\(self.t)🔄 Executing scheduled loadMore")
                                    }
                                    self.loadMoreCommits()
                                }
                            }
                        }
                }

                if loading && !commits.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(height: 44)

                    Divider()
                }
            }
        }
        .background(Color(.controlBackgroundColor))
    }
}

// MARK: - Action

extension CommitList {
    /// 加载更多提交记录
    /// 使用分页方式获取下一页的提交数据
    private func loadMoreCommits() {
        guard let project = vm.project, !loading, hasMoreCommits else {
            return
        }

        loading = true
        
        let currentPage = self.currentPage
        let pageSize = self.pageSize
        let currentCommits = self.commits

        Task.detached(priority: .userInitiated) {
            do {
                let newCommits = try project.getCommitsWithPagination(
                    currentPage,
                    limit: pageSize
                )

                await MainActor.run {
                    if !newCommits.isEmpty {
                        // 添加去重逻辑，防止重复添加相同的 commit
                        let uniqueNewCommits = newCommits.filter { newCommit in
                            !currentCommits.contains { existingCommit in
                                existingCommit.hash == newCommit.hash
                            }
                        }

                        if !uniqueNewCommits.isEmpty {
                            self.commits.append(contentsOf: uniqueNewCommits)
                        } else if Self.verbose {
                            os_log("\(Self.t)⚠️ LoadMoreCommits - all commits were duplicates!")
                        }
                        self.currentPage += 1
                    } else {
                        self.hasMoreCommits = false
                    }
                    self.loading = false
                }

            } catch {
                await MainActor.run {
                    self.loading = false
                }
                os_log(.error, "\(Self.t)❌ LoadMoreCommits error: \(error)")
            }
        }
    }

    /// 选择指定的提交
    /// - Parameter commit: 要选择的提交对象
    private func selectCommit(_ commit: GitCommit) {
        data.setCommit(commit)

        // 保存选择的 commit
        if let projectPath = vm.project?.path {
            commitRepo.saveLastSelectedCommit(projectPath: projectPath, commit: commit)
        }
    }

    /// 设置当前选中的提交（异步版本）
    /// - Parameter commit: 要设置的提交对象，可选
    func setCommit(_ commit: GitCommit?) {
        data.setCommit(commit)
    }

    /// 刷新提交列表数据
    /// - Parameter reason: 刷新原因描述，用于调试
    func refresh(_ reason: String = "") {
        guard let project = vm.project else {
            return
        }

        // 取消之前的刷新任务
        currentRefreshTask?.cancel()
        currentRefreshWorkerTask?.cancel()

        // 在主线程更新 UI 状态
        self.loading = true

        currentPage = 0
        hasMoreCommits = true

        // 捕获 pageSize 以避免 main actor 隔离问题
        let pageSize = self.pageSize

        // 启动新任务
        currentRefreshTask = Task {
            if Task.isCancelled { return }

            do {
                // 使用 Task.detached 在后台执行异步操作
                let worker = Task.detached(priority: .userInitiated) {
                    try Task.checkCancellation()

                    if Self.verbose {
                        os_log("\(Self.t)🍋 Refresh(\(reason))")
                    }

                    let commits = try project.getCommitsWithPagination(
                        0, limit: pageSize
                    )

                    try Task.checkCancellation()

                    // 获取未推送的 commits
                    let unpushed = try await project.getUnPushedCommits()
                    let unpushedHashes = Set(unpushed.map { $0.hash })

                    return (commits, unpushedHashes)
                }
                currentRefreshWorkerTask = worker
                let (initialCommits, unpushedHashes) = try await worker.value

                if Task.isCancelled { return }

                // 在主线程更新 UI 状态
                await MainActor.run {
                    self.commits = initialCommits
                    self.unpushedCommits = unpushedHashes
                    self.loading = false
                    self.currentPage = 1 // Next page to load
                }
            } catch {
                if Task.isCancelled { return }

                // 在主线程更新 UI 状态
                await MainActor.run {
                    self.commits = []
                    self.unpushedCommits = []
                    self.loading = false
                }
            }
        }
    }

    /// 刷新未推送状态（不重新加载提交列表）
    /// 用于推送成功后快速更新 UI 状态
    func refreshUnpushedStatus() {
        guard let project = vm.project else {
            return
        }

        if Self.verbose {
            os_log("\(Self.t)🔄 Refreshing unpushed status only")
        }

        Task.detached(priority: .userInitiated) {
            do {
                let unpushed = try await project.getUnPushedCommits()
                let unpushedHashes = Set(unpushed.map { $0.hash })

                if Self.verbose {
                    os_log("\(Self.t)📊 Unpushed status updated: \(unpushedHashes.count) commits")
                }

                await MainActor.run {
                    self.unpushedCommits = unpushedHashes
                }
            } catch {
                if Self.verbose {
                    os_log(.error, "\(Self.t)❌ Failed to refresh unpushed status: \(error)")
                }
            }
        }
    }

    /// 恢复上次选择的提交
    /// 从本地存储中恢复用户之前选择的提交位置
    private func restoreLastSelectedCommit() {
        guard let project = vm.project else { return }

        // 获取上次选择的 commit hash
        if let lastCommitHash = commitRepo.getLastSelectedCommitHash(projectPath: project.path) {
            // 在当前 commit 列表中查找匹配的 commit
            if let matchedCommit = commits.first(where: { $0.hash == lastCommitHash }) {
                self.setCommit(matchedCommit)
            } else if hasMoreCommits {
                // 如果在当前页面没有找到，并且还有更多 commit，尝试加载更多
                loadMoreCommitsUntilFound(targetHash: lastCommitHash)
            }
        } else {
            self.setCommit(self.commits.first)
        }
    }

    /// 加载更多提交直到找到目标提交
    /// - Parameters:
    ///   - targetHash: 目标提交的哈希值
    ///   - maxAttempts: 最大尝试次数，防止无限循环
    private func loadMoreCommitsUntilFound(targetHash: String, maxAttempts: Int = 3) {
        guard let project = vm.project, !loading, hasMoreCommits, maxAttempts > 0 else { return }

        loading = true
        
        let currentPage = self.currentPage
        let pageSize = self.pageSize
        let currentCommits = self.commits

        Task.detached(priority: .userInitiated) {
            do {
                let newCommits = try project.getCommitsWithPagination(
                    currentPage,
                    limit: pageSize
                )

                await MainActor.run {
                    if !newCommits.isEmpty {
                        // 添加去重逻辑
                        let uniqueNewCommits = newCommits.filter { newCommit in
                            !currentCommits.contains { existingCommit in
                                existingCommit.hash == newCommit.hash
                            }
                        }
                        self.commits.append(contentsOf: uniqueNewCommits)
                        self.currentPage += 1

                        // 检查是否找到目标 commit
                        if let matchedCommit = newCommits.first(where: { $0.hash == targetHash }) {
                            // 选择找到的 commit
                            self.setCommit(matchedCommit)
                        } else if self.hasMoreCommits {
                            // 如果还没找到，继续加载更多
                            // 注意：这里递归调用可能会导致堆栈过深，但在异步任务中应该没问题，且有 maxAttempts 限制
                            self.loadMoreCommitsUntilFound(targetHash: targetHash, maxAttempts: maxAttempts - 1)
                        }
                    } else {
                        self.hasMoreCommits = false
                    }
                    self.loading = false
                }

            } catch {
                await MainActor.run {
                    self.loading = false
                }
            }
        }
    }
}

// MARK: - Setter

extension CommitList {
    // UI 状态设置相关方法
    // 如有需要可在此添加 @MainActor 标记的状态更新方法
}

// MARK: - Event Handlers

extension CommitList {
    /// 几何尺寸改变事件处理：根据视图高度动态调整页面大小
    /// - Parameter geometry: 几何尺寸信息
    func onGeometryAppear(_ geometry: GeometryProxy) {
        let rowHeight: CGFloat = 31
        let visibleRows = Int(ceil(geometry.size.height / rowHeight))
        pageSize = max(self.pageSize, visibleRows + 5)
    }

    /// 项目变更事件处理
    func onProjectChange() {
        self.refresh("Project Changed")
    }

    /// 分支变更事件处理
    /// - Parameter eventInfo: 事件信息，包含新分支名称
    func onBranchChanged(_ eventInfo: ProjectEventInfo) {
        self.refresh("Branch Changed")
    }

    /// 提交成功事件处理
    /// - Parameter eventInfo: 事件信息
    func onCommitSuccess(_ eventInfo: ProjectEventInfo) {
        self.refresh("GitCommitSuccess")
    }

    /// 视图出现事件处理
    func onAppear() {
        self.refresh("OnAppear")
        self.restoreLastSelectedCommit()
    }

    /// 选择变更事件处理
    func onChangeOfSelection() {
    }

    /// 拉取成功事件处理
    /// - Parameter eventInfo: 事件信息
    func onPullSuccess(_ eventInfo: ProjectEventInfo) {
        self.refresh("GitPullSuccess")
    }

    /// 推送成功事件处理 - 只刷新未推送状态，不重新加载提交列表
    /// - Parameter eventInfo: 事件信息
    func onPushSuccess(_ eventInfo: ProjectEventInfo) {
        if Self.verbose {
            os_log("\(Self.t)🚀 Git push success - refreshing unpushed status only")
        }
        // 只更新未推送状态，避免不必要的提交列表重新加载
        self.refreshUnpushedStatus()
    }

    /// 应用即将变为活跃状态事件处理
    func onAppWillBecomeActive() {
        Task {
            self.refresh("ApplicationWillBecomeActive")
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
