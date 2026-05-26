import GitCoreKit
import LibGit2Swift
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 显示stash列表的视图组件
struct StashList: View, SuperLog, SuperThread {
    /// 日志标识符
    nonisolated static let emoji = "📦"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static let shared = StashList()

    @EnvironmentObject var app: AppVM
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var stashes: [GitStashEntry] = []
    @State private var isLoading = true
    @State private var showStashForm = false
    @State private var showBranchForm = false
    @State private var branchName = ""
    @State private var stashMessage = ""
    @State private var currentBranchName = "main"
    @State private var isPerformingAction = false
    @State private var activeStashIndex: Int?
    @State private var pendingDirtyAction: PendingStashAction?
    @State private var branchSourceStashIndex: Int?

    private init() {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                headerBar
                stashListView
            }
            .padding(DesignTokens.Spacing.md)
        }
        .sheet(isPresented: $showStashForm) {
            stashFormView
        }
        .sheet(isPresented: $showBranchForm) {
            branchFormView
        }
        .alert("工作区有未提交改动", isPresented: hasPendingDirtyAction) {
            Button("取消", role: .cancel) {
                pendingDirtyAction = nil
            }
            Button("继续", role: .destructive) {
                if let pendingDirtyAction {
                    performStashAction(pendingDirtyAction, skipCleanCheck: true)
                }
                pendingDirtyAction = nil
            }
        } message: {
            Text("应用、弹出或基于 stash 创建分支可能与当前工作区改动冲突。建议先提交或再创建一个 stash。")
        }
        .onAppear(perform: onAppear)
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onProjectGitStashDidChange(perform: onGitDirectoryDidChange)
    }
}

// MARK: - View

extension StashList {
    private var headerBar: some View {
        GlassCard(glowColor: DesignTokens.Color.semantic.info) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Stash")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text("参考 Desktop 的工作流，把临时改动放到可恢复的队列里。")
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                    }

                    Spacer()

                    Button(action: {
                        showStashForm = true
                    }) {
                        Label("新建暂存", systemImage: "plus")
                            .font(DesignTokens.Typography.bodyEmphasized)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Material.glass.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.project == nil || isPerformingAction)
                    .help("创建新暂存")
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    metricPill(
                        icon: "archivebox.fill",
                        title: "\(stashes.count)",
                        subtitle: "Stashes",
                        color: DesignTokens.Color.semantic.info
                    )

                    metricPill(
                        icon: "arrow.triangle.branch",
                        title: currentBranchName,
                        subtitle: "Current Branch",
                        color: DesignTokens.Color.semantic.primary
                    )

                    Spacer()
                }
            }
        }
    }

    private func metricPill(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.bodyEmphasized)
                    .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.caption1)
                    .foregroundColor(DesignTokens.Color.semantic.textTertiary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(color.opacity(0.10))
        )
    }

    private var stashListView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                GlassSectionHeader(
                    icon: "tray.full",
                    title: "Saved Work",
                    subtitle: isLoading ? "Loading your saved changes" : "Review, restore, or discard individual stashes",
                    iconColor: DesignTokens.Color.semantic.info
                )

                if isLoading {
                    ProgressView("加载暂存列表...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.xl)
                } else if stashes.isEmpty {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 42))
                            .foregroundColor(DesignTokens.Color.semantic.textTertiary)

                        Text("暂无 stash")
                            .font(DesignTokens.Typography.bodyEmphasized)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text("点击上方“新建暂存”把当前改动临时收起。")
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.xxl)
                } else {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(stashes, id: \.index) { stash in
                            StashRow(
                                stash: stash,
                                branchName: currentBranchName,
                                onBranch: { prepareBranch(from: stash) },
                                onApply: { performStashAction(.apply(index: stash.index)) },
                                onPop: { performStashAction(.pop(index: stash.index)) },
                                onDrop: { dropStash(at: stash.index) }
                            )
                            .disabled(isPerformingAction)
                            .opacity(isPerformingAction && activeStashIndex != stash.index ? 0.55 : 1.0)
                            .id(stash.index)
                        }
                    }
                }
            }
        }
    }

    private var stashFormView: some View {
        VStack(spacing: 16) {
            Text("创建 Stash")
                .font(.headline)

            TextField("暂存描述（可选）", text: $stashMessage)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack {
                Button("取消") {
                    stashMessage = ""
                    showStashForm = false
                }

                Button("创建") {
                    createStash()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isPerformingAction)
            }
        }
        .padding()
        .frame(width: 350)
    }

    private var branchFormView: some View {
        VStack(spacing: 16) {
            Text("从 Stash 创建分支")
                .font(.headline)

            TextField("新分支名称", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 320)

            HStack {
                Button("取消") {
                    branchName = ""
                    branchSourceStashIndex = nil
                    showBranchForm = false
                }

                Button("创建") {
                    if let branchSourceStashIndex {
                        performStashAction(.branch(index: branchSourceStashIndex, name: branchName))
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPerformingAction)
            }
        }
        .padding()
        .frame(width: 380)
    }
}

