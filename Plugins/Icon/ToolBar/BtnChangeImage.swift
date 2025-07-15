import SwiftUI
import MagicCore

struct BtnChangeImage: View {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    var body: some View {
        Button("换图") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
                do {
                    if var icon = i.currentModel {
                        try icon.updateImageURL(url)
                    } else {
                        m.error("没有找到可以更新的图标")
                    }
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
