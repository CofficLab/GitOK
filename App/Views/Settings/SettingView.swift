import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 设置视图
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

    /// 当前选中的标签页
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                // 用户信息配置 Tab
                UserInfoConfigView(
                    userName: $userName,
                    userEmail: $userEmail,
                    hasChanges: $hasChanges,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage,
                    savedConfigs: $savedConfigs,
                    selectedConfig: $selectedConfig,
                    dataProvider: data
                )
                .tabItem {
                    Label("用户信息", systemImage: "person.circle")
                }
                .tag(0)

                // Commit 风格配置 Tab
                CommitStyleConfigView(
                    commitStyle: $commitStyle,
                    globalCommitStyle: $globalCommitStyle,
                    dataProvider: data
                )
                .tabItem {
                    Label("Commit 风格", systemImage: "text.alignleft")
                }
                .tag(1)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // 底部按钮区域
            bottomButtons
        }
        .navigationTitle("Git用户配置")
        .frame(width: 600, height: 600)
        .onAppear(perform: handleOnAppear)
        .disabled(isLoading)
    }

    // MARK: - 底部按钮
    private var bottomButtons: some View {
        HStack {
            MagicButton(
                icon: .iconClose,
                title: "取消",
                preventDoubleClick: true
            ) { completion in
                dismiss()
                completion()
            }
            .magicSize(.auto)
            .frame(width: 120)

            Spacer()

            // 只在用户信息 Tab 显示"保存为预设"和"应用"按钮
            if selectedTab == 0 {
                MagicButton(
                    icon: .iconUpload,
                    title: "保存为预设",
                    preventDoubleClick: true
                ) { completion in
                    saveAsPreset()
                    completion()
                }
                .magicSize(.auto)
                .frame(width: 120)
                .disabled(isLoading || userName.isEmpty || userEmail.isEmpty)

                MagicButton(
                    icon: .iconUpload,
                    title: "应用",
                    preventDoubleClick: true
                ) { completion in
                    saveUserConfig()
                    completion()
                }
                .magicSize(.auto)
                .frame(width: 120)
                .disabled(isLoading || !hasChanges || userName.isEmpty || userEmail.isEmpty)
            }
        }
        .padding()
        .frame(height: 32)
    }
}

// MARK: - Event Handler
extension SettingView {
    private func handleOnAppear() {
        loadCurrentUserInfo()
        loadSavedConfigs()
        loadCommitStyle()
    }

    private func loadCommitStyle() {
        // 创建一个临时的 CommitStyleConfigView 来调用其方法
        let configView = CommitStyleConfigView(
            commitStyle: $commitStyle,
            globalCommitStyle: $globalCommitStyle,
            dataProvider: data
        )
        configView.loadCommitStyle()
    }
}

// MARK: - Actions
extension SettingView {
    private func saveUserConfig() {
        let configView = UserInfoConfigView(
            userName: $userName,
            userEmail: $userEmail,
            hasChanges: $hasChanges,
            isLoading: $isLoading,
            errorMessage: $errorMessage,
            savedConfigs: $savedConfigs,
            selectedConfig: $selectedConfig,
            dataProvider: data
        )

        if configView.saveUserConfig() {
            dismiss()
        }
    }

    private func saveAsPreset() {
        let configView = UserInfoConfigView(
            userName: $userName,
            userEmail: $userEmail,
            hasChanges: $hasChanges,
            isLoading: $isLoading,
            errorMessage: $errorMessage,
            savedConfigs: $savedConfigs,
            selectedConfig: $selectedConfig,
            dataProvider: data
        )
        configView.saveAsPreset()
    }
}

// MARK: - Private Helpers
extension SettingView {
    private func loadCurrentUserInfo() {
        let configView = UserInfoConfigView(
            userName: $userName,
            userEmail: $userEmail,
            hasChanges: $hasChanges,
            isLoading: $isLoading,
            errorMessage: $errorMessage,
            savedConfigs: $savedConfigs,
            selectedConfig: $selectedConfig,
            dataProvider: data
        )
        configView.loadCurrentUserInfo()
    }

    private func loadSavedConfigs() {
        let configView = UserInfoConfigView(
            userName: $userName,
            userEmail: $userEmail,
            hasChanges: $hasChanges,
            isLoading: $isLoading,
            errorMessage: $errorMessage,
            savedConfigs: $savedConfigs,
            selectedConfig: $selectedConfig,
            dataProvider: data
        )
        configView.loadSavedConfigs()
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
