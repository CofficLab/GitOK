import SwiftUI
import OSLog

struct BtnCommitAndPush: View, SuperLog {
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let emoji = "🐔"
    var repoPath: String
    var commitMessage: String = ""

    var body: some View {
        VStack {
            Button("Commit and Push") {
                do {
                    let result = try commitAndPush()
                    os_log("\(self.t)提交结果: \(result)")
                } catch let error {
                    os_log(.error, "提交失败: \(error.localizedDescription)")
                    alertMessage = "提交失败: \(error.localizedDescription)"
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("错误"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
        }
        .padding()
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
            alertMessage = "HTTPS 凭据未配置，请输入凭据。"
            showAlert = true
            return "HTTPS 凭据未配置"
        }

        // 执行 commit
        do {
            try git.add(path)
            _ = try git.commit(path, commit: commitMessage)
        } catch let error {
            os_log(.error, "提交失败: \(error.localizedDescription)")
            alertMessage = "提交失败: \(error.localizedDescription)"
            showAlert = true
            return "提交失败: \(error.localizedDescription)"
        }

        // 执行 push
        do {
            try git.push(path)
        } catch let error {
            os_log(.error, "推送失败: \(error.localizedDescription)")
            alertMessage = "推送失败: \(error.localizedDescription)"
            showAlert = true
            return "推送失败: \(error.localizedDescription)"
        }

        return "提交和推送成功"
    }
}

#Preview {
    BtnCommitAndPush(repoPath: "/path/to/your/repo") // 初始化时传入路径
}
