import GitOKAppCore
import Foundation
import GitOKCoreKit
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

private enum GitUserPresetBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

/// Git 用户预设管理视图组件
public struct GitUserPresetView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 已保存的配置列表
    @State private var savedConfigs: [GitUserConfig] = []

    /// 当前项目实际使用的用户名
    @State private var currentUserName: String = ""

    /// 当前项目实际使用的用户邮箱
    @State private var currentUserEmail: String = ""

    /// 是否正在应用配置
    @State private var isApplying = false

    /// 是否显示管理预设表单
    @State private var showManagePresets = false

    /// 配置仓库
    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    public var body: some View {
        AppSettingSection(title: "Git 用户预设", titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 预设配置列表
                if !savedConfigs.isEmpty {
                    presetConfigsView

                    Divider()
                        .padding(.vertical, 8)
                } else {
                    // 空状态提示
                    emptyStateView

                    Divider()
                        .padding(.vertical, 8)
                }

                // 管理预设按钮
                managePresetsButton
            }
        }
        .onAppear(perform: loadData)
        .onChange(of: showManagePresets) { _, isPresented in
            if isPresented {
                NotificationCenter.default.post(name: .openSettings, object: nil)
                showManagePresets = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSaveGitUserConfig)) { _ in
            loadData()
        }
    }

    // MARK: - View Components

    /// 空状态视图
    private var emptyStateView: some View {
        AppSettingRow(
            title: "暂无预设",
            description: "点击下方按钮添加用户预设",
            icon: .iconUser
        ) {
            EmptyView()
        }
    }

    /// 预设配置列表视图
    private var presetConfigsView: some View {
        VStack(spacing: 0) {
            ForEach(savedConfigs, id: \.persistentModelID) { config in
                presetConfigRow(config)
                if config.persistentModelID != savedConfigs.last?.persistentModelID {
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
    }

    /// 单个预设配置行
    private func presetConfigRow(_ config: GitUserConfig) -> some View {
        let isSelected = currentUserName == config.name && currentUserEmail == config.email

        return AppSettingRow(
            title: config.name,
            description: config.email,
            icon: .iconUser,
            action: { applyConfig(config) }
        ) {
            Group {
                if isApplying && !isSelected {
                    AppLoadingOverlay(size: .small)
                } else if isSelected {
                    Image(systemName: .iconCheckmark)
                        .foregroundColor(.accentColor)
                } else {
                    EmptyView()
                }
            }
        }
        .contentShape(Rectangle())
        .id("\(config.persistentModelID)_\(isSelected)") // 强制在选中状态变化时刷新
    }

    /// 管理预设按钮
    private var managePresetsButton: some View {
        AppSettingRow(
            title: "管理预设",
            description: "添加、编辑或删除用户预设",
            icon: .iconSettings
        ) {
            AppIconButton(systemImage: "gearshape", size: .regular) {
                showManagePresets = true
            }
        }
    }

    // MARK: - Actions

    /// 应用配置到当前项目
    private func applyConfig(_ config: GitUserConfig) {
        if Self.verbose {
            os_log("\(Self.t)Applying config: \(config.name) <\(config.email)>")
        }

        guard let loadedProject = vm.project else { return }
        let projectTransfer = GitUserPresetBackgroundRunner.UnsafeTransfer(value: loadedProject)
        let configName = config.name
        let configEmail = config.email

        // 如果已经是当前配置，不需要重新应用
        if currentUserName == configName && currentUserEmail == configEmail {
            return
        }

        isApplying = true

        Task.detached(priority: .userInitiated) {
            do {
                try await projectTransfer.value.setUserConfigAsync(name: configName, email: configEmail)

                Task { @MainActor in
                    currentUserName = configName
                    currentUserEmail = configEmail
                    isApplying = false

                    if Self.verbose {
                        os_log("\(Self.t)✅ Applied config: \(configName) <\(configEmail)>")
                    }

                    // 发送通知，让其他视图更新
                    NotificationCenter.default.post(name: .didUpdateGitUserConfig, object: nil)
                }
            } catch {
                let message = error.localizedDescription

                Task { @MainActor in
                    isApplying = false
                    if Self.verbose {
                        os_log(.error, "\(Self.t)❌ Failed to apply config: \(message)")
                    }
                }
            }
        }
    }

    // MARK: - Load Data

    private func loadData() {
        loadSavedConfigs()
        loadCurrentUserInfo()
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

    private func loadCurrentUserInfo() {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = GitUserPresetBackgroundRunner.UnsafeTransfer(value: loadedProject)

        Task.detached(priority: .utility) {
            do {
                let loadedName = try await projectTransfer.value.getUserNameAsync()
                let loadedEmail = try await projectTransfer.value.getUserEmailAsync()

                Task { @MainActor in
                    currentUserName = loadedName
                    currentUserEmail = loadedEmail

                    if Self.verbose {
                        os_log("\(Self.t)Current user info: \(loadedName) <\(loadedEmail)>")
                    }

                    // 如果当前用户信息不为空，且不在预设列表中，自动添加
                    if !loadedName.isEmpty && !loadedEmail.isEmpty {
                        addCurrentUserToPresetsIfNeeded()
                    }
                }
            } catch {
                let message = error.localizedDescription

                Task { @MainActor in
                    currentUserName = ""
                    currentUserEmail = ""

                    if Self.verbose {
                        os_log(.error, "\(Self.t)Failed to load user info: \(message)")
                    }
                }
            }
        }
    }

    /// 如果当前用户信息不在预设列表中，自动添加
    private func addCurrentUserToPresetsIfNeeded() {
        // 检查是否已存在
        let alreadyExists = savedConfigs.contains { config in
            config.name == currentUserName && config.email == currentUserEmail
        }

        // 如果不存在，创建并添加到预设
        if !alreadyExists {
            do {
                let config = try configRepo.create(
                    name: currentUserName,
                    email: currentUserEmail,
                    isDefault: savedConfigs.isEmpty // 如果是第一个配置，设为默认
                )

                savedConfigs.append(config)

                if Self.verbose {
                    os_log("\(Self.t)✅ Auto-added current user to presets: \(currentUserName) <\(currentUserEmail)>")
                }
            } catch {
                if Self.verbose {
                    os_log(.error, "\(Self.t)❌ Failed to add current user to presets: \(error)")
                }
            }
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// 当 Git 用户配置更新时调用的便捷方法
    /// - Parameter perform: 更新时执行的操作
    /// - Returns: 修改后的视图
    func onGitUserConfigUpdated(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .didUpdateGitUserConfig)) { _ in
            action()
        }
    }
}

// MARK: - Preview

