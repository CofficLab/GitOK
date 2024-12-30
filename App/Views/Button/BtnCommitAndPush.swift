import OSLog
import SwiftUI
import MagicKit

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
    @State private var isHovered = false

    let emoji = "🐔"
    var repoPath: String
    var commitMessage: String = ""

    var body: some View {
        Button(title) {
            isLoading = true
            do {
                try checkAndPush()
            } catch let error {
                self.main.async {
                    os_log(.error, "提交失败: \(error.localizedDescription)")
                    alertMessage = "Commit and Push failed: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
        .cornerRadius(8)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(isLoading)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showCredentialsAlert) {
            VStack {
                Text("Input credentials")
                TextField("Username", text: $username)
                SecureField("Personal access token", text: $token)
                HStack {
                    Button("OK") {
                        isLoading = true
                        showCredentialsAlert = false
                        DispatchQueue.global(qos: .userInitiated).async {
                            do {
                                try checkAndPush()
                            } catch let error {
                                self.main.async {
                                    os_log(.error, "Commit and Push failed: \(error.localizedDescription)")
                                    alertMessage = "Commit and Push failed: \(error.localizedDescription)"
                                    showAlert = true
                                    isLoading = false
                                }
                            }
                        }
                    }
                    Button("Cancel") {
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
            self.title = "Commit Success"
            isLoading = true
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
                alertMessage = "HTTPS credentials not configured, please input credentials."
                showAlert = true
            }

            throw GitError.credentialsNotConfigured
        }

        self.bg.async {
            os_log("\(self.t)Commit")
            do {
                try GitShell.add(repoPath)
                try GitShell.commit(repoPath, commit: commitMessage)
                try GitShell.push(repoPath, username: username, token: token)

                self.main.async {
                    isLoading = false
                }
            } catch {
                self.quitWithError(error)
            }
        }
    }

    private func quitWithError(_ error: Error) {
        os_log(.error, "提交失败: \(error.localizedDescription)")
        self.main.async {
            alertMessage = "Commit and Push failed: \(error.localizedDescription)"
            showAlert = true
            isLoading = false
        }
    }
}

#Preview {
    BtnCommitAndPush(repoPath: "/path/to/your/repo") // 初始化时传入路径
}
