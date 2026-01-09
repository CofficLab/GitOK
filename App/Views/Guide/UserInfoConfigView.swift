import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 用户信息配置视图
struct UserInfoConfigView: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var hasChanges: Bool
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    @Binding var savedConfigs: [GitUserConfig]
    @Binding var selectedConfig: GitUserConfig?

    private let verbose = true
    let dataProvider: DataProvider

    private var configRepo: any GitUserConfigRepoProtocol {
        dataProvider.repoManager.gitUserConfigRepo
    }

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
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("配置当前项目的Git用户信息")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("这些设置仅适用于当前项目，不会影响全局Git配置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                // 预设配置选择
                if !savedConfigs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(savedConfigs) { config in
                                    GitUserConfigRowView(
                                        config: config,
                                        selectedConfig: selectedConfig,
                                        onTap: { selectedConfig in
                                            self.selectedConfig = selectedConfig
                                            userName = selectedConfig.name
                                            userEmail = selectedConfig.email
                                            hasChanges = true
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }

                    Divider()
                }

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用户名")
                            .font(.headline)

                        TextField("输入用户名", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: userName) {
                                hasChanges = true
                                selectedConfig = nil
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱")
                            .font(.headline)

                        TextField("输入邮箱", text: $userEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: userEmail) {
                                hasChanges = true
                                selectedConfig = nil
                            }
                    }
                }
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
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

            if verbose {
                os_log("\(Self.t)✅ Saved user config - name: \(userName), email: \(userEmail)")
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(Self.t)❌ Failed to save user config: \(error)")
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

            if verbose {
                os_log("\(Self.t)✅ Saved as preset: \(trimmedName) <\(trimmedEmail)>")
            }

        } catch {
            errorMessage = "保存预设失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(Self.t)❌ Failed to save preset: \(error)")
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

            if verbose {
                os_log("\(Self.t)✅ Loaded user info - name: \(userName), email: \(userEmail)")
            }
        } catch {
            errorMessage = "无法加载当前用户信息: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(Self.t)❌ Failed to load user info: \(error)")
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

            if verbose {
                os_log("\(Self.t)✅ Loaded \(savedConfigs.count) saved configs")
            }
        } catch {
            if verbose {
                os_log(.error, "\(Self.t)❌ Failed to load saved configs: \(error)")
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
        .frame(width: 700)
        .frame(height: 700)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
