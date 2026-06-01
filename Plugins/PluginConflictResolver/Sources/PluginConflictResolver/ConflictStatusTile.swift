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
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isMerging ? "exclamationmark.triangle.fill" : "checkmark.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isMerging ? .red : .secondary)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(isMerging ? PluginConflictResolverLocalization.string("Conflicts \(conflictCount)") : PluginConflictResolverLocalization.string("Merge OK"))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(isMerging ? .red : .secondary)
                        .monospacedDigit()
                }
            }
            .frame(height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                format: PluginConflictResolverLocalization.string("There are %d conflicted files. Click to resolve them."),
                conflictCount
            )
        }
        return PluginConflictResolverLocalization.string("No merge conflicts")
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
