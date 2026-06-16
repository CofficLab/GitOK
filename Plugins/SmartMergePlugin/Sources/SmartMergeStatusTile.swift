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
            .help(Localization.string("Merge branches"))
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

    @AppStorage private var lastSourceBranchName: String
    @AppStorage private var lastTargetBranchName: String

    public init(projectURL: URL) {
        self.projectURL = projectURL
        let storageKey = "SmartMergePlugin.lastMerge.\(projectURL.absoluteString)"
        _lastSourceBranchName = AppStorage(wrappedValue: "", "\(storageKey).source")
        _lastTargetBranchName = AppStorage(wrappedValue: "", "\(storageKey).target")
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $sourceBranch) {
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }
            .disabled(isWorking)

            Text(Localization.string("to"))
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
                Localization.string("Merge"),
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
                    // Restore last selected branches if they still exist
                    let savedSource = lastSourceBranchName
                    let savedTarget = lastTargetBranchName
                    if !savedSource.isEmpty,
                       let restored = loadedBranches.first(where: { $0.name == savedSource }) {
                        sourceBranch = restored
                    } else {
                        sourceBranch = loadedBranches.first(where: { $0.isCurrent == false }) ?? loadedBranches.first
                    }
                    if !savedTarget.isEmpty,
                       let restored = loadedBranches.first(where: { $0.name == savedTarget }) {
                        targetBranch = restored
                    } else {
                        targetBranch = loadedBranches.first(where: \.isCurrent) ?? loadedBranches.first
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(
                        format: "%@: %@",
                        Localization.string("Failed to load branches"),
                        error.localizedDescription
                    )
                }
            }
        }
    }

    private func merge() {
        guard let sourceBranch, let targetBranch else { return }
        // Save the user's branch selection for next time
        lastSourceBranchName = sourceBranch.name
        lastTargetBranchName = targetBranch.name
        isWorking = true
        statusMessage = nil
        errorMessage = nil
        let operationTitle = String(
            format: Localization.string("Merging %@ into %@"),
            sourceBranch.name,
            targetBranch.name
        )
        let operationID = BlockingOperationCenter.shared.begin(
            title: Localization.string("Merging branches"),
            message: operationTitle,
            detail: Localization.string("Large branch merges may take a while. Please keep GitOK open.")
        )

        Task.detached {
            let repository = GitRepositoryCLI(repositoryURL: projectURL)
            do {
                await MainActor.run {
                    BlockingOperationCenter.shared.update(
                        id: operationID,
                        message: String(format: Localization.string("Switching to %@"), targetBranch.name),
                        detail: operationTitle
                    )
                }

                await MainActor.run {
                    BlockingOperationCenter.shared.update(
                        id: operationID,
                        message: String(format: Localization.string("Merging %@"), sourceBranch.name),
                        detail: Localization.string("GitOK is updating the repository. Other actions are temporarily blocked.")
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
                        message: Localization.string("Checking merge result"),
                        detail: Localization.string("Refreshing repository state after merge.")
                    )
                }
                try? repository.finalizeMergeIfNeeded()
                let conflictCount = (try? repository.getMergeConflictFiles().count) ?? 0

                await MainActor.run {
                    BlockingOperationCenter.shared.end(id: operationID)
                    isWorking = false
                    if conflictCount > 0 {
                        errorMessage = String(
                            format: Localization.string("Merge paused with %d conflict files"),
                            conflictCount
                        )
                    } else {
                        statusMessage = String(
                            format: Localization.string("Merged %@ into %@"),
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
                            format: Localization.string("Merge paused with %d conflict files"),
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
                    String(format: Localization.string("Still merging %@ into %@"), sourceBranchName, targetBranchName),
                    Localization.string("The helper is still working on this merge. Large conflict sets can take several minutes.")
                ),
                (
                    17_000_000_000,
                    Localization.string("Still working through a large merge"),
                    Localization.string("GitOK is waiting for the helper process to finish. The app is blocked to protect the repository.")
                ),
                (
                    35_000_000_000,
                    Localization.string("Large merge still in progress"),
                    Localization.string("This can happen when thousands of files changed or conflicts need to be prepared. Please wait.")
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
