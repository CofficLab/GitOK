import KitGit
import LumiUI
import ProviderCoAuthor
import ProviderProjects
import ProviderToast
import SwiftUI

/// 协作者设置视图（对齐旧版 `GitUserInfoSettingView` 的布局风格）。
///
/// 预设的存储与增删改由 `CoAuthorProviding`（ProviderCoAuthor）管理，
/// 本视图只负责「展示预设 + 增删改 + 应用到当前项目」：
/// - 「Existing Co-Authors」：展示已保存的协作者，可编辑、删除、应用到当前项目；
/// - 「Add New Co-Author」：输入用户名 / 邮箱保存为协作者。
public struct CoAuthorSettingView: View {
    let projects: any ProjectProviding
    let provider: any CoAuthorProviding
    let toast: (any ToastProviding)?
    @LumiTheme private var theme

    @State private var authors: [CoAuthor] = []
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var editingAuthorId: UUID?
    @State private var editingName = ""
    @State private var editingEmail = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(
        projects: any ProjectProviding,
        provider: any CoAuthorProviding,
        toast: (any ToastProviding)?
    ) {
        self.projects = projects
        self.provider = provider
        self.toast = toast
    }

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
                if !authors.isEmpty {
                    existingAuthorsSection
                }
                addNewAuthorSection
                if let errorMessage {
                    AppErrorBanner(message: LocalizedStringKey(errorMessage))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { reload() }
    }

    // MARK: - Existing Co-Authors

