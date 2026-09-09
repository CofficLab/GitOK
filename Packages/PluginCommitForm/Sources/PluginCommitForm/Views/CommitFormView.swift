import KitGit
import LumiUI
import ProviderContentView
import ProviderCommitForm
import ProviderGit
import ProviderGitRepositoryWatch
import ProviderGitUser
import ProviderProjects
import SwiftUI

/// 本地化 helper：按当前系统语言从本插件 catalog 取文案（默认英语）。
private func loc(_ key: String) -> String {
    CommitFormLocalization.string(key, bundle: .module)
}

private extension GitRemoteOperation.SyncStep {
    var localizationKey: String {
        switch self {
        case .fetch: "Fetch failed"
        case .merge: "Merge failed"
        case .push: "Push failed"
        }
    }
}

/// 提交表单视图（对齐旧版 CommitFormLayout）。
///
/// 显示在详情区顶部：第一行「提交风格 + 提交类别 + 当前 git 用户 + 共同作者」，
/// 最后一行「消息输入 + 提交 / 提交并推送」。
///
/// 表单状态与提交动作的权威源是 `CommitFormProviding`；本视图只是 UI 呈现，
/// 编辑即时写回 Provider，提交后由 Provider 重置 subject。
public struct CommitFormView: View {
    let projects: any ProjectProviding
    let form: any CommitFormProviding
    let git: any GitProviding
    let errorCenter: CommitFormErrorCenter?
    /// 仓库监听（可选）：订阅 `.git` 目录变化（HEAD / index / stash / refs /
    /// 工作区文件），外部修改（终端 commit / checkout / stash 等）也能触发
    /// 工作区干净状态重算，避免工作区已干净但表单仍显示的漏刷新。
    let gitWatch: (any GitRepositoryWatching)?
    /// Git 用户预设管理（可选）：用于用户选择器下拉列表。
    let gitUserPresets: (any GitUserPresetProviding)?
    @LumiTheme private var theme
    @StateObject private var formObservation: CommitFormObservationModel
    @StateObject private var projectObservation: ProjectObservationModel
    @StateObject private var gitWatchObservation: GitRepositoryWatchObservationModel

    @State private var subject: String = ""
    @State private var category: CommitCategory = .Chore
    @State private var style: CommitStyle = CommitStyleStore.current
    @State private var coAuthors: [CoAuthor] = []
    @State private var user: (name: String?, email: String?)?
    @State private var showCoAuthorSheet = false
    /// 共同作者弹窗（popover）是否展示。
    @State private var isCoAuthorPopoverPresented = false
    /// 共同作者按钮是否悬停。
    @State private var isCoAuthorHovering = false
    /// 用户选择器弹窗（popover）是否展示。
    @State private var isUserBadgePopoverPresented = false
    /// 用户选择器按钮是否悬停。
    @State private var isUserBadgeHovering = false

    /// 当前项目工作区是否干净（无未提交 / 未跟踪变更）。
    /// 对齐旧版 `GitDetailPresentationRules`：工作区干净时提交表单隐藏自身。
    @State private var isClean: Bool = true
    /// 已加载工作区状态的项目 URL（避免同一项目重复加载）。
    @State private var loadedProjectURL: URL?
    /// 工作区状态加载序号：仅最后一次加载结果落地，防止旧任务（脏）覆盖新结果（干净）。
    @State private var worktreeStatusLoadToken = 0

    public init(
        projects: any ProjectProviding,
        form: any CommitFormProviding,
        git: any GitProviding,
        gitWatch: (any GitRepositoryWatching)? = nil,
        errorCenter: CommitFormErrorCenter? = nil,
        gitUserPresets: (any GitUserPresetProviding)? = nil
    ) {
        self.projects = projects
        self.form = form
        self.git = git
        self.gitWatch = gitWatch
        self.errorCenter = errorCenter
        self.gitUserPresets = gitUserPresets
        _formObservation = StateObject(wrappedValue: CommitFormObservationModel(form: form))
        _projectObservation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        _gitWatchObservation = StateObject(wrappedValue: GitRepositoryWatchObservationModel(gitWatch: gitWatch))
    }

    @ViewBuilder
    public var body: some View {
        // 对齐旧版 GitDetailPresentationRules.headerContentMode：
        // - 选中（历史）commit → 隐藏表单，详情区展示 commit 信息；
        // - 未选中 commit 且工作区不干净（isClean == false）→ 显示提交表单；
        // - 未选中 commit 且工作区干净 → 隐藏表单。
        Group {
            if projects.currentCommit == nil && !isClean {
                formContent
            }
        }
        // commit 选择 / 项目切换 / 仓库数据变化 → 重算显隐（干净时隐藏表单）。
        .onReceive(projectObservation.$revision) { _ in
            reloadWorktreeStatusIfNeeded()
        }
        .onReceive(projectObservation.$lastEvent) { event in
            if case .dataChanged = event {
                reloadWorktreeStatusIfNeeded(force: true)
            }
        }
        // 外部修改仓库（终端 commit / checkout / stash / 其他工具改仓库）时，
        // FSEventStream 监听 .git 目录广播事件 → 强制重算工作区干净状态，
        // 否则外部把工作区改干净后表单仍残留显示。
        .onReceive(gitWatchObservation.$revision) { _ in
            reloadWorktreeStatusIfNeeded(force: true)
        }
        .onAppear {
            reloadWorktreeStatusIfNeeded(force: true)
        }
        .onChange(of: projects.currentProject?.url) { _, _ in
            reloadWorktreeStatusIfNeeded()
        }
    }

