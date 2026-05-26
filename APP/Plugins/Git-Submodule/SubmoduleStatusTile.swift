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
            Text("Submodule")
                .foregroundColor(.secondary)
        } else if issueCount > 0 {
            Text("Submodule \(issueCount)")
                .font(.footnote.weight(.medium))
                .foregroundColor(.orange)
                .monospacedDigit()
        } else {
            Text("Submodule \(submodules.count)")
                .font(.footnote.weight(.medium))
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }

    private var helpText: String {
        guard vm.project != nil else { return "未选择项目" }
        if submodules.isEmpty {
            return "当前仓库没有子模块"
        }
        if issueCount > 0 {
            return "发现 \(issueCount) 个需要处理的子模块"
        }
        return "共有 \(submodules.count) 个子模块"
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
                Text("Submodule")
                    .font(.headline)
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("初始化全部") {
                initializeSubmodules()
            }
            .disabled(vm.project == nil || submodules.isEmpty)

            Button("更新全部") {
                updateSubmodules()
            }
            .disabled(vm.project == nil || submodules.isEmpty)
        }
    }

    private var headerSubtitle: String {
        if submodules.isEmpty {
            return "未发现子模块"
        }
        if issueCount > 0 {
            return "\(submodules.count) 个子模块，\(issueCount) 个需要处理"
        }
        return "\(submodules.count) 个子模块状态正常"
    }

    private var emptyState: some View {
        Text("当前仓库没有配置 Git submodule。")
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

                Button("Diff") {
                    loadDiff(for: submodule.path)
                }
                .disabled(vm.project == nil)

                Button(submodule.status == .uninitialized ? "初始化" : "更新") {
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
                Text("Diff: \(path)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("关闭") {
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
                Text("当前子模块没有可显示的 diff 摘要。")
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
                    alert_info(paths.isEmpty ? "已初始化子模块" : "已初始化 \(paths[0])")
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
                    alert_info(paths.isEmpty ? "已更新子模块" : "已更新 \(paths[0])")
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
            return "已初始化"
        case .uninitialized:
            return "未初始化"
        case .modified:
            return "HEAD 与索引不一致"
        case .conflicted:
            return "存在冲突"
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
