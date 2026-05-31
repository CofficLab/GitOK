import GitCoreKit
import GitOKPluginKit
import SwiftUI

public struct BranchStatusTile: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @Environment(\.gitOKBranchName) private var branchName
    @Environment(\.gitOKIsGitRepository) private var isGitRepository
    @State private var isPresented = false

    public init() {}

    public var body: some View {
        if projectURL != nil, isGitRepository {
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
                BranchManagementView()
                    .frame(width: 560, height: 640)
            }
        }
    }

    private var displayBranchName: String {
        guard let branchName, branchName.isEmpty == false else {
            return PluginBranchLocalization.string("No Branch")
        }
        return branchName
    }
}
