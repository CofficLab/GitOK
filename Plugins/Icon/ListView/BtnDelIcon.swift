import MagicCore
import OSLog
import SwiftUI

struct BtnDelIcon: View {
    @EnvironmentObject var m: MagicMessageProvider

    var icon: IconModel

    var body: some View {
        Button(action: {
            do {
                try self.icon.deleteFromDisk()
            } catch {
                m.error(error.localizedDescription)
            }
        }) {
            Label("删除「\(icon.title)」", systemImage: "trash")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
