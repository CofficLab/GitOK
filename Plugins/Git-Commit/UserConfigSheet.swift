import Foundation
import MagicCore
import OSLog
import SwiftUI

struct UserConfigSheet: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasChanges = false
    @State private var savedConfigs: [GitUserConfig] = []
    @State private var selectedConfig: GitUserConfig?

    private let verbose = true

    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
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

            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("保存为预设") {
                    saveAsPreset()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading || userName.isEmpty || userEmail.isEmpty)

                Button("应用") {
                    saveUserConfig()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || !hasChanges || userName.isEmpty || userEmail.isEmpty)
            }
        }
        .padding()
        .navigationTitle("Git用户配置")
        .frame(width: 600, height: 600)
        .onAppear {
            loadCurrentUserInfo()
            loadSavedConfigs()
        }
        .disabled(isLoading)
    }

    private func loadCurrentUserInfo() {
        guard let project = data.project else { return }

        isLoading = true
        errorMessage = nil

        do {
            userName = try project.getUserName()
            userEmail = try project.getUserEmail()
            hasChanges = false

            if verbose {
                os_log("\(self.t)✅ Loaded user info - name: \(userName), email: \(userEmail)")
            }
        } catch {
            errorMessage = "无法加载当前用户信息: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to load user info: \(error)")
            }
        }

        isLoading = false
    }

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

            if verbose {
                os_log("\(self.t)✅ Saved user config - name: \(userName), email: \(userEmail)")
            }

            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to save user config: \(error)")
            }
        }

        isLoading = false
    }

    private func loadSavedConfigs() {
        do {
            savedConfigs = try configRepo.getRecentConfigs(limit: 10)

            // 如果有默认配置，自动选择
            if let defaultConfig = try configRepo.findDefault() {
                selectedConfig = defaultConfig
                userName = defaultConfig.name
                userEmail = defaultConfig.email
            }

            if verbose {
                os_log("\(self.t)✅ Loaded \(savedConfigs.count) saved configs")
            }
        } catch {
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to load saved configs: \(error)")
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
                isDefault: savedConfigs.isEmpty // 如果是第一个配置，自动设为默认
            )

            // 重新加载配置列表
            loadSavedConfigs()

            // 选择刚保存的配置
            selectedConfig = config

            if verbose {
                os_log("\(self.t)✅ Saved as preset: \(trimmedName) <\(trimmedEmail)>")
            }

        } catch {
            errorMessage = "保存预设失败: \(error.localizedDescription)"
            if verbose {
                os_log(.error, "\(self.t)❌ Failed to save preset: \(error)")
            }
        }
    }
}

#Preview {
    UserConfigSheet().inRootView()
}

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
