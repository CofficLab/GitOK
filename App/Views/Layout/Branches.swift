import MagicCore
import OSLog
import SwiftUI

struct Branches: View, SuperThread, SuperLog, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var m: MessageProvider

    @State var branches: [Branch] = []
    @State var selection: Branch?

    var emoji = "🌿"

    var body: some View {
        Picker("branch", selection: $selection, content: {
            ForEach(branches, id: \.self, content: {
                Text($0.name)
                    .tag($0 as Branch?)
            })
        })
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
        .onChange(of: selection, setBranch)
        .onReceive(nc.publisher(for: .appWillBecomeActive), perform: onWillBecomeActive)
    }
}

// MARK: Action

extension Branches {
    func refresh(reason: String) {
        self.m.append("刷新分支\(reason)")
        let verbose = false

        guard let project = g.project else {
            return
        }

        if verbose {
            os_log("\(t)Refresh")
        }

        do {
            branches = try GitShell.getBranches(project.path)
        } catch let error {
            os_log(.error, "\(error.localizedDescription)")
            self.m.toast("刷新分支失败")
        }

        selection = branches.first(where: {
            $0.name == g.currentBranch?.name
        })
    }
    
    func setBranch() {
        do {
            try g.setBranch(selection)
            self.m.toast("已切换到 \(g.currentBranch?.name ?? "None")")
        } catch let error {
            m.alert("切换分支发生错误", info: error.localizedDescription)
            self.refresh(reason: "SetBranch")
        }
    }

}

// MARK: - Event {

extension Branches {
    func onProjectChange() {
        self.refresh(reason: "onProjectChange")
    }

    func onAppear() {
        self.refresh(reason: "OnAppear")
    }

    func onWillBecomeActive(_ notification: Notification) {
        self.refresh(reason: "onWillBecomeActive")
    }
}

#Preview("App-Small Screen") {
    RootView {
        ContentView()
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
