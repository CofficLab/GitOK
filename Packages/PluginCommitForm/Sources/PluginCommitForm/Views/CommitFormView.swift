import KitGit
import LumiUI
import ProviderCommitForm
import ProviderProjects
import SwiftUI

/// 本地化 helper：按当前系统语言从本插件 catalog 取文案（默认英语）。
private func loc(_ key: String) -> String {
    CommitFormLocalization.string(key, bundle: .module)
}

/// 提交表单视图（对齐旧版 CommitFormLayout）。
///
/// 显示在详情区顶部：第一行「提交风格 + 提交类别 + 消息输入」，
/// 第二行「当前 git 用户 + 共同作者 + 提交 / 提交并推送」。
///
/// 表单状态与提交动作的权威源是 `CommitFormProviding`；本视图只是 UI 呈现，
/// 编辑即时写回 Provider，提交后由 Provider 重置 subject。
public struct CommitFormView: View {
    let projects: any ProjectProviding
    let form: any CommitFormProviding
    @LumiTheme private var theme
    @StateObject private var formObservation: CommitFormObservationModel

    @State private var subject: String = ""
    @State private var category: CommitCategory = .Chore
    @State private var style: CommitStyle = CommitStyleStore.current
    @State private var coAuthors: [CoAuthor] = []
    @State private var user: (name: String?, email: String?)?
    @State private var showCoAuthorSheet = false

    public init(projects: any ProjectProviding, form: any CommitFormProviding) {
        self.projects = projects
        self.form = form
        _formObservation = StateObject(wrappedValue: CommitFormObservationModel(form: form))
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                firstRow
                secondRow
                if let error = form.lastErrorMessage, !error.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text(error)
                            .font(DesignTokens.Typography.caption2)
                            .lineLimit(2)
                    }
                    .foregroundStyle(theme.error)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background {
            theme.surface
        }
        .onReceive(formObservation.$revision) { _ in syncFromForm() }
        .onAppear {
            syncFromForm()
            loadUserIfNeeded()
        }
        .onChange(of: projects.currentProject?.url) { _, _ in
            syncFromForm()
            loadUserIfNeeded()
        }
        .sheet(isPresented: $showCoAuthorSheet) {
            CoAuthorEditorSheet(selected: $coAuthors) { updated in
                coAuthors = updated
                form.setCoAuthors(updated)
            }
        }
    }

    // MARK: - Rows

    /// 第一行：风格 + 类别 + 消息输入。
    private var firstRow: some View {
        HStack(spacing: 8) {
            Picker("", selection: Binding(
                get: { style },
                set: { form.setStyle($0) }
            )) {
                ForEach(CommitStyle.allCases, id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .frame(width: 118)
            .labelsHidden()

            Picker("", selection: Binding(
                get: { category },
                set: { form.setCategory($0) }
            )) {
                ForEach(CommitCategory.allCases, id: \.self) { c in
                    Text(displayLabel(for: c)).tag(c)
                }
            }
            .frame(width: 150)
            .labelsHidden()

            Spacer(minLength: 8)

            AppInputField(LocalizedStringKey(loc("commit")), text: Binding(
                get: { subject },
                set: {
                    subject = $0
                    form.setSubject($0)
                }
            ))
            .frame(maxWidth: .infinity)
        }
    }

    /// 第二行：用户 + 共同作者 + 提交按钮。
    private var secondRow: some View {
        HStack(spacing: 8) {
            userBadge
            Spacer(minLength: 8)

            coAuthorButton

            if form.isSubmitting {
                ProgressView()
                    .controlSize(.small)
            } else {
                AppButton(loc("Commit"), systemImage: "checkmark.circle", style: .secondary, size: .small, action: {
                    submit(commitOnly: true)
                })
                .disabled(!canSubmit)

                AppButton(loc("Commit & Push"), systemImage: "arrow.up.circle", style: .primary, size: .small, action: {
                    submit(commitOnly: false)
                })
                .disabled(!canSubmit)
            }
        }
    }

    /// 当前 git 用户徽标（未配置时提示去设置）。
    @ViewBuilder
    private var userBadge: some View {
        if let user, let name = user.name, !name.isEmpty {
            HStack(spacing: 5) {
                Image(systemName: "person.crop.circle")
                    .font(DesignTokens.Typography.caption2)
                Text(user.email?.isEmpty == false ? "\(name) <\(user.email!)>" : name)
                    .font(DesignTokens.Typography.caption2)
            }
            .foregroundStyle(theme.textSecondary)
            .lineLimit(1)
        } else {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 10))
                Text(loc("Git user not configured"))
                    .font(DesignTokens.Typography.caption2)
            }
            .foregroundStyle(theme.error)
        }
    }

    /// 共同作者选择按钮（Menu 多选 + 添加入口）。
    private var coAuthorButton: some View {
        Menu {
            ForEach(CoAuthorStore.shared.loadCoAuthors()) { author in
                Button {
                    toggle(author)
                } label: {
                    if coAuthors.contains(where: { $0.id == author.id }) {
                        Label(author.displayText, systemImage: "checkmark")
                    } else {
                        Text(author.displayText)
                    }
                }
            }
            AppDivider()
            Button {
                showCoAuthorSheet = true
            } label: {
                Label(loc("Add Co-author"), systemImage: "plus.circle")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                if !coAuthors.isEmpty {
                    Text("\(coAuthors.count)")
                        .font(DesignTokens.Typography.caption2.weight(.semibold))
                }
            }
            .font(DesignTokens.Typography.caption1)
            .foregroundStyle(coAuthors.isEmpty ? theme.textTertiary : theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.08))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Actions

    private var canSubmit: Bool {
        projects.currentProject != nil && !form.isSubmitting
    }

    private func submit(commitOnly: Bool) {
        guard let project = projects.currentProject else { return }
        Task {
            do {
                try await form.submit(commitOnly: commitOnly, in: project.url)
            } catch {
                // 错误已写入 form.lastErrorMessage，由视图展示。
            }
        }
    }

    private func toggle(_ author: CoAuthor) {
        var updated = coAuthors
        if let index = updated.firstIndex(where: { $0.id == author.id }) {
            updated.remove(at: index)
        } else {
            updated.append(author)
        }
        coAuthors = updated
        form.setCoAuthors(updated)
    }

    private func displayLabel(for category: CommitCategory) -> String {
        if style.includeEmoji {
            return category.label
        } else if style.isLowercase {
            return category.title.lowercased()
        } else {
            return category.title
        }
    }

    // MARK: - Sync

    /// 从 Provider 同步本地状态（提交后 Provider 重置 subject 时也会触发）。
    private func syncFromForm() {
        subject = form.subject
        category = form.category
        style = form.style
        coAuthors = form.coAuthors
    }

    private func loadUserIfNeeded() {
        guard let project = projects.currentProject else {
            user = nil
            return
        }
        Task.detached(priority: .utility) {
            let loaded = GitConfigReader.user(in: project.url)
            await MainActor.run {
                user = loaded
            }
        }
    }
}

