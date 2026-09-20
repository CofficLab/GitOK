import Foundation
import MarkdownUI
import SwiftUI

/// Displays a project's root README as formatted Markdown when one is available.
public struct ProjectReadmeView: View {
    private let projectURL: URL
    @State private var document: ReadmeDocument?

    private static let markdownTheme: Theme = {
        var theme = Theme.gitHub
        theme.text = FontSize(16)
        return theme
    }()

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let document {
                Label(document.url.lastPathComponent, systemImage: "doc.text")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Markdown(
                    document.markdown,
                    baseURL: document.url.deletingLastPathComponent()
                )
                    .markdownTheme(Self.markdownTheme)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(document == nil ? 0 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if document != nil {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.35))
            }
        }
        .task(id: projectURL.standardizedFileURL) {
            document = nil
            let rootURL = projectURL
            let loadedDocument = await Task.detached(priority: .utility) {
                Self.loadReadme(in: rootURL)
            }.value
            guard !Task.isCancelled else { return }
            document = loadedDocument
        }
    }

    nonisolated private static func loadReadme(in projectURL: URL) -> ReadmeDocument? {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let readmeNames = ["readme.md", "readme.markdown", "readme.mdown"]
        let candidate = files
            .filter { readmeNames.contains($0.lastPathComponent.lowercased()) }
            .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .sorted {
                let lhs = readmeNames.firstIndex(of: $0.lastPathComponent.lowercased()) ?? .max
                let rhs = readmeNames.firstIndex(of: $1.lastPathComponent.lowercased()) ?? .max
                if lhs != rhs { return lhs < rhs }
                return $0.lastPathComponent < $1.lastPathComponent
            }
            .first

        guard let candidate,
              let markdown = try? String(contentsOf: candidate, encoding: .utf8) else {
            return nil
        }
        return ReadmeDocument(url: candidate, markdown: markdown)
    }
}

private struct ReadmeDocument: Sendable {
    let url: URL
    let markdown: String
}
