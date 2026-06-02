import SwiftUI

public struct OpenKiroButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            KiroProjectLauncher.open(projectURL)
        } label: {
            Image(systemName: "water.waves")
                .frame(width: 24)
        }
        .help(OpenKiroPluginLocalization.string("Open in Kiro"))
    }
}