/// 共同作者编辑 sheet：列出已存作者，勾选 / 新增。
private struct CoAuthorEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: [CoAuthor]
    let onCommit: ([CoAuthor]) -> Void

    @State private var newName = ""
    @State private var newEmail = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("Co-authors"))
                .font(.headline)

            let all = CoAuthorStore.shared.loadCoAuthors()
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(all) { author in
                        Button {
                            if selected.contains(where: { $0.id == author.id }) {
                                selected.removeAll { $0.id == author.id }
                            } else {
                                selected.append(author)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(where: { $0.id == author.id })
                                    ? "checkmark.square.fill"
                                    : "square")
                                Text(author.displayText)
                                Spacer()
                            }
                            .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(minHeight: 100, maxHeight: 200)

            AppDivider()

            HStack(spacing: 8) {
                TextField(loc("Name"), text: $newName)
                TextField(loc("Email"), text: $newEmail)
                Button(loc("Add")) {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return }
                    let author = CoAuthor(name: trimmedName, email: trimmedEmail)
                    CoAuthorStore.shared.addCoAuthor(author)
                    selected.append(author)
                    newName = ""
                    newEmail = ""
                }
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack {
                Spacer()
                Button(loc("Cancel")) { dismiss() }
                Button(loc("Done")) {
                    onCommit(selected)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 420)
    }
}

/// 提交表单观察模型：订阅 `CommitFormProviding` 事件，
/// 转成 `@Published revision` 驱动 SwiftUI 重算（同步 Provider 权威状态）。
@MainActor
final class CommitFormObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CommitFormObserverHandle)?

    init(form: any CommitFormProviding) {
        handle = form.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
