import MagicCore
import OSLog
import SwiftUI

struct BranchesView: View, SuperThread, SuperLog, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MessageProvider

    @State var branches: [Branch] = []
    @State var selection: Branch?

    var emoji = "🌿"

    var body: some View {
        Group {
            if data.project?.isGit == true && !branches.isEmpty {
                Picker("branch", selection: $selection, content: {
                    ForEach(branches, id: \.self, content: {
                        Text($0.name)
                            .tag($0 as Branch?)
                    })
                })
                // 确保 selection 始终有值，避免 "selection is invalid" 错误
                .onAppear {
                    if selection == nil && !branches.isEmpty {
                        selection = branches.first
                    }
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: data.project) { self.onProjectChanged() }
        .onReceive(nc.publisher(for: .appWillBecomeActive), perform: onAppWillBecomeActive)
    }
}

// MARK: - Action

extension BranchesView {
    /**
     * 刷新分支列表
     * @param reason 刷新原因
     */
    func refreshBranches(reason: String) {
        let verbose = true

        guard let project = data.project else {
            return
        }
        
        guard project.isGit else {
            self.branches = []
            self.selection = nil
            return
        }

        if verbose {
            os_log("\(self.t)🍋 Refresh(\(reason))")
        }

        do {
            branches = try GitShell.getBranches(project.path)
            if branches.isEmpty {
                os_log("\(self.t)🍋 Refresh, but no branches")
                selection = nil
            } else {
                // 尝试选择当前分支
                let currentBranch = self.getCurrentBranch()
                selection = branches.first(where: {
                    $0.name == currentBranch?.name
                })
                
                // 如果没有找到匹配的分支，则选择第一个分支
                if selection == nil {
                    selection = branches.first
                    os_log("\(self.t)🍋 No matching branch found, selecting first branch: \(selection?.name ?? "unknown")")
                }
            }
        } catch let e {
            self.m.setError(e)
        }
    }
    
    func getCurrentBranch() -> Branch? {
        guard let project = data.project else {
            return nil
        }

        do {
            return try GitShell.getCurrentBranch(project.path)
        } catch _ {
            return nil
        }
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
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
