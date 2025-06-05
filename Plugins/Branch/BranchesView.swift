import SwiftUI
import MagicCore
import OSLog

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