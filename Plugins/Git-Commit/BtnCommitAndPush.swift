import MagicKit
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

/// 提交并推送按钮组件
struct BtnCommitAndPush: View, SuperLog, SuperThread {
    /// emoji 标识符
    nonisolated static let emoji = "🐔"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    /// 提交消息
    var commitMessage: String = ""

    /// 是否只执行提交操作，不推送
    var commitOnly: Bool = false

    /// 按钮视图主体
    var body: some View {
        MagicButton(
            icon: .iconUpload,
            title: commitOnly ? "提交" : "提交并推送",
            size: .auto,
            preventDoubleClick: true,
            loadingStyle: .spinner,
            action: { completion in
                guard let project = g.project else {
                    completion()
                    return
                }

                if Self.verbose {
                    os_log("\(self.t)Starting commit operation")
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
                                m.info("提交并推送成功")
                            } else {
                                m.info("提交成功")
                            }
                        }
                    } catch {
                        await MainActor.run {
                            m.error(error)
                        }
                    }

                    setStatus(nil)
                    await MainActor.run {
                        completion()
                    }
                }
            }
        )
        .frame(height: 40)
        .frame(width: 150)
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
