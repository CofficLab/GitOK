import OSLog
import SwiftData
import SwiftUI
import MagicCore

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

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

