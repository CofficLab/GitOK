import MagicCore
import OSLog
import SwiftUI

class GitPlugin: SuperPlugin, SuperLog {
    let emoji = "📣"
    var label: String = "Git"
    var isTab: Bool = true

    func addDetailView() -> AnyView {
        AnyView(GitDetail()
            .environmentObject(GitProvider.shared)
        )
    }
}

#Preview {
    RootView {
        ContentView()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
