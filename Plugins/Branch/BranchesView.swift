import MagicCore
import OSLog
import SwiftUI

struct BranchesView: View, SuperThread, SuperLog, SuperEvent {
    static let shared = BranchesView()

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var branches: [GitBranch] = []
    @State private var selection: GitBranch?
    @State private var isRefreshing = false

    static var emoji = "🌿"
    private let verbose = false
    
    private init() {}

    var body: some View {
        ZStack {
            if data.project?.isGit == true && branches.isNotEmpty && selection != nil {
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
        .onNotification(.appWillBecomeActive, perform: onAppWillBecomeActive)
        .onAppear(perform: onAppear)
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

        guard project.isGit else {
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
            self.m.error(e.localizedDescription)
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
}

// MARK: - Event

extension BranchesView {
    func onAppWillBecomeActive(_ notification: Notification) {
        self.refreshBranches(reason: "AppWillBecomeActive(\(data.project?.title ?? ""))")
    }

    func onProjectChanged() {
        self.refreshBranches(reason: "Project Changed to \(data.project?.title ?? "")")
    }

    func onAppear() {
        self.refreshBranches(reason: "onAppear while project is \(data.project?.title ?? "")")
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
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
