
import MagicKit
import MagicAlert
import OSLog
import SwiftUI
import LibGit2Swift

/// 分支列表视图：负责展示可选分支并支持切换当前分支。
struct BranchesView: View, SuperThread, SuperLog, SuperEvent {
    static let shared = BranchesView()

    /// 环境对象
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var vm: ProjectVM

    /// 可选分支列表
    @State var branches: [GitBranch] = []

    /// 当前选中的分支
    @State private var selection: GitBranch?

    /// 是否正在刷新分支列表
    @State private var isRefreshing = false

    /// 是否为Git项目
    @State private var isGitProject = false

    /// 是否启用详细日志输出
    nonisolated static let emoji = "🌿"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false
    
    private init() {}

    var body: some View {
        ZStack {
            if self.isGitProject && branches.isNotEmpty && selection != nil {
                Picker(String(localized: "分支", table: "GitBranch"), selection: $selection, content: {
                    ForEach(branches, id: \.id, content: {
                        Text($0.name)
                            .tag($0 as GitBranch?)
                    })
                })
            } else {
                Picker(String(localized: "分支", table: "GitBranch"), selection: .constant(nil as GitBranch?), content: {
                    Text("项目不存在", tableName: "GitBranch")
                        .tag(nil as GitBranch?)
                }).disabled(true)
            }
        }
        .onChange(of: vm.project) { self.onProjectChanged() }
        .onChange(of: self.selection, onSelectionChange)
        .onAppear(perform: onAppear)
        .onApplicationWillBecomeActive(perform: onAppWillBecomeActive)
        .onProjectDidChangeBranch { eventInfo in
            handleBranchChanged(eventInfo)
        }
    }
}

// MARK: - Action

extension BranchesView {
    /// 刷新分支列表
    /// - Parameter reason: 刷新原因
    func refreshBranches(reason: String) {
        // 防止并发执行
        guard !isRefreshing else {
            os_log("\(self.t)⚠️ Refresh(\(reason)) skipped - already refreshing")
            return
        }

        guard let project = vm.project else {
            if Self.verbose {
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

        if Self.verbose {
            os_log("\(self.t)🍋 Refresh(\(reason))")
        }
        
        Task.detached(priority: .userInitiated) {
            do {
                let branches = try project.getBranches()
                let currentBranch = try project.getCurrentBranch()
                
                await MainActor.run {
                    self.branches = branches
                    
                    if branches.isEmpty {
                        os_log("\(Self.t)🍋 Refresh, but no branches")
                        self.updateSelection(nil, reason: "Refresh, but no branches")
                    } else {
                        // 尝试选择当前分支
                        self.updateSelection(branches.first(where: {
                            $0.id == currentBranch?.id
                        }), reason: "Refresh, branches is not empty")

                        // 如果没有找到匹配的分支，则选择第一个分支
                        if self.selection == nil {
                            self.updateSelection(branches.first, reason: "Refresh, set first branch")
                            os_log("\(Self.t)🍋 No matching branch found, selecting first branch: \(self.selection?.id ?? "unknown")")
                        }
                    }
                    // 重置刷新状态
                    self.isRefreshing = false
                }
            } catch let e {
                await MainActor.run {
                    os_log(.error, "\(Self.t)❌ 刷新分支列表失败: \(e.localizedDescription)")
                    alert_error(e)
                    // 重置刷新状态
                    self.isRefreshing = false
                }
            }
        }

    }
}

// MARK: - Setter

extension BranchesView {
    /// 更新选中分支
    /// - Parameters:
    ///   - s: 要选中的分支
    ///   - reason: 更新原因
    func updateSelection(_ s: GitBranch?, reason: String) {
        if Self.verbose {
            os_log("\(self.t)Update Selection to \(s?.id ?? "nil") (\(reason))")
        }

        self.selection = s
    }

    /// 更新Git项目状态
    func updateIsGitProject() {
        self.isGitProject = vm.project?.isGitRepo ?? false
    }

    /// 异步更新Git项目状态：使用异步方式避免阻塞主线程，解决CPU占用100%的问题
    func updateIsGitProjectAsync() async {
        guard let project = vm.project else {
            await MainActor.run {
                self.isGitProject = false
            }
            return
        }

        let isGit = project.isGit()
        await MainActor.run {
            self.isGitProject = isGit
        }
    }
}

// MARK: - Event Handler

extension BranchesView {
    func onAppWillBecomeActive() {
        self.refreshBranches(reason: "AppWillBecomeActive(\(vm.project?.title ?? ""))")
    }

    func onProjectChanged() {
        Task {
            await self.updateIsGitProjectAsync()
            self.refreshBranches(reason: "Project Changed to \(vm.project?.title ?? "")")
        }
    }

    func onAppear() {
        Task {
            await self.updateIsGitProjectAsync()
            self.refreshBranches(reason: "onAppear while project is \(vm.project?.title ?? "")")
        }
    }
    
    func handleBranchChanged(_ eventInfo: ProjectEventInfo) {
        // 分支变更事件处理 - 刷新分支列表以反映最新状态
        if Self.verbose {
            os_log("\(self.t)🌿 Branch changed, refreshing branches list")
        }
        self.refreshBranches(reason: "BranchChanged(\(eventInfo.additionalInfo?["branchName"] as? String ?? "unknown"))")
    }

    func onSelectionChange() {
        do {
            try data.setBranch(self.selection, project: vm.project)
        } catch let e {
            os_log(.error, "\(Self.t)❌ 切换分支失败: \(e.localizedDescription)")
            alert_error(e.localizedDescription)
        }
    }
}

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
