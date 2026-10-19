import LumiUI
import ProviderProjects
import ProviderStatusBar
import SwiftUI

/// .gitignore 状态图标：存在时点击查看内容（对齐旧版 GitIgnoreStatusIcon）。
public struct GitIgnoreStatusIcon: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var hasGitIgnore = false
    @State private var isSheetPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                AppStatusBarTile(systemImage: "doc.text.fill", action: {
                    if hasGitIgnore {
                        isSheetPresented.toggle()
                    }
                })
                    .help(hasGitIgnore
                        ? GitIgnoreLocalization.string("View .gitignore file", bundle: .module)
                        : GitIgnoreLocalization.string("No .gitignore file found", bundle: .module))
                    .sheet(isPresented: $isSheetPresented) {
                        GitIgnoreViewer(projects: projects)
                            .frame(minWidth: 600, minHeight: 400)
                    }
            }
        }
        .onReceive(observation.$lastEvent) { event in
            // .gitignore 只在仓库数据变化时才可能增删；会话级选择
            // （commit / 文件）不影响它，跳过可省去无谓的文件存在性检查。
            if case .dataChanged = event {
                check()
            }
        }
        .onAppear(perform: check)
    }

    private func check() {
        hasGitIgnore = GitIgnoreFile(repositoryRoot: projects.currentProject?.url).exists
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
            // 仓库数据变化才会影响 .gitignore 的存在性；项目列表与会话级
            // 选择（切换项目 / commit / 文件）不影响 gitignore 文件本身。
            guard event.isRepositoryScoped else { return }
            self?.lastEvent = event
            self?.revision += 1
        }
    }
}
