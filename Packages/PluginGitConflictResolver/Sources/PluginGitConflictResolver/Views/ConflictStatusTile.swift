import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 冲突状态 tile：合并中显示冲突数（红），否则 Merge OK（对齐旧版 ConflictStatusTile）。
public struct ConflictStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isMerging = false
    @State private var conflictCount = 0
    @State private var isPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                HStack(spacing: 4) {
                    Image(systemName: isMerging ? "exclamationmark.triangle.fill" : "checkmark.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(isMerging ? theme.warning : theme.textTertiary)
                    Text(isMerging ? String(format: LumiPluginLocalization.string("Conflicts %lld", bundle: .module), conflictCount) : LumiPluginLocalization.string("Merge OK", bundle: .module))
                        .font(.appCaption)
                        .foregroundStyle(isMerging ? theme.warning : theme.textTertiary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented.toggle()
                }
                .help(isMerging
                    ? String(format: LumiPluginLocalization.string("There are %lld conflicted files. Click to resolve them.", bundle: .module), conflictCount)
                    : LumiPluginLocalization.string("No merge conflicts", bundle: .module))
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                    ConflictResolverList(projects: projects)
                        .frame(width: 560, height: 480)
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
            isMerging = false
            conflictCount = 0
            return
        }
        Task.detached(priority: .utility) {
            let merging = GitMergeOperation.hasConflictOperation(in: url)
            let count = merging ? GitMergeOperation.conflictFiles(in: url).count : 0
            await MainActor.run {
                isMerging = merging
                conflictCount = count
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
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
