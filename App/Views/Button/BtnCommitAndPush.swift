import OSLog
import SwiftUI

struct BtnCommitAndPush: View, SuperLog {
    static let defaultTitle = "Commit and Push"

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

    var body: some View {
        Button(title) {
            isLoading = true
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try checkAndPush()
                } catch let error {
                    DispatchQueue.main.async {
                        os_log(.error, "提交失败: \(error.localizedDescription)")
                        alertMessage = "提交失败: \(error.localizedDescription)"
                        showAlert = true
                        isLoading = false
                    }
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
                                _ = try commitAndPush()
                            } catch let error {
                                DispatchQueue.main.async {
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
            self.title = "Commiting..."
            isLoading = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
            self.title = "Commit Success"
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
        let path = repoPath
        let git = Git()

        // 检查是否使用 HTTPS
        let remoteUrl = try git.getRemoteUrl(path)
        DispatchQueue.main.async {
            if remoteUrl.starts(with: "https://") {
                showCredentialsAlert = true
                isLoading = false
            } else {
                do {
                    try commitAndPush()
                } catch let error {
                    os_log(.error, "提交失败: \(error.localizedDescription)")
                    alertMessage = "提交失败: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }

    private func commitAndPush() throws -> String {
        let path = repoPath
        let git = Git()

        do {
            let helper = try git.getCredentialHelper(path)
            os_log("\(self.t)Get credential helper: \(helper)")
        } catch {
            os_log(.error, "\(error.localizedDescription)")
        }

        // 检查HTTPS凭据
        let commit = GitCommit.headFor(path)
        if !commit.checkHttpsCredentials() {
            // 要求用户输入凭据
            DispatchQueue.main.async {
                alertMessage = "HTTPS 凭据未配置，请输入凭据。"
                showAlert = true
            }
            return "HTTPS 凭据未配置"
        }

        // 执行 commit
        do {
            try git.add(path)
            _ = try git.commit(path, commit: commitMessage)
        } catch let error {
            DispatchQueue.main.async {
                os_log(.error, "提交失败: \(error.localizedDescription)")
                alertMessage = "提交失败: \(error.localizedDescription)"
                showAlert = true
            }
            return "提交失败: \(error.localizedDescription)"
        }

        // 执行 push
        do {
            try git.push(path, username: username, token: token)
        } catch let error {
            DispatchQueue.main.async {
                os_log(.error, "推送失败: \(error.localizedDescription)")
                alertMessage = "推送失败: \(error.localizedDescription)"
                showAlert = true
            }
            return "推送失败: \(error.localizedDescription)"
        }

        DispatchQueue.main.async {
            isLoading = false
        }

        return "提交和推送成功"
    }
}

extension Git {
    func getRemoteUrl(_ path: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "config", "--get", "remote.origin.url"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw NSError(domain: "GitError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }

        return output
    }

    func push(_ path: String, username: String, token: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "push"]
        process.environment = ["GIT_ASKPASS": "echo", "GIT_USERNAME": username, "GIT_PASSWORD": token]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw NSError(domain: "GitError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }
    }
}

#Preview {
    BtnCommitAndPush(repoPath: "/path/to/your/repo") // 初始化时传入路径
}
