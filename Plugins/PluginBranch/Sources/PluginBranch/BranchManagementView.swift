import AppKit
import GitOKCoreKit
import SwiftUI

public struct BranchManagementView: View {
    let context: BranchPluginContext
    @State private var branches: [GitBranchSummary] = []
    @State private var remoteBranches: [String] = []
    @State private var newBranchName = ""
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedBranch: GitBranchSummary?
    @State private var branchToRename: GitBranchSummary?
    @State private var renameBranchName = ""
    @State private var branchToSetUpstream: GitBranchSummary?
    @State private var selectedUpstreamBranch = ""
    @State private var compareBaseBranch: GitBranchSummary?
    @State private var compareHeadBranch: GitBranchSummary?
    @State private var branchCompare: GitBranchCompare?
    @State private var isComparing = false
    @State private var compareError: String?

    public init(context: BranchPluginContext) {
        self.context = context
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                newBranchSection
                Divider()
                TextField(PluginBranchLocalization.string("Search branches"), text: $searchText)
                    .textFieldStyle(.roundedBorder)
                branchListSection
                if remoteBranches.isEmpty == false {
                    Divider()
                    remoteBranchesSection
                }
                if branches.count >= 2 {
                    Divider()
                    compareSection
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(20)
        }
        .onAppear(perform: loadBranches)
        .sheet(item: $branchToRename) { branch in
            renameSheet(branch)
        }
        .sheet(item: $branchToSetUpstream) { branch in
            upstreamSheet(branch)
        }
    }

    private var repository: GitRepositoryCLI? {
        context.projectURL.map(GitRepositoryCLI.init(repositoryURL:))
    }

