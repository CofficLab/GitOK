import MagicKit
import LibGit2Swift
import OSLog
import SwiftUI

struct CommitList: View, SuperThread, SuperLog {
    nonisolated static let emoji = "🖥️"
    nonisolated static let verbose = false

    static var shared = CommitList()

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider

    @State private var commits: [GitCommit] = []
    @State private var loading = false
    @State private var isRefreshing = false
    @State private var hasMoreCommits = true
    @State private var currentPage = 0
    @State private var pageSize: Int = 50
    @State private var unpushedCommits: Set<String> = []  // 存储未推送 commit 的 hash
    @State private var isLoadingMoreScheduled = false  // 防止快速连续触发加载更多

    // 使用GitCommitRepo来存储和恢复commit选择
    private let commitRepo = GitCommitRepo.shared

    private init() {}

    var body: some View {
        ZStack {
            if data.project != nil {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if loading && commits.isEmpty {
                            Spacer()
                            Text(LocalizedStringKey("loading"))
                            Spacer()
                        } else {
                            CurrentWorkingStateView()
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
        .onChange(of: data.project, onProjectChange)
        .onProjectDidChangeBranch(perform: onBranchChanged)
        .onProjectDidCommit(perform: onCommitSuccess)
        .onProjectDidPull(perform: onPullSuccess)
        .onProjectDidPush(perform: onPushSuccess)
        .onApplicationDidBecomeActive {
            self.onApplicationDidBecomeActive()
        }
    }
}

// MARK: - View

extension CommitList {
    /// 提交列表视图：包含滚动视图和所有提交项
    private var commitListView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                Divider()

                ForEach(commits.indices, id: \.self) { index in
                    let commit = commits[index]
                    let isUnpushed = unpushedCommits.contains(commit.hash)
                    CommitRow(commit: commit, isUnpushed: isUnpushed)
                        .overlay(alignment: .trailing) {
                            // 在第一个 commit 右侧显示刷新 loading
                            if index == 0 && isRefreshing {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(1)
                                    .padding(.trailing, 8)
                            }
                        }
                        .onAppear {
                            // 只在最后几个commit出现时触发加载更多
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
    private func loadMoreCommits() {
        guard let project = data.project, !loading, hasMoreCommits else {
            if Self.verbose {
                os_log("\(self.t)🔄 LoadMoreCommits skipped - loading: \(loading), hasMore: \(hasMoreCommits)")
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)🔄 LoadMoreCommits started - page: \(currentPage), total: \(commits.count)")
        }

        loading = true

        do {
            let newCommits = try project.getCommitsWithPagination(
                self.currentPage,
                limit: self.pageSize
            )

            if Self.verbose {
                os_log("\(self.t)🔄 LoadMoreCommits - page: \(self.currentPage), fetched: \(newCommits.count) commits")
                for (index, commit) in newCommits.prefix(3).enumerated() {
                    os_log("\(self.t)🔄 New Commit \(index): \(commit.hash.prefix(8)) - \(commit.message.prefix(50))")
                }
            }

            if !newCommits.isEmpty {
                // 添加去重逻辑，防止重复添加相同的commit
                let uniqueNewCommits = newCommits.filter { newCommit in
                    !commits.contains { existingCommit in
                        existingCommit.hash == newCommit.hash
                    }
                }

                if Self.verbose {
                    os_log("\(self.t)🔄 LoadMoreCommits - fetched: \(newCommits.count), unique: \(uniqueNewCommits.count)")
                }

                if !uniqueNewCommits.isEmpty {
                    commits.append(contentsOf: uniqueNewCommits)
                } else if Self.verbose {
                    os_log("\(self.t)⚠️ LoadMoreCommits - all commits were duplicates!")
                }
                currentPage += 1
            } else {
                hasMoreCommits = false
                if Self.verbose {
                    os_log("\(self.t)🔄 LoadMoreCommits - no more commits available")
                }
            }
            loading = false

        } catch {
            loading = false
            if Self.verbose {
                os_log(.error, "\(self.t)❌ LoadMoreCommits error: \(error)")
            }
        }
    }

    private func selectCommit(_ commit: GitCommit) {
        data.setCommit(commit)

        // 保存选择的commit
        if let projectPath = data.project?.path {
            commitRepo.saveLastSelectedCommit(projectPath: projectPath, commit: commit)
        }
    }

    func setCommit(_ commit: GitCommit?) {
        DispatchQueue.main.async {
            data.setCommit(commit)
        }
    }

    func refresh(_ reason: String = "") {
        if Self.verbose {
            os_log("\(self.t)🍋 Refresh(\(reason))")
        }

        guard let project = data.project else {
            return
        }

        // 如果正在刷新，先重置状态，然后延迟刷新
        if isRefreshing {
            DispatchQueue.main.async {
                self.isRefreshing = false
                self.loading = false
            }
            // 延迟刷新，确保状态重置完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.refresh(reason)
            }
            return
        }

        // 在主线程更新 UI 状态
        DispatchQueue.main.async {
            self.isRefreshing = true
            self.loading = true
        }

        currentPage = 0
        hasMoreCommits = true

        // 捕获 pageSize 以避免 main actor 隔离问题
        let pageSize = self.pageSize

        // 使用 Task.detached 在后台执行异步操作
        Task.detached(priority: .userInitiated) {
            do {
                let initialCommits = try project.getCommitsWithPagination(
                    0, limit: pageSize
                )

                // 获取未推送的 commits
                let unpushed = try await project.getUnPushedCommits()
                let unpushedHashes = Set(unpushed.map { $0.hash })

                if Self.verbose {
                    os_log("\(self.t)🔄 Refresh - fetched \(initialCommits.count) commits from page 0")
                    os_log("\(self.t)🔄 Refresh - \(unpushed.count) unpushed commits")
                }

                // 在主线程更新 UI 状态
                await MainActor.run {
                    self.commits = initialCommits
                    self.unpushedCommits = unpushedHashes
                    self.loading = false
                    self.isRefreshing = false
                    self.currentPage = 1 // Next page to load
                }
            } catch {
                // 在主线程更新 UI 状态
                await MainActor.run {
                    self.loading = false
                    self.isRefreshing = false
                }
            }
        }
    }

    // 恢复上次选择的commit
    private func restoreLastSelectedCommit() {
        guard let project = data.project else { return }

        // 获取上次选择的commit
        if let lastCommit = commitRepo.getLastSelectedCommit(projectPath: project.path) {
            // 在当前commit列表中查找匹配的commit
            if let matchedCommit = commits.first(where: { $0.hash == lastCommit.hash }) {
                self.setCommit(matchedCommit)
            } else if hasMoreCommits {
                // 如果在当前页面没有找到，并且还有更多commit，尝试加载更多
                loadMoreCommitsUntilFound(targetHash: lastCommit.hash)
            }
        } else {
            self.setCommit(self.commits.first)
        }
    }

    // 加载更多commit直到找到目标commit
    private func loadMoreCommitsUntilFound(targetHash: String, maxAttempts: Int = 3) {
        guard let project = data.project, !loading, hasMoreCommits, maxAttempts > 0 else { return }

        loading = true

        do {
            let newCommits = try project.getCommitsWithPagination(
                currentPage,
                limit: pageSize
            )

            if !newCommits.isEmpty {
                // 添加去重逻辑
                let uniqueNewCommits = newCommits.filter { newCommit in
                    !commits.contains { existingCommit in
                        existingCommit.hash == newCommit.hash
                    }
                }
                commits.append(contentsOf: uniqueNewCommits)
                currentPage += 1

                // 检查是否找到目标commit
                if let matchedCommit = newCommits.first(where: { $0.hash == targetHash }) {
                    // 选择找到的commit
                    self.setCommit(matchedCommit)
                } else if hasMoreCommits {
                    // 如果还没找到，继续加载更多
                    loadMoreCommitsUntilFound(targetHash: targetHash, maxAttempts: maxAttempts - 1)
                }
            } else {
                hasMoreCommits = false
            }
            loading = false

        } catch {
            loading = false
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

    func onProjectChange() {
        self.bg.async {
            self.refresh("Project Changed")
        }
    }

    func onBranchChanged(_ eventInfo: ProjectEventInfo) {
        self.bg.async {
            self.refresh("Branch Changed to \(eventInfo.additionalInfo?["branchName"] as? String ?? "unknown")")
        }
    }

    func onCommitSuccess(_ eventInfo: ProjectEventInfo) {
        // 延迟一小段时间，确保 Git 操作完全完成
        Task.detached {
            // 等待 100ms，确保 Git 操作完成
            try? await Task.sleep(nanoseconds: 100000000)
            await MainActor.run {
                self.refresh("GitCommitSuccess")
            }
        }
    }

    func onAppear() {
        self.bg.async {
            self.refresh("OnAppear")
            self.restoreLastSelectedCommit()
        }
    }

    func onChangeOfSelection() {
    }

    func onPullSuccess(_ eventInfo: ProjectEventInfo) {
        self.bg.async {
            self.refresh("GitPullSuccess")
        }
    }

    func onPushSuccess(_ eventInfo: ProjectEventInfo) {
        // 延迟一小段时间，确保 Git 操作完全完成
        Task.detached {
            // 等待 100ms，确保 Git 操作完成
            try? await Task.sleep(nanoseconds: 100000000)
            await MainActor.run {
                // 刷新会自动更新 unpushedCommits
                self.refresh("GitPushSuccess")
            }
        }
    }

    func onAppWillBecomeActive(_ notification: Notification) {
        self.bg.async {
            self.refresh("AppWillBecomeActive")
        }
    }

    func onAppDidBecomeActive(_ notification: Notification) {
        self.bg.async {
            self.refresh("AppDidBecomeActive")
        }
    }

    func onApplicationDidBecomeActive() {
        self.bg.async {
            self.refresh("ApplicationDidBecomeActive")
        }
    }
}

// MARK: - Preview

#Preview("App-Small Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .hideSidebar()
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
