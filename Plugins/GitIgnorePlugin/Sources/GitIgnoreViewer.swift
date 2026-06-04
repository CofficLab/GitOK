import GitOKCoreKit
import GitOKUI
import SwiftUI

struct GitIgnoreViewer: View {
    let projectURL: URL
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isLoading = true
    @State private var hasError = false
    @State private var isApplyingTemplate = false
    @State private var isOrganizing = false
    @State private var statusMessage: String?

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

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

                    Text(projectURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if isLoading {
                    AppLoadingOverlay(size: .small)
                        .frame(width: 28, height: 28)
                }

                organizerControls

                AppButton(
                    GitIgnorePluginLocalization.string("Close"),
                    style: .secondary,
                    size: .small
                ) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .gitOKUISurface(style: .toolbar, cornerRadius: 0)
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
                AppContextMenuRow(GitIgnoreTemplate.xcode.title, systemImage: "hammer") {
                    applyTemplate(.xcode)
                }
                AppContextMenuRow(GitIgnoreTemplate.flutter.title, systemImage: "iphone.gen3") {
                    applyTemplate(.flutter)
                }
            } label: {
                Label(GitIgnorePluginLocalization.string("Add Ignore"), systemImage: "plus.circle")
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderedButton)
            .controlSize(.small)
            .fixedSize()
            .disabled(isApplyingTemplate || isOrganizing || isLoading)

            AppButton(
                GitIgnorePluginLocalization.string("Organize Groups"),
                systemImage: "line.3.horizontal.decrease.circle",
                style: .secondary,
                size: .small,
                isLoading: isOrganizing
            ) {
                organizeGitIgnore()
            }
            .disabled(isApplyingTemplate || isOrganizing || isLoading)
        }
    }

    private var loadingView: some View {
        AppLoadingOverlay(message: GitIgnorePluginLocalization.string("Loading .gitignore..."), size: .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 300)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            AppEmptyState(
                icon: "doc.text.below.ecg",
                title: GitIgnorePluginLocalization.string("No .gitignore file found"),
                description: GitIgnorePluginLocalization.string("No .gitignore file found in current project")
            )
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
                    statusMessage = String(format: GitIgnorePluginLocalization.string("%@ has been added"), template.header)
                }
            } catch {
                await MainActor.run {
                    isApplyingTemplate = false
                    statusMessage = String(format: GitIgnorePluginLocalization.string("Failed to write .gitignore: %@"), error.localizedDescription)
                    hasError = true
                }
            }
        }
    }

    private func organizeGitIgnore() {
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
                    statusMessage = GitIgnorePluginLocalization.string("Organized and grouped")
                }
            } catch {
                await MainActor.run {
                    isOrganizing = false
                    statusMessage = String(format: GitIgnorePluginLocalization.string("Organize failed: %@"), error.localizedDescription)
                    hasError = true
                }
            }
        }
    }
}
