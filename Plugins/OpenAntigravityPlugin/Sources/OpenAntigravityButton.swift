import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenAntigravityButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(action: {
            AntigravityProjectLauncher.open(projectURL)
        }) {
            Image.antigravityApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenAntigravityPluginLocalization.string("Open in Antigravity"))
    }
}
