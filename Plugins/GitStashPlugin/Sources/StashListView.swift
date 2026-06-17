import GitOKCoreKit
import GitCoreKit
import SwiftUI

private enum StashListBackgroundRunner {
    static func stashList(projectURL: URL) throws -> [GitStashEntry] {
        try GitRepositoryCLI(repositoryURL: projectURL).stashList()
    }

    static func stashSave(projectURL: URL, message: String?) throws {
        try GitRepositoryCLI(repositoryURL: projectURL).stashSave(message: message)
    }

    static func hasStatusChanges(projectURL: URL) throws -> Bool {
        try GitRepositoryCLI(repositoryURL: projectURL).lightweightStatusEntries().isEmpty == false
    }

    static func runStashAction(
        projectURL: URL,
        operation: @escaping @Sendable (GitRepositoryCLI) throws -> Void
    ) throws {
        try operation(GitRepositoryCLI(repositoryURL: projectURL))
    }
}

struct StashListView: View {
    let projectURL: URL?
    let refreshToken: Int
    let onStashesChanged: () -> Void

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
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if isLoading {
                        AppLoadingOverlay(
                            message: GitStashPluginLocalization.string("Loading stash list…"),
                            size: .small
                        )
                        .frame(minHeight: 120)
                    } else if stashes.isEmpty {
                        emptyState
                    } else {
                        ForEach(stashes, id: \.index) { stash in
                            StashRow(
                                stash: stash,
                                fallbackBranchName: currentBranchName,
                                isBusy: isPerformingAction,
                                onBranch: { prepareBranch(from: stash) },
                                onApply: { performStashAction(.apply(index: stash.index)) },
                                onPop: { performStashAction(.pop(index: stash.index)) },
                                onDrop: { dropStash(at: stash.index) }
                            )
                            .opacity(isPerformingAction && activeStashIndex != stash.index ? 0.55 : 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .sheet(isPresented: $showStashForm) {
            stashFormView
        }
        .sheet(isPresented: $showBranchForm) {
            branchFormView
        }
        .alert(GitStashPluginLocalization.string("Uncommitted Changes"), isPresented: hasPendingDirtyAction) {
            Button(GitStashPluginLocalization.string("Cancel"), role: .cancel) {
                pendingDirtyAction = nil
            }
            Button(GitStashPluginLocalization.string("Continue"), role: .destructive) {
                if let pendingDirtyAction {
                    performStashAction(pendingDirtyAction, skipCleanCheck: true)
                }
                pendingDirtyAction = nil
            }
        } message: {
            Text(GitStashPluginLocalization.string("Applying, popping, or branching from a stash may conflict with your current working tree changes. Consider committing first or creating another stash."))
        }
        .onAppear(perform: loadStashes)
        .onChange(of: projectURL) { _, _ in loadStashes() }
        .onChange(of: refreshToken) { _, _ in loadStashes() }
        .onReceive(NotificationCenter.default.publisher(for: .pluginStashProjectDidCommit)) { _ in
            loadStashes()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginStashProjectGitStashDidChange)) { _ in
            loadStashes()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "archivebox")
                .foregroundStyle(stashes.isEmpty ? Color.secondary : Color.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(GitStashPluginLocalization.string("Stash"))
                    .font(.headline)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            AppButton(
                GitStashPluginLocalization.string("New Stash"),
                systemImage: "plus",
                style: .secondary,
                size: .small
            ) {
                showStashForm = true
            }
            .disabled(projectURL == nil || isPerformingAction)
        }
    }

    private var headerSubtitle: String {
        guard projectURL != nil else { return GitStashPluginLocalization.string("No project selected") }
        if isLoading {
            return GitStashPluginLocalization.string("Loading your saved changes")
        }
        if stashes.isEmpty {
            return GitStashPluginLocalization.string("No Stashes Yet")
        }
        return GitStashPluginLocalization.string("%lld stashes on %@", stashes.count, currentBranchName)
    }

    private var emptyState: some View {
        AppEmptyState(
            icon: "archivebox",
            title: GitStashPluginLocalization.string("No Stashes Yet"),
            description: GitStashPluginLocalization.string("Click \"New Stash\" above to temporarily store your current changes.")
        )
        .frame(minHeight: 180)
    }

    private var stashFormView: some View {
        VStack(spacing: 16) {
            Text(GitStashPluginLocalization.string("Create Stash"))
                .font(.headline)

            AppInputField(GitStashPluginLocalization.string("Stash description (optional)"), text: $stashMessage)
                .frame(width: 320)

            HStack {
                AppButton(GitStashPluginLocalization.string("Cancel"), style: .secondary) {
                    stashMessage = ""
                    showStashForm = false
                }

                AppButton(GitStashPluginLocalization.string("Create"), systemImage: "archivebox", style: .primary) {
                    createStash()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(projectURL == nil || isPerformingAction)
            }
        }
        .padding()
        .frame(width: 370)
    }

    private var branchFormView: some View {
        VStack(spacing: 16) {
            Text(GitStashPluginLocalization.string("Create Branch from Stash"))
                .font(.headline)

            AppInputField(GitStashPluginLocalization.string("New branch name"), text: $branchName)
                .frame(width: 340)

            HStack {
                AppButton(GitStashPluginLocalization.string("Cancel"), style: .secondary) {
                    branchName = ""
                    branchSourceStashIndex = nil
                    showBranchForm = false
                }

                AppButton(GitStashPluginLocalization.string("Create"), systemImage: "arrow.triangle.branch", style: .primary) {
                    if let branchSourceStashIndex {
                        performStashAction(.branch(index: branchSourceStashIndex, name: branchName))
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPerformingAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private var hasPendingDirtyAction: Binding<Bool> {
        Binding(
            get: { pendingDirtyAction != nil },
            set: { if $0 == false { pendingDirtyAction = nil } }
        )
    }

    private func createStash() {
        guard let projectURL, isPerformingAction == false else { return }

        let message = stashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        isPerformingAction = true
        activeStashIndex = nil
        clearMessages()

        Task.detached(priority: .userInitiated) {
            do {
                try StashListBackgroundRunner.stashSave(projectURL: projectURL, message: message.isEmpty ? nil : message)
                await MainActor.run {
                    finishAction(message: GitStashPluginLocalization.string("Stash created"))
                    stashMessage = ""
                    showStashForm = false
                }
            } catch {
                await MainActor.run {
                    failAction(error)
                }
            }
        }
    }

    private func prepareBranch(from stash: GitStashEntry) {
        branchSourceStashIndex = stash.index
        branchName = StashPresentation.branchName(from: stash, fallbackBranchName: currentBranchName)
        showBranchForm = true
    }

    private func performStashAction(_ action: PendingStashAction, skipCleanCheck: Bool = false) {
        guard let projectURL, isPerformingAction == false else { return }

        if skipCleanCheck == false, action.requiresCleanWorkingTree {
            Task.detached(priority: .userInitiated) {
                do {
                    let hasChanges = try StashListBackgroundRunner.hasStatusChanges(projectURL: projectURL)

                    await MainActor.run {
                        if hasChanges {
                            pendingDirtyAction = action
                        } else {
                            performStashAction(action, skipCleanCheck: true)
                        }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            return
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
        runStashAction(index: index, successMessage: GitStashPluginLocalization.string("Applied stash@{%lld}", index)) { cli in
            try cli.stashApply(index: index)
        }
    }

    private func popStash(at index: Int) {
        runStashAction(index: index, successMessage: GitStashPluginLocalization.string("Popped stash@{%lld}", index)) { cli in
            try cli.stashPop(index: index)
        }
    }

    private func dropStash(at index: Int) {
        runStashAction(index: index, successMessage: GitStashPluginLocalization.string("Deleted stash@{%lld}", index)) { cli in
            try cli.stashDrop(index: index)
        }
    }

    private func createBranch(from index: Int, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        runStashAction(index: index, successMessage: GitStashPluginLocalization.string("Created branch from stash@{%lld}", index)) { cli in
            try cli.stashBranch(name: trimmedName, index: index)
        }
        branchName = ""
        branchSourceStashIndex = nil
        showBranchForm = false
    }

    private func runStashAction(index: Int, successMessage: String, operation: @escaping @Sendable (GitRepositoryCLI) throws -> Void) {
        guard let projectURL, isPerformingAction == false else { return }

        isPerformingAction = true
        activeStashIndex = index
        clearMessages()

        Task.detached(priority: .userInitiated) {
            do {
                try StashListBackgroundRunner.runStashAction(projectURL: projectURL, operation: operation)
                await MainActor.run {
                    finishAction(message: successMessage)
                }
            } catch {
                await MainActor.run {
                    failAction(error)
                }
            }
        }
    }

    private func loadStashes() {
        guard let projectURL else {
            stashes = []
            currentBranchName = "main"
            isLoading = false
            return
        }

        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                let stashList = try StashListBackgroundRunner.stashList(projectURL: projectURL)
                await MainActor.run {
                    stashes = stashList
                    currentBranchName = "main"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    stashes = []
                    currentBranchName = "main"
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func finishAction(message: String) {
        self.message = message
        isPerformingAction = false
        activeStashIndex = nil
        loadStashes()
        onStashesChanged()
    }

    private func failAction(_ error: Error) {
        isPerformingAction = false
        activeStashIndex = nil
        errorMessage = error.localizedDescription
    }

    private func clearMessages() {
        message = nil
        errorMessage = nil
    }
}
