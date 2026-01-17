import MagicAlert
import MagicKit
import SwiftUI

/// 推送按钮组件
struct BtnPush: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "⬆️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    /// 消息绑定
    @Binding var message: String

    /// 是否正在推送
    @State var isPushing = false

    /// 路径
    var path: String

    /// 按钮视图主体
    var body: some View {
        Button(
            "推送",
            action: {
                do {
                    try data.project?.push()
                } catch let error {
                    m.warning("Push出错", subtitle: error.localizedDescription)
                }
            }
        )
        .disabled(isPushing)
        //        .onNotification(.gitPushStart, perform: { _ in
        //            isPushing = true
        //        })
        //        .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess)) { _ in
        //            isPushing = false
        //        }
        //        .onReceive(NotificationCenter.default.publisher(for: .gitPushFailed)) { _ in
        //            isPushing = false
        //        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
