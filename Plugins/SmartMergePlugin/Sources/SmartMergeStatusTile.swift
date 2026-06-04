import AppKit
import GitCoreKit
import GitOKCoreKit
import GitOKUI
import SwiftUI

public struct SmartMergeStatusTile: View {
    let projectURL: URL
    let isGitRepository: Bool
    @State private var isPresented = false

    public init(projectURL: URL, isGitRepository: Bool) {
        self.projectURL = projectURL
        self.isGitRepository = isGitRepository
    }

    public var body: some View {
        if isGitRepository {
            AppStatusBarTile(systemImage: "arrow.trianglehead.merge", action: {
                isPresented.toggle()
            })
            .help(SmartMergePluginLocalization.string("Merge branches"))
            .popover(isPresented: $isPresented) {
                SmartMergeForm(projectURL: projectURL)
                    .padding()
                    .frame(width: 240, height: 250)
            }
        }
    }
}

public struct SmartMergeForm: View {
    let projectURL: URL
    @State private var branches: [GitBranchSummary] = []
    @State private var sourceBranch: GitBranchSummary?
    @State private var targetBranch: GitBranchSummary?
    @State private var isWorking = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $sourceBranch) {
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }

            Text(SmartMergePluginLocalization.string("to"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            Picker("", selection: $targetBranch) {
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }

            AppButton(
                SmartMergePluginLocalization.string("Merge"),
                systemImage: "arrow.trianglehead.merge",
                style: .primary,
                fillsWidth: true,
                isLoading: isWorking
            ) {
                merge()
            }
            .disabled(sourceBranch == nil || targetBranch == nil || sourceBranch == targetBranch || isWorking)
        }
        .onAppear(perform: loadBranches)
    }

    private func loadBranches() {
        Task.detached(priority: .userInitiated) {
            do {
                let loadedBranches = try GitRepositoryCLI(repositoryURL: projectURL)
                    .branches()
                    .filter { $0.isRemote == false }

                await MainActor.run {
                    branches = loadedBranches
                    sourceBranch = loadedBranches.first(where: { $0.isCurrent == false }) ?? loadedBranches.first
                    targetBranch = loadedBranches.first(where: \.isCurrent) ?? loadedBranches.first
                }
            } catch {
                await MainActor.run {
                    showError(error, title: SmartMergePluginLocalization.string("Failed to load branches"))
                }
            }
        }
    }

    private func merge() {
        guard let sourceBranch, let targetBranch else { return }
        isWorking = true

        Task.detached {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).mergeBranches(
                    fromBranch: sourceBranch.name,
                    toBranch: targetBranch.name
                )
                await MainActor.run {
                    isWorking = false
                    showInfo(
                        String(
                            format: SmartMergePluginLocalization.string("Merged %@ into %@"),
                            sourceBranch.name,
                            targetBranch.name
                        )
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    showError(error, title: SmartMergePluginLocalization.string("Merge failed"))
                }
            }
        }
    }

    @MainActor
    private func showInfo(_ message: String) {
        let alert = NSAlert()
        alert.messageText = SmartMergePluginLocalization.string("Merge complete")
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    @MainActor
    private func showError(_ error: Error, title: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
