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
                    MagicSettingSection(title: "现有预设", titleAlignment: .leading) {
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
        .navigationTitle("用户信息")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    // 关闭设置视图（通过通知）
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
        .onAppear(perform: loadData)
    }

    // MARK: - View Components

    private func presetConfigRow(_ config: GitUserConfig) -> some View {
        MagicSettingRow(
            title: config.name,
            description: config.email,
            icon: .iconUser
        ) {
            // 删除按钮
            Button(action: { deletePreset(config) }) {
                Image(systemName: .iconTrash)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("删除此预设")
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                deletePreset(config)
            } label: {
                Label("删除预设", systemImage: .iconTrash)
            }
        }
    }

    private var addNewPresetSection: some View {
        MagicSettingSection(title: "添加新预设", titleAlignment: .leading) {
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
            Text("用户名")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            TextField("输入用户名", text: $userName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: userName) {
                    hasChanges = true
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
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var saveButtonsView: some View {
        MagicButton(
            icon: .iconPlus,
            title: "添加",
            preventDoubleClick: true
        ) { completion in
            saveAsPreset()
            // 清空输入框
            userName = ""
            userEmail = ""
            hasChanges = false
            completion()
        }
        .magicSize(.auto)
        .disabled(isLoading || userName.isEmpty || userEmail.isEmpty)
        .frame(height: 50)
        .frame(width: 120)
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

    private func deletePreset(_ config: GitUserConfig) {
        do {
            try configRepo.delete(config)

            // 从列表中移除
            savedConfigs.removeAll { $0.id == config.id }

            if Self.verbose {
                os_log("\(Self.t)Deleted preset: \(config.name)")
            }

        } catch {
            errorMessage = "删除预设失败: \(error.localizedDescription)"
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
        guard let project = data.project else { return }

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
            errorMessage = "无法加载当前用户信息: \(error.localizedDescription)"
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to load user info: \(error)")
            }
        }

        isLoading = false
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
