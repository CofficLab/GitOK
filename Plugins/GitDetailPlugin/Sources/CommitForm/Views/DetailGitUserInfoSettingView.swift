import GitOKAppCore
import GitOKSupportKit
import GitOKUI
import OSLog
import SwiftUI

private enum DetailGitUserInfoBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

struct DetailGitUserInfoSettingView: View, SuperLog {
    nonisolated static let emoji = "👤"
    nonisolated static let verbose = false

    @EnvironmentObject private var data: DataVM
    @EnvironmentObject private var vm: ProjectVM

    @State private var userName = ""
    @State private var userEmail = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasChanges = false
    @State private var savedConfigs: [GitUserConfig] = []

    private var configRepo: any GitUserConfigRepoProtocol {
        data.repoManager.gitUserConfigRepo
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !savedConfigs.isEmpty {
                    GitOKUI.AppSettingsSection(title: GitDetailPluginLocalization.string("Existing Presets")) {
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

                addNewPresetSection

                if let errorMessage {
                    AppErrorBanner(message: errorMessage)
                }
            }
            .padding()
        }
        .navigationTitle(Text(GitDetailPluginLocalization.string("User Info")))
        .onAppear(perform: loadData)
    }

    private func presetConfigRow(_ config: GitUserConfig) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: "person")
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.system(size: 13, weight: .medium))

                    Text(config.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                AppIconButton(systemImage: "trash", tint: DesignTokens.Color.semantic.error) {
                    deletePreset(config)
                }
                .help(Text(GitDetailPluginLocalization.string("Delete this preset")))
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                deletePreset(config)
            } label: {
                Label(
                    title: { Text(GitDetailPluginLocalization.string("Delete Preset")) },
                    icon: { Image(systemName: .iconTrash) }
                )
            }
        }
    }

    private var addNewPresetSection: some View {
        GitOKUI.AppSettingsSection(title: GitDetailPluginLocalization.string("Add New Preset")) {
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
            Text(GitDetailPluginLocalization.string("Username"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            AppInputField(GitDetailPluginLocalization.string("Enter username"), text: $userName)
                .onChange(of: userName) {
                    hasChanges = true
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var userEmailInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(GitDetailPluginLocalization.string("Email"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            AppInputField(GitDetailPluginLocalization.string("Enter email"), text: $userEmail)
                .onChange(of: userEmail) {
                    hasChanges = true
                }
                .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var saveButtonsView: some View {
        AppButton(
            GitDetailPluginLocalization.string("Add New Preset"),
            systemImage: "plus",
            style: .secondary,
            size: .small,
            isLoading: isLoading
        ) {
            saveAsPreset()
            userName = ""
            userEmail = ""
            hasChanges = false
        }
        .disabled(isLoading || userName.isEmpty || userEmail.isEmpty)
        .padding(.horizontal)
        .padding(.vertical, 10)
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
        } catch {
            errorMessage = String(
                format: GitDetailPluginLocalization.string("Failed to save preset: %@"),
                error.localizedDescription
            )
        }
    }

    private func deletePreset(_ config: GitUserConfig) {
        do {
            try configRepo.delete(config)
            savedConfigs.removeAll { $0.id == config.id }
        } catch {
            errorMessage = String(
                format: GitDetailPluginLocalization.string("Failed to delete preset: %@"),
                error.localizedDescription
            )
        }
    }

    private func loadData() {
        do {
            savedConfigs = try configRepo.getRecentConfigs(limit: 10)
        } catch {
            if Self.verbose {
                os_log(.error, "\(Self.t)Failed to load saved configs: \(error)")
            }
        }
    }
}
