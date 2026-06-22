import AppKit
import GitCoreKit
import GitOKUI
import SwiftUI

/// Git 凭据输入视图
/// 用于让用户输入并保存 Git 凭据（用户名和 Personal Access Token）
public struct CredentialInputView: View {
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

    public init(server: String = "github.com", onSave: @escaping () -> Void) {
        self.server = server
        self.onSave = onSave
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text(GitWorkingStatePluginLocalization.string("Add Git Credentials"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(String(localized: "Add your Git authentication information for \(server)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(GitWorkingStatePluginLocalization.string("Git Username"))
                        .font(.headline)
                        .foregroundColor(.primary)

                    AppInputField(GitWorkingStatePluginLocalization.string("e.g., CofficLab"), text: $username)
                        .disableAutocorrection(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(GitWorkingStatePluginLocalization.string("Personal Access Token or Password"))
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        AppIconButton(systemImage: "questionmark.circle", tint: .blue, size: .regular) {
                            openTokenHelp()
                        }
                    }

                    AppInputField(GitWorkingStatePluginLocalization.string("Token or Password"), text: $token, fieldType: .secure)

                    Text(GitWorkingStatePluginLocalization.string("GitOK saves credentials through the current Git credential helper; platforms like GitHub/GitLab usually require tokens."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack(spacing: 12) {
                AppButton(GitWorkingStatePluginLocalization.string("Cancel"), style: .secondary) {
                    dismiss()
                }
                .disabled(isSaving)

                AppButton(GitWorkingStatePluginLocalization.string("Save Credentials"), systemImage: "key.fill", style: .primary, isLoading: isSaving) {
                    saveCredentials()
                }
                .disabled(username.isEmpty || token.isEmpty || isSaving)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 400)
        .alert(GitWorkingStatePluginLocalization.string("Save Successful"), isPresented: $showSuccessAlert) {
            Button(GitWorkingStatePluginLocalization.string("OK")) {
                dismiss()
                onSave()
            }
        } message: {
            Text(GitWorkingStatePluginLocalization.string("Credentials securely saved to macOS Keychain"))
        }
        .alert(GitWorkingStatePluginLocalization.string("Save Failed"), isPresented: $showErrorAlert) {
            Button(GitWorkingStatePluginLocalization.string("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Methods

    /// 保存凭据到 Keychain
    private func saveCredentials() {
        isSaving = true
        let server = server
        let username = username
        let token = token

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
