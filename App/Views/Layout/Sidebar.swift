import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct Sidebar: View, SuperThread, SuperEvent {
    var body: some View {
        Projects()
            .toolbar(content: {
                ToolbarItem {
                    BtnAdd()
                }
            })
    }
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
