import GitOKCoreKit
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
            AppStatusBarTile(systemImage: "network", action: {
                showRemoteManagement = true
            })
            .help(RemoteRepositoryPluginLocalization.string("Manage Remote Repositories"))
            .sheet(isPresented: $showRemoteManagement) {
                RemoteRepositoryView(projectURL: projectURL)
            }
        }
    }
}
