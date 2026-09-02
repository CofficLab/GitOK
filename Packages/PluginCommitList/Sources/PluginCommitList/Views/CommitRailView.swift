import LumiUI
import ProviderProjects
import SwiftUI

/// Commit 列表 Rail 视图：显示当前打开项目的提交历史。
///
/// 作为 Rail 注入根布局（位于侧边栏右侧、内容区左侧）。订阅
/// `ProjectProviding` 的观察者事件；`currentProject` 变化时异步读取
/// 该仓库的 commit 列表（后台线程执行 git CLI，主线程更新）。
struct CommitRailView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel

    @State private var commits: [GitCommit] = []
    @State private var isLoading = false
    @State private var loadedProjectURL: URL?
    @State private var loadError: String?

    init(projects: any ProjectProviding) {
        self.projects = projects
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
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.appCaptionEmphasized)
            Text("Commits")
                .font(.appCaptionEmphasized)
            Spacer()
            if let project = projects.currentProject {
                Text(project.title)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if projects.currentProject == nil {
            empty("Select a project", icon: "folder")
        } else if isLoading && commits.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadError {
            empty(loadError, icon: "exclamationmark.triangle")
        } else if commits.isEmpty {
            empty("No commits", icon: "clock")
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(commits) { commit in
                        commitRow(commit)
                        if commit.id != commits.last?.id {
                            AppDivider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func commitRow(_ commit: GitCommit) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(commit.shortHash)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(commit.date, style: .relative)
                    .font(.appMicro)
                    .foregroundStyle(.tertiary)
            }
            Text(commit.message)
                .font(.appBody)
                .lineLimit(2)
            Text(commit.author)
                .font(.appMicro)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func empty(_ text: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
