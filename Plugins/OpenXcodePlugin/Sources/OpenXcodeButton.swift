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
            Image(systemName: "hammer")
                .frame(width: 24)
        }
        .help(OpenXcodePluginLocalization.string("Open in Xcode"))
    }
}
