import GitOKCoreKit
import SwiftUI

public struct BranchStatusTile: View {
    let context: BranchPluginContext
    @State private var isPresented = false

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
        }
    }

    private var displayBranchName: String {
        guard let branchName = context.branchName, branchName.isEmpty == false else {
            return BranchPluginLocalization.string("No Branch")
        }
        return branchName
    }
}
