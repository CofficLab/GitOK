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
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(PluginOpenXcodeLocalization.string("Open in Xcode"))
    }
}
