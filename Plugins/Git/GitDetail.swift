import AppKit
import MagicKit
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

struct GitDetail: View, SuperEvent, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State private var isProjectClean: Bool = true
    @State private var isGitProject: Bool = false
    @State private var updateCleanTask: Task<Void, Never>?
    @State private var lastUpdateTime: Date = Date.distantPast

    static let shared = GitDetail()

    private var verbose = false

    private init() {
        if verbose {
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

// MARK: - Action

extension GitDetail {
    func updateIsProjectClean() {
        let now = Date()

        // 防抖：300ms 内的重复更新请求会被忽略
        guard now.timeIntervalSince(lastUpdateTime) > 0.3 else {
            if verbose {
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
                if self.verbose {
                    os_log(.info, "\(Self.t)🔄 Update isProjectClean: \(isClean)")
                }
            }
        }
    }

    func updateIsGitProject() {
        guard let project = data.project else {
            return
        }

        self.isGitProject = project.isGitRepo
    }
    
    /**
        异步更新Git项目状态
        
        使用异步方式避免阻塞主线程，解决CPU占用100%的问题
     */
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

// MARK: Event

extension GitDetail {
    func onAppWillBecomeActive(_ notification: Notification) {
        // 延迟执行，避免与其他组件同时刷新
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)  // 延迟 0.3 秒
            self.updateIsProjectClean()
        }
    }

    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
            self.updateIsProjectClean()
        }
    }

    func onProjectChange() {
        self.updateIsProjectClean()
    }

    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        self.updateIsProjectClean()
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
