import MagicCore
import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog, SuperThread {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    static let emoji = "🐔"
    var commitMessage: String = ""

    var body: some View {
        MagicButton(
            icon: .iconUpload,
            title: "Commit and Push",
            size: .auto,
            preventDoubleClick: true,
            loadingStyle: .spinner,
            action: {_ in 
                checkAndPush()
            }
        )
        .frame(height: 40)
        .frame(width: 150)
    }

    private func checkAndPush() {
        guard let project = g.project else {
            return
        }

        os_log("\(self.t)💼 Commit")

        // 显示加载状态
        m.loading("正在提交并推送...")

        do {
            try project.addAll()
            try project.submit(commitMessage)
            try project.push()

            // 隐藏加载状态 - 成功消息会通过Project的事件系统自动显示
            m.hideLoading()
        } catch {
            // 隐藏加载状态并显示错误
            m.hideLoading()
            m.error(error.localizedDescription)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
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
