import GitOKDesignKit
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
            Image.vscodeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenVSCodePluginLocalization.string("Open in VS Code"))
    }
}
