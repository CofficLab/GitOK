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
            if data.project?.isGit == true && selection != nil {
                Picker("branch", selection: $selection, content: {
                    ForEach(branches, id: \.self, content: {
                        Text($0.name)
                            .tag($0 as Branch?)
                    })
                })
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

        if verbose {
            os_log("\(self.t)🍋 Refresh(\(reason))")
        }

        do {
            branches = try GitShell.getBranches(project.path)
            if branches.isEmpty {
                os_log("\(self.t)🍋 Refresh, but no branches")
            }
            selection = branches.first(where: {
                $0.name == self.getCurrentBranch()?.name
            })
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
