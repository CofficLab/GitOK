import MagicCore
import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog, SuperThread {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MessageProvider

    static let emoji = "🐔"
    var commitMessage: String = ""

    var body: some View {
        MagicButton(
            icon: .iconUpload,
            title: "Commit and Push",
            size: .auto,
            action: checkAndPush, preventDoubleClick: true,
            loadingStyle: .spinner
        )
        .frame(height: 40)
        .frame(width: 150)
    }

    private func checkAndPush() {
        guard let project = g.project else {
            return
        }

        os_log("\(self.t)Commit")
        do {
            try project.addAll()
            try project.submit(commitMessage)
            try project.push()
            self.m.toast("已提交并推送")
        } catch {
            self.m.error(error)
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
