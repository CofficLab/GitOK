import GitCoreKit
import SwiftUI

public struct BranchStatusTile: View {
    let context: BranchPluginContext
    @State private var isPresented = false

    public init(context: BranchPluginContext) {
        self.context = context
    }

    public var body: some View {
        if context.projectURL != nil, context.isGitRepository {
            Button {
                isPresented.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.branch")
                    Text(displayBranchName)
                        .lineLimit(1)
                }
                .font(.footnote)
                .frame(height: 22)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginBranchLocalization.string("Manage Branches"))
            .popover(isPresented: $isPresented) {
                BranchManagementView(context: context)
                    .frame(width: 560, height: 640)
            }
        }
    }

    private var displayBranchName: String {
        guard let branchName = context.branchName, branchName.isEmpty == false else {
            return PluginBranchLocalization.string("No Branch")
        }
        return branchName
    }
}
