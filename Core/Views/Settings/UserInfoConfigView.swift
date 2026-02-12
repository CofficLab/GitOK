import Foundation
import MagicKit
import OSLog
import SwiftUI

/// 用户信息配置视图
struct UserInfoConfigView: View, SuperLog {
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

    /// 数据提供者
    let dataProvider: DataProvider

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
        dataProvider: DataProvider
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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 说明文本
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置当前项目的Git用户信息", tableName: "Core")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("这些设置仅适用于当前项目，不会影响全局Git配置", tableName: "Core")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 预设配置选择
                if !savedConfigs.isEmpty {
                    MagicSettingSection(title: String(localized: "预设配置", table: "Core"), titleAlignment: .leading) {
                        VStack(spacing: 0) {
                            ForEach(savedConfigs) { config in
                                MagicSettingRow(
                                    title: config.name,
                                    description: config.email,
                                    icon: selectedConfig?.id == config.id ? .iconCheckmark : .iconUser
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
                MagicSettingSection(title: String(localized: "用户信息", table: "Core"), titleAlignment: .leading) {
                    VStack(spacing: 0) {
                        // 用户名
                        HStack {
                            Text("用户名", tableName: "Core")
                                .frame(width: 80, alignment: .leading)
                            TextField(String(localized: "输入用户名", table: "Core"), text: $userName)
                                .textFieldStyle(.plain)
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
                            Text("邮箱", tableName: "Core")
                                .frame(width: 80, alignment: .leading)
                            TextField(String(localized: "输入邮箱", table: "Core"), text: $userEmail)
                                .textFieldStyle(.plain)
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
                    HStack(spacing: 8) {
                        Image(systemName: .iconWarning)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    func saveUserConfig() -> Bool {
        guard let project = dataProvider.project else { return false }

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
            return true
        } catch {
        errorMessage = String.localizedStringWithFormat(String(localized: "保存失败: %@", table: "Core"), error.localizedDescription)
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to save user config: \(error)")
            }

            isLoading = false
            return false
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
        errorMessage = String.localizedStringWithFormat(String(localized: "保存预设失败: %@", table: "Core"), error.localizedDescription)
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to save preset: \(error)")
            }
        }
    }

    // MARK: - Load Data

    func loadCurrentUserInfo() {
        guard let project = dataProvider.project else { return }

        isLoading = true
        errorMessage = nil

        do {
            userName = try project.getUserName()
            userEmail = try project.getUserEmail()
            hasChanges = false

            if Self.verbose {
                os_log("\(Self.t)Loaded user info - name: \(userName), email: \(userEmail)")
            }
        } catch {
        errorMessage = String.localizedStringWithFormat(String(localized: "无法加载当前用户信息: %@", table: "Core"), error.localizedDescription)
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to load user info: \(error)")
            }
        }

        isLoading = false
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
