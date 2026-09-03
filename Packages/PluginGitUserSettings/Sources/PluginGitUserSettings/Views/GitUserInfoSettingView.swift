import KitGit
import LumiUI
import ProviderProjects
import ProviderToast
import SwiftUI

/// Git 用户信息设置视图（对齐旧版 `GitUserInfoSettingView`）。
///
/// - 「Existing Presets」：展示已保存的预设，点击可写入当前项目 git 配置；
/// - 「Add New Preset」：输入用户名 / 邮箱保存为预设（同时写入当前项目）。
public struct GitUserInfoSettingView: View {
    let projects: any ProjectProviding
    let store: GitUserConfigStore
    let toast: (any ToastProviding)?
    @LumiTheme private var theme

    @State private var presets: [GitUserConfig] = []
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(
        projects: any ProjectProviding,
        store: GitUserConfigStore,
        toast: (any ToastProviding)?
    ) {
        self.projects = projects
        self.store = store
        self.toast = toast
    }

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
                if !presets.isEmpty {
                    existingPresetsSection
                }
                addNewPresetSection
                if let errorMessage {
                    AppErrorBanner(message: LocalizedStringKey(errorMessage))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { reload() }
    }

    // MARK: - Existing Presets

    private var existingPresetsSection: some View {
        AppSettingSection(title: "Existing Presets", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(presets) { config in
                    AppSettingRow(
                        title: config.name,
                        description: config.email,
                        icon: "person.crop.circle"
                    ) {
                        HStack(spacing: 8) {
                            AppButton("Apply", systemImage: "checkmark.circle", style: .secondary, size: .small) {
                                apply(config)
                            }
                            AppIconButton(
                                systemImage: "trash",
                                tint: theme.error,
                                action: { delete(config) }
                            )
                            .help("Delete this preset")
                        }
                    }
                    if config != presets.last {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Add New Preset

    private var addNewPresetSection: some View {
        AppSettingSection(title: "Add New Preset", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                userInput(title: "Username", placeholder: "Enter username", text: $userName)
                Divider()
                userInput(title: "Email", placeholder: "Enter email", text: $userEmail)
                Divider()
                HStack {
                    Spacer()
                    AppButton(
                        "Add New Preset",
                        systemImage: "plus",
                        style: .secondary,
                        size: .small
                    ) {
                        saveAsPreset()
                    }
                    .disabled(isSaving || trimmedName.isEmpty || trimmedEmail.isEmpty)
                }
            }
        }
    }

    private func userInput(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(width: 80, alignment: .leading)
            AppInputField(LocalizedStringKey(placeholder), text: text)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private var trimmedName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 保存为预设；若当前有项目，同时写入该项目 git 配置。
    private func saveAsPreset() {
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return }
        errorMessage = nil
        isSaving = true

        let config = store.addPreset(name: trimmedName, email: trimmedEmail)
        presets = store.loadPresets()
        userName = ""
        userEmail = ""
        isSaving = false

        writeToCurrentProject(name: config.name, email: config.email, successTitle: "Saved User Preset")
    }

    /// 应用某预设到当前项目 git 配置。
    private func apply(_ config: GitUserConfig) {
        errorMessage = nil
        writeToCurrentProject(name: config.name, email: config.email, successTitle: "Applied User Info")
    }

    private func delete(_ config: GitUserConfig) {
        store.deletePreset(id: config.id)
        presets = store.loadPresets()
    }

    /// 将用户名 / 邮箱写入当前项目（仓库级 git config）。
    private func writeToCurrentProject(name: String, email: String, successTitle: String) {
        guard let project = projects.currentProject else {
            toast?.show("No Project", detail: "Open a project to apply git user info.", style: .info)
            return
        }
        let url = project.url
        Task.detached(priority: .userInitiated) {
            do {
                try GitConfigReader.setValue("user.name", name, in: url)
                try GitConfigReader.setValue("user.email", email, in: url)
                await MainActor.run {
                    toast?.show(successTitle, detail: "\(name) <\(email)>", style: .success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func reload() {
        presets = store.loadPresets()
    }
}
