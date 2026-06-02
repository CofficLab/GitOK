import GitOKDesignKit
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
            Image.antigravityApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenAntigravityPluginLocalization.string("Open in Antigravity"))
    }
}
