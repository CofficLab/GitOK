import AppKit
import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 冲突文件列表：展示合并中的冲突文件，可复制路径或定位到 Finder。
public struct ConflictResolverList: View {
    let projects: any ProjectProviding
    @State private var files: [String] = []
    @State private var isLoading = true
    @State private var selectedFile: String?

    public init(projects: any ProjectProviding) {
        self.projects = projects
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if isLoading {
                        ProgressView("Checking conflicts…")
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if files.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(theme.success)
                            Text("No merge conflicts")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(files, id: \.self) { file in
                            conflictRow(file)
                        }
                    }
                }
            }
        }
        .padding(16)
        .onAppear(perform: load)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Conflict Resolution")
                .font(.headline)
            Text(files.isEmpty ? "No conflicted files" : "\(files.count) conflicted file(s)")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
    }

    private func conflictRow(_ file: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(theme.warning)
            Text(file)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            AppIconButton(systemImage: "doc.on.doc", label: "Copy Path", tint: theme.textSecondary) {
                copyText(file)
            }
            AppIconButton(systemImage: "folder", label: "Reveal in Finder", tint: theme.textSecondary) {
                reveal(file)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            selectedFile = file
        }
    }

    @MainActor
    private func load() {
        guard let url = projects.currentProject?.url else {
            files = []
            isLoading = false
            return
        }
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let loaded = GitMergeOperation.conflictFiles(in: url)
            await MainActor.run {
                files = loaded
                isLoading = false
            }
        }
    }

    private func copyText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func reveal(_ file: String) {
        guard let url = projects.currentProject?.url else { return }
        let target = url.appendingPathComponent(file)
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }

    @LumiTheme private var theme: LumiUITheme
}
