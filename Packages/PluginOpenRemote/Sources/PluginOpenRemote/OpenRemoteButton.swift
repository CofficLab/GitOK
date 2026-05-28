import AppKit
import GitOKPluginKit
import SwiftUI

public struct OpenRemoteButton: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @State private var webURL: URL?
    @State private var loadTask: Task<Void, Never>?

    nonisolated public init() {}

    public var body: some View {
        Group {
            if let webURL {
                Button {
                    NSWorkspace.shared.open(webURL)
                } label: {
                    Image(systemName: "link")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(PluginOpenRemoteLocalization.string("Open in Browser"))
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

    @MainActor
    private func reloadWebURL() async {
        loadTask?.cancel()

        guard let projectURL else {
            webURL = nil
            return
        }

        let task = Task {
            await OpenRemoteURLProvider.webURL(for: projectURL)
        }
        loadTask = Task {
            let nextURL = await task.value
            await MainActor.run {
                webURL = nextURL
            }
        }
        await loadTask?.value
    }
}
