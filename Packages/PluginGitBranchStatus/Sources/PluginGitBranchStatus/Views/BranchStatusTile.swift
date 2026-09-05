import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 当前分支状态 tile：点击弹出分支管理面板（对齐旧版 BranchStatusTile）。
public struct BranchStatusTile: View {
    let projects: any ProjectProviding
    @ObservedObject private var viewModel: GitBranchStatusViewModel
    @State private var isPresented = false

    public init(projects: any ProjectProviding, viewModel: GitBranchStatusViewModel) {
        self.projects = projects
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.currentProjectURL != nil {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10))
                    Text(viewModel.currentBranch ?? LumiPluginLocalization.string("No Branch", bundle: .module))
                        .font(.appCaption)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented.toggle()
                }
                .help(LumiPluginLocalization.string("Manage Branches", bundle: .module))
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    BranchManagementView(projects: projects)
                        .frame(width: 560, height: 520)
                }
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
