import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

// MARK: - Notifications

extension Notification.Name {
    static let didSaveGitUserConfig = Notification.Name("didSaveGitUserConfig")
}

/// Git 用户信息设置视图
struct GitUserInfoSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider

    /// 用户名绑定
    @Binding var userName: String

    /// 用户邮箱绑定
    @Binding var userEmail: String

    /// 是否有未保存的更改
    @Binding var hasChanges: Bool

    /// 是否正在加载
    @Binding var isLoading: Bool

    /// 错误消息
    @Binding var errorMessage: String?

    /// 已保存的配置列表
    @Binding var savedConfigs: [GitUserConfig]

    /// 当前选中的配置
    @Binding var selectedConfig: GitUserConfig?

    /// 配置仓库
    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    var body: some View {
        MagicSettingSection(title: "Git 用户信息", titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 预设配置列表
                if !savedConfigs.isEmpty {
                    ForEach(savedConfigs) { config in
                        presetConfigRow(config)
                        if config != savedConfigs.last {
                            Divider()
                        }
                    }
                    Divider()
                }

                // 用户名输入
                userNameInputView
                Divider()
                // 邮箱输入
                userEmailInputView
                Divider()
                // 操作按钮
                actionButtonsView
            }
        }
    }

    // MARK: - View Components

    private func presetConfigRow(_ config: GitUserConfig) -> some View {
        MagicSettingRow(
            title: config.name,
            description: config.email,
            icon: .iconUser
        ) {
            if selectedConfig?.id == config.id {
                Image(systemName: .iconCheckmark)
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedConfig = config
            userName = config.name
            userEmail = config.email
            hasChanges = true
        }
    }

    private var userNameInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("用户名")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            TextField("输入用户名", text: $userName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: userName) {
                    hasChanges = true
                    selectedConfig = nil
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var userEmailInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("邮箱")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            TextField("输入邮箱", text: $userEmail)
                .textFieldStyle(.roundedBorder)
                .onChange(of: userEmail) {
                    hasChanges = true
                    selectedConfig = nil
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            MagicButton(
                icon: .iconUpload,
                title: "保存为预设",
                preventDoubleClick: true
            ) { completion in
                saveAsPreset()
                completion()
            }
            .magicSize(.auto)
            .disabled(isLoading || userName.isEmpty || userEmail.isEmpty)
            .frame(height: 50)
            .frame(width: 120)

            MagicButton(
                icon: .iconCheckmark,
                title: "应用",
                preventDoubleClick: true
            ) { completion in
                saveUserConfig()
                completion()
            }
            .magicSize(.auto)
            .disabled(isLoading || !hasChanges || userName.isEmpty || userEmail.isEmpty)
            .frame(height: 50)
            .frame(width: 120)
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Actions

    private func saveUserConfig() {
        guard let project = data.project else { return }

        isLoading = true
        errorMessage = nil

        do {
            try project.setUserConfig(
                name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            hasChanges = false

            if Self.verbose {
                os_log("\(Self.t)Saved user config - name: \(userName), email: \(userEmail)")
            }

            isLoading = false

            // 保存成功后发送通知
            NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to save user config: \(error)")
            }

            isLoading = false
        }
    }

    private func saveAsPreset() {
        guard !userName.isEmpty && !userEmail.isEmpty else { return }

        do {
            let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEmail = userEmail.trimmingCharacters(in: .whitespacesAndNewlines)

            let config = try configRepo.create(
                name: trimmedName,
                email: trimmedEmail,
                isDefault: savedConfigs.isEmpty
            )

            savedConfigs.append(config)
            selectedConfig = config

            if Self.verbose {
                os_log("\(Self.t)Saved as preset: \(trimmedName) <\(trimmedEmail)>")
            }

        } catch {
            errorMessage = "保存预设失败: \(error.localizedDescription)"
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to save preset: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview("Git User Info Settings") {
    GitUserInfoSettingView(
        userName: .constant("John Doe"),
        userEmail: .constant("john@example.com"),
        hasChanges: .constant(false),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        savedConfigs: .constant([]),
        selectedConfig: .constant(nil)
    )
    .padding()
    .frame(height: 600)
}
