import GitOKAppCore
import Foundation
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

enum UserInfoConfigBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

/// 用户信息配置视图
public struct UserInfoConfigView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

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

    /// 数据提供者
    let dataProvider: DataVM

    /// 配置仓库
    private var configRepo: any GitUserConfigRepoProtocol {
        dataProvider.repoManager.gitUserConfigRepo
    }

    /// 初始化用户信息配置视图
    /// - Parameters:
    ///   - userName: 用户名绑定
    ///   - userEmail: 用户邮箱绑定
    ///   - hasChanges: 更改状态绑定
    ///   - isLoading: 加载状态绑定
    ///   - errorMessage: 错误消息绑定
    ///   - savedConfigs: 已保存配置绑定
    ///   - selectedConfig: 选中配置绑定
    ///   - dataProvider: 数据提供者
    init(
        userName: Binding<String>,
        userEmail: Binding<String>,
        hasChanges: Binding<Bool>,
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        savedConfigs: Binding<[GitUserConfig]>,
        selectedConfig: Binding<GitUserConfig?>,
        dataProvider: DataVM
    ) {
        self._userName = userName
        self._userEmail = userEmail
        self._hasChanges = hasChanges
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self._savedConfigs = savedConfigs
        self._selectedConfig = selectedConfig
        self.dataProvider = dataProvider
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 说明文本
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "配置当前项目的Git用户信息"))
                        .font(.title2)
                        .fontWeight(.medium)

                    Text(String(localized: "这些设置仅适用于当前项目，不会影响全局Git配置"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 预设配置选择
                if !savedConfigs.isEmpty {
                    GitOKUI.AppSettingsSection(title: String(localized: "Preset Configs")) {
                        VStack(spacing: 0) {
                            ForEach(savedConfigs) { config in
                                presetConfigRow(config)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedConfig = config
                                    userName = config.name
                                    userEmail = config.email
                                    hasChanges = true
                                }

                                if config != savedConfigs.last {
                                    Divider()
                                }
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                }

                // 用户信息输入
                GitOKUI.AppSettingsSection(title: String(localized: "User Info")) {
                    VStack(spacing: 0) {
                        // 用户名
                        HStack {
                            Text(String(localized: "用户名"))
                                .frame(width: 80, alignment: .leading)
                            AppInputField(String(localized: "Enter username"), text: $userName)
                                .onChange(of: userName) {
                                    hasChanges = true
                                    selectedConfig = nil
                                }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)

                        Divider()
                            .padding(.leading, 16)

                        // 邮箱
                        HStack {
                            Text(String(localized: "邮箱"))
                                .frame(width: 80, alignment: .leading)
                            AppInputField(String(localized: "Enter email"), text: $userEmail)
                                .onChange(of: userEmail) {
                                    hasChanges = true
                                    selectedConfig = nil
                                }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                // 错误消息
                if let errorMessage = errorMessage {
                    AppErrorBanner(message: errorMessage)
                }
            }
            .padding()
        }
    }

    private func presetConfigRow(_ config: GitUserConfig) -> some View {
        GitOKUI.AppSettingsRow(isSelected: selectedConfig?.id == config.id, verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: selectedConfig?.id == config.id ? "checkmark.circle.fill" : "person")
                    .foregroundColor(selectedConfig?.id == config.id ? .accentColor : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(config.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedConfig?.id == config.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Actions

    func saveUserConfig() {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = UserInfoConfigBackgroundRunner.UnsafeTransfer(value: loadedProject)
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
                }
            } catch {
                let message = String.localizedStringWithFormat(String(localized: "Save failed: %@"), error.localizedDescription)

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

    func saveAsPreset() {
        guard !userName.isEmpty && !userEmail.isEmpty else { return }

        do {
            let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEmail = userEmail.trimmingCharacters(in: .whitespacesAndNewlines)

            let config = try configRepo.create(
                name: trimmedName,
                email: trimmedEmail,
                isDefault: savedConfigs.isEmpty // 如果是第一个配置，自动设为默认
            )

            // 重新加载配置列表
            loadSavedConfigs()

            // 选择刚保存的配置
            selectedConfig = config

            if Self.verbose {
                os_log("\(Self.t)Saved as preset: \(trimmedName) <\(trimmedEmail)>")
            }

        } catch {
        errorMessage = String.localizedStringWithFormat(String(localized: "Failed to save preset: %@"), error.localizedDescription)
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to save preset: \(error)")
            }
        }
    }

    // MARK: - Load Data

    func loadCurrentUserInfo() {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = UserInfoConfigBackgroundRunner.UnsafeTransfer(value: loadedProject)

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
                let message = String.localizedStringWithFormat(String(localized: "Unable to load current user info: %@"), error.localizedDescription)

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

    func loadSavedConfigs() {
        do {
            savedConfigs = try configRepo.getRecentConfigs(limit: 10)

            // 如果有默认配置，自动选择
            if let defaultConfig = try configRepo.findDefault() {
                selectedConfig = defaultConfig
                userName = defaultConfig.name
                userEmail = defaultConfig.email
            }

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
