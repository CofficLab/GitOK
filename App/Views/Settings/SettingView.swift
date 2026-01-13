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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Git 用户信息设置
                MagicSettingSection(title: "Git 用户信息", titleAlignment: .leading) {
                    VStack(spacing: 0) {
                        // 预设配置列表
                        if !savedConfigs.isEmpty {
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

                            Divider()
                        }

                        // 用户名输入
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

                        Divider()

                        // 邮箱输入
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
                }

                // Commit 风格设置
                MagicSettingSection(title: "Commit 风格", titleAlignment: .leading) {
                    VStack(spacing: 0) {
                        MagicSettingPicker(
                            title: "当前项目风格",
                            description: "此项目的 Commit 消息显示风格",
                            icon: .iconTextAlignLeft,
                            options: CommitStyle.allCases.map { $0.displayName },
                            selection: Binding(
                                get: { commitStyle.displayName },
                                set: { newStyle in
                                    if let style = CommitStyle.allCases.first(where: { $0.displayName == newStyle }) {
                                        commitStyle = style
                                        // 保存到项目
                                        if let project = data.project {
                                            project.commitStyle = style
                                        }
                                    }
                                }
                            )
                        ) { $0 }

                        Divider()

                        MagicSettingPicker(
                            title: "全局默认风格",
                            description: "新项目的默认 Commit 消息显示风格",
                            icon: .iconGearShape,
                            options: CommitStyle.allCases.map { $0.displayName },
                            selection: Binding(
                                get: { globalCommitStyle.displayName },
                                set: { newStyle in
                                    if let style = CommitStyle.allCases.first(where: { $0.displayName == newStyle }) {
                                        globalCommitStyle = style
                                        // 保存全局设置
                                        UserDefaults.standard.set(style.rawValue, forKey: "globalCommitStyle")
                                    }
                                }
                            )
                        ) { $0 }
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

                // 底部按钮区域
                HStack(spacing: 12) {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

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
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Git 用户配置")
        .frame(width: 600, height: 600)
        .onAppear(perform: handleOnAppear)
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
