import MagicCore
import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog, SuperThread {
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MessageProvider

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCredentialsAlert = false
    @State private var username = ""
    @State private var token = ""

    static let emoji = "🐔"
    var repoPath: String
    var commitMessage: String = ""

    var body: some View {
        MagicButton(
            icon: .iconUpload,
            title: "Commit and Push",
            size: .auto,
            preventDoubleClick: true,
            loadingStyle: .spinner,
            asyncAction: {
                do {
                    try checkAndPush()
                } catch let error {
                    self.main.async {
                        os_log(.error, "提交失败: \(error.localizedDescription)")
                        alertMessage = "提交失败: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            })
            .frame(height: 40)
            .frame(width: 150)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("错误"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
    }

    private func checkAndPush() throws {
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
            self.quitWithError(error)
        }
    }

    private func quitWithError(_ error: Error) {
        os_log(.error, "\(t)❌ 提交失败: \(error.localizedDescription)")
        self.main.async {
            alertMessage = "提交失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    BtnCommitAndPush(repoPath: "/path/to/your/repo") // 初始化时传入路径
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
