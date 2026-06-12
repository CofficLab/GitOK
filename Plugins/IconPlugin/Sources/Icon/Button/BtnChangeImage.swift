import SwiftUI
import GitOKCoreKit
import MagicAlert
import OSLog

struct BtnChangeImage: View {

    @EnvironmentObject var i: IconProvider

    var body: some View {
        AppButton("换图", systemImage: "photo", style: .secondary, size: .small) {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
                if i.currentData != nil {
                    i.updateImageURL(url)
                } else {
                    os_log(.error, "❌ 未找到可以更新的图标")
                    alert_error("没有找到可以更新的图标")
                }
            }
        }
    }
}