// MARK: - Action

extension StashList {
    private var hasPendingDirtyAction: Binding<Bool> {
        Binding(
            get: { pendingDirtyAction != nil },
            set: { if $0 == false { pendingDirtyAction = nil } }
        )
    }

    private func createStash() {
        guard let project = vm.project, !isPerformingAction else { return }

        let message = stashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        isPerformingAction = true
        activeStashIndex = nil

        Task(priority: .userInitiated) {
            do {
                try project.stashSave(message: message.isEmpty ? nil : message)

                await MainActor.run {
                    alert_info("已创建 stash")
                    stashMessage = ""
                    showStashForm = false
                    isPerformingAction = false
                    loadStashes()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    alert_error(error)
                }
            }
        }
    }

    private func prepareBranch(from stash: GitStashEntry) {
        branchSourceStashIndex = stash.index
        let sourceBranch = stash.branchName ?? currentBranchName
        branchName = "stash/\(sourceBranch)-\(stash.index)"
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        showBranchForm = true
    }

    private func performStashAction(_ action: PendingStashAction, skipCleanCheck: Bool = false) {
        guard let project = vm.project, !isPerformingAction else { return }

        if skipCleanCheck == false, action.requiresCleanWorkingTree {
            do {
                if try project.statusEntries().isEmpty == false {
                    pendingDirtyAction = action
                    return
                }
            } catch {
                alert_error(error)
                return
            }
        }

        switch action {
        case let .apply(index):
            applyStash(at: index)
        case let .pop(index):
            popStash(at: index)
        case let .branch(index, name):
            createBranch(from: index, name: name)
        }
    }

    private func applyStash(at index: Int) {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true
        activeStashIndex = index

        Task(priority: .userInitiated) {
            do {
                try project.stashApply(index: index)

                await MainActor.run {
                    alert_info("已应用 stash@{\(index)}")
                    isPerformingAction = false
                    activeStashIndex = nil
                    loadStashes()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeStashIndex = nil
                    alert_error(error)
                }
            }
        }
    }

    private func popStash(at index: Int) {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true
        activeStashIndex = index

        Task(priority: .userInitiated) {
            do {
                try project.stashPop(index: index)

                await MainActor.run {
                    alert_info("已弹出 stash@{\(index)}")
                    isPerformingAction = false
                    activeStashIndex = nil
                    loadStashes()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeStashIndex = nil
                    alert_error(error)
                }
            }
        }
    }

    private func dropStash(at index: Int) {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true
        activeStashIndex = index

        Task(priority: .userInitiated) {
            do {
                try project.stashDrop(index: index)

                await MainActor.run {
                    alert_info("已删除 stash@{\(index)}")
                    isPerformingAction = false
                    activeStashIndex = nil
                    loadStashes()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeStashIndex = nil
                    alert_error(error)
                }
            }
        }
    }

    private func createBranch(from index: Int, name: String) {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true
        activeStashIndex = index

        Task(priority: .userInitiated) {
            do {
                try project.stashBranch(name: name, index: index)

                await MainActor.run {
                    alert_info("已从 stash@{\(index)} 创建分支")
                    branchName = ""
                    branchSourceStashIndex = nil
                    showBranchForm = false
                    isPerformingAction = false
                    activeStashIndex = nil
                    loadStashes()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeStashIndex = nil
                    alert_error(error)
                }
            }
        }
    }

    private func loadStashes() {
        guard let project = vm.project else {
            stashes = []
            currentBranchName = "main"
            isLoading = false
            return
        }

        isLoading = true
        let repositoryURL = project.url

        Task(priority: .userInitiated) {
            do {
                let (stashList, branchName) = try await Task.detached(priority: .userInitiated) {
                    let cli = GitRepositoryCLI(repositoryURL: repositoryURL)
                    let stashList = try cli.stashList()
                    let branchName = (try? LibGit2.getCurrentBranch(at: repositoryURL.path)) ?? ""
                    return (stashList, branchName)
                }.value

                stashes = stashList
                currentBranchName = branchName.isEmpty ? "main" : branchName
                isLoading = false
            } catch {
                if Self.verbose {
                    os_log("\(self.t)❌ Failed to load stashes: \(error)")
                }
                stashes = []
                currentBranchName = "main"
                isLoading = false
                alert_error(error)
            }
        }
    }
}

private enum PendingStashAction: Equatable {
    case apply(index: Int)
    case pop(index: Int)
    case branch(index: Int, name: String)

    var requiresCleanWorkingTree: Bool {
        switch self {
        case .apply, .pop, .branch:
            return true
        }
    }
}

// MARK: - Event Handler

extension StashList {
    func onAppear() {
        loadStashes()
    }

    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        if ProjectEventRefreshRules.shouldRefreshStash(for: eventInfo.operation) {
            loadStashes()
        }
    }

    func onGitDirectoryDidChange(_ eventInfo: ProjectEventInfo) {
        guard eventInfo.project.path == vm.project?.path else { return }
        loadStashes()
    }
}
