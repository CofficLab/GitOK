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
    @State private var statusMessage: String?
    @State private var errorMessage: String?

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
            .disabled(isWorking)

            Text(SmartMergePluginLocalization.string("to"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            Picker("", selection: $targetBranch) {
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }
            .disabled(isWorking)

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

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
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
                    errorMessage = String(
                        format: "%@: %@",
                        SmartMergePluginLocalization.string("Failed to load branches"),
                        error.localizedDescription
                    )
                }
            }
        }
    }

    private func merge() {
        guard let sourceBranch, let targetBranch else { return }
        isWorking = true
        statusMessage = nil
        errorMessage = nil
        let operationTitle = String(
            format: SmartMergePluginLocalization.string("Merging %@ into %@"),
            sourceBranch.name,
            targetBranch.name
        )
        let operationID = BlockingOperationCenter.shared.begin(
            title: SmartMergePluginLocalization.string("Merging branches"),
            message: operationTitle,
            detail: SmartMergePluginLocalization.string("Large branch merges may take a while. Please keep GitOK open.")
        )

        Task.detached {
            let repository = GitRepositoryCLI(repositoryURL: projectURL)
            do {
                await MainActor.run {
                    BlockingOperationCenter.shared.update(
                        id: operationID,
                        message: String(format: SmartMergePluginLocalization.string("Switching to %@"), targetBranch.name),
                        detail: operationTitle
                    )
                }

                await MainActor.run {
                    BlockingOperationCenter.shared.update(
                        id: operationID,
                        message: String(format: SmartMergePluginLocalization.string("Merging %@"), sourceBranch.name),
                        detail: SmartMergePluginLocalization.string("GitOK is updating the repository. Other actions are temporarily blocked.")
                    )
                }
                let longMergeStatusUpdates = Self.beginLongMergeStatusUpdates(
                    operationID: operationID,
                    sourceBranchName: sourceBranch.name,
                    targetBranchName: targetBranch.name
                )
                defer { longMergeStatusUpdates.cancel() }

                try await GitOperationHelperClient.shared.mergeBranches(
                    repositoryURL: projectURL,
                    sourceBranch: sourceBranch.name,
                    targetBranch: targetBranch.name
                )

                await MainActor.run {
                    BlockingOperationCenter.shared.update(
                        id: operationID,
                        message: SmartMergePluginLocalization.string("Checking merge result"),
                        detail: SmartMergePluginLocalization.string("Refreshing repository state after merge.")
                    )
                }
                let conflictCount = (try? repository.getMergeConflictFiles().count) ?? 0

                await MainActor.run {
                    BlockingOperationCenter.shared.end(id: operationID)
                    isWorking = false
                    if conflictCount > 0 {
                        errorMessage = String(
                            format: SmartMergePluginLocalization.string("Merge paused with %d conflict files"),
                            conflictCount
                        )
                    } else {
                        statusMessage = String(
                            format: SmartMergePluginLocalization.string("Merged %@ into %@"),
                            sourceBranch.name,
                            targetBranch.name
                        )
                    }
                }
            } catch {
                let conflictCount = (try? repository.getMergeConflictFiles().count) ?? 0
                await MainActor.run {
                    BlockingOperationCenter.shared.end(id: operationID)
                    isWorking = false
                    if conflictCount > 0 {
                        errorMessage = String(
                            format: SmartMergePluginLocalization.string("Merge paused with %d conflict files"),
                            conflictCount
                        )
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    nonisolated private static func beginLongMergeStatusUpdates(
        operationID: UUID,
        sourceBranchName: String,
        targetBranchName: String
    ) -> Task<Void, Never> {
        Task {
            let updates: [(UInt64, String, String)] = [
                (
                    8_000_000_000,
                    String(format: SmartMergePluginLocalization.string("Still merging %@ into %@"), sourceBranchName, targetBranchName),
                    SmartMergePluginLocalization.string("The helper is still working on this merge. Large conflict sets can take several minutes.")
                ),
                (
                    17_000_000_000,
                    SmartMergePluginLocalization.string("Still working through a large merge"),
                    SmartMergePluginLocalization.string("GitOK is waiting for the helper process to finish. The app is blocked to protect the repository.")
                ),
                (
                    35_000_000_000,
                    SmartMergePluginLocalization.string("Large merge still in progress"),
                    SmartMergePluginLocalization.string("This can happen when thousands of files changed or conflicts need to be prepared. Please wait.")
                ),
            ]

            for (delay, message, detail) in updates {
                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch {
                    return
                }
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    BlockingOperationCenter.shared.update(id: operationID, message: message, detail: detail)
                }
            }
        }
    }
}
