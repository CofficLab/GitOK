import GitOKCoreKit
import GitCoreKit
import SwiftUI

public struct BranchPickerView: View {
    let context: GitBranchPluginContext
    @Environment(\.branchMonitor) private var monitor
    @Environment(\.branchService) private var service
    @State private var branches: [GitBranchSummary] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    nonisolated public init(context: GitBranchPluginContext) {
        self.context = context
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(.secondary)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if let currentBranch = monitor?.branchName {
                Menu {
                    if branches.isEmpty {
                        Text(GitBranchPluginLocalization.string("No Branch"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(branches) { branch in
                            Button {
                                checkout(branch)
                            } label: {
                                HStack {
                                    Text(branch.name)
                                    if branch.name == currentBranch {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Text(currentBranch)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .disabled(branches.isEmpty)
            } else {
                Text(GitBranchPluginLocalization.string("No Branch"))
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize()
        .onAppear(perform: loadBranches)
        .onChange(of: context.projectURL) { _, _ in loadBranches() }
        .onChange(of: context.isGitRepository) { _, _ in loadBranches() }
        .help(errorMessage ?? GitBranchPluginLocalization.string("Switch Branch"))
    }

    private func loadBranches() {
        guard let service, context.projectURL != nil, context.isGitRepository else {
            branches = []
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedBranches = try service.branches()
                await MainActor.run {
                    branches = loadedBranches
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    branches = []
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func checkout(_ branch: GitBranchSummary) {
        guard let service, let monitor else { return }

        let branchName = branch.name
        errorMessage = nil

        Task {
            do {
                try service.checkoutBranch(named: branchName)
                await MainActor.run {
                    monitor.refresh()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
