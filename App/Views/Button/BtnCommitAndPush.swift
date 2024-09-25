import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog, SuperThread {
    static let defaultTitle = "Commit and Push"

    @EnvironmentObject var g: GitProvider

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var title = defaultTitle
    @State private var showCredentialsAlert = false
    @State private var username = ""
    @State private var token = ""

    let emoji = "🐔"
    var repoPath: String
    var commitMessage: String = ""
    var git: Git { g.git }

    var body: some View {
        Button(title) {
            isLoading = true
            do {
                try checkAndPush()
            } catch let error {
                self.main.async {
                    os_log(.error, "提交失败: \(error.localizedDescription)")
                    alertMessage = "提交失败: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
        .disabled(isLoading)
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
                        isLoading = true
                        showCredentialsAlert = false
                        DispatchQueue.global(qos: .userInitiated).async {
                            do {
                                try checkAndPush()
                            } catch let error {
                                self.main.async {
                                    os_log(.error, "提交失败: \(error.localizedDescription)")
                                    alertMessage = "提交失败: \(error.localizedDescription)"
                                    showAlert = true
                                    isLoading = false
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
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitStart)) { _ in
            self.title = "Committing..."
            isLoading = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
            self.title = BtnCommitAndPush.defaultTitle
            isLoading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitPushStart)) { _ in
            self.title = "Pushing..."
            isLoading = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess)) { _ in
            self.title = BtnCommitAndPush.defaultTitle
            isLoading = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitFailed)) { _ in
            self.title = BtnCommitAndPush.defaultTitle
            isLoading = false
        }
    }

    private func checkAndPush() throws {
        let verbose = true

        do {
            let helper = try git.getCredentialHelper(repoPath)
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

        self.bg.async {
            // 执行 commit
            do {
                try git.add(repoPath)
                try git.commit(repoPath, commit: commitMessage)
            } catch {
                os_log(.error, "提交失败: \(error.localizedDescription)")
                self.main.async {
                    alertMessage = "提交失败: \(error.localizedDescription)"
                    showAlert = true
                }

                return
            }

            // 执行 push
            do {
                try git.push(repoPath, username: username, token: token)
            } catch let error {
                os_log(.error, "推送失败: \(error.localizedDescription)")
                self.main.async {
                    alertMessage = "推送失败: \(error.localizedDescription)"
                    showAlert = true
                }
            }

            self.main.async {
                isLoading = false
            }
        }
    }
}

#Preview {
    BtnCommitAndPush(repoPath: "/path/to/your/repo") // 初始化时传入路径
}
