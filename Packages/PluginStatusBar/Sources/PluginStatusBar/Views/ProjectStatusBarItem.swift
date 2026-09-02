import LumiUI
import ProviderProjects
import SwiftUI

/// 状态栏左侧：当前打开的项目。
///
/// 订阅 `ProjectProviding` 观察者事件，`currentProject` 变化时
/// 显示对应项目标题（无项目时显示占位）。
struct ProjectStatusBarItem: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel

    init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    var body: some View {
        AppStatusBarTile(systemImage: "folder") {
            Text(projects.currentProject?.title ?? "No Project")
                .lineLimit(1)
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