    private var filteredBranches: [GitBranchSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return branches }
        return branches.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredRemoteBranches: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return remoteBranches }
        return remoteBranches.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var newBranchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PluginBranchLocalization.string("New Branch"))
                .font(.headline)
            HStack(spacing: 8) {
                TextField(PluginBranchLocalization.string("Branch name"), text: $newBranchName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    createBranch()
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(newBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
    }

    private var branchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PluginBranchLocalization.string("Switch Branch"))
                .font(.headline)
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if filteredBranches.isEmpty {
                Text(PluginBranchLocalization.string("No branches yet"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(filteredBranches) { branch in
                        BranchRowView(
                            branch: branch,
                            isSelected: selectedBranch?.id == branch.id,
                            onSwitch: { switchBranch(branch) },
                            onDelete: { deleteBranch(branch) },
                            onRename: { beginRename(branch) },
                            onPublish: { publishBranch(branch) },
                            onSetUpstream: { beginSetUpstream(branch) },
                            onUnsetUpstream: { unsetUpstream(branch) }
                        )
                    }
                }
            }
        }
    }

    private var remoteBranchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PluginBranchLocalization.string("Remote Branches"))
                .font(.headline)
            ForEach(filteredRemoteBranches, id: \.self) { branchName in
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.secondary)
                    Text(branchName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        deleteRemoteBranch(branchName)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    private var compareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(PluginBranchLocalization.string("Branch Compare"))
                .font(.headline)
            Picker(PluginBranchLocalization.string("Base"), selection: $compareBaseBranch) {
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }
            Picker(PluginBranchLocalization.string("Head"), selection: $compareHeadBranch) {
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }
            Button {
                loadCompare()
            } label: {
                Label(PluginBranchLocalization.string("Compare"), systemImage: "arrow.left.arrow.right")
            }
            .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compareBaseBranch?.id == compareHeadBranch?.id || isComparing)

            if isComparing {
                ProgressView()
            } else if let compareError {
                Text(compareError)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let branchCompare {
                compareResultView(branchCompare)
            } else {
                Text(PluginBranchLocalization.string("Select base/head to view ahead/behind counts, commits, and file changes."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func compareResultView(_ compare: GitBranchCompare) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(String(format: PluginBranchLocalization.string("Ahead %d"), compare.ahead))
                    .font(.caption)
                    .foregroundColor(.green)
                Text(String(format: PluginBranchLocalization.string("Behind %d"), compare.behind))
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(String(format: PluginBranchLocalization.string("%d files"), compare.files.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ForEach(compare.commits.prefix(5)) { commit in
                HStack {
                    Text(String(commit.hash.prefix(7)))
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                    Text(commit.subject)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            ForEach(compare.files.prefix(6)) { file in
                HStack {
                    Text(file.status)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .frame(width: 34, alignment: .leading)
                    Text(file.oldPath.map { "\($0) -> \(file.path)" } ?? file.path)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            HStack {
                Button(PluginBranchLocalization.string("Merge Head into Base")) {
                    mergeComparedBranches()
                }
                .disabled(compareBaseBranch == nil || compareHeadBranch == nil || compare.ahead == 0)
                pullRequestButton(compare: compare)
            }
        }
    }

    @ViewBuilder
    private func pullRequestButton(compare: GitBranchCompare) -> some View {
        if let links = pullRequestLinks() {
            Button(PluginBranchLocalization.string("Create PR")) {
                NSWorkspace.shared.open(links.createURL)
            }
            .disabled(compare.ahead == 0)
        }
    }
}

private extension BranchManagementView {
    func createBranch() {
        let branchName = newBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard branchName.isEmpty == false else { return }
        runAction { repository in
            try repository.createBranch(named: branchName)
        } onSuccess: {
            newBranchName = ""
            loadBranches()
        }
    }

    func switchBranch(_ branch: GitBranchSummary) {
        let branchName = branch.name
        runAction { repository in
            try repository.checkoutBranch(named: branchName)
        } onSuccess: {
            selectedBranch = branch
            loadBranches()
        }
    }

    func deleteBranch(_ branch: GitBranchSummary) {
        guard selectedBranch?.id != branch.id else {
            errorMessage = PluginBranchLocalization.string("Cannot delete the current branch")
            return
        }
        let branchName = branch.name
        runAction { repository in
            try repository.deleteLocalBranch(named: branchName)
        } onSuccess: {
            loadBranches()
        }
    }

    func beginRename(_ branch: GitBranchSummary) {
        renameBranchName = branch.name
        branchToRename = branch
    }

    func renameBranch(_ branch: GitBranchSummary) {
        let branchName = branch.name
        let newName = renameBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newName.isEmpty == false else { return }
        runAction { repository in
            try repository.renameBranch(from: branchName, to: newName)
        } onSuccess: {
            loadBranches()
        }
    }

    func beginSetUpstream(_ branch: GitBranchSummary) {
        selectedUpstreamBranch = remoteBranches.first ?? ""
        branchToSetUpstream = branch
    }

    func setUpstream(_ branch: GitBranchSummary, upstreamBranch: String) {
        let branchName = branch.name
        runAction { repository in
            try repository.setUpstream(localBranch: branchName, upstreamBranch: upstreamBranch)
        } onSuccess: {
            loadBranches()
        }
    }

    func unsetUpstream(_ branch: GitBranchSummary) {
        let branchName = branch.name
        runAction { repository in
            try repository.unsetUpstream(localBranch: branchName)
        } onSuccess: {
            loadBranches()
        }
    }

    func publishBranch(_ branch: GitBranchSummary) {
        let branchName = branch.name
        runAction { repository in
            try repository.publishBranch(localBranch: branchName)
        } onSuccess: {
            loadBranches()
        }
    }

    func deleteRemoteBranch(_ branchName: String) {
        let parts = branchName.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        let remoteName = parts[0]
        let remoteBranchName = parts[1]
        runAction { repository in
            try repository.deleteRemoteBranch(named: remoteBranchName, remote: remoteName)
        } onSuccess: {
            loadBranches()
        }
    }

    func loadCompare() {
        guard let projectURL = context.projectURL, let base = compareBaseBranch, let head = compareHeadBranch, base.id != head.id else { return }
        let baseBranchName = base.name
        let headBranchName = head.name
        isComparing = true
        compareError = nil
        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                let compare = try repository.compareBranches(base: baseBranchName, head: headBranchName)
                await MainActor.run {
                    branchCompare = compare
                    isComparing = false
                }
            } catch {
                await MainActor.run {
                    branchCompare = nil
                    compareError = error.localizedDescription
                    isComparing = false
                }
            }
        }
    }

    func mergeComparedBranches() {
        guard let base = compareBaseBranch, let head = compareHeadBranch, base.id != head.id else { return }
        let baseBranchName = base.name
        let headBranchName = head.name
        runAction { repository in
            try repository.mergeBranches(fromBranch: headBranchName, toBranch: baseBranchName)
        } onSuccess: {
            loadBranches()
            loadCompare()
        }
    }

    func pullRequestLinks() -> RemoteRepositoryFormRules.PullRequestWebLinks? {
        guard let repository, let base = compareBaseBranch, let head = compareHeadBranch else { return nil }
        let remotes = (try? repository.remotes()) ?? []
        let preferredRemote = remotes.first(where: { $0.name == "origin" }) ?? remotes.first
        let remoteURL = preferredRemote?.url ?? preferredRemote?.fetchURL ?? preferredRemote?.pushURL
        guard let remoteURL else { return nil }
        return RemoteRepositoryFormRules.pullRequestWebLinks(remoteURL: remoteURL, baseBranch: base.name, headBranch: head.name)
    }

    func loadBranches() {
        guard let projectURL = context.projectURL else {
            branches = []
            remoteBranches = []
            selectedBranch = nil
            return
        }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                let loadedBranches = try repository.branches()
                let loadedRemoteBranches = (try? repository.remoteBranches()) ?? []
                await MainActor.run {
                    branches = loadedBranches
                    remoteBranches = loadedRemoteBranches
                    selectedBranch = loadedBranches.first(where: \.isCurrent)
                    updateCompareSelection(with: loadedBranches)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    branches = []
                    remoteBranches = []
                    selectedBranch = nil
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func updateCompareSelection(with branches: [GitBranchSummary]) {
        guard branches.count >= 2 else {
            compareBaseBranch = nil
            compareHeadBranch = nil
            branchCompare = nil
            return
        }
        if compareBaseBranch == nil || branches.contains(where: { $0.id == compareBaseBranch?.id }) == false {
            compareBaseBranch = selectedBranch ?? branches.first
        }
        if compareHeadBranch == nil || branches.contains(where: { $0.id == compareHeadBranch?.id }) == false || compareHeadBranch?.id == compareBaseBranch?.id {
            compareHeadBranch = branches.first(where: { $0.id != compareBaseBranch?.id })
        }
    }

    func runAction(
        _ action: @escaping @Sendable (GitRepositoryCLI) throws -> Void,
        onSuccess: @escaping @MainActor @Sendable () -> Void
    ) {
        guard let projectURL = context.projectURL else { return }
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                try action(repository)
                await MainActor.run {
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func renameSheet(_ branch: GitBranchSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PluginBranchLocalization.string("Rename Branch"))
                .font(.headline)
            Text(branch.name)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(PluginBranchLocalization.string("New branch name"), text: $renameBranchName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button(PluginBranchLocalization.string("Cancel")) {
                    branchToRename = nil
                }
                Button(PluginBranchLocalization.string("Rename")) {
                    renameBranch(branch)
                    branchToRename = nil
                }
                .disabled(renameBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
    }

    func upstreamSheet(_ branch: GitBranchSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PluginBranchLocalization.string("Set Upstream"))
                .font(.headline)
            Text(branch.name)
                .font(.caption)
                .foregroundColor(.secondary)
            Picker(PluginBranchLocalization.string("Upstream branch"), selection: $selectedUpstreamBranch) {
                ForEach(remoteBranches, id: \.self) { branchName in
                    Text(branchName).tag(branchName)
                }
            }
            HStack {
                Spacer()
                Button(PluginBranchLocalization.string("Cancel")) {
                    branchToSetUpstream = nil
                }
                Button(PluginBranchLocalization.string("Set")) {
                    setUpstream(branch, upstreamBranch: selectedUpstreamBranch)
                    branchToSetUpstream = nil
                }
                .disabled(selectedUpstreamBranch.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
    }
}
