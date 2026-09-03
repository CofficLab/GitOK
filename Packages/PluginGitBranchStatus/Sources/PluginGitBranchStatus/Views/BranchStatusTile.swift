import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 当前分支状态 tile：点击弹出分支管理面板（对齐旧版 BranchStatusTile）。
public struct BranchStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var branch: String?
    @State private var isPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10))
                    Text(branch ?? "No Branch")
                        .font(.appCaption)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented.toggle()
                }
                .help("Manage Branches")
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    BranchManagementView(projects: projects)
                        .frame(width: 560, height: 520)
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
        guard let project = projects.currentProject else {
            branch = nil
            return
        }
        let url = project.url
        Task.detached(priority: .utility) {
            let loaded = GitRefReader.currentBranch(in: url)
            await MainActor.run {
                branch = loaded
            }
        }
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件，转成 @Published 驱动视图。
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
