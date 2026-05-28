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
        .alert(String(localized: "Uncommitted Changes"), isPresented: hasPendingDirtyAction) {
            Button(String(localized: "Cancel"), role: .cancel) {
                pendingDirtyAction = nil
            }
            Button(String(localized: "Continue"), role: .destructive) {
                if let pendingDirtyAction {
                    performStashAction(pendingDirtyAction, skipCleanCheck: true)
                }
                pendingDirtyAction = nil
            }
        } message: {
            Text(String(localized: "Applying, popping, or branching from a stash may conflict with your current working tree changes. Consider committing first or creating another stash."))
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
                        Text(String(localized: "Stash", table: "GitStash"))
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text(String(localized: "Reference the Desktop workflow to temporarily put changes into a restorable queue."))
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                    }

                    Spacer()

                    Button(action: {
                        showStashForm = true
                    }) {
                        Label(String(localized: "New Stash"), systemImage: "plus")
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
                    .help(String(localized: "Create a new stash"))
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    metricPill(
                        icon: "archivebox.fill",
                        title: "\(stashes.count)",
                        subtitle: String(localized: "Stashes", table: "GitStash"),
                        color: DesignTokens.Color.semantic.info
                    )

                    metricPill(
                        icon: "arrow.triangle.branch",
                        title: currentBranchName,
                        subtitle: String(localized: "Current Branch", table: "GitStash"),
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
                    title: String(localized: "Saved Work", table: "GitStash"),
                    subtitle: isLoading ? String(localized: "Loading your saved changes", table: "GitStash") : String(localized: "Review, restore, or discard individual stashes", table: "GitStash"),
                    iconColor: DesignTokens.Color.semantic.info
                )

                if isLoading {
                    ProgressView(String(localized: "Loading stash list…"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.xl)
                } else if stashes.isEmpty {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 42))
                            .foregroundColor(DesignTokens.Color.semantic.textTertiary)

                        Text(String(localized: "No Stashes Yet"))
                            .font(DesignTokens.Typography.bodyEmphasized)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text(String(localized: "Click \"New Stash\" above to temporarily store your current changes."))
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
            Text(String(localized: "Create Stash"))
                .font(.headline)

            TextField(String(localized: "Stash description (optional)"), text: $stashMessage)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack {
                Button(String(localized: "Cancel")) {
                    stashMessage = ""
                    showStashForm = false
                }

                Button(String(localized: "Create")) {
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
            Text(String(localized: "Create Branch from Stash"))
                .font(.headline)

            TextField(String(localized: "New branch name"), text: $branchName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 320)

            HStack {
                Button(String(localized: "Cancel")) {
                    branchName = ""
                    branchSourceStashIndex = nil
                    showBranchForm = false
                }

                Button(String(localized: "Create")) {
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
                    alert_info(String(localized: "Stash created"))
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
                    alert_info(String(localized: "Applied stash@{\(index)}"))
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
                    alert_info(String(localized: "Popped stash@{\(index)}"))
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
                    alert_info(String(localized: "Deleted stash@{\(index)}"))
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
                    alert_info(String(localized: "Created branch from stash@{\(index)}"))
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
