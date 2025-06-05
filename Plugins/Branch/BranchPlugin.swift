import SwiftUI
import MagicCore
import OSLog

class BranchPlugin: SuperPlugin, SuperLog {
    let emoji = "🌿"
    var label: String = "Branch"
    var icon: String = "arrow.triangle.branch"
    var isTab: Bool = false

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(EmptyView())
    }

    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }

    func addToolBarLeadingView() -> AnyView {
        AnyView(BranchesView())
    }

    func onInit() {
        os_log("\(self.t) onInit")
    }

    func onAppear() {
        os_log("\(self.t) onAppear")
    }

    func onDisappear() {
        os_log("\(self.t) onDisappear")
    }

    func onPlay() {
        os_log("\(self.t) onPlay")
    }

    func onPlayStateUpdate() {
        os_log("\(self.t) onPlayStateUpdate")
    }

    func onPlayAssetUpdate() {
        os_log("\(self.t) onPlayAssetUpdate")
    }
}

struct BranchesView: View, SuperThread, SuperLog, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MessageProvider

    @State var selection: Branch?

    var emoji = "🌿"

    var body: some View {
        if g.project?.isGit == true {
            Picker("branch", selection: $g.branch, content: {
                ForEach(g.branches, id: \.self, content: {
                    Text($0.name)
                        .tag($0 as Branch?)
                })
            })
        }
    }
}