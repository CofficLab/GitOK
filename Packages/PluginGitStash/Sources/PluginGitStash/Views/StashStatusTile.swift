import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import SwiftUI

/// Stash 状态 tile：显示 stash 数，点击弹出管理面板（对齐旧版 StashStatusTile）。
public struct StashStatusTile: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var stashCount = 0
    @State private var isPresented = false
    @State private var loadTask: Task<Void, Never>?
    @State private var loadCancellation: GitProcessCancellation?
    @State private var loadGeneration = 0

    public init(projects: any ProjectProviding, git: any GitProviding) {
        self.projects = projects
        self.git = git
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                HStack(spacing: 4) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 10))
                    if stashCount > 0 {
                        Text("\(stashCount)")
                            .font(.appCaption)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented.toggle()
                }
                .help(GitStashLocalization.string("Manage Stash", bundle: .module))
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    StashListView(projects: projects, git: git, onStashesChanged: { load() })
                        .frame(width: 460, height: 520)
                }
            }
        }
        .onReceive(observation.$revision) { _ in load() }
        .onAppear { load() }
        .onDisappear(perform: cancelLoad)
    }

    @MainActor
    private func load() {
        loadGeneration &+= 1
        let generation = loadGeneration
        cancelLoad()

        guard let url = projects.currentProject?.url else {
            stashCount = 0
            return
        }
        stashCount = 0
        let cancellation = GitProcessCancellation()
        loadCancellation = cancellation
        loadTask = Task.detached(priority: .utility) {
            let count = git.listStashes(in: url, cancellation: cancellation).count
            await MainActor.run {
                guard generation == loadGeneration, !cancellation.isCancelled else { return }
                stashCount = count
                loadTask = nil
                loadCancellation = nil
            }
        }
    }

    @MainActor
    private func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
        loadCancellation?.cancel()
        loadCancellation = nil
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            switch event {
            case .selectionChanged, .dataChanged:
                self?.revision += 1
            default:
                break
            }
        }
    }
}
