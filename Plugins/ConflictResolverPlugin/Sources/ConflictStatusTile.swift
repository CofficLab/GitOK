import GitOKCoreKit
import GitCoreKit
import SwiftUI

public struct ConflictStatusTile: View {
    let projectURL: URL
    let isGitRepository: Bool
    @State private var conflictCount = 0
    @State private var isLoading = false
    @State private var isMerging = false
    @State private var isPresented = false

    public init(projectURL: URL, isGitRepository: Bool) {
        self.projectURL = projectURL
        self.isGitRepository = isGitRepository
    }

    public var body: some View {
        AppStatusBarTile(
            systemImage: isMerging ? "exclamationmark.triangle.fill" : "checkmark.circle",
            tint: isMerging ? .red : .secondary,
            action: {
                isPresented.toggle()
            }
        ) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(isMerging ? ConflictResolverPluginLocalization.string("Conflicts \(conflictCount)") : ConflictResolverPluginLocalization.string("Merge OK"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(isMerging ? .red : .secondary)
                    .monospacedDigit()
            }
        }
        .help(helpText)
        .popover(isPresented: $isPresented) {
            ConflictResolverList(projectURL: projectURL)
                .frame(width: 720, height: 640)
        }
        .onAppear(perform: loadConflictStatus)
    }

    private var helpText: String {
        if isMerging {
            return String(
                format: ConflictResolverPluginLocalization.string("There are %d conflicted files. Click to resolve them."),
                conflictCount
            )
        }
        return ConflictResolverPluginLocalization.string("No merge conflicts")
    }

    private func loadConflictStatus() {
        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                let merging = try repository.isMerging()
                let conflicts = merging ? try repository.getMergeConflictFiles() : []

                await MainActor.run {
                    conflictCount = conflicts.count
                    isMerging = merging
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    conflictCount = 0
                    isMerging = false
                    isLoading = false
                }
            }
        }
    }
}
