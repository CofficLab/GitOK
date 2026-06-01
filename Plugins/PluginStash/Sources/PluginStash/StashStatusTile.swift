import GitOKCoreKit
import SwiftUI

public struct StashStatusTile: View {
    let projectURL: URL?

    @State private var stashCount = 0
    @State private var isLoading = false
    @State private var isPresented = false
    @State private var refreshToken = 0

    public init(projectURL: URL?) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "archivebox")
                    .font(.system(size: 11, weight: .semibold))
                content
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(helpText)
        .popover(isPresented: $isPresented) {
            StashListView(projectURL: projectURL, refreshToken: refreshToken) {
                refresh()
            }
            .frame(width: 460, height: 540)
        }
        .onAppear(perform: refresh)
        .onChange(of: projectURL) { _, _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .pluginStashAppDidBecomeActive)) { _ in
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginStashProjectDidCommit)) { _ in
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginStashProjectGitStashDidChange)) { _ in
            refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if stashCount > 0 {
            Text("\(PluginStashLocalization.string("Stash")) \(stashCount)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.blue)
                .monospacedDigit()
        } else {
            Text(PluginStashLocalization.string("Stash"))
                .foregroundStyle(.secondary)
        }
    }

    private var helpText: String {
        guard projectURL != nil else { return PluginStashLocalization.string("No project selected") }
        if stashCount > 0 {
            return PluginStashLocalization.string("View %lld stashes", stashCount)
        }
        return PluginStashLocalization.string("No stashes, click to open panel")
    }

    private func refresh() {
        refreshToken += 1

        guard let projectURL else {
            stashCount = 0
            isLoading = false
            return
        }

        isLoading = true
        Task {
            do {
                let stashes = try await Task.detached(priority: .utility) {
                    try GitRepositoryCLI(repositoryURL: projectURL).stashList()
                }.value
                stashCount = stashes.count
                isLoading = false
            } catch {
                stashCount = 0
                isLoading = false
            }
        }
    }
}
