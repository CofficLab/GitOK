
import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 用户信息显示视图
struct UserView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider

    /// 文本输入
    @State var text: String = ""

    /// 当前选择的提交类别
    @State var category: CommitCategory = .Chore

    /// 当前用户名
    @State var currentUser: String = ""

    /// 当前用户邮箱
    @State var currentEmail: String = ""

    /// 是否显示用户配置表单
    @State var showUserConfig = false

    /// 已保存的配置列表
    @State private var savedConfigs: [GitUserConfig] = []

    /// 配置仓库
    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    var body: some View {
        Menu {
            // 预设配置列表
            if !savedConfigs.isEmpty {
                ForEach(savedConfigs, id: \.persistentModelID) { config in
                    Button(action: {
                        applyConfig(config)
                    }) {
                        HStack {
                            Text("\(config.name) (\(config.email))")

                            if currentUser == config.name && currentEmail == config.email {
                                Spacer()
                                Image(systemName: .iconCheckmark)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                Divider()
            }

            // 管理预设按钮
            Button(action: {
                showUserConfig = true
            }) {
                Text("管理预设...")
            }
        } label: {
            // 当前用户信息显示
            if !currentUser.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: .iconUser)
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser)
                            .font(.caption)
                            .fontWeight(.medium)
                        if !currentEmail.isEmpty {
                            Text(currentEmail)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Image(systemName: .iconChevronDown)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .menuStyle(.borderlessButton)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))

                    Text("未配置用户信息")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Image(systemName: .iconChevronDown)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                .menuStyle(.borderlessButton)
            }
        }
        .menuStyle(.borderlessButton)
        .sheet(isPresented: $showUserConfig) {
            SettingView()
                .environmentObject(data)
                .onDisappear {
                    loadUserInfo()
                    loadSavedConfigs()
                }
        }
        .onAppear(perform: onAppear)
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateGitUserConfig)) { _ in
            loadUserInfo()
        }
    }
}

// MARK: - Action

extension UserView {
    private func loadUserInfo() {
        do {
            let userName = try data.project?.getUserName()
            let userEmail = try data.project?.getUserEmail()

            self.currentUser = userName ?? ""
            self.currentEmail = userEmail ?? ""
        } catch {
            // 如果获取用户信息失败，保持空字符串
            self.currentUser = ""
            self.currentEmail = ""
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

    private func applyConfig(_ config: GitUserConfig) {
        guard let project = data.project else { return }

        // 如果已经是当前配置，不需要重新应用
        if currentUser == config.name && currentEmail == config.email {
            return
        }

        Task.detached(priority: .userInitiated) {
            let configName = config.name
            let configEmail = config.email

            do {
                try project.setUserConfig(
                    name: configName,
                    email: configEmail
                )

                await MainActor.run {
                    // 更新 UI 状态
                    self.currentUser = configName
                    self.currentEmail = configEmail

                    // 发送通知，让其他视图更新
                    NotificationCenter.default.post(name: .didUpdateGitUserConfig, object: nil)

                    if Self.verbose {
                        os_log("\(Self.t)✅ Applied config: \(configName) <\(configEmail)>")
                    }
                }
            } catch {
                if Self.verbose {
                    os_log(.error, "\(Self.t)❌ Failed to apply config: \(error)")
                }
            }
        }
    }
}

// MARK: - Event

extension UserView {
    private func onAppear() {
        loadUserInfo()
        loadSavedConfigs()
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
