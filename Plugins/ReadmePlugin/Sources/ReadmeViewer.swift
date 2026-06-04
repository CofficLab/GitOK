import GitOKCoreKit
import GitOKUI
import ProjectSupportKit
import SwiftUI

struct ReadmeViewer: View {
    let projectURL: URL
    @Environment(\.dismiss) private var dismiss

    @State private var readmeContent = ""
    @State private var isLoading = true
    @State private var hasError = false

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            contentArea
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: loadReadme)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("README.md")
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

                AppButton(
                    ReadmePluginLocalization.string("Close"),
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

    private var contentArea: some View {
        ScrollView {
            if isLoading {
                AppLoadingOverlay(message: ReadmePluginLocalization.string("Loading document..."), size: .large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 300)
            } else if hasError || readmeContent.isEmpty {
                AppEmptyState(
                    icon: "doc.text.below.ecg",
                    title: ReadmePluginLocalization.string("README.md not found"),
                    description: ReadmePluginLocalization.string("No README.md file found in the current project")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 300)
            } else {
                Text(renderedReadme)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
    }

    private var renderedReadme: AttributedString {
        (try? AttributedString(markdown: readmeContent)) ?? AttributedString(readmeContent)
    }

    private func loadReadme() {
        isLoading = true
        hasError = false

        Task {
            do {
                let content = try ProjectDocumentResolver.readReadmeContent(in: projectURL)
                await MainActor.run {
                    readmeContent = content
                    isLoading = false
                    hasError = false
                }
            } catch {
                await MainActor.run {
                    readmeContent = ""
                    isLoading = false
                    hasError = true
                }
            }
        }
    }
}
