import MagicCore
import OSLog
import SwiftUI

struct CommitList: View, SuperThread, SuperLog {
    static var shared = CommitList()

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider

    @State private var commits: [GitCommit] = []
    @State private var loading = false
    @State private var isRefreshing = false
    @State private var hasMoreCommits = true
    @State private var currentPage = 0
    @State private var pageSize: Int = 50

    // 使用GitCommitRepo来存储和恢复commit选择
    private let commitRepo = GitCommitRepo.shared
    private let verbose = false

    private init() {}

    static var emoji = "🖥️"

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

                            ScrollView {
                                LazyVStack(spacing: 0, pinnedViews: []) {
                                    Divider()

                                    ForEach(commits) { commit in
                                        CommitRow(commit: commit)
                                            .onAppear {
                                                // 只在最后几个commit出现时触发加载更多
                                                let index = commits.firstIndex(of: commit) ?? 0
                                                let threshold = max(commits.count - 10, Int(Double(commits.count) * 0.8))

                                                if index >= threshold && hasMoreCommits && !loading {
                                                    if verbose {
                                                        os_log("\(self.t)👁️ Commit \(index) appeared, triggering loadMore")
                                                    }
                                                    loadMoreCommits()
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
                    .onAppear {
                        let rowHeight: CGFloat = 31
                        let visibleRows = Int(ceil(geometry.size.height / rowHeight))
                        pageSize = max(self.pageSize, visibleRows + 5)
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: data.project, onProjectChange)
        .onNotification(.projectDidCommit, perform: onCommitSuccess)
        .onNotification(.projectDidPull, perform: onPullSuccess)
        .onNotification(.projectDidPush, perform: onPushSuccess)
    }

    private func loadMoreCommits() {
        guard let project = data.project, !loading, hasMoreCommits else {
            if verbose {
                os_log("\(self.t)🔄 LoadMoreCommits skipped - loading: \(loading), hasMore: \(hasMoreCommits)")
            }
            return
        }

        if verbose {
            os_log("\(self.t)🔄 LoadMoreCommits started - page: \(currentPage), total: \(commits.count)")
        }

        loading = true

        do {
            let newCommits = try project.getCommitsWithPagination(
                self.currentPage,
                limit: self.pageSize
            )

            if !newCommits.isEmpty {
                // 添加去重逻辑，防止重复添加相同的commit
                let uniqueNewCommits = newCommits.filter { newCommit in
                    !commits.contains { existingCommit in
                        existingCommit.hash == newCommit.hash
                    }
                }

                if verbose {
                    os_log("\(self.t)🔄 LoadMoreCommits - fetched: \(newCommits.count), unique: \(uniqueNewCommits.count)")
                }

                if !uniqueNewCommits.isEmpty {
                    commits.append(contentsOf: uniqueNewCommits)
                } else if verbose {
                    os_log("\(self.t)⚠️ LoadMoreCommits - all commits were duplicates!")
                }
                currentPage += 1
            } else {
                hasMoreCommits = false
                if verbose {
                    os_log("\(self.t)🔄 LoadMoreCommits - no more commits available")
                }
            }
            loading = false

        } catch {
            loading = false
            if verbose {
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
}

// MARK: - Action

extension CommitList {
    func setCommit(_ commit: GitCommit?) {
        DispatchQueue.main.async {
            data.setCommit(commit)
        }
    }

    func refresh(_ reason: String = "") {
        if verbose {
            os_log("\(self.t)🍋 Refresh(\(reason))")
        }
        guard let project = data.project, !isRefreshing else { return }

        isRefreshing = true
        loading = true

        currentPage = 0
        hasMoreCommits = true

        do {
            let initialCommits = try project.getCommitsWithPagination(
                0, limit: self.pageSize
            )

            commits = initialCommits
            loading = false
            isRefreshing = false
            currentPage = 1

            // 恢复上次选择的commit
            restoreLastSelectedCommit()
        } catch {
            loading = false
            isRefreshing = false
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

// MARK: - Event Handlers

extension CommitList {
    func onProjectChange() {
        self.bg.async {
            self.refresh("Project Changed")
        }
    }

    func onCommitSuccess(_ notification: Notification) {
        self.bg.async {
            self.refresh("GitCommitSuccess")
        }
    }

    func onAppear() {
        self.bg.async {
            self.refresh("OnAppear")
        }
    }

    func onChangeOfSelection() {
    }

    func onPullSuccess(_ notification: Notification) {
        self.bg.async {
            self.refresh("GitPullSuccess")
        }
    }

    func onPushSuccess(_ notification: Notification) {
        self.bg.async {
            self.refresh("GitPushSuccess")
        }
    }

    func onAppWillBecomeActive(_ notification: Notification) {
        self.bg.async {
            self.refresh("AppWillBecomeActive")
        }
    }
}

#Preview("App-Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
