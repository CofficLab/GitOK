import GitOKDesignKit
import SwiftUI

public struct OpenXcodeButton: View {
    let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            XcodeProjectLauncher.open(projectURL)
        } label: {
            Image.xcodeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
        }
        .help(OpenXcodePluginLocalization.string("Open in Xcode"))
    }
}
