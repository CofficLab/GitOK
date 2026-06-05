import GitOKCoreKit
import GitCoreKit
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
    @State private var refreshTask: Task<Void, Never>?
    @State private var diffTask: Task<Void, Never>?
    @State private var initializeTask: Task<Void, Never>?
    @State private var updateTask: Task<Void, Never>?

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        AppStatusBarTile(systemImage: iconName, action: {
            isPresented.toggle()
        }) {
            content
        }
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
        .onDisappear(perform: onDisappear)
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
            AppLoadingOverlay(size: .small)
                .frame(width: 24, height: 20)
        } else if submodules.isEmpty {
            Text(SubmodulePluginLocalization.string("Submodule"))
                .foregroundStyle(.secondary)
        } else if issueCount > 0 {
            Text("\(SubmodulePluginLocalization.string("Submodule")) \(issueCount)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.orange)
                .monospacedDigit()
        } else {
            Text("\(SubmodulePluginLocalization.string("Submodule")) \(submodules.count)")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var helpText: String {
        if submodules.isEmpty {
            return SubmodulePluginLocalization.string("No submodules in this repository")
        }
        if issueCount > 0 {
            return SubmodulePluginLocalization.string("Found %lld submodules that need attention", issueCount)
        }
        return SubmodulePluginLocalization.string("%lld submodules total", submodules.count)
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
                AppErrorBanner(message: errorMessage)
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
                Text(SubmodulePluginLocalization.string("Submodule"))
                    .font(.headline)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AppButton(SubmodulePluginLocalization.string("Initialize All"), systemImage: "square.and.arrow.down", style: .secondary, size: .small) {
                initializeSubmodules()
            }
            .disabled(submodules.isEmpty)

            AppButton(SubmodulePluginLocalization.string("Update All"), systemImage: "arrow.triangle.2.circlepath", style: .secondary, size: .small) {
                updateSubmodules()
            }
            .disabled(submodules.isEmpty)
        }
    }

    private var headerSubtitle: String {
        if submodules.isEmpty {
            return SubmodulePluginLocalization.string("No submodules found")
        }
        if issueCount > 0 {
            return SubmodulePluginLocalization.string("%lld submodules, %lld need attention", submodules.count, issueCount)
        }
        return SubmodulePluginLocalization.string("%lld submodules are up to date", submodules.count)
    }

    private var emptyState: some View {
        AppEmptyState(
            icon: "shippingbox",
            title: SubmodulePluginLocalization.string("Submodule"),
            description: SubmodulePluginLocalization.string("No Git submodules configured in this repository.")
        )
        .frame(minHeight: 160)
    }

    private func submoduleRow(_ submodule: GitRepositoryCLI.GitSubmodule) -> some View {
        AppSettingsRow(verticalPadding: 8) {
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

                AppButton(SubmodulePluginLocalization.string("Diff"), systemImage: "doc.text.magnifyingglass", style: .tonal, size: .small) {
                    loadDiff(for: submodule.path)
                }

                AppButton(
                    submodule.status == .uninitialized ? SubmodulePluginLocalization.string("Initialize") : SubmodulePluginLocalization.string("Update"),
                    systemImage: submodule.status == .uninitialized ? "square.and.arrow.down" : "arrow.triangle.2.circlepath",
                    style: .secondary,
                    size: .small
                ) {
                    if submodule.status == .uninitialized {
                        initializeSubmodules(paths: [submodule.path])
                    } else {
                        updateSubmodules(paths: [submodule.path])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func diffSection(path: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(SubmodulePluginLocalization.string("Diff: %@", path))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                AppButton(SubmodulePluginLocalization.string("Close"), systemImage: "xmark", style: .ghost, size: .small) {
                    diffPath = nil
                    diffText = nil
                }
            }

            if isDiffLoading {
                AppLoadingOverlay(message: SubmodulePluginLocalization.string("Loading..."), size: .small)
                    .frame(height: 60)
            } else if let diffText, diffText.isEmpty == false {
                Text(diffText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(SubmodulePluginLocalization.string("No diff summary available for this submodule."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func refresh() {
        refreshTask?.cancel()
        isLoading = true
        refreshTask = Task.detached(priority: .utility) {
            do {
                let nextSubmodules = try GitRepositoryCLI(repositoryURL: projectURL).submodules()
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    submodules = nextSubmodules
                    isLoading = false
                    errorMessage = nil
                    refreshTask = nil
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    submodules = []
                    isLoading = false
                    errorMessage = nil
                    refreshTask = nil
                }
            }
        }
    }

    private func initializeSubmodules(paths: [String] = []) {
        initializeTask?.cancel()
        initializeTask = Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).initializeSubmodules(paths: paths)
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    initializeTask = nil
                    message = paths.isEmpty ? SubmodulePluginLocalization.string("Submodule initialized") : SubmodulePluginLocalization.string("Initialized %@", paths[0])
                    errorMessage = nil
                    refresh()
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    initializeTask = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func updateSubmodules(paths: [String] = []) {
        updateTask?.cancel()
        updateTask = Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).updateSubmodules(paths: paths)
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    updateTask = nil
                    message = paths.isEmpty ? SubmodulePluginLocalization.string("Submodules updated") : SubmodulePluginLocalization.string("Updated %@", paths[0])
                    errorMessage = nil
                    refresh()
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    updateTask = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadDiff(for path: String) {
        diffTask?.cancel()
        diffPath = path
        diffText = nil
        isDiffLoading = true

        diffTask = Task.detached(priority: .utility) {
            do {
                let output = try GitRepositoryCLI(repositoryURL: projectURL).submoduleDiff(path: path)
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    diffText = output
                    isDiffLoading = false
                    diffTask = nil
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    diffText = error.localizedDescription
                    isDiffLoading = false
                    diffTask = nil
                }
            }
        }
    }

    private func onDisappear() {
        refreshTask?.cancel()
        diffTask?.cancel()
        initializeTask?.cancel()
        updateTask?.cancel()
        refreshTask = nil
        diffTask = nil
        initializeTask = nil
        updateTask = nil
        isLoading = false
        isDiffLoading = false
        submodules.removeAll()
        diffPath = nil
        diffText = nil
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
