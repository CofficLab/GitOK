import SwiftUI

public struct OpenAntigravityButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            AntigravityProjectLauncher.open(projectURL)
        } label: {
            Image(systemName: "paperplane")
                .frame(width: 24)
        }
        .help(OpenAntigravityPluginLocalization.string("Open in Antigravity"))
    }
}