    private var existingAuthorsSection: some View {
        AppSettingSection(title: CoAuthorSettingsLocalization.string("Existing Co-Authors", bundle: .module), titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(authors) { author in
                    authorRow(for: author)
                    if author != authors.last {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func authorRow(for author: CoAuthor) -> some View {
        Group {
            if editingAuthorId == author.id {
                editingRow(for: author)
            } else {
                normalRow(for: author)
            }
        }
    }

    private func normalRow(for author: CoAuthor) -> some View {
        AppSettingRow(
            title: author.name,
            description: author.email,
            icon: "person.crop.circle"
        ) {
            HStack(spacing: 8) {
                AppButton(CoAuthorSettingsLocalization.string("Apply", bundle: .module), systemImage: "checkmark.circle", style: .secondary, size: .small) {
                    apply(author)
                }
                AppIconButton(
                    systemImage: "pencil",
                    tint: .primary,
                    action: { startEditing(author) }
                )
                .help(CoAuthorSettingsLocalization.string("Edit this co-author", bundle: .module))
                AppIconButton(
                    systemImage: "trash",
                    tint: theme.error,
                    action: { delete(author) }
                )
                .help(CoAuthorSettingsLocalization.string("Delete this co-author", bundle: .module))
            }
        }
    }

    private func editingRow(for author: CoAuthor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(CoAuthorSettingsLocalization.string("Username", bundle: .module))
                    .frame(width: 80, alignment: .leading)
                AppInputField(LocalizedStringKey(CoAuthorSettingsLocalization.string("Enter username", bundle: .module)), text: $editingName)
            }
            Divider().padding(.leading, 16)
            HStack(spacing: 12) {
                Text(CoAuthorSettingsLocalization.string("Email", bundle: .module))
                    .frame(width: 80, alignment: .leading)
                AppInputField(LocalizedStringKey(CoAuthorSettingsLocalization.string("Enter email", bundle: .module)), text: $editingEmail)
            }
            HStack {
                Spacer()
                AppButton(CoAuthorSettingsLocalization.string("Cancel", bundle: .module), systemImage: "xmark", style: .secondary, size: .small) {
                    cancelEditing()
                }
                AppButton(CoAuthorSettingsLocalization.string("Save", bundle: .module), systemImage: "checkmark", style: .primary, size: .small) {
                    saveEditing(author)
                }
                .disabled(trimmedEditingName.isEmpty || trimmedEditingEmail.isEmpty)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Add New Co-Author

    private var addNewAuthorSection: some View {
        AppSettingSection(title: CoAuthorSettingsLocalization.string("Add New Co-Author", bundle: .module), titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                userInput(title: CoAuthorSettingsLocalization.string("Username", bundle: .module), placeholder: CoAuthorSettingsLocalization.string("Enter username", bundle: .module), text: $newName)
                Divider()
                userInput(title: CoAuthorSettingsLocalization.string("Email", bundle: .module), placeholder: CoAuthorSettingsLocalization.string("Enter email", bundle: .module), text: $newEmail)
                Divider()
                HStack {
                    Spacer()
                    AppButton(
                        CoAuthorSettingsLocalization.string("Add Co-Author", bundle: .module),
                        systemImage: "plus",
                        style: .secondary,
                        size: .small
                    ) {
                        saveAuthor()
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
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEditingName: String {
        editingName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEditingEmail: String {
        editingEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveAuthor() {
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return }
        errorMessage = nil
        isSaving = true

        let result = provider.addAuthor(name: trimmedName, email: trimmedEmail)
        if result == nil {
            errorMessage = CoAuthorSettingsLocalization.string("A co-author with this email already exists.", bundle: .module)
            isSaving = false
            return
        }

        authors = provider.loadAuthors()
        newName = ""
        newEmail = ""
        isSaving = false
        toast?.show(
            CoAuthorSettingsLocalization.string("Added Co-Author", bundle: .module),
            detail: "\(trimmedName) <\(trimmedEmail)>",
            style: .success
        )
    }

    private func delete(_ author: CoAuthor) {
        provider.deleteAuthor(id: author.id)
        authors = provider.loadAuthors()
        if editingAuthorId == author.id {
            cancelEditing()
        }
    }

    private func apply(_ author: CoAuthor) {
        errorMessage = nil
        writeToCurrentProject(name: author.name, email: author.email, successTitle: CoAuthorSettingsLocalization.string("Applied Co-Author", bundle: .module))
    }

    // MARK: - Editing

    private func startEditing(_ author: CoAuthor) {
        editingAuthorId = author.id
        editingName = author.name
        editingEmail = author.email
    }

    private func cancelEditing() {
        editingAuthorId = nil
        editingName = ""
        editingEmail = ""
    }

    private func saveEditing(_ author: CoAuthor) {
        guard !trimmedEditingName.isEmpty, !trimmedEditingEmail.isEmpty else { return }
        errorMessage = nil

        var updated = author
        updated.name = trimmedEditingName
        updated.email = trimmedEditingEmail
        provider.updateAuthor(updated)

        authors = provider.loadAuthors()
        cancelEditing()
        toast?.show(
            CoAuthorSettingsLocalization.string("Updated Co-Author", bundle: .module),
            detail: "\(trimmedEditingName) <\(trimmedEditingEmail)>",
            style: .success
        )
    }

    /// 将用户名 / 邮箱写入当前项目（仓库级 git config）。
    private func writeToCurrentProject(name: String, email: String, successTitle: String) {
        guard let project = projects.currentProject else {
            toast?.show(CoAuthorSettingsLocalization.string("No Project", bundle: .module), detail: CoAuthorSettingsLocalization.string("Open a project to apply git user info.", bundle: .module), style: .info)
            return
        }
        let url = project.url
        Task.detached(priority: .userInitiated) {
            do {
                try GitConfigReader.setValue("user.name", name, in: url)
                try GitConfigReader.setValue("user.email", email, in: url)
                await MainActor.run {
                    projects.notifyDataChanged()
                    toast?.show(successTitle, detail: String(format: CoAuthorSettingsLocalization.string("%@ <%@>", bundle: .module), name, email), style: .success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(format: CoAuthorSettingsLocalization.string("Save failed: %@", bundle: .module), error.localizedDescription)
                }
            }
        }
    }

    private func reload() {
        authors = provider.loadAuthors()
    }
}
