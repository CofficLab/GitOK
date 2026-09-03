import LumiUI
import ProviderProjects
import SwiftUI

/// 工具栏项目选择器：下拉选择当前项目（对齐旧版 ProjectPickerView）。
public struct ProjectPickerView: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var selection: UUID?

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Picker("", selection: $selection) {
            Text("Select Project").tag(nil as UUID?)
            ForEach(projects.projects) { project in
                Text(project.title).tag(Optional(project.id))
            }
        }
        .labelsHidden()
        .frame(width: 160)
        .onChange(of: selection) { _, newValue in
            guard let newValue, newValue != projects.currentProject?.id else { return }
            projects.setCurrentProject(id: newValue)
        }
        .onReceive(observation.$revision) { _ in
            selection = projects.currentProject?.id
        }
        .onAppear {
            selection = projects.currentProject?.id
        }
    }
}

/// 项目观察模型：订阅 `ProjectProviding` 事件，转成 @Published 驱动视图。
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
