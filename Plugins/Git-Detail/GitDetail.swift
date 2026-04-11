import AppKit
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// Git 详情视图：显示 Git 项目的状态、提交信息和文件变更列表。
struct GitDetail: View, SuperEvent, SuperLog {
    nonisolated static let emoji = "🚄"
    nonisolated static let verbose = true

    @EnvironmentObject var app: AppVM
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 是否为 Git 项目
    @State private var isGitProject: Bool = false

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
                            } else if !vm.isClean {
                                CommitForm()
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)

                        if !vm.isClean || self.data.commit != nil {
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
    }

    /// Git 提交成功时的事件处理
    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
    }

    /// 视图出现时的事件处理
    func onAppear() {
        self.updateIsGitProject()
    }

    /// 项目变更时的事件处理
    func onProjectChange() {
        self.updateIsGitProject()
    }

    /// 选择的Commit变动时的事件处理
    func onCommitChange() {
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
