import GitOKAppCore
import GitOKSupportKit
import GitOKUI
import OSLog
import SwiftUI

private enum DetailGitUserPresetBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

struct DetailGitUserPresetView: View, SuperLog {
    nonisolated static let emoji = "👤"
    nonisolated static let verbose = false

    @EnvironmentObject private var data: DataVM
    @EnvironmentObject private var vm: ProjectVM

    @State private var savedConfigs: [GitUserConfig] = []
    @State private var currentUserName = ""
    @State private var currentUserEmail = ""
    @State private var isApplying = false
    @State private var showManagePresets = false

    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    var body: some View {
        AppSettingSection(title: "Git 用户预设", titleAlignment: .leading) {
            VStack(spacing: 0) {
                if !savedConfigs.isEmpty {
                    presetConfigsView
                    Divider()
                        .padding(.vertical, 8)
                } else {
                    emptyStateView
                    Divider()
                        .padding(.vertical, 8)
                }
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

    private var emptyStateView: some View {
        AppSettingRow(
            title: "暂无预设",
            description: "点击下方按钮添加用户预设",
            icon: .iconUser
        ) {
            EmptyView()
        }
    }

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
        .id("\(config.persistentModelID)_\(isSelected)")
    }

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

    private func applyConfig(_ config: GitUserConfig) {
        guard let loadedProject = vm.project else { return }

        let configName = config.name
        let configEmail = config.email

        if currentUserName == configName && currentUserEmail == configEmail {
            return
        }

        isApplying = true
        let projectTransfer = DetailGitUserPresetBackgroundRunner.UnsafeTransfer(value: loadedProject)

        Task.detached(priority: .userInitiated) {
            do {
                try await projectTransfer.value.setUserConfigAsync(name: configName, email: configEmail)

                await MainActor.run {
                    currentUserName = configName
                    currentUserEmail = configEmail
                    isApplying = false
                    NotificationCenter.default.post(name: .didUpdateGitUserConfig, object: nil)
                }
            } catch {
                await MainActor.run {
                    isApplying = false
                }
            }
        }
    }

    private func loadData() {
        loadSavedConfigs()
        loadCurrentUserInfo()
    }

    private func loadSavedConfigs() {
        do {
            savedConfigs = try configRepo.getRecentConfigs(limit: 10)
        } catch {
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to load saved configs: \(error)")
            }
        }
    }

    private func loadCurrentUserInfo() {
        guard let loadedProject = vm.project else { return }
        let projectTransfer = DetailGitUserPresetBackgroundRunner.UnsafeTransfer(value: loadedProject)

        Task.detached(priority: .utility) {
            do {
                let loadedName = try await projectTransfer.value.getUserNameAsync()
                let loadedEmail = try await projectTransfer.value.getUserEmailAsync()

                await MainActor.run {
                    currentUserName = loadedName
                    currentUserEmail = loadedEmail
                    if !loadedName.isEmpty && !loadedEmail.isEmpty {
                        addCurrentUserToPresetsIfNeeded()
                    }
                }
            } catch {
                await MainActor.run {
                    currentUserName = ""
                    currentUserEmail = ""
                }
            }
        }
    }

    private func addCurrentUserToPresetsIfNeeded() {
        let alreadyExists = savedConfigs.contains { config in
            config.name == currentUserName && config.email == currentUserEmail
        }

        guard !alreadyExists else { return }

        do {
            let config = try configRepo.create(
                name: currentUserName,
                email: currentUserEmail,
                isDefault: savedConfigs.isEmpty
            )
            savedConfigs.append(config)
        } catch {
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to add current user to presets: \(error)")
            }
        }
    }
}
