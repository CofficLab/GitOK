import MagicCore
import OSLog
import SwiftUI

struct BtnDelIcon: View {
    @EnvironmentObject var m: MagicMessageProvider

    var icon: IconData

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
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
