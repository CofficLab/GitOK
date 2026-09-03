import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// Stash 状态 tile：显示 stash 数，点击弹出管理面板（对齐旧版 StashStatusTile）。
public struct StashStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var stashCount = 0
    @State private var isPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
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
                .help("Manage Stash")
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    StashListView(projects: projects, onStashesChanged: { load() })
                        .frame(width: 460, height: 520)
                }
            }
        }
        .onReceive(observation.$revision) { _ in load() }
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                load()
            }
        }
        .onAppear { load() }
    }

    @MainActor
    private func load() {
        guard let url = projects.currentProject?.url else {
            stashCount = 0
            return
        }
        Task.detached(priority: .utility) {
            let count = GitStashOperation.list(in: url).count
            await MainActor.run {
                stashCount = count
            }
        }
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    @Published private(set) var lastEvent: ProjectProvidingEvent?
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            self?.lastEvent = event
            self?.revision += 1
        }
    }
}
