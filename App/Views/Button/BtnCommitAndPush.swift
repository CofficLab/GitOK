import MagicCore
import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog, SuperThread {
    @EnvironmentObject var g: DataProvider

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
            .sheet(isPresented: $showCredentialsAlert) {
                VStack {
                    Text("输入凭据")
                    TextField("用户名", text: $username)
                    SecureField("个人访问令牌", text: $token)
                    HStack {
                        Button("确定") {
                            showCredentialsAlert = false
                            DispatchQueue.global(qos: .userInitiated).async {
                                do {
                                    try checkAndPush()
                                } catch let error {
                                    self.main.async {
                                        os_log(.error, "提交失败: \(error.localizedDescription)")
                                        alertMessage = "提交失败: \(error.localizedDescription)"
                                        showAlert = true
                                    }
                                }
                            }
                        }
                        Button("取消") {
                            showCredentialsAlert = false
                        }
                    }
                }
                .padding()
            }
    }

    private func checkAndPush() throws {
        let verbose = true

        do {
            let helper = try GitShell.getCredentialHelper(repoPath)
            if verbose {
                os_log("\(self.t)Get credential helper: \(helper)")
            }
        } catch {
            os_log(.error, "\(error.localizedDescription)")

            throw error
        }

        // 检查HTTPS凭据
        let commit = GitCommit.headFor(repoPath)
        if !commit.checkHttpsCredentials() {
            self.main.async {
                alertMessage = "HTTPS 凭据未配置，请输入凭据。"
                showAlert = true
            }

            throw GitError.credentialsNotConfigured
        }

        os_log("\(self.t)Commit")
        do {
            try GitShell.add(repoPath)
            try GitShell.commit(repoPath, commit: commitMessage)
            try GitShell.push(repoPath, username: username, token: token)
        } catch {
            self.quitWithError(error)
        }
    }

    private func quitWithError(_ error: Error) {
        os_log(.error, "提交失败: \(error.localizedDescription)")
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
