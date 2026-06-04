import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenVSCodeButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            VSCodeProjectLauncher.open(projectURL)
        }) {
            Image.vscodeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenVSCodePluginLocalization.string("Open in VS Code"))
    }
}
