import GitOKDesignKit
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
            Image.kiroApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenKiroPluginLocalization.string("Open in Kiro"))
    }
}
