import SwiftUI

public struct OpenVSCodeButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            VSCodeProjectLauncher.open(projectURL)
        } label: {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .frame(width: 24)
        }
        .help(OpenVSCodePluginLocalization.string("Open in VS Code"))
    }
}
