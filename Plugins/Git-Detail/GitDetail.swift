import AppKit
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// Git 详情视图：显示 Git 项目的状态、提交信息和文件变更列表。
struct GitDetail: View, SuperEvent, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🚄"

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    /// 环境对象：应用提供者
    @EnvironmentObject var app: AppProvider

    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var vm: ProjectVM

    /// 项目是否干净（无未提交的变更）
    @State private var isProjectClean: Bool = true

    /// 是否为 Git 项目
    @State private var isGitProject: Bool = false

    /// 最后更新时间（用于防抖）
    @State private var lastUpdateTime: Date = Date.distantPast

    /// 是否正在执行清理检查（用于防止并发调用）
    @State private var isCheckingClean: Bool = false

    /// 单例实例
    static let shared = GitDetail()

    var body: some View {
        ZStack {
            if vm.project != nil {
                if self.isGitProject {
                    VStack(alignment: .leading, spacing: 0) {
                        Group {
                            if let commit = data.commit {
                                CommitInfoView(commit: commit)
                            } else if self.isProjectClean == false {
                                CommitForm()
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)

                        if !self.isProjectClean || self.data.commit != nil {
                            HSplitView {
                                FileList()
                                    .frame(idealWidth: 200)
                                    .frame(minWidth: 200, maxWidth: 300)
                                    .layoutPriority(1)

                                FileDetail()
                            }
                            .padding(.horizontal, 0)
                            .padding(.vertical, 0)
                        } else {
                            NoLocalChanges()
                        }
                    }
                } else {
                    ProjectNotGitView()
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: vm.project, onProjectChange)
        .onProjectDidCommit(perform: onGitCommitSuccess)
        .onChange(of: data.commit, onCommitChange)
        .onApplicationWillBecomeActive(perform: onAppWillBecomeActive)
    }
}

// MARK: - Action

extension GitDetail {
    /// 更新项目清理状态：检查工作目录是否有未提交的变更
    func updateIsProjectClean(reason: String) {
        let now = Date()

        // 防抖：300ms 内的重复更新请求会被忽略
        guard now.timeIntervalSince(lastUpdateTime) > 0.3 else {
            return
        }

        lastUpdateTime = now

        // 防止并发执行
        guard !isCheckingClean else {
            return
        }

        isCheckingClean = true
        defer {
            isCheckingClean = false
        }

        guard let project = vm.project else {
            os_log(.error, "\(Self.t)❌ No project available")
            return
        }

        do {
            self.isProjectClean = try project.isClean(verbose: Self.verbose)
        } catch {
            os_log(.error, "\(Self.t)❌ Failed to update isProjectClean: \(error)")
        }
    }

    /// 更新 Git 项目状态
    func updateIsGitProject() {
        guard let project = vm.project else {
            self.isGitProject = false
            return
        }

        self.isGitProject = project.isGit()
    }
}

// MARK: - Event Handler

extension GitDetail {
    /// 应用即将变为活跃状态的事件处理
    func onAppWillBecomeActive() {
        self.updateIsGitProject()
        self.updateIsProjectClean(reason: "onAppWillBecomeActive")
    }

    /// Git 提交成功时的事件处理
    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        self.updateIsProjectClean(reason: "onGitCommitSuccess")
    }

    /// 视图出现时的事件处理
    func onAppear() {
        self.updateIsGitProject()
        self.updateIsProjectClean(reason: "onAppear")
    }

    /// 项目变更时的事件处理
    func onProjectChange() {
        self.updateIsGitProject()
        self.updateIsProjectClean(reason: "onProjectChange")
    }

    /// 选择的Commit变动时的事件处理
    func onCommitChange() {
        self.updateIsProjectClean(reason: "onCommitChange")
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
