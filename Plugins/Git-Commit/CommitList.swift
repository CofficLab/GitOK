import MagicCore
import OSLog
import SwiftUI

struct CommitList: View, SuperThread, SuperLog {
    static var shared = CommitList()

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider

    @State private var commits: [GitCommit] = []
    @State private var loading = false
    @State private var showCommitForm = false
    @State private var isRefreshing = false
    @State private var hasMoreCommits = true
    @State private var currentPage = 0
    @State private var pageSize: Int = 50

    // 使用GitCommitRepo来存储和恢复commit选择
    private let commitRepo = GitCommitRepo.shared
    private let verbose = true

    private init() {}

    static var emoji = "🖥️"

    var body: some View {
        ZStack {
            if let project = data.project, project.isGit {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if loading && commits.isEmpty {
                            Spacer()
                            Text(LocalizedStringKey("loading"))
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0, pinnedViews: []) {
                                    Divider()
                                    
                                    HStack {
                                        Text("当前")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(MagicBackground.deepOceanCurrent)
                                    .onTapGesture {
                                        data.commit = nil
                                    }

                                    ForEach(commits) { commit in
                                        CommitRow(commit: commit)
                                            .id(commit.id)
                                            .onAppear {
                                                let index = commits.firstIndex(of: commit) ?? 0
                                                let threshold = Int(Double(commits.count) * 0.8)
                                                if index >= threshold && hasMoreCommits && !loading {
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
//        .onNotification(.gitCommitSuccess, perform: onCommitSuccess)
//        .onNotification(.gitPullSuccess, perform: onPullSuccess)
//        .onNotification(.gitPushSuccess, perform: onPushSuccess)
    }

    private func loadMoreCommits() {
        guard let project = data.project, !loading, hasMoreCommits else { return }

        loading = true

        do {
            let newCommits = try project.getCommitsWithPagination(
                self.currentPage,
                limit: self.pageSize
            )

            if !newCommits.isEmpty {
                commits.append(contentsOf: newCommits)
                currentPage += 1
            } else {
                hasMoreCommits = false
            }
            loading = false

        } catch {
            loading = false
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

            let hasChanges = try? project.hasUnCommittedChanges()
            showCommitForm = hasChanges ?? true

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
                data.setCommit(matchedCommit)
            } else if hasMoreCommits {
                // 如果在当前页面没有找到，并且还有更多commit，尝试加载更多
                loadMoreCommitsUntilFound(targetHash: lastCommit.hash)
            }
        } else {
            data.setCommit(self.commits.first)
        }
    }

    // 加载更多commit直到找到目标commit
    private func loadMoreCommitsUntilFound(targetHash: String, maxAttempts: Int = 3) {
        guard let project = data.project, !loading, hasMoreCommits, maxAttempts > 0 else { return }

        loading = true

        do {
            let newCommits = try project.getCommitsWithPagination(
                pageSize,
                limit: pageSize
            )

            if !newCommits.isEmpty {
                commits.append(contentsOf: newCommits)
                currentPage += 1

                // 检查是否找到目标commit
                if let matchedCommit = newCommits.first(where: { $0.hash == targetHash }) {
                    // 选择找到的commit
                    data.setCommit(matchedCommit)
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
        self.refresh("Project Changed")
    }

    func onCommitSuccess(_ notification: Notification) {
        self.refresh("GitCommitSuccess")
    }

    func onAppear() {
        refresh("OnAppear")
    }

    func onChangeOfSelection() {
    }

    func onPullSuccess(_ notification: Notification) {
        self.refresh("GitPullSuccess")
    }

    func onPushSuccess(_ notification: Notification) {
        self.refresh("GitPushSuccess")
    }

    func onAppWillBecomeActive(_ notification: Notification) {
        self.refresh("AppWillBecomeActive")
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
