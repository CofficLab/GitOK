import GitOKDesignKit
import GitOKUI
import SwiftUI

public struct OpenRemoteButton: View {
    let projectURL: URL
    @State private var webURL: URL?
    @State private var loadTask: Task<Void, Never>?

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Group {
            if let webURL {
                AppStatusBarTile(action: {
                    NSWorkspace.shared.open(webURL)
                }) {
                    buttonIcon
                }
                .help(OpenRemotePluginLocalization.string("Open in Browser"))
            } else {
                Color.clear
                    .frame(width: 24, height: 24)
            }
        }
        .task(id: projectURL) {
            await reloadWebURL()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    @ViewBuilder
    private var buttonIcon: some View {
        Image.defaultBrowserApp
            .resizable()
            .frame(height: 22)
            .frame(width: 22)
    }

    @MainActor
    private func reloadWebURL() async {
        loadTask?.cancel()

        loadTask = Task.detached(priority: .utility) {
            let nextURL = await OpenRemoteURLProvider.webURL(for: projectURL)
            guard Task.isCancelled == false else { return }

            await MainActor.run {
                webURL = nextURL
                loadTask = nil
            }
        }
        await loadTask?.value
    }
}
