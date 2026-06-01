import GitOKCoreKit
import SwiftUI

public struct SubmoduleStatusTile: View {
    let projectURL: URL

    @State private var submodules: [GitRepositoryCLI.GitSubmodule] = []
    @State private var isLoading = false
    @State private var isPresented = false
    @State private var diffPath: String?
    @State private var diffText: String?
    @State private var isDiffLoading = false
    @State private var message: String?
    @State private var errorMessage: String?

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconName)
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
            popoverContent
                .frame(width: 500, height: 500)
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: .pluginSubmoduleAppDidBecomeActive)) { _ in
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginSubmoduleProjectGitHeadDidChange)) { _ in
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pluginSubmoduleProjectGitIndexDidChange)) { _ in
            refresh()
        }
    }

    private var issueCount: Int {
        SubmodulePresentation.issueCount(submodules)
    }

    private var iconName: String {
        SubmodulePresentation.iconName(issueCount: issueCount)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if submodules.isEmpty {
            Text(PluginSubmoduleLocalization.string("Submodule"))
                .foregroundStyle(.secondary)
        } else if issueCount > 0 {
            Text("\(PluginSubmoduleLocalization.string("Submodule")) \(issueCount)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
                .monospacedDigit()
        } else {
            Text("\(PluginSubmoduleLocalization.string("Submodule")) \(submodules.count)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var helpText: String {
        if submodules.isEmpty {
            return PluginSubmoduleLocalization.string("No submodules in this repository")
        }
        if issueCount > 0 {
            return PluginSubmoduleLocalization.string("Found %lld submodules that need attention", issueCount)
        }
        return PluginSubmoduleLocalization.string("%lld submodules total", submodules.count)
    }

    private var popoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if submodules.isEmpty {
                        emptyState
                    } else {
                        ForEach(submodules, id: \.path) { submodule in
                            submoduleRow(submodule)
                        }
                    }

                    if let diffPath {
                        Divider()
                        diffSection(path: diffPath)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(issueCount > 0 ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(PluginSubmoduleLocalization.string("Submodule"))
                    .font(.headline)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(PluginSubmoduleLocalization.string("Initialize All")) {
                initializeSubmodules()
            }
            .disabled(submodules.isEmpty)

            Button(PluginSubmoduleLocalization.string("Update All")) {
                updateSubmodules()
            }
            .disabled(submodules.isEmpty)
        }
    }

    private var headerSubtitle: String {
        if submodules.isEmpty {
            return PluginSubmoduleLocalization.string("No submodules found")
        }
        if issueCount > 0 {
            return PluginSubmoduleLocalization.string("%lld submodules, %lld need attention", submodules.count, issueCount)
        }
        return PluginSubmoduleLocalization.string("%lld submodules are up to date", submodules.count)
    }

    private var emptyState: some View {
        Text(PluginSubmoduleLocalization.string("No Git submodules configured in this repository."))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func submoduleRow(_ submodule: GitRepositoryCLI.GitSubmodule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: SubmodulePresentation.statusIcon(for: submodule.status))
                    .foregroundStyle(statusColor(for: submodule.status))
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(submodule.path)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(SubmodulePresentation.rowSubtitle(for: submodule))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(PluginSubmoduleLocalization.string("Diff")) {
                    loadDiff(for: submodule.path)
                }

                Button(submodule.status == .uninitialized ? PluginSubmoduleLocalization.string("Initialize") : PluginSubmoduleLocalization.string("Update")) {
                    if submodule.status == .uninitialized {
                        initializeSubmodules(paths: [submodule.path])
                    } else {
                        updateSubmodules(paths: [submodule.path])
                    }
                }
                .disabled(projectURL == nil)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func diffSection(path: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(PluginSubmoduleLocalization.string("Diff: %@", path))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(PluginSubmoduleLocalization.string("Close")) {
                    diffPath = nil
                    diffText = nil
                }
            }

            if isDiffLoading {
                ProgressView()
                    .controlSize(.small)
            } else if let diffText, diffText.isEmpty == false {
                Text(diffText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(PluginSubmoduleLocalization.string("No diff summary available for this submodule."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func refresh() {
        isLoading = true
        Task.detached(priority: .utility) {
            do {
                let nextSubmodules = try GitRepositoryCLI(repositoryURL: projectURL).submodules()
                await MainActor.run {
                    submodules = nextSubmodules
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    submodules = []
                    isLoading = false
                    errorMessage = nil
                }
            }
        }
    }

    private func initializeSubmodules(paths: [String] = []) {
        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).initializeSubmodules(paths: paths)
                await MainActor.run {
                    message = paths.isEmpty ? PluginSubmoduleLocalization.string("Submodule initialized") : PluginSubmoduleLocalization.string("Initialized %@", paths[0])
                    errorMessage = nil
                    refresh()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func updateSubmodules(paths: [String] = []) {
        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).updateSubmodules(paths: paths)
                await MainActor.run {
                    message = paths.isEmpty ? PluginSubmoduleLocalization.string("Submodules updated") : PluginSubmoduleLocalization.string("Updated %@", paths[0])
                    errorMessage = nil
                    refresh()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadDiff(for path: String) {
        diffPath = path
        diffText = nil
        isDiffLoading = true

        Task.detached(priority: .utility) {
            do {
                let output = try GitRepositoryCLI(repositoryURL: projectURL).submoduleDiff(path: path)
                await MainActor.run {
                    diffText = output
                    isDiffLoading = false
                }
            } catch {
                await MainActor.run {
                    diffText = error.localizedDescription
                    isDiffLoading = false
                }
            }
        }
    }

    private func statusColor(for status: GitRepositoryCLI.GitSubmodule.Status) -> Color {
        switch status {
        case .initialized:
            return .secondary
        case .uninitialized, .modified:
            return .orange
        case .conflicted:
            return .red
        }
    }
}
