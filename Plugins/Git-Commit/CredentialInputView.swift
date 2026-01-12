import SwiftUI
import Security

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
                    Text("GitHub 用户名")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("例如: CofficLab", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                }

                // Personal Access Token
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Personal Access Token")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: openTokenHelp) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
                        .textFieldStyle(.roundedBorder)

                    Text("在 GitHub Settings → Developer settings → Personal access tokens 中创建")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal)

            Spacer()

            // 按钮
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .disabled(isSaving)

                Button("保存凭据") {
                    saveCredentials()
                }
                .buttonStyle(.borderedProminent)
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
            let result = saveToKeychain(username: username, token: token, server: server)

            DispatchQueue.main.async {
                isSaving = false

                if result {
                    showSuccessAlert = true
                } else {
                    errorMessage = "无法保存凭据到 Keychain，请重试"
                    showErrorAlert = true
                }
            }
        }
    }

    /// 保存到 Keychain
    private func saveToKeychain(username: String, token: String, server: String) -> Bool {
        let tokenData = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrProtocol as String: "https",
            kSecAttrAccount as String: username,
            kSecValueData as String: tokenData
        ]

        // 先删除旧的凭据
        SecItemDelete(query as CFDictionary)

        // 添加新凭据
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// 打开 Token 帮助文档
    private func openTokenHelp() {
        if let url = URL(string: "https://github.com/settings/tokens") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Credential Input") {
    CredentialInputView {
        print("Credentials saved!")
    }
}
