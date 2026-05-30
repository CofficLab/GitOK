import ProjectSupportKit
import SwiftUI

struct AutoPushConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.gitOKProjectPath) private var projectPath
    @Environment(\.gitOKProjectTitle) private var projectTitle
    @Environment(\.gitOKBranchName) private var branchName
    @Environment(\.gitOKIsGitRepository) private var isGitRepository

    @ObservedObject private var settingsStore = AutoPushSettingsStore.shared
    @State private var currentProjectAutoPushEnabled = false
    @State private var isLoading = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            AutoPushConfigHeaderView(isLoading: isLoading, onClose: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let currentProject {
                        CurrentProjectSectionView(
                            project: currentProject,
                            isEnabled: $currentProjectAutoPushEnabled,
                            onToggle: { enabled in handleToggle(project: currentProject, enabled: enabled) }
                        )
                    }

                    ConfiguredProjectsSectionView(
                        settingsStore: settingsStore,
                        isCurrentProject: isCurrentProject,
                        onToggle: handleToggleConfig,
                        onDelete: handleDeleteConfig
                    )
                }
                .padding()
            }

            AutoPushStatusBarView(message: statusMessage)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear(perform: updateCurrentProjectStatus)
        .onChange(of: projectPath) { updateCurrentProjectStatus() }
        .onChange(of: branchName) { updateCurrentProjectStatus() }
    }

    private var currentProject: AutoPushProjectSnapshot? {
        guard let projectPath, let projectTitle else { return nil }
        return AutoPushProjectSnapshot(
            projectPath: projectPath,
            projectTitle: projectTitle,
            branchName: branchName,
            isGitRepository: isGitRepository
        )
    }

    private func updateCurrentProjectStatus() {
        guard let projectPath, let branchName else {
            currentProjectAutoPushEnabled = false
            return
        }

        currentProjectAutoPushEnabled = settingsStore.isAutoPushEnabled(for: projectPath, branchName: branchName)
    }

    private func handleToggle(project: AutoPushProjectSnapshot, enabled: Bool) {
        guard let branchName = project.branchName else { return }

        settingsStore.setAutoPushEnabled(
            for: project.projectPath,
            branchName: branchName,
            enabled: enabled
        )

        if enabled {
            performPush(projectPath: project.projectPath, branchName: branchName)
        }

        showStatusMessage(String(format: PluginAutoPushLocalization.string("Auto-push %@: %@/%@"), enabled ? "enabled" : "disabled", project.projectTitle, branchName))
    }

    private func handleToggleConfig(_ config: ProjectBranchAutoPushConfig) {
        let newStatus = !config.isEnabled
        settingsStore.setAutoPushEnabled(for: config.projectPath, branchName: config.branchName, enabled: newStatus)

        if isCurrentProject(config) {
            currentProjectAutoPushEnabled = newStatus
            if newStatus {
                performPush(projectPath: config.projectPath, branchName: config.branchName)
            }
        }

        showStatusMessage(String(format: PluginAutoPushLocalization.string("Auto-push %@: %@/%@"), newStatus ? "enabled" : "disabled", config.projectTitle, config.branchName))
    }

    private func handleDeleteConfig(_ config: ProjectBranchAutoPushConfig) {
        settingsStore.removeConfig(for: config.projectPath, branchName: config.branchName)

        if isCurrentProject(config) {
            currentProjectAutoPushEnabled = false
        }

        showStatusMessage(String(format: PluginAutoPushLocalization.string("Configuration deleted: %@/%@"), config.projectTitle, config.branchName))
    }

    private func isCurrentProject(_ config: ProjectBranchAutoPushConfig) -> Bool {
        config.projectPath == projectPath && config.branchName == branchName
    }

    private func showStatusMessage(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                statusMessage = nil
            }
        }
    }

    private func performPush(projectPath: String, branchName: String) {
        isLoading = true
        statusMessage = PluginAutoPushLocalization.string("Pushing...")

        Task {
            await AutoPushService.shared.performPush(projectPath: projectPath, branchName: branchName)
            isLoading = false

            switch AutoPushService.shared.lastPushStatus {
            case .success:
                statusMessage = PluginAutoPushLocalization.string("Push succeeded")
            case let .failed(message):
                statusMessage = String(format: PluginAutoPushLocalization.string("Push failed: %@"), message)
            case .idle, .pushing:
                statusMessage = nil
            }
        }
    }
}
