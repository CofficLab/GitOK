import MagicCore
import OSLog
import SwiftUI

class GitPlugin: SuperPlugin, SuperLog {
    static let shared = GitPlugin()
    let emoji = "📣"
    static var label: String = "Git"
    var isTab: Bool = true

    private init() {}

    func addDetailView() -> AnyView? {
        AnyView(GitDetail.shared)
    }
}

#Preview {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