    @ViewBuilder
    private var formContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                firstRow
                secondRow
                if errorCenter == nil, let error = form.lastErrorMessage, !error.isEmpty {
                    AppErrorBanner(message: LocalizedStringKey(error))
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

    /// 第一行：风格 + 类别 + 用户 + 共同作者。
    private var firstRow: some View {
        HStack(spacing: 8) {
            ToolbarStylePicker(
                title: loc("Commit Style"),
                options: CommitStyle.allCases,
                selection: style,
                labelForOption: { $0.label }
            ) { form.setStyle($0) }
            .frame(width: 140)

            ToolbarStylePicker(
                title: loc("Commit Category"),
                options: CommitCategory.allCases,
                selection: category,
                labelForOption: { displayLabel(for: $0) }
            ) { form.setCategory($0) }
            .frame(width: 150)

            userBadge

            coAuthorButton

            Spacer(minLength: 0)
        }
    }

    /// 最后一行：消息输入 + 提交 + 提交并推送。
    private var secondRow: some View {
        HStack(spacing: 8) {
            AppInputField(LocalizedStringKey(loc("commit")), text: Binding(
                get: { subject },
                set: {
                    subject = $0
                    form.setSubject($0)
                }
            ))
            .frame(maxWidth: .infinity)

            if form.isSubmitting {
                ContentLoadingIndicator(loc("Submitting..."), controlSize: .small)
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

    /// 当前 git 用户选择器，视觉风格对齐左侧 ToolbarStylePicker。
    ///
    /// 有预设时展示下拉列表（popover），选中预设后写入当前项目 git 配置；
    /// 无预设 provider 或无当前用户时退回静态 AppTag。
    @ViewBuilder
    private var userBadge: some View {
        if let user, let name = user.name, !name.isEmpty {
            let displayName = user.email?.isEmpty == false ? "\(name) <\(user.email!)>" : name
            if gitUserPresets != nil {
                Button {
                    isUserBadgePopoverPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        Image(systemName: isUserBadgePopoverPresented ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isUserBadgeHovering || isUserBadgePopoverPresented ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.07))
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isUserBadgePopoverPresented, arrowEdge: .bottom) {
                    userBadgePopoverContent
                }
                .onHover { isUserBadgeHovering = $0 }
            } else {
                AppTag(displayName, systemImage: "person.crop.circle")
                    .lineLimit(1)
            }
        } else {
            AppTag(
                loc("Git user not configured"),
                systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(theme.error)
        }
    }

    /// 用户预设选择面板：列出 `GitUserPresetProviding` 中的预设，
    /// 点击某条后将 name / email 写入当前项目的仓库级 git 配置。
    @ViewBuilder
    private var userBadgePopoverContent: some View {
        VStack(spacing: 0) {
            Text(loc("Git User"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            AppDivider()

            let presets = gitUserPresets?.loadPresets() ?? []
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(presets) { preset in
                        userPresetRow(preset: preset)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 200)
        }
        .frame(width: 260)
    }

    private func userPresetRow(preset: GitUserPreset) -> some View {
        let isCurrent = preset.name == user?.name && preset.email == user?.email
        return Button {
            applyUserPreset(preset)
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.title)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Text(preset.email)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    /// 将预设写入当前项目仓库级 git 配置，并刷新 user 状态。
    private func applyUserPreset(_ preset: GitUserPreset) {
        guard let project = projects.currentProject else {
            isUserBadgePopoverPresented = false
            return
        }
        isUserBadgePopoverPresented = false
        let url = project.url
        Task.detached(priority: .userInitiated) {
            do {
                try GitConfigReader.setValue("user.name", preset.name, in: url)
                try GitConfigReader.setValue("user.email", preset.email, in: url)
                await MainActor.run {
                    self.user = (name: preset.name, email: preset.email)
                    self.projects.notifyDataChanged()
                }
            } catch {
                // 写入失败时静默处理，用户可在设置页手动配置。
            }
        }
    }

    /// 共同作者选择按钮（Menu 多选 + 添加入口），视觉风格对齐左侧 ToolbarStylePicker。
    private var coAuthorButton: some View {
        Button {
            isCoAuthorPopoverPresented = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.2")
                    .font(.system(size: 13, weight: .medium))

                if !coAuthors.isEmpty {
                    Text("\(coAuthors.count)")
                        .font(.system(size: 13, weight: .medium))
                }

                Image(systemName: isCoAuthorPopoverPresented ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(coAuthors.isEmpty ? theme.textTertiary : theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCoAuthorHovering || isCoAuthorPopoverPresented ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isCoAuthorPopoverPresented, arrowEdge: .bottom) {
            coAuthorPopoverContent
        }
        .onHover { isCoAuthorHovering = $0 }
    }

    /// 共同作者弹出面板：多选 + 添加入口。
    @ViewBuilder
    private var coAuthorPopoverContent: some View {
        VStack(spacing: 0) {
            Text(loc("Co-authors"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            AppDivider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(CoAuthorStore.shared.loadCoAuthors()) { author in
                        coAuthorRow(author: author)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 200)

            AppDivider()
            Button {
                showCoAuthorSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text(loc("Add Co-author"))
                }
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.08))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            )
            .padding(.bottom, 8)
        }
        .frame(width: 220)
    }

    private func coAuthorRow(author: CoAuthor) -> some View {
        let isSelected = coAuthors.contains(where: { $0.id == author.id })
        return Button {
            toggle(author)
        } label: {
            HStack(spacing: 8) {
                Text(author.displayText)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
                presentSubmitError(error, repository: project.url)
            }
        }
    }

    @MainActor
    private func presentSubmitError(_ error: Error, repository: URL) {
        if let syncError = error as? GitRemoteOperation.SyncError {
            // Merge 冲突由现有冲突解决器自动打开，避免错误面板盖住冲突操作界面。
            if case .merge = syncError.step,
               git.hasConflictOperation(in: repository) {
                return
            }
            errorCenter?.present(
                operation: loc(syncError.step.localizationKey),
                message: syncError.message
            )
            return
        }

        errorCenter?.present(
            operation: loc("Commit failed"),
            message: error.localizedDescription
        )
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

    // MARK: - Worktree Status

    /// 项目 / 仓库数据变化时重算工作区是否干净；force 为 true 时强制刷新。
    /// 工作区干净（isClean == true）时表单隐藏自身，对齐旧版 GitDetail 行为。
    ///
    /// 用 `worktreeStatusLoadToken` 保证并发下只有最后一次加载的结果会落地，
    /// 避免旧的「脏」结果覆盖新的「干净」结果导致表单残留。
    private func reloadWorktreeStatusIfNeeded(force: Bool = false) {
        guard let project = projects.currentProject else {
            loadedProjectURL = nil
            isClean = true
            worktreeStatusLoadToken &+= 1
            return
        }
        if loadedProjectURL == project.url && !force { return }
        loadedProjectURL = project.url

        worktreeStatusLoadToken &+= 1
        let token = worktreeStatusLoadToken
        let url = project.url
        Task.detached(priority: .utility) {
            let status = try? git.loadStatus(in: url)
            await MainActor.run {
                guard token == self.worktreeStatusLoadToken else { return }
                self.isClean = status?.isClean ?? true
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
                AppInputField(LocalizedStringKey(loc("Name")), text: $newName)
                AppInputField(LocalizedStringKey(loc("Email")), text: $newEmail)
                AppButton(loc("Add"), style: .secondary, size: .small, action: {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return }
                    let author = CoAuthor(name: trimmedName, email: trimmedEmail)
                    CoAuthorStore.shared.addCoAuthor(author)
                    selected.append(author)
                    newName = ""
                    newEmail = ""
                })
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack {
                Spacer()
                AppButton(loc("Cancel"), style: .ghost, size: .small, action: { dismiss() })
                AppButton(loc("Done"), style: .primary, size: .small, action: {
                    onCommit(selected)
                    dismiss()
                })
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

/// 项目观察模型：订阅 `ProjectProviding` 事件（commit 选择 / 项目切换 /
/// 仓库数据变化），转成 `@Published revision` 与 `lastEvent` 驱动 SwiftUI 重算——
/// 用户选中（历史）commit 时表单隐藏自身，清除选择后恢复显示；
/// 仓库数据变化（提交 / 推送等）时强制重算工作区干净状态。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var lastEvent: ProjectProvidingEvent?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            self?.lastEvent = event
            self?.revision += 1
        }
    }
}

/// Git 仓库监听观察模型：订阅 `GitRepositoryWatching` 的事件，
/// 把 `.git` 目录变化（HEAD / index / stash / refs）与工作区文件变化转成
/// `@Published revision` 以驱动 SwiftUI 强制重算工作区干净状态。
///
/// 当外部修改仓库（如终端 `git commit` / `git checkout` / `git stash` /
/// 其他工具改仓库）时，FSEventStream 监听到变化并广播事件，本模型接收后
/// 触发表单重算——这是表单在「工作区被外部改干净」时仍残留显示的修复关键。
@MainActor
final class GitRepositoryWatchObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any GitRepositoryWatchingObserverHandle)?

    init(gitWatch: (any GitRepositoryWatching)?) {
        guard let gitWatch else { return }
        handle = gitWatch.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
