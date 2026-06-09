import Foundation
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

private enum GitUserInfoBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

/// Git 用户信息设置视图
struct GitUserInfoSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 用户名
    @State private var userName: String = ""

    /// 用户邮箱
    @State private var userEmail: String = ""

    /// 是否正在加载
    @State private var isLoading = false

    /// 错误消息
    @State private var errorMessage: String?

    /// 是否有未保存的更改
    @State private var hasChanges = false

    /// 已保存的配置列表
    @State private var savedConfigs: [GitUserConfig] = []

    /// 配置仓库
    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 现有预设配置列表
                if !savedConfigs.isEmpty {
                    GitOKUI.AppSettingsSection(title: String(localized: "Existing Presets")) {
                        VStack(spacing: 0) {
                            ForEach(savedConfigs) { config in
                                presetConfigRow(config)
                                if config != savedConfigs.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // 添加新预设表单
                addNewPresetSection

                // 错误消息
                if let errorMessage = errorMessage {
                    AppErrorBanner(message: errorMessage)
                }
            }
            .padding()
        }
        .navigationTitle(Text(String(localized: "User Info")))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(String(localized: "Done"), style: .secondary, size: .small) {
                    // 关闭设置视图（通过通知）
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
        .onAppear(perform: loadData)
    }

    // MARK: - View Components

    private func presetConfigRow(_ config: GitUserConfig) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: "person")
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(config.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                AppIconButton(systemImage: "trash", tint: DesignTokens.Color.semantic.error) {
                    deletePreset(config)
                }
                .help(Text(String(localized: "Delete this preset")))
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                deletePreset(config)
            } label: {
                Label(
                    title: { Text(String(localized: "Delete Preset")) },
                    icon: { Image(systemName: .iconTrash) }
                )
            }
        }
    }

    private var addNewPresetSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Add New Preset")) {
            VStack(spacing: 0) {
                userNameInputView
                Divider()
                userEmailInputView
                Divider()
                saveButtonsView
            }
        }
    }

    private var userNameInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Username"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            AppInputField(String(localized: "Enter username"), text: $userName)
                .onChange(of: userName) {
                    hasChanges = true
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var userEmailInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Email"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            AppInputField(String(localized: "Enter email"), text: $userEmail)
                .onChange(of: userEmail) {
                    hasChanges = true
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var saveButtonsView: some View {
        AppButton(
            String(localized: "Add New Preset"),
            systemImage: "plus",
            style: .secondary,
            size: .small,
            isLoading: isLoading
        ) {
            saveAsPreset()
            // 清空输入框
            userName = ""
            userEmail = ""
            hasChanges = false
        }
        .disabled(isLoading || userName.isEmpty || userEmail.isEmpty)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func saveUserConfig() {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = GitUserInfoBackgroundRunner.UnsafeTransfer(value: loadedProject)
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = userEmail.trimmingCharacters(in: .whitespacesAndNewlines)

        isLoading = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) {
            do {
                try await projectTransfer.value.setUserConfigAsync(name: trimmedName, email: trimmedEmail)

                Task { @MainActor in
                    hasChanges = false
                    isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)Saved user config - name: \(trimmedName), email: \(trimmedEmail)")
                    }

                    // 保存成功后发送通知
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            } catch {
                let message = String.localizedStringWithFormat(NSLocalizedString("Save failed: %@", comment: ""), error.localizedDescription)

                Task { @MainActor in
                    errorMessage = message
                    isLoading = false

                    if Self.verbose {
                        os_log(.error, "\(Self.t)Failed to save user config: \(message)")
                    }
                }
            }
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

            if Self.verbose {
                os_log("\(Self.t)Saved as preset: \(trimmedName) <\(trimmedEmail)>")
            }

        } catch {
            errorMessage = String.localizedStringWithFormat(NSLocalizedString("Failed to save preset: %@", comment: ""), error.localizedDescription)
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to save preset: \(error)")
            }
        }
    }

    private func deletePreset(_ config: GitUserConfig) {
        do {
            try configRepo.delete(config)

            // 从列表中移除
            savedConfigs.removeAll { $0.id == config.id }

            if Self.verbose {
                os_log("\(Self.t)Deleted preset: \(config.name)")
            }

        } catch {
            errorMessage = String.localizedStringWithFormat(NSLocalizedString("Failed to delete preset: %@", comment: ""), error.localizedDescription)
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to delete preset: \(error)")
            }
        }
    }

    // MARK: - Load Data

    private func loadData() {
        loadSavedConfigs()
    }

    private func loadCurrentUserInfo() {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = GitUserInfoBackgroundRunner.UnsafeTransfer(value: loadedProject)

        isLoading = true
        errorMessage = nil

        Task.detached(priority: .utility) {
            do {
                let loadedName = try await projectTransfer.value.getUserNameAsync()
                let loadedEmail = try await projectTransfer.value.getUserEmailAsync()

                Task { @MainActor in
                    userName = loadedName
                    userEmail = loadedEmail
                    hasChanges = false
                    isLoading = false

                    if Self.verbose {
                        os_log("\(Self.t)Loaded user info - name: \(loadedName), email: \(loadedEmail)")
                    }
                }
            } catch {
                let message = String.localizedStringWithFormat(NSLocalizedString("Unable to load current user info: %@", comment: ""), error.localizedDescription)

                Task { @MainActor in
                    errorMessage = message
                    isLoading = false

                    if Self.verbose {
                        os_log(.error, "\(Self.t)Failed to load user info: \(message)")
                    }
                }
            }
        }
    }

    private func loadSavedConfigs() {
        do {
            savedConfigs = try configRepo.getRecentConfigs(limit: 10)

            if Self.verbose {
                os_log("\(Self.t)Loaded \(savedConfigs.count) saved configs")
            }
        } catch {
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to load saved configs: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
