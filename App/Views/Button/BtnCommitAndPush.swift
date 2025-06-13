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
            action: {completion in
                checkAndPush()
                completion()
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

        // 确保在主线程执行 Git 操作
        DispatchQueue.main.async {
            do {
                try project.addAll()
                try project.submit(commitMessage)
                try project.push()

                m.info("Commit and push success")
            } catch {
                m.error(error.localizedDescription)
            }
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
