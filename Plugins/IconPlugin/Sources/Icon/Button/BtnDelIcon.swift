
import OSLog
import MagicAlert
import GitOKCoreKit
import SwiftUI

struct BtnDelIcon: View {


    var icon: IconData

    var body: some View {
        AppButton("删除「\(icon.title)」", systemImage: "trash", style: .destructive, size: .small) {
            do {
                try self.icon.deleteFromDisk()
            } catch {
                os_log(.error, "❌ 删除图标失败: \(error.localizedDescription)")
                alert_error(error.localizedDescription)
            }
        }
    }
}
