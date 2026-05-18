import GitCoreKit
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

struct GitLFSStatusTile: View, SuperLog {
    nonisolated static let emoji = "🧱"
    nonisolated static let verbose = false

    @EnvironmentObject var vm: ProjectVM

    @State private var status = GitRepositoryCLI.GitLFSStatus(isAvailable: false, version: nil)
    @State private var largeFiles: [GitRepositoryCLI.GitLFSLargeFileCandidate] = []
    @State private var mismatches: [GitRepositoryCLI.GitLFSAttributeMismatch] = []
    @State private var isLoading = false
    @State private var isPresented = false

    private let largeFileThresholdBytes: Int64 = 50 * 1024 * 1024

    var body: some View {
        StatusBarTile(icon: iconName, onTap: {
            isPresented.toggle()
        }) {
            content
        }
        .help(helpText)
        .popover(isPresented: $isPresented) {
            popoverContent
                .frame(width: 440, height: 420)
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
        largeFiles.count + mismatches.count
    }

    private var iconName: String {
        issueCount > 0 ? "externaldrive.badge.exclamationmark" : "externaldrive"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if issueCount > 0 {
            Text("LFS \(issueCount)")
                .font(.footnote.weight(.medium))
                .foregroundColor(.orange)
                .monospacedDigit()
        } else {
            Text("LFS")
                .foregroundColor(.secondary)
        }
    }

    private var helpText: String {
        guard vm.project != nil else { return "未选择项目" }
        if issueCount > 0 {
            return "发现 \(issueCount) 个 Git LFS 建议或配置问题"
        }
        return "Git LFS 状态正常"
    }

    private var popoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    mismatchSection
                    largeFileSection
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
                Text("Git LFS")
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("初始化") {
                initializeLFS()
            }
            .disabled(vm.project == nil)
        }
    }

    private var statusText: String {
        if status.isAvailable {
            if let version = status.version {
                return "可用，版本 \(version)"
            }
            return "可用"
        }
        return "未检测到 git-lfs"
    }

    @ViewBuilder
    private var mismatchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Attribute mismatch", count: mismatches.count)

            if mismatches.isEmpty {
                emptyText("未发现 LFS pointer 与 .gitattributes 不一致")
            } else {
                ForEach(mismatches, id: \.path) { mismatch in
                    issueRow(
                        icon: "exclamationmark.triangle",
                        title: mismatch.path,
                        subtitle: mismatchDescription(mismatch)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var largeFileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("大文件建议", count: largeFiles.count)

            if largeFiles.isEmpty {
                emptyText("未发现超过 \(formattedBytes(largeFileThresholdBytes)) 的候选文件")
            } else {
                ForEach(largeFiles, id: \.path) { file in
                    issueRow(
                        icon: "doc.badge.plus",
                        title: file.path,
                        subtitle: formattedBytes(file.byteSize)
                    )
                }
            }
        }
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func issueRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func refresh() {
        guard let project = vm.project, project.isGitRepo else {
            status = GitRepositoryCLI.GitLFSStatus(isAvailable: false, version: nil)
            largeFiles = []
            mismatches = []
            isLoading = false
            return
        }

        isLoading = true
        let repositoryURL = project.url

        Task.detached(priority: .utility) {
            let start = Date()
            let cli = GitRepositoryCLI(repositoryURL: repositoryURL)

            do {
                let nextStatus = cli.lfsStatus()
                let nextLargeFiles = try cli.lfsLargeFileCandidates(thresholdBytes: largeFileThresholdBytes)
                let nextMismatches = try cli.lfsAttributeMismatches()

                await MainActor.run {
                    os_log("\(Self.t)✅ Refreshed Git LFS status elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
                    status = nextStatus
                    largeFiles = nextLargeFiles
                    mismatches = nextMismatches
                    isLoading = false
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t) Failed to refresh Git LFS status: \(error.localizedDescription)")
                }
                await MainActor.run {
                    largeFiles = []
                    mismatches = []
                    isLoading = false
                }
            }
        }
    }

    private func initializeLFS() {
        guard let project = vm.project else { return }
        let repositoryURL = project.url

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: repositoryURL).initializeLFS()
                await MainActor.run {
                    alert_info("Git LFS 已初始化")
                    refresh()
                }
            } catch {
                await MainActor.run {
                    alert_error(error)
                }
            }
        }
    }

    private func mismatchDescription(_ mismatch: GitRepositoryCLI.GitLFSAttributeMismatch) -> String {
        switch mismatch.kind {
        case .pointerWithoutLFSAttribute:
            return "索引中是 LFS pointer，但当前属性未匹配 filter=lfs"
        case .lfsAttributeWithoutPointer:
            return "当前属性匹配 filter=lfs，但索引中不是 LFS pointer"
        }
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
