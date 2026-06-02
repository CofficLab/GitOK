import SwiftUI

public struct RemoteRepositoryStatusButton: View {
    let projectURL: URL
    let isGitRepository: Bool
    @State private var showRemoteManagement = false

    public init(projectURL: URL, isGitRepository: Bool) {
        self.projectURL = projectURL
        self.isGitRepository = isGitRepository
    }

    public var body: some View {
        if isGitRepository {
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
                RemoteRepositoryView(projectURL: projectURL)
            }
        }
    }
}
