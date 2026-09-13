import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import SwiftUI

/// 未推送状态 tile：显示当前分支相对上游未推送的提交数。
public struct UnpushedStatusTile: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var unpushedCount: Int?
    @State private var countTask: Task<Void, Never>?
    @State private var countCancellation: GitProcessCancellation?
    @State private var loadGeneration = 0

    public init(projects: any ProjectProviding, git: any GitProviding) {
        self.projects = projects
        self.git = git
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if let count = unpushedCount, count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text(String(format: GitUnpushedStatusLocalization.string("%ld unpushed", bundle: .module), count))
                        .font(.appCaption)
                        .lineLimit(1)
                }
                .help(String(format: GitUnpushedStatusLocalization.string("%ld unpushed commit(s)", bundle: .module), count))
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

        guard let project = projects.currentProject else {
            unpushedCount = nil
            return
        }
        let url = project.url
        unpushedCount = nil
        let cancellation = GitProcessCancellation()
        countCancellation = cancellation
        countTask = Task.detached(priority: .utility) {
            let count = git.unpushedCount(in: url, cancellation: cancellation)
            await MainActor.run {
                guard generation == loadGeneration, !cancellation.isCancelled else { return }
                unpushedCount = count
                countTask = nil
                countCancellation = nil
            }
        }
    }

    @MainActor
    private func cancelLoad() {
        countTask?.cancel()
        countTask = nil
        countCancellation?.cancel()
        countCancellation = nil
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件，转成 @Published 驱动视图。
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
