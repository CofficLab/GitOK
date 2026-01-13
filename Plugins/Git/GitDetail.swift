import AppKit
import MagicKit
import MagicAlert
import MagicUI
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

    /// 环境对象：消息提供者
    @EnvironmentObject var m: MagicMessageProvider

    /// 项目是否干净（无未提交的变更）
    @State private var isProjectClean: Bool = true

    /// 是否为 Git 项目
    @State private var isGitProject: Bool = false

    /// 更新清理状态的任务
    @State private var updateCleanTask: Task<Void, Never>?

    /// 最后更新时间（用于防抖）
    @State private var lastUpdateTime: Date = Date.distantPast

    /// 单例实例
    static let shared = GitDetail()

    private init() {
        if Self.verbose {
            os_log("\(Self.onInit)")
        }
    }

    var body: some View {
        ZStack {
            if data.project != nil {
                if self.isGitProject {
                    VStack(alignment: .leading, spacing: 8) {
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
                    NoGitProjectView()
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: data.project, onProjectChange)
        .onProjectDidCommit(perform: onGitCommitSuccess)
        .onNotification(.appWillBecomeActive, perform: onAppWillBecomeActive)
    }

    /// 背景视图：根据提交状态显示不同的背景颜色
    private var background: some View {
        ZStack {
            if data.commit == nil {
                MagicBackground.orange.opacity(0.15)
            } else {
                MagicBackground.colorGreen.opacity(0.15)
            }
        }
    }
}

// MARK: - View

extension GitDetail {
    // View 相关的辅助视图和修饰符可以在这里添加
}

// MARK: - Action

extension GitDetail {
    /// 更新项目清理状态：检查工作目录是否有未提交的变更
    func updateIsProjectClean() {
        let now = Date()

        // 防抖：300ms 内的重复更新请求会被忽略
        guard now.timeIntervalSince(lastUpdateTime) > 0.3 else {
            if Self.verbose {
                os_log("\(Self.t)🚫 updateIsProjectClean skipped (debounced)")
            }
            return
        }

        lastUpdateTime = now

        // 取消之前的任务
        updateCleanTask?.cancel()

        // 在后台执行，避免阻塞主线程
        updateCleanTask = Task.detached(priority: .utility) {
            guard let project = await self.data.project else {
                return
            }

            let isClean: Bool
            do {
                isClean = try project.isClean(verbose: false)
            } catch {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ Failed to update isProjectClean: \(error)")
                }
                return
            }

            await MainActor.run {
                // 检查任务是否被取消
                guard !Task.isCancelled else { return }

                self.isProjectClean = isClean
                if Self.verbose {
                    os_log(.info, "\(Self.t)🔄 Update isProjectClean: \(isClean)")
                }
            }
        }
    }

    /// 更新 Git 项目状态：检查当前项目是否为 Git 仓库
    func updateIsGitProject() {
        guard let project = data.project else {
            return
        }

        self.isGitProject = project.isGitRepo
    }

    /// 异步更新 Git 项目状态：使用异步方式避免阻塞主线程，解决 CPU 占用 100% 的问题
    func updateIsGitProjectAsync() async {
        guard let project = data.project else {
            await MainActor.run {
                self.isGitProject = false
            }
            return
        }
        
        let isGit = await project.isGitAsync()
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Event Handler

extension GitDetail {
    /// 应用即将变为活跃状态的事件处理
    func onAppWillBecomeActive(_ notification: Notification) {
        // 延迟执行，避免与其他组件同时刷新
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)  // 延迟 0.3 秒
            self.updateIsProjectClean()
        }
    }

    /// 视图出现时的事件处理
    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
            self.updateIsProjectClean()
        }
    }

    /// 项目变更时的事件处理
    func onProjectChange() {
        self.updateIsProjectClean()
    }

    /// Git 提交成功时的事件处理
    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        self.updateIsProjectClean()
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
