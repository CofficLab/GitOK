import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 未推送状态 tile：显示当前分支相对上游未推送的提交数。
public struct UnpushedStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var unpushedCount: Int?

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if let count = unpushedCount, count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(count) unpushed")
                        .font(.appCaption)
                        .lineLimit(1)
                }
                .help("\(count) unpushed commit(s)")
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
            unpushedCount = nil
            return
        }
        let url = project.url
        Task.detached(priority: .utility) {
            let count = GitRefReader.unpushedCount(in: url)
            await MainActor.run {
                unpushedCount = count
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
