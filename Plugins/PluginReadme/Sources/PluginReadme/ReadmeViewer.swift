import GitOKCoreKit
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
                    ProgressView()
                        .controlSize(.small)
                }

                Button(PluginReadmeLocalization.string("Close")) {
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

    private var contentArea: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text(PluginReadmeLocalization.string("Loading document..."))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 300)
            } else if hasError || readmeContent.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(PluginReadmeLocalization.string("README.md not found"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(PluginReadmeLocalization.string("No README.md file found in the current project"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 300)
            } else {
                Markdown(readmeContent)
                    .markdownTheme(.gitHub)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
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
