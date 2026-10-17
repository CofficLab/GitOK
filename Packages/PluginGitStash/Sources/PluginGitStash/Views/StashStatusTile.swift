import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import ProviderStatusBar
import SwiftUI

/// Stash 状态 tile：显示 stash 数，点击弹出管理面板（对齐旧版 StashStatusTile）。
public struct StashStatusTile: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var loader: StashCountLoader
    @State private var isPresented = false

    public init(projects: any ProjectProviding, git: any GitProviding) {
        self.projects = projects
        self.git = git
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
        let gitProvider = git
        _loader = State(initialValue: StashCountLoader(
            git: StashCountGitCapabilityAdapter(git: gitProvider),
            repositoryURL: { [projects] in projects.currentProject?.url }
        ))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                AppStatusBarTile(systemImage: "archivebox", action: { isPresented.toggle() }) {
                    if loader.count > 0 {
                        Text("\(loader.count)").lineLimit(1)
                    }
                }
                .help(GitStashLocalization.string("Manage Stash", bundle: .module))
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    StashListView(projects: projects, git: git, onStashesChanged: { loader.load() })
                        .frame(width: 460, height: 520)
                }
            }
        }
        .onReceive(observation.$revision) { _ in loader.load() }
        .onAppear { loader.load() }
        .onDisappear { loader.cancel() }
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            // stash 属于仓库数据，只关心仓库级事件
            guard event.isRepositoryScoped else { return }
            self?.revision += 1
        }
    }
}
