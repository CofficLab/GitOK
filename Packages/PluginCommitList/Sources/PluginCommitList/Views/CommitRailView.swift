import KitGit
import LumiUI
import ProviderCommitDetail
import ProviderProjects
import SwiftUI

/// Commit 列表 Rail 视图：显示当前打开项目的提交历史。
///
/// 作为 Rail 注入根布局（位于侧边栏右侧、内容区左侧）。订阅
/// `ProjectProviding` 的观察者事件；`currentProject` 变化时异步读取
/// 该仓库的 commit 列表（后台线程执行 git CLI，主线程更新）。
///
/// 行点击时把选中的 commit 写入 `CommitDetailProviding`，主内容区
/// （PluginCommitDetail）据此展示该 commit 的变动。
///
/// 视觉对齐旧版 GitOK 的 commit 行布局（message / 作者 + 相对时间 /
/// 完整日期），并使用 LumiUI 组件（AppToolbarContainer / AppListRow /
/// AppEmptyState / AppDivider）保证与整体设计语言一致。
struct CommitRailView: View {
    let projects: any ProjectProviding
    let detail: any CommitDetailProviding
    @StateObject private var observation: ProjectObservationModel

    @State private var commits: [GitCommit] = []
    @State private var isLoading = false
    @State private var loadedProjectURL: URL?
    @State private var loadError: String?

    init(projects: any ProjectProviding, detail: any CommitDetailProviding) {
        self.projects = projects
        self.detail = detail
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            AppDivider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color(nsColor: .underPageBackgroundColor)
        }
        .onReceive(observation.$revision) { _ in reloadIfNeeded() }
        .onAppear { reloadIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        AppToolbarContainer(
            height: 32,
            padding: EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        ) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.appCaptionEmphasized)
                Text("Commits")
                    .font(.appCaptionEmphasized)
                Spacer(minLength: 8)
                if let project = projects.currentProject {
                    Text(project.title)
                        .font(.appMicro)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if projects.currentProject == nil {
            AppEmptyState(
                icon: "folder",
                title: "Select a Project",
                description: "Choose a project from the sidebar to see its commits."
            )
        } else if isLoading && commits.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            AppEmptyState(
                icon: "exclamationmark.triangle",
                title: "Unable to Load Commits",
                description: loadError
            )
        } else if commits.isEmpty {
            AppEmptyState(
                icon: "clock",
                title: "No Commits",
                description: "This repository has no commits yet."
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(commits) { commit in
                        commitRow(commit)
                        if commit.id != commits.last?.id {
                            AppDivider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Commit Row

    private func commitRow(_ commit: GitCommit) -> some View {
        AppListRow {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(commit.message)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 8)
                        Text(commit.shortHash)
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    HStack(spacing: 6) {
                        authorBadge(commit.author)
                        Text(commit.author)
                            .font(.appMicro)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(Self.relativeTime(commit.date))
                            .font(.appMicro)
                            .foregroundStyle(.secondary)
                    }
                    Text(Self.fullDate(commit.date))
                        .font(.appMicro)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .onTapGesture {
            guard let project = projects.currentProject else { return }
            detail.selectCommit(commit, in: project.url)
        }
    }

    /// 作者首字母小徽标（基于名字稳定取色）。
    private func authorBadge(_ author: String) -> some View {
        let initial = author.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?"
        let hue = Double(abs(author.hashValue % 360)) / 360.0
        let color = Color(hue: hue, saturation: 0.45, brightness: 0.8)
        return ZStack {
            Circle().fill(color.opacity(0.18))
            Text(initial.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 16, height: 16)
    }

    // MARK: - Time Formatting

    private static func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    // MARK: - Loading

    private func reloadIfNeeded() {
        guard let project = projects.currentProject else {
            if loadedProjectURL != nil {
                loadedProjectURL = nil
                commits = []
                isLoading = false
                loadError = nil
            }
            return
        }
        guard loadedProjectURL != project.url else { return }
        loadedProjectURL = project.url
        isLoading = true
        commits = []
        loadError = nil

        let url = project.url
        Task.detached(priority: .userInitiated) {
            let result = Result { try GitCommitLoader.loadCommits(in: url) }
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let loaded):
                    commits = loaded
                case .failure(let error):
                    loadError = (error as? GitCommitLoaderError)?.localizedDescription
                        ?? error.localizedDescription
                }
            }
        }
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 的观察者事件，
/// 把变化转成 `@Published revision` 以驱动 SwiftUI 视图重算。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
