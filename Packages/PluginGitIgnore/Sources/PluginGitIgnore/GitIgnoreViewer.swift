import GitOKPluginKit
import SwiftUI

struct GitIgnoreViewer: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isLoading = true
    @State private var hasError = false
    @State private var isApplyingTemplate = false
    @State private var isOrganizing = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                if isLoading {
                    loadingView
                } else if hasError || content.isEmpty {
                    emptyView
                } else {
                    ScrollView([.vertical, .horizontal]) {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: loadGitIgnore)
        .onChange(of: projectURL) {
            loadGitIgnore()
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.primary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(".gitignore")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let projectURL {
                        Text(projectURL.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                organizerControls

                Button(PluginGitIgnoreLocalization.string("Close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    private var organizerControls: some View {
        HStack(spacing: 8) {
            Menu {
                Button(GitIgnoreTemplate.xcode.title) {
                    applyTemplate(.xcode)
                }
                Button(GitIgnoreTemplate.flutter.title) {
                    applyTemplate(.flutter)
                }
            } label: {
                Label(PluginGitIgnoreLocalization.string("Add Ignore"), systemImage: "plus.circle")
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderedButton)
            .controlSize(.small)
            .fixedSize()
            .disabled(isApplyingTemplate || isOrganizing || isLoading || projectURL == nil)

            Button(PluginGitIgnoreLocalization.string("Organize Groups")) {
                organizeGitIgnore()
            }
            .controlSize(.small)
            .disabled(isApplyingTemplate || isOrganizing || isLoading || projectURL == nil)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(PluginGitIgnoreLocalization.string("Loading .gitignore..."))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(PluginGitIgnoreLocalization.string("No .gitignore file found"))
                .font(.headline)
                .foregroundColor(.secondary)
            Text(PluginGitIgnoreLocalization.string("No .gitignore file found in current project"))
                .font(.caption)
                .foregroundColor(.secondary)
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(hasError ? .red : .secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
    }

    private func loadGitIgnore() {
        guard let projectURL else {
            content = ""
            isLoading = false
            hasError = true
            return
        }

        isLoading = true
        hasError = false

        Task {
            do {
                let fileContent = try GitIgnoreDocument.read(in: projectURL)
                await MainActor.run {
                    content = fileContent
                    isLoading = false
                    hasError = false
                }
            } catch {
                await MainActor.run {
                    content = ""
                    isLoading = false
                    hasError = true
                }
            }
        }
    }

    private func applyTemplate(_ template: GitIgnoreTemplate) {
        guard let projectURL else { return }

        isApplyingTemplate = true
        statusMessage = nil

        Task {
            do {
                let existing = (try? GitIgnoreDocument.read(in: projectURL)) ?? ""
                let merged = GitIgnoreOrganizer.merge(existing: existing, template: template)
                try GitIgnoreDocument.write(merged, in: projectURL)

                await MainActor.run {
                    content = merged
                    isLoading = false
                    hasError = false
                    isApplyingTemplate = false
                    statusMessage = String(format: PluginGitIgnoreLocalization.string("%@ has been added"), template.header)
                }
            } catch {
                await MainActor.run {
                    isApplyingTemplate = false
                    statusMessage = String(format: PluginGitIgnoreLocalization.string("Failed to write .gitignore: %@"), error.localizedDescription)
                    hasError = true
                }
            }
        }
    }

    private func organizeGitIgnore() {
        guard let projectURL else { return }

        isOrganizing = true
        statusMessage = nil

        Task {
            do {
                let existing = (try? GitIgnoreDocument.read(in: projectURL)) ?? ""
                let organized = GitIgnoreOrganizer.organize(existing: existing)
                try GitIgnoreDocument.write(organized, in: projectURL)

                await MainActor.run {
                    content = organized
                    isOrganizing = false
                    isLoading = false
                    hasError = false
                    statusMessage = PluginGitIgnoreLocalization.string("Organized and grouped")
                }
            } catch {
                await MainActor.run {
                    isOrganizing = false
                    statusMessage = String(format: PluginGitIgnoreLocalization.string("Organize failed: %@"), error.localizedDescription)
                    hasError = true
                }
            }
        }
    }
}
