import GitOKCoreKit
import GitCoreKit
import SwiftUI

public struct BranchPickerView: View {
    let context: BranchPluginContext
    @Environment(\.branchService) private var service
    @State private var branches: [GitBranchSummary] = []
    @State private var selection: GitBranchSummary?
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var refreshGeneration = 0

    nonisolated public init(context: BranchPluginContext) {
        self.context = context
    }

    public var body: some View {
        Picker(BranchPluginLocalization.string("Branch"), selection: $selection) {
            if branches.isEmpty, isRefreshing {
                Text(BranchPluginLocalization.string("Loading Branch"))
                    .tag(nil as GitBranchSummary?)
            } else if branches.isEmpty {
                Text(BranchPluginLocalization.string("No Branch"))
                    .tag(nil as GitBranchSummary?)
            } else {
                ForEach(branches) { branch in
                    Text(branch.name)
                        .tag(branch as GitBranchSummary?)
                }
            }
        }
        .disabled(context.projectURL == nil || !context.isGitRepository || branches.isEmpty || isRefreshing)
        .onAppear(perform: refreshBranches)
        .onChange(of: context.projectURL) { _, _ in refreshBranches() }
        .onChange(of: context.branchName) { _, _ in refreshBranches() }
        .onChange(of: context.isGitRepository) { _, _ in refreshBranches() }
        .onChange(of: selection) { _, branch in
            guard let branch, branch.name != context.branchName else { return }
            checkout(branch)
        }
        .help(errorMessage ?? BranchPluginLocalization.string("Switch Branch"))
    }

    private func refreshBranches() {
        refreshGeneration += 1
        let generation = refreshGeneration

        guard let service, context.projectURL != nil, context.isGitRepository else {
            branches = []
            selection = nil
            isRefreshing = false
            return
        }

        isRefreshing = true
        errorMessage = nil
        let currentBranchName = context.branchName
        Task.detached(priority: .userInitiated) {
            do {
                let loadedBranches = try service.branches()
                await MainActor.run {
                    guard generation == refreshGeneration else { return }
                    branches = loadedBranches
                    selection = BranchLogic.selectCurrentBranch(in: loadedBranches)
                        ?? BranchLogic.selectBranch(named: currentBranchName, in: loadedBranches)
                        ?? loadedBranches.first
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    guard generation == refreshGeneration else { return }
                    branches = []
                    selection = nil
                    errorMessage = error.localizedDescription
                    isRefreshing = false
                }
            }
        }
    }

    private func checkout(_ branch: GitBranchSummary) {
        guard let service else { return }
        let branchName = branch.name
        isRefreshing = true
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try service.checkoutBranch(named: branchName)
                await MainActor.run {
                    refreshBranches()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRefreshing = false
                    refreshBranches()
                }
            }
        }
    }
}
