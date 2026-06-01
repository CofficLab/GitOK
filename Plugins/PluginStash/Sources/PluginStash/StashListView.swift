import GitOKCoreKit
import SwiftUI

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
                        ProgressView(PluginStashLocalization.string("Loading stash list…"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
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
        .alert(PluginStashLocalization.string("Uncommitted Changes"), isPresented: hasPendingDirtyAction) {
            Button(PluginStashLocalization.string("Cancel"), role: .cancel) {
                pendingDirtyAction = nil
            }
            Button(PluginStashLocalization.string("Continue"), role: .destructive) {
                if let pendingDirtyAction {
                    performStashAction(pendingDirtyAction, skipCleanCheck: true)
                }
                pendingDirtyAction = nil
            }
        } message: {
            Text(PluginStashLocalization.string("Applying, popping, or branching from a stash may conflict with your current working tree changes. Consider committing first or creating another stash."))
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
                Text(PluginStashLocalization.string("Stash"))
                    .font(.headline)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showStashForm = true
            } label: {
                Label(PluginStashLocalization.string("New Stash"), systemImage: "plus")
            }
            .disabled(projectURL == nil || isPerformingAction)
        }
    }

    private var headerSubtitle: String {
        guard projectURL != nil else { return PluginStashLocalization.string("No project selected") }
        if isLoading {
            return PluginStashLocalization.string("Loading your saved changes")
        }
        if stashes.isEmpty {
            return PluginStashLocalization.string("No Stashes Yet")
        }
        return PluginStashLocalization.string("%lld stashes on %@", stashes.count, currentBranchName)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "archivebox")
                .font(.system(size: 38))
                .foregroundStyle(.tertiary)
            Text(PluginStashLocalization.string("No Stashes Yet"))
                .font(.subheadline.weight(.semibold))
            Text(PluginStashLocalization.string("Click \"New Stash\" above to temporarily store your current changes."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }

    private var stashFormView: some View {
        VStack(spacing: 16) {
            Text(PluginStashLocalization.string("Create Stash"))
                .font(.headline)

            TextField(PluginStashLocalization.string("Stash description (optional)"), text: $stashMessage)
                .textFieldStyle(.roundedBorder)
                .frame(width: 320)

            HStack {
                Button(PluginStashLocalization.string("Cancel")) {
                    stashMessage = ""
                    showStashForm = false
                }

                Button(PluginStashLocalization.string("Create")) {
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
            Text(PluginStashLocalization.string("Create Branch from Stash"))
                .font(.headline)

            TextField(PluginStashLocalization.string("New branch name"), text: $branchName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 340)

            HStack {
                Button(PluginStashLocalization.string("Cancel")) {
                    branchName = ""
                    branchSourceStashIndex = nil
                    showBranchForm = false
                }

                Button(PluginStashLocalization.string("Create")) {
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

        Task(priority: .userInitiated) {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try GitRepositoryCLI(repositoryURL: projectURL).stashSave(message: message.isEmpty ? nil : message)
                }.value
                finishAction(message: PluginStashLocalization.string("Stash created"))
                stashMessage = ""
                showStashForm = false
            } catch {
                failAction(error)
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
            do {
                if try GitRepositoryCLI(repositoryURL: projectURL).statusEntries().isEmpty == false {
                    pendingDirtyAction = action
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
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
        runStashAction(index: index, successMessage: PluginStashLocalization.string("Applied stash@{%lld}", index)) { cli in
            try cli.stashApply(index: index)
        }
    }

    private func popStash(at index: Int) {
        runStashAction(index: index, successMessage: PluginStashLocalization.string("Popped stash@{%lld}", index)) { cli in
            try cli.stashPop(index: index)
        }
    }

    private func dropStash(at index: Int) {
        runStashAction(index: index, successMessage: PluginStashLocalization.string("Deleted stash@{%lld}", index)) { cli in
            try cli.stashDrop(index: index)
        }
    }

    private func createBranch(from index: Int, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        runStashAction(index: index, successMessage: PluginStashLocalization.string("Created branch from stash@{%lld}", index)) { cli in
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

        Task(priority: .userInitiated) {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try operation(GitRepositoryCLI(repositoryURL: projectURL))
                }.value
                finishAction(message: successMessage)
            } catch {
                failAction(error)
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
        Task(priority: .userInitiated) {
            do {
                let stashList = try await Task.detached(priority: .userInitiated) {
                    try GitRepositoryCLI(repositoryURL: projectURL).stashList()
                }.value
                stashes = stashList
                currentBranchName = "main"
                isLoading = false
            } catch {
                stashes = []
                currentBranchName = "main"
                isLoading = false
                errorMessage = error.localizedDescription
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
