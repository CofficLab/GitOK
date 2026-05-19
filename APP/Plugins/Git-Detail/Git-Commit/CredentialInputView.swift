import GitCoreKit
import SwiftUI

/// Git 凭据输入视图
/// 用于让用户输入并保存 Git 凭据（用户名和 Personal Access Token）
struct CredentialInputView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let server: String
    let onSave: () -> Void

    // MARK: - State

    @State private var username: String = ""
    @State private var token: String = ""
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // MARK: - Initialization

    init(server: String = "github.com", onSave: @escaping () -> Void) {
        self.server = server
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("添加 Git 凭据")
                    .font(.title)
                    .fontWeight(.bold)

                Text("为 \(server) 添加您的 Git 认证信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // 表单
            VStack(alignment: .leading, spacing: 12) {
                // GitHub 用户名
                VStack(alignment: .leading, spacing: 4) {
                    Text("Git 用户名")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("例如: CofficLab", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                }

                // Personal Access Token
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                    Text("Personal Access Token 或密码")
                        .font(.headline)
                        .foregroundColor(.primary)

                        Spacer()

                        AppIconButton(
                            systemImage: "questionmark.circle",
                            tint: .blue,
                            size: .regular
                        ) {
                            openTokenHelp()
                        }
                    }

                    SecureField("token 或密码", text: $token)
                        .textFieldStyle(.roundedBorder)

                    Text("GitOK 会通过当前 Git credential helper 保存凭据；GitHub/GitLab 等平台通常需要 token。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal)

            Spacer()

            // 按钮
            HStack(spacing: 12) {
                AppButton("取消", style: .secondary) {
                    dismiss()
                }
                .disabled(isSaving)

                AppButton("保存凭据", style: .primary) {
                    saveCredentials()
                }
                .disabled(username.isEmpty || token.isEmpty || isSaving)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 400)
        .alert("保存成功", isPresented: $showSuccessAlert) {
            Button("确定") {
                dismiss()
                onSave()
            }
        } message: {
            Text("凭据已安全保存到 macOS Keychain")
        }
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Methods

    /// 保存凭据到 Keychain
    private func saveCredentials() {
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try GitRepositoryCLI.approveCredential(
                    host: server,
                    username: username,
                    password: token
                )

                DispatchQueue.main.async {
                    isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    /// 打开 Token 帮助文档
    private func openTokenHelp() {
        if let url = URL(string: "https://github.com/settings/tokens") {
            NSWorkspace.shared.open(url)
        }
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
