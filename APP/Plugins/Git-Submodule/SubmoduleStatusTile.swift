import GitCoreKit
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

struct SubmoduleStatusTile: View, SuperLog {
    nonisolated static let emoji = "📦"
    nonisolated static let verbose = false

    @EnvironmentObject var vm: ProjectVM

    @State private var submodules: [GitRepositoryCLI.GitSubmodule] = []
    @State private var isLoading = false
    @State private var isPresented = false
    @State private var diffPath: String?
    @State private var diffText: String?
    @State private var isDiffLoading = false

    var body: some View {
        StatusBarTile(icon: iconName, onTap: {
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
        .onChange(of: vm.project, refresh)
        .onApplicationDidBecomeActive {
            refresh()
        }
        .onProjectGitIndexDidChange { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            refresh()
        }
        .onProjectGitHeadDidChange { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            refresh()
        }
    }

    private var issueCount: Int {
        submodules.filter { $0.status != .initialized }.count
    }

    private var iconName: String {
        issueCount > 0 ? "shippingbox.fill" : "shippingbox"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if submodules.isEmpty {
            Text(String(localized: "Submodule", table: "GitSubmodule"))
                .foregroundColor(.secondary)
        } else if issueCount > 0 {
            Text(String(localized: "Submodule \(issueCount)", table: "GitSubmodule"))
                .font(.footnote.weight(.medium))
                .foregroundColor(.orange)
                .monospacedDigit()
        } else {
            Text(String(localized: "Submodule \(submodules.count)", table: "GitSubmodule"))
                .font(.footnote.weight(.medium))
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }

    private var helpText: String {
        guard vm.project != nil else { return String(localized: "No project selected") }
        if submodules.isEmpty {
            return String(localized: "No submodules in this repository")
        }
        if issueCount > 0 {
            return String(localized: "Found \(issueCount) submodules that need attention")
        }
        return String(localized: "\(submodules.count) submodules total")
    }

    private var popoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
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
                .foregroundColor(issueCount > 0 ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Submodule", table: "GitSubmodule"))
                    .font(.headline)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(String(localized: "Initialize All")) {
                initializeSubmodules()
            }
            .disabled(vm.project == nil || submodules.isEmpty)

            Button(String(localized: "Update All")) {
                updateSubmodules()
            }
            .disabled(vm.project == nil || submodules.isEmpty)
        }
    }

    private var headerSubtitle: String {
        if submodules.isEmpty {
            return String(localized: "No submodules found")
        }
        if issueCount > 0 {
            return String(localized: "\(submodules.count) submodules, \(issueCount) need attention")
        }
        return String(localized: "\(submodules.count) submodules are up to date")
    }

    private var emptyState: some View {
        Text(String(localized: "No Git submodules configured in this repository."))
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func submoduleRow(_ submodule: GitRepositoryCLI.GitSubmodule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: statusIcon(for: submodule.status))
                    .foregroundColor(statusColor(for: submodule.status))
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(submodule.path)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(rowSubtitle(for: submodule))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(String(localized: "Diff", table: "GitSubmodule")) {
                    loadDiff(for: submodule.path)
                }
                .disabled(vm.project == nil)

                Button(submodule.status == .uninitialized ? String(localized: "Initialize") : String(localized: "Update")) {
                    if submodule.status == .uninitialized {
                        initializeSubmodules(paths: [submodule.path])
                    } else {
                        updateSubmodules(paths: [submodule.path])
                    }
                }
                .disabled(vm.project == nil)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func diffSection(path: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Diff: \(path)", table: "GitSubmodule"))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(String(localized: "Close", table: "GitSubmodule")) {
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
                Text(String(localized: "No diff summary available for this submodule."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func refresh() {
        guard let project = vm.project, project.isGitRepo else {
            submodules = []
            isLoading = false
            return
        }

        isLoading = true
        let repositoryURL = project.url

        Task.detached(priority: .utility) {
            let start = Date()
            let cli = GitRepositoryCLI(repositoryURL: repositoryURL)

            do {
                let nextSubmodules = try cli.submodules()
                await MainActor.run {
                    os_log("\(Self.t)✅ Refreshed submodules elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
                    submodules = nextSubmodules
                    isLoading = false
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t) Failed to refresh submodules: \(error.localizedDescription)")
                }
                await MainActor.run {
                    submodules = []
                    isLoading = false
                }
            }
        }
    }

    private func initializeSubmodules(paths: [String] = []) {
        guard let project = vm.project else { return }
        let repositoryURL = project.url

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: repositoryURL).initializeSubmodules(paths: paths)
                await MainActor.run {
                    alert_info(paths.isEmpty ? String(localized: "Submodule initialized") : String(localized: "Initialized \(paths[0])"))
                    refresh()
                }
            } catch {
                await MainActor.run {
                    alert_error(error)
                }
            }
        }
    }

    private func updateSubmodules(paths: [String] = []) {
        guard let project = vm.project else { return }
        let repositoryURL = project.url

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: repositoryURL).updateSubmodules(paths: paths)
                await MainActor.run {
                    alert_info(paths.isEmpty ? String(localized: "Submodules updated") : String(localized: "Updated \(paths[0])"))
                    refresh()
                }
            } catch {
                await MainActor.run {
                    alert_error(error)
                }
            }
        }
    }

    private func loadDiff(for path: String) {
        guard let project = vm.project else { return }
        let repositoryURL = project.url

        diffPath = path
        diffText = nil
        isDiffLoading = true

        Task.detached(priority: .utility) {
            do {
                let output = try GitRepositoryCLI(repositoryURL: repositoryURL).submoduleDiff(path: path)
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

    private func rowSubtitle(for submodule: GitRepositoryCLI.GitSubmodule) -> String {
        let shortHash = String(submodule.commitHash.prefix(8))
        let description = submodule.description.map { " · \($0)" } ?? ""
        return "\(statusText(for: submodule.status)) · \(shortHash)\(description)"
    }

    private func statusText(for status: GitRepositoryCLI.GitSubmodule.Status) -> String {
        switch status {
        case .initialized:
            return String(localized: "Initialized")
        case .uninitialized:
            return String(localized: "Uninitialized")
        case .modified:
            return String(localized: "HEAD differs from index")
        case .conflicted:
            return String(localized: "Conflicted")
        }
    }

    private func statusIcon(for status: GitRepositoryCLI.GitSubmodule.Status) -> String {
        switch status {
        case .initialized:
            return "checkmark.circle"
        case .uninitialized:
            return "tray.and.arrow.down"
        case .modified:
            return "arrow.triangle.2.circlepath"
        case .conflicted:
            return "exclamationmark.triangle"
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
