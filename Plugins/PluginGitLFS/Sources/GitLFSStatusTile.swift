import AppKit
import GitCoreKit
import GitOKCoreKit
import SwiftUI

struct GitLFSStatusTile: View {
    let projectURL: URL
    @State private var status = GitRepositoryCLI.GitLFSStatus(isAvailable: false, version: nil)
    @State private var largeFiles: [GitRepositoryCLI.GitLFSLargeFileCandidate] = []
    @State private var mismatches: [GitRepositoryCLI.GitLFSAttributeMismatch] = []
    @State private var isLoading = false
    @State private var isPresented = false
    @State private var message: PluginGitLFSMessage?

    private let largeFileThresholdBytes: Int64 = 50 * 1024 * 1024

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 11))

                content
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(helpText)
        .popover(isPresented: $isPresented) {
            popoverContent
                .frame(width: 440, height: 420)
        }
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
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
            Text(PluginGitLFSLocalization.string("LFS"))
                .foregroundColor(.secondary)
        }
    }

    private var helpText: String {
        if issueCount > 0 {
            return String(
                format: PluginGitLFSLocalization.string("Found %d Git LFS suggestions or configuration issues"),
                issueCount
            )
        }
        return PluginGitLFSLocalization.string("LFS status normal")
    }

    private var popoverContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let message {
                messageView(message)
            }
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
                Text(PluginGitLFSLocalization.string("Git LFS"))
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(PluginGitLFSLocalization.string("Initialize")) {
                initializeLFS()
            }
        }
    }

    private var statusText: String {
        if status.isAvailable {
            if let version = status.version {
                return String(format: PluginGitLFSLocalization.string("Available, version %@"), version)
            }
            return PluginGitLFSLocalization.string("Available")
        }
        return PluginGitLFSLocalization.string("git-lfs not detected")
    }

    @ViewBuilder
    private var mismatchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(PluginGitLFSLocalization.string("Attribute mismatch"), count: mismatches.count)

            if mismatches.isEmpty {
                emptyText(PluginGitLFSLocalization.string("No mismatches between LFS pointers and .gitattributes"))
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
            sectionTitle(PluginGitLFSLocalization.string("Large File Recommendations"), count: largeFiles.count)

            if largeFiles.isEmpty {
                emptyText(
                    String(
                        format: PluginGitLFSLocalization.string("No candidate files larger than %@ found"),
                        formattedBytes(largeFileThresholdBytes)
                    )
                )
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

    private func messageView(_ message: PluginGitLFSMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: message.isError ? "exclamationmark.triangle" : "checkmark.circle")
                .foregroundColor(message.isError ? .red : .green)
            Text(message.text)
                .font(.caption)
                .foregroundColor(message.isError ? .red : .secondary)
            Spacer()
            Button(PluginGitLFSLocalization.string("Clear")) {
                self.message = nil
            }
            .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background((message.isError ? Color.red : Color.green).opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func refresh() {
        isLoading = true

        Task.detached(priority: .utility) {
            let cli = GitRepositoryCLI(repositoryURL: projectURL)

            do {
                let nextStatus = cli.lfsStatus()
                let nextLargeFiles = try cli.lfsLargeFileCandidates(thresholdBytes: largeFileThresholdBytes)
                let nextMismatches = try cli.lfsAttributeMismatches()

                await MainActor.run {
                    status = nextStatus
                    largeFiles = nextLargeFiles
                    mismatches = nextMismatches
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    largeFiles = []
                    mismatches = []
                    isLoading = false
                    message = PluginGitLFSMessage(text: error.localizedDescription, isError: true)
                }
            }
        }
    }

    private func initializeLFS() {
        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI(repositoryURL: projectURL).initializeLFS()
                await MainActor.run {
                    message = PluginGitLFSMessage(
                        text: PluginGitLFSLocalization.string("Git LFS initialized"),
                        isError: false
                    )
                    refresh()
                }
            } catch {
                await MainActor.run {
                    message = PluginGitLFSMessage(text: error.localizedDescription, isError: true)
                }
            }
        }
    }

    private func mismatchDescription(_ mismatch: GitRepositoryCLI.GitLFSAttributeMismatch) -> String {
        switch mismatch.kind {
        case .pointerWithoutLFSAttribute:
            return PluginGitLFSLocalization.string("LFS pointer in index without matching filter=lfs attribute")
        case .lfsAttributeWithoutPointer:
            return PluginGitLFSLocalization.string("LFS attribute matches but index is not an LFS pointer")
        }
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private struct PluginGitLFSMessage: Equatable {
    let text: String
    let isError: Bool
}
