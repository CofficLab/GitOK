import MagicCore
import OSLog
import SwiftUI

struct Branches: View, SuperThread, SuperLog, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MessageProvider

    @State var selection: Branch?

    var emoji = "🌿"

    var body: some View {
        Picker("branch", selection: $g.branch, content: {
            ForEach(g.branches, id: \.self, content: {
                Text($0.name)
                    .tag($0 as Branch?)
            })
        })
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
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
