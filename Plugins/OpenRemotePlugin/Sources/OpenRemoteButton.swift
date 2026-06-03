import AppKit
import SwiftUI

public struct OpenRemoteButton: View {
    let projectURL: URL
    @State private var webURL: URL?
    @State private var browserIcon: NSImage?
    @State private var loadTask: Task<Void, Never>?

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Group {
            if let webURL {
                Button {
                    NSWorkspace.shared.open(webURL)
                } label: {
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
        if let browserIcon {
            Image(nsImage: browserIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: "link")
                .frame(width: 22, height: 22)
        }
    }

    @MainActor
    private func reloadWebURL() async {
        loadTask?.cancel()

        let task = Task {
            await OpenRemoteURLProvider.webURL(for: projectURL)
        }
        loadTask = Task {
            let nextURL = await task.value
            await MainActor.run {
                webURL = nextURL
                browserIcon = nextURL.flatMap(Self.browserIcon)
            }
        }
        await loadTask?.value
    }

    private static func browserIcon(for webURL: URL) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: webURL) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
