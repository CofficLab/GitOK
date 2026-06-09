import GitCoreKit
import GitOKCoreKit
import SwiftUI

public struct BranchStatusTile: View {
    let context: BranchPluginContext
    @State private var isPresented = false
    @State private var fallbackBranchName: String?
    @State private var isLoadingBranch = false
    @State private var refreshGeneration = 0

    public init(context: BranchPluginContext) {
        self.context = context
    }

    public var body: some View {
        if context.projectURL != nil, context.isGitRepository {
            AppStatusBarTile(systemImage: "arrow.branch", action: {
                isPresented.toggle()
            }) {
                Text(displayBranchName)
                    .lineLimit(1)
            }
            .help(BranchPluginLocalization.string("Manage Branches"))
            .popover(isPresented: $isPresented) {
                BranchManagementView(context: context)
                    .frame(width: 560, height: 640)
            }
            .onAppear(perform: refreshFallbackBranch)
            .onChange(of: context.projectURL) { _, _ in refreshFallbackBranch() }
            .onChange(of: context.branchName) { _, _ in refreshFallbackBranch() }
            .onChange(of: context.isGitRepository) { _, _ in refreshFallbackBranch() }
        }
    }

    private var displayBranchName: String {
        if let branchName = context.branchName, branchName.isEmpty == false {
            return branchName
        }

        if let fallbackBranchName, fallbackBranchName.isEmpty == false {
            return fallbackBranchName
        }

        if context.projectURL != nil, context.isGitRepository, isLoadingBranch {
            return BranchPluginLocalization.string("Loading Branch")
        }

        return BranchPluginLocalization.string("No Branch")
    }

    private func refreshFallbackBranch() {
        refreshGeneration += 1
        let generation = refreshGeneration

        if let branchName = context.branchName, branchName.isEmpty == false {
            fallbackBranchName = branchName
            isLoadingBranch = false
            return
        }

        guard let projectURL = context.projectURL, context.isGitRepository else {
            fallbackBranchName = nil
            isLoadingBranch = false
            return
        }

        isLoadingBranch = true
        Task.detached(priority: .utility) {
            let branchName = try? GitRepositoryCLI(repositoryURL: projectURL).currentBranchName()
            guard Task.isCancelled == false else { return }

            await MainActor.run {
                guard generation == refreshGeneration else { return }
                fallbackBranchName = branchName
                isLoadingBranch = false
            }
        }
    }
}
