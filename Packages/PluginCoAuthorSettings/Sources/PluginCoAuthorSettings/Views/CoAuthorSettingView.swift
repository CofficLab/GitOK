import LumiUI
import ProviderCoAuthor
import ProviderToast
import SwiftUI

/// 协作者设置视图（对齐旧版 `GitUserInfoSettingView` 的布局风格）。
///
/// 预设的存储与增删改由 `CoAuthorProviding`（ProviderCoAuthor）管理，
/// 本视图只负责「展示预设 + 增删改」：
/// - 「Existing Co-Authors」：展示已保存的协作者，可删除；
/// - 「Add New Co-Author」：输入用户名 / 邮箱保存为协作者。
public struct CoAuthorSettingView: View {
    let provider: any CoAuthorProviding
    let toast: (any ToastProviding)?
    @LumiTheme private var theme

    @State private var authors: [CoAuthor] = []
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var errorMessage: String?

    public init(
        provider: any CoAuthorProviding,
        toast: (any ToastProviding)? = nil
    ) {
        self.provider = provider
        self.toast = toast
    }

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
                existingAuthorsSection
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
                if authors.isEmpty {
                    AppSettingRow(
                        title: CoAuthorSettingsLocalization.string("No Co-Authors", bundle: .module),
                        description: CoAuthorSettingsLocalization.string("Add a co-author below.", bundle: .module),
                        icon: "person.2"
                    ) {
                        EmptyView()
                    }
                } else {
                    ForEach(authors) { author in
                        AppSettingRow(
                            title: author.name,
                            description: author.email,
                            icon: "person.crop.circle"
                        ) {
                            AppIconButton(
                                systemImage: "trash",
                                tint: theme.error,
                                action: { delete(author) }
                            )
                            .help(CoAuthorSettingsLocalization.string("Delete this co-author", bundle: .module))
                        }
                        if author != authors.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
            }
        }
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
                    .disabled(trimmedName.isEmpty || trimmedEmail.isEmpty)
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

    private func saveAuthor() {
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return }
        errorMessage = nil

        let result = provider.addAuthor(name: trimmedName, email: trimmedEmail)
        if result == nil {
            errorMessage = CoAuthorSettingsLocalization.string("A co-author with this email already exists.", bundle: .module)
            return
        }

        authors = provider.loadAuthors()
        newName = ""
        newEmail = ""
        toast?.show(
            CoAuthorSettingsLocalization.string("Added Co-Author", bundle: .module),
            detail: "\(trimmedName) <\(trimmedEmail)>",
            style: .success
        )
    }

    private func delete(_ author: CoAuthor) {
        provider.deleteAuthor(id: author.id)
        authors = provider.loadAuthors()
    }

    private func reload() {
        authors = provider.loadAuthors()
    }
}
