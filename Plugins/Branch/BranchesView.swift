
import MagicKit
import MagicAlert
import OSLog
import SwiftUI
import LibGit2Swift

/// 分支列表视图：负责展示可选分支并支持切换当前分支。
struct BranchesView: View, SuperThread, SuperLog, SuperEvent {
    static let shared = BranchesView()

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var branches: [GitBranch] = []
    @State private var selection: GitBranch?
    @State private var isRefreshing = false
    @State private var isGitProject = false

    static var emoji = "🌿"
    private let verbose = false
    
    private init() {}

    var body: some View {
        ZStack {
            if self.isGitProject && branches.isNotEmpty && selection != nil {
                Picker("branch", selection: $selection, content: {
                    ForEach(branches, id: \.id, content: {
                        Text($0.name)
                            .tag($0 as GitBranch?)
                    })
                })
            } else {
                Picker("branch", selection: .constant(nil as GitBranch?), content: {
                    Text("项目不存在")
                        .tag(nil as GitBranch?)
                }).disabled(true)
            }
        }
        .onChange(of: data.project) { self.onProjectChanged() }
        .onChange(of: self.selection, onSelectionChange)
        .onAppear(perform: onAppear)
        .onApplicationWillBecomeActive(perform: onAppWillBecomeActive)
    }
}

// MARK: - Action

extension BranchesView {
    /**
     * 刷新分支列表
     * @param reason 刷新原因
     */
    func refreshBranches(reason: String) {
        // 防止并发执行
        guard !isRefreshing else {
            os_log("\(self.t)⚠️ Refresh(\(reason)) skipped - already refreshing")
            return
        }

        guard let project = data.project else {
            if verbose {
                os_log("\(self.t)⚠️ Refresh(\(reason)) but project is nil")
            }
            return
        }

        guard self.isGitProject else {
            self.branches = []
            self.updateSelection(nil, reason: "branches is empty")
            return
        }

        // 设置刷新状态
        isRefreshing = true

        if verbose {
            os_log("\(self.t)🍋 Refresh(\(reason))")
        }

        do {
            branches = try project.getBranches()
            if branches.isEmpty {
                os_log("\(self.t)🍋 Refresh, but no branches")
                self.updateSelection(nil, reason: "Refresh, but no branches")
            } else {
                // 尝试选择当前分支
                let currentBranch = try self.data.project?.getCurrentBranch()
                self.updateSelection(branches.first(where: {
                    $0.id == currentBranch?.id
                }), reason: "Refresh, branches is not empty")

                // 如果没有找到匹配的分支，则选择第一个分支
                if selection == nil {
                    self.updateSelection(branches.first, reason: "Refresh, set first branch")
                    os_log("\(self.t)🍋 No matching branch found, selecting first branch: \(selection?.id ?? "unknown")")
                }
            }
        } catch let e {
            self.m.error(e)
        }

        // 重置刷新状态
        isRefreshing = false
    }
    
    func updateSelection(_ s: GitBranch?, reason: String) {
        if verbose {
            os_log("\(self.t)Update Selection to \(s?.id ?? "nil") (\(reason))")
        }
        
        self.selection = s
    }

    func updateIsGitProject() {
        self.isGitProject = data.project?.isGitRepo ?? false
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

// MARK: - Event

extension BranchesView {
    func onAppWillBecomeActive() {
        self.refreshBranches(reason: "AppWillBecomeActive(\(data.project?.title ?? ""))")
    }

    func onProjectChanged() {
        Task {
            await self.updateIsGitProjectAsync()
            self.refreshBranches(reason: "Project Changed to \(data.project?.title ?? "")")
        }
    }

    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
            self.refreshBranches(reason: "onAppear while project is \(data.project?.title ?? "")")
        }
    }
    
    func onSelectionChange() {
        do {
            try data.setBranch(self.selection)
            // 成功消息会通过Project的事件系统自动显示，这里不需要重复显示
        } catch let e {
            m.error(e.localizedDescription)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(GitPlugin.label)
            .hideToolbar()
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
