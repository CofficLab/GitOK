import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 设置视图 - Tab 样式
struct SettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss

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

    /// 当前选中的配置
    @State private var selectedConfig: GitUserConfig?

    /// Commit 风格
    @State private var commitStyle: CommitStyle = .emoji

    /// 全局 Commit 风格
    @State private var globalCommitStyle: CommitStyle = .emoji

    /// 当前选中的 Tab
    @State private var selectedTab: SettingTab = .userInfo

    /// 设置 Tab 枚举
    enum SettingTab: String, CaseIterable {
        case userInfo = "用户信息"
        case commitStyle = "Commit 风格"

        var icon: String {
            switch self {
            case .userInfo: return "person.circle"
            case .commitStyle: return "text.alignleft"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 200)
        } detail: {
            // Detail 内容
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .userInfo:
                        GitUserInfoSettingView(
                            userName: $userName,
                            userEmail: $userEmail,
                            hasChanges: $hasChanges,
                            isLoading: $isLoading,
                            errorMessage: $errorMessage,
                            savedConfigs: $savedConfigs,
                            selectedConfig: $selectedConfig
                        )
                        .environmentObject(data)

                    case .commitStyle:
                        CommitStyleSettingView(
                            commitStyle: $commitStyle,
                            globalCommitStyle: $globalCommitStyle
                        )
                        .environmentObject(data)
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
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 500)
        .onAppear(perform: handleOnAppear)
        .onReceive(NotificationCenter.default.publisher(for: .didSaveGitUserConfig)) { _ in
            dismiss()
        }
        .disabled(isLoading)
    }
}

// MARK: - Event Handler

extension SettingView {
    private func handleOnAppear() {
        loadCurrentUserInfo()
        loadSavedConfigs()
        loadCommitStyle()
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
            savedConfigs = try data.repoManager.gitUserConfigRepo.getRecentConfigs(limit: 10)

            if let defaultConfig = try data.repoManager.gitUserConfigRepo.findDefault() {
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

    private func loadCommitStyle() {
        if let project = data.project {
            commitStyle = project.commitStyle
        }

        if let savedStyleRaw = UserDefaults.standard.string(forKey: "globalCommitStyle"),
           let savedStyle = CommitStyle(rawValue: savedStyleRaw) {
            globalCommitStyle = savedStyle
        }
    }
}

// MARK: - Preview

#Preview("Setting") {
    SettingView()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

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
