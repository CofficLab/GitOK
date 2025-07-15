import SwiftUI
import MagicCore

struct BtnChangeImage: View {
    @EnvironmentObject var m: MagicMessageProvider
    @Binding var icon: IconModel

    var body: some View {
        Button("换图") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
                do {
                    try self.icon.updateImageURL(url)
                } catch {
                    m.error(error.localizedDescription)
                }
            }
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
