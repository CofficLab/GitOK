#if os(macOS)
import AppKit
#endif
import Combine
import LumiUI
import ProviderProjectLanguages
import ProviderProjectReadme
import ProviderProjects
import SwiftUI

/// 当前项目目录不是 Git 仓库时的项目概览。
///
/// 复用 Git 项目干净工作区概览里的语言统计与 README，只隐藏依赖 Git 的区块
/// （提交热力图、分支、标签、远程仓库与 Git 用户配置）。
@MainActor
struct NotGitRepositoryView: View {
    let project: Project
    /// 延迟解析 README 提供者：Project README 插件晚于根视图插件启动。
    let readmeProvider: () -> (any ProjectReadmeProviding)?
    /// 延迟解析语言统计提供者：Project Languages 插件晚于根视图插件启动。
    let languagesProvider: () -> (any ProjectLanguagesProviding)?
    let onRemoveProject: () -> Void

    @LumiTheme private var theme
    @State private var readmeView: AnyView?
    @StateObject private var languagesModel = ProjectLanguagesOverviewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                languagesSection
                readmeSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surface)
        .accessibilityIdentifier("gitok.notGit.root")
        .task(id: project.url) {
            loadOverview()
        }
        .onDisappear {
            languagesModel.stop()
        }
    }

    // MARK: - Header

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            wideHeader
            compactHeader
        }
    }

    private var wideHeader: some View {
        HStack(alignment: .top, spacing: AppUI.Spacing.md) {
            projectIcon

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: AppUI.Spacing.sm) {
                    projectTitle
                    statusTag
                }
                projectPath
            }

            Spacer(minLength: AppUI.Spacing.sm)

            headerActions
        }
    }

    /// 窄窗口下把状态标签与操作移到路径下方，避免项目名被截成几个字符。
    private var compactHeader: some View {
        HStack(alignment: .top, spacing: AppUI.Spacing.md) {
            projectIcon

            VStack(alignment: .leading, spacing: 6) {
                projectTitle
                projectPath

                HStack(spacing: AppUI.Spacing.sm) {
                    statusTag
                    Spacer(minLength: AppUI.Spacing.sm)
                    headerActions
                }
                .padding(.top, 2)
            }
        }
    }

    private var projectIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.textSecondary.opacity(0.08))

            Image(systemName: "folder.fill")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(theme.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.warning)
                .background(Circle().fill(theme.surface).padding(1))
                .offset(x: 3, y: 3)
        }
        .frame(width: 56, height: 56)
    }

    private var projectTitle: some View {
        Text(project.title)
            .font(.appTitle)
            .foregroundStyle(theme.textPrimary)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    private var projectPath: some View {
        Text(project.url.path)
            .font(.appMonoCaption)
            .foregroundStyle(theme.textSecondary)
            .lineLimit(2)
            .truncationMode(.middle)
            .textSelection(.enabled)
    }

    private var statusTag: some View {
        AppTag(
            pluginLocalization.string("Not a Git Repository"),
            systemImage: "exclamationmark.triangle.fill"
        )
    }

    private var headerActions: some View {
        HStack(spacing: AppUI.Spacing.xs) {
            AppIconButton(systemImage: "doc.on.doc") {
                copyProjectPath()
            }
            .help(pluginLocalization.string("Copy Project Path"))
            .accessibilityLabel(pluginLocalization.string("Copy Project Path"))
            .accessibilityIdentifier("gitok.notGit.copyPath")

            AppButton(
                pluginLocalization.string("Remove from Project List"),
                systemImage: "trash",
                style: .ghost,
                size: .small
            ) {
                onRemoveProject()
            }
            .accessibilityIdentifier("gitok.notGit.remove")
        }
    }

    // MARK: - Languages

    @ViewBuilder
    private var languagesSection: some View {
        if let snapshot = languagesModel.snapshot, !snapshot.languages.isEmpty {
            AppSettingSection(
                title: pluginLocalization.string("Languages"),
                titleAlignment: .leading
            ) {
                languageBar(snapshot)
            }
        } else if languagesModel.isLoading {
            AppSettingSection(
                title: pluginLocalization.string("Languages"),
                titleAlignment: .leading
            ) {
                loadingPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(theme.textSecondary.opacity(0.12))
                .frame(height: 10)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(theme.textSecondary.opacity(0.10))
                        .frame(height: 12)
                }
            }
        }
    }

    private func languageBar(_ snapshot: ProjectLanguagesSnapshot) -> some View {
        let languages = displayLanguages(from: snapshot)
        return VStack(alignment: .leading, spacing: 12) {
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

    private func displayLanguages(from snapshot: ProjectLanguagesSnapshot) -> [DisplayLanguage] {
        let visible = snapshot.languages.prefix(6).map { DisplayLanguage(source: $0) }
        let visibleBytes = visible.reduce(Int64(0)) { $0 + $1.source.byteCount }
        let otherBytes = snapshot.totalByteCount - visibleBytes
        guard otherBytes > 0 else { return Array(visible) }

        return Array(visible) + [
            DisplayLanguage(
                id: "other",
                name: pluginLocalization.string("Other"),
                byteCount: otherBytes
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

        init(id: String, name: String, byteCount: Int64) {
            self.id = id
            self.name = name
            self.source = ProjectLanguage(id: id, name: name, byteCount: byteCount)
        }
    }

    // MARK: - README

    @ViewBuilder
    private var readmeSection: some View {
        if let readmeView {
            readmeView
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private func loadOverview() {
        readmeView = nil
        languagesModel.start(provider: languagesProvider(), url: project.url)

        if let readmeProvider = readmeProvider() {
            readmeView = readmeProvider.makeReadmeView(for: project.url)
        }
    }

    private func copyProjectPath() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(project.url.path, forType: .string)
        #endif
    }
}

/// 观察当前项目的语言统计；普通文件夹同样适用。
@MainActor
private final class ProjectLanguagesOverviewModel: ObservableObject {
    @Published private(set) var snapshot: ProjectLanguagesSnapshot?
    @Published private(set) var isLoading = false

    private weak var provider: (any ProjectLanguagesProviding)?
    private var handle: (any ProjectLanguagesObserverHandle)?

    func start(provider: (any ProjectLanguagesProviding)?, url: URL) {
        stop()
        guard let provider else { return }
        self.provider = provider
        handle = provider.addObserver { [weak self] _ in
            self?.sync()
        }
        // 插件通常已经在项目选择时刷新过；仅在缺少当前目录结果时补一次，
        // 避免对大型普通文件夹重复扫描。
        if provider.currentSnapshot?.repositoryPath != url.standardizedFileURL.path,
           !provider.isLoading {
            provider.refresh(for: url)
        }
        sync()
    }

    func stop() {
        handle?.cancel()
        handle = nil
        provider = nil
    }

    private func sync() {
        snapshot = provider?.currentSnapshot
        isLoading = provider?.isLoading ?? false
    }
}
