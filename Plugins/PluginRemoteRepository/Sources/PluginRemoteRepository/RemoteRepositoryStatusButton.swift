import GitOKPluginKit
import SwiftUI

public struct RemoteRepositoryStatusButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @Environment(\.gitOKIsGitRepository) private var isGitRepository
    @State private var showRemoteManagement = false

    public init() {}

    public var body: some View {
        if projectURL != nil, isGitRepository {
            Button {
                showRemoteManagement = true
            } label: {
                Image(systemName: "network")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(PluginRemoteRepositoryLocalization.string("Manage Remote Repositories"))
            .sheet(isPresented: $showRemoteManagement) {
                RemoteRepositoryView()
            }
        }
    }
}
