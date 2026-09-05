import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import ProviderToast
import SwiftUI

/// Git 用户信息设置视图（对齐旧版 `GitUserInfoSettingView`）。
///
/// 预设的存储与增删改由 `GitUserPresetProviding`（ProviderGit）管理，
/// 本视图只负责「展示预设 + 应用到当前项目 git 配置」：
/// - 「Existing Presets」：展示已保存的预设，点击可写入当前项目 git 配置；
/// - 「Add New Preset」：输入用户名 / 邮箱保存为预设（同时写入当前项目）。
public struct GitUserInfoSettingView: View {
    let projects: any ProjectProviding
    let provider: any GitUserPresetProviding
    let toast: (any ToastProviding)?
    @LumiTheme private var theme

    @State private var presets: [GitUserPreset] = []
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(
        projects: any ProjectProviding,
        provider: any GitUserPresetProviding,
        toast: (any ToastProviding)?
    ) {
        self.projects = projects
        self.provider = provider
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
        AppSettingSection(title: LumiPluginLocalization.string("Existing Presets", bundle: .module), titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(presets) { preset in
                    AppSettingRow(
                        title: preset.title,
                        description: preset.email,
                        icon: "person.crop.circle"
                    ) {
                        HStack(spacing: 8) {
                            AppButton("Apply", systemImage: "checkmark.circle", style: .secondary, size: .small) {
                                apply(preset)
                            }
                            AppIconButton(
                                systemImage: "trash",
                                tint: theme.error,
                                action: { delete(preset) }
                            )
                            .help(LumiPluginLocalization.string("Delete this preset", bundle: .module))
                        }
                    }
                    if preset != presets.last {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Add New Preset

    private var addNewPresetSection: some View {
        AppSettingSection(title: LumiPluginLocalization.string(LumiPluginLocalization.string("Add New Preset", bundle: .module), bundle: .module), titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                userInput(title: LumiPluginLocalization.string("Username", bundle: .module), placeholder: LumiPluginLocalization.string("Enter username", bundle: .module), text: $userName)
                Divider()
                userInput(title: LumiPluginLocalization.string("Email", bundle: .module), placeholder: LumiPluginLocalization.string("Enter email", bundle: .module), text: $userEmail)
                Divider()
                HStack {
                    Spacer()
                    AppButton(
                        LumiPluginLocalization.string("Add New Preset", bundle: .module),
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

        let preset = provider.addPreset(name: trimmedName, email: trimmedEmail)
        presets = provider.loadPresets()
        userName = ""
        userEmail = ""
        isSaving = false

        writeToCurrentProject(name: preset.name, email: preset.email, successTitle: LumiPluginLocalization.string("Saved User Preset", bundle: .module))
    }

    /// 应用某预设到当前项目 git 配置。
    private func apply(_ preset: GitUserPreset) {
        errorMessage = nil
        writeToCurrentProject(name: preset.name, email: preset.email, successTitle: LumiPluginLocalization.string("Applied User Info", bundle: .module))
    }

    private func delete(_ preset: GitUserPreset) {
        provider.deletePreset(id: preset.id)
        presets = provider.loadPresets()
    }

    /// 将用户名 / 邮箱写入当前项目（仓库级 git config）。
    private func writeToCurrentProject(name: String, email: String, successTitle: String) {
        guard let project = projects.currentProject else {
            toast?.show(LumiPluginLocalization.string("No Project", bundle: .module), detail: LumiPluginLocalization.string("Open a project to apply git user info.", bundle: .module), style: .info)
            return
        }
        let url = project.url
        Task.detached(priority: .userInitiated) {
            do {
                try GitConfigReader.setValue("user.name", name, in: url)
                try GitConfigReader.setValue("user.email", email, in: url)
                await MainActor.run {
                    toast?.show(successTitle, detail: String(format: LumiPluginLocalization.string("%@ <%@>", bundle: .module), name, email), style: .success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(format: LumiPluginLocalization.string("Save failed: %@", bundle: .module), error.localizedDescription)
                }
            }
        }
    }

    private func reload() {
        presets = provider.loadPresets()
    }
}
