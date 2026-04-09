import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 提交并推送按钮组件
struct BtnCommitAndPush: View, SuperLog, SuperThread {
    /// emoji 标识符
    nonisolated static let emoji = "🐔"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var vm: ProjectVM
    

    /// 提交消息
    var commitMessage: String = ""

    /// 是否只执行提交操作，不推送
    var commitOnly: Bool = false

    /// 按钮视图主体
    var body: some View {
        AppButton(
            commitOnly ? "提交" : "提交并推送",
            systemImage: .iconUpload,
            style: .primary,
            action: {
            guard let project = vm.project else {
                return
            }

            /// 设置状态信息
            /// - Parameter text: 状态文本，nil 表示清除状态
            func setStatus(_ text: String?) {
                Task { @MainActor in
                    g.activityStatus = text
                }
            }

            Task.detached {
                setStatus("添加文件中…")
                do {
                    try project.addAll()

                    let message = commitMessage.isEmpty ? "自动提交" : commitMessage

                    setStatus("提交中…")
                    try await MainActor.run {
                        try project.submit(message)
                    }

                    if commitOnly == false {
                        setStatus("推送中…")
                        try project.push()
                    }

                    await MainActor.run {
                        if commitOnly == false {
                            alert_info("提交并推送成功")
                        } else {
                            alert_info("提交成功")
                        }
                    }
                } catch {
                    await MainActor.run {
                        os_log(.error, "\(Self.t)❌ 提交或推送失败: \(error.localizedDescription)")
                        alert_error(error)
                    }
                }

                setStatus(nil)
            }
        })
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
