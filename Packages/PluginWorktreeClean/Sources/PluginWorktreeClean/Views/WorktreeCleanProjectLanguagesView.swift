import LumiUI
import ProviderContentView
import ProviderProjectLanguages
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// GitHub-style language bar for the current project's tracked source files.
struct WorktreeCleanProjectLanguagesView: View {
    @ObservedObject var viewModel: WorktreeCleanProjectLanguagesViewModel
    @LumiTheme private var theme

    private let maximumVisibleLanguages = 6

    var body: some View {
        Group {
            if let snapshot = viewModel.snapshot, !snapshot.languages.isEmpty {
                languageSection(snapshot: snapshot)
            } else if viewModel.isLoading {
                loadingSection
            }
        }
    }

    private func languageSection(snapshot: ProjectLanguagesSnapshot) -> some View {
        let languages = displayLanguages(from: snapshot)
        return AppSettingSection(title: loc("Languages"), titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        ForEach(languages) { language in
                            Rectangle()
                                .fill(color(for: language.id))
                                .frame(width: proxy.size.width * snapshot.percentage(for: language.source))
                        }
                    }
                }
                .frame(height: 10)
                .clipShape(Capsule())

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(languages) { language in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(color(for: language.id))
                                .frame(width: 8, height: 8)
                            Text(language.name)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer(minLength: 4)
                            Text(percentageText(snapshot.percentage(for: language.source)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var loadingSection: some View {
        AppSettingSection(title: loc("Languages"), titleAlignment: .leading) {
            HStack(spacing: 8) {
                ContentLoadingIndicator(loc("Loading project languages..."), controlSize: .small)
                    .tint(theme.primary)
                Text(loc("Analyzing tracked source files..."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func displayLanguages(from snapshot: ProjectLanguagesSnapshot) -> [DisplayLanguage] {
        let visible = snapshot.languages.prefix(maximumVisibleLanguages).map {
            DisplayLanguage(source: $0)
        }
        let visibleBytes = visible.reduce(Int64(0)) { $0 + $1.source.byteCount }
        let otherBytes = snapshot.totalByteCount - visibleBytes
        guard otherBytes > 0 else { return Array(visible) }

        return Array(visible) + [
            DisplayLanguage(
                id: "other",
                name: loc("Other"),
                byteCount: otherBytes,
                source: nil
            ),
        ]
    }

    private func percentageText(_ percentage: Double) -> String {
        String(format: "%.1f%%", percentage * 100)
    }

    private func color(for id: String) -> Color {
        switch id {
        case "swift": return .orange
        case "objective-c", "objective-cpp": return .pink
        case "cpp", "c": return .blue
        case "python": return .yellow
        case "javascript", "jsx": return .yellow
        case "typescript", "tsx": return .blue
        case "rust": return .brown
        case "go": return .cyan
        case "java", "kotlin": return .red
        case "ruby": return .red
        case "html", "xml": return .orange
        case "css", "scss": return .purple
        case "markdown": return .gray
        case "json", "yaml", "toml": return .teal
        case "shell": return .green
        default: return theme.primary
        }
    }

    private struct DisplayLanguage: Identifiable {
        let id: String
        let name: String
        let source: ProjectLanguage

        init(source: ProjectLanguage) {
            self.id = source.id
            self.name = source.name
            self.source = source
        }

        init(id: String, name: String, byteCount: Int64, source: ProjectLanguage?) {
            self.id = id
            self.name = name
            self.source = source ?? ProjectLanguage(id: id, name: name, byteCount: byteCount)
        }
    }
}
