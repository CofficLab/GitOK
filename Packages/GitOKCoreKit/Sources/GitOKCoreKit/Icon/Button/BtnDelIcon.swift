
import OSLog
import SwiftUI

struct BtnDelIcon: View {


    var icon: IconData

    var body: some View {
        Button(action: {
            do {
                try self.icon.deleteFromDisk()
            } catch {
                os_log(.error, "❌ 删除图标失败: \(error.localizedDescription)")
                alert_error(error.localizedDescription)
            }
        }) {
            Label("删除「\(icon.title)」", systemImage: "trash")
        }
    }
}
