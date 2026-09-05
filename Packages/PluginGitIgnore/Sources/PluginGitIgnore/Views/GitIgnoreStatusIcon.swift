import LumiUI
import ProviderProjects
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
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if hasGitIgnore {
                            isSheetPresented.toggle()
                        }
                    }
                    .help(hasGitIgnore
                        ? GitIgnoreLocalization.string("View .gitignore file", bundle: .module)
                        : GitIgnoreLocalization.string("No .gitignore file found", bundle: .module))
                    .sheet(isPresented: $isSheetPresented) {
                        GitIgnoreViewer(projects: projects)
                            .frame(minWidth: 600, minHeight: 400)
                    }
            }
        }
        .onReceive(observation.$revision) { _ in check() }
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                check()
            }
        }
        .onAppear(perform: check)
    }

    private func check() {
        guard let url = projects.currentProject?.url else {
            hasGitIgnore = false
            return
        }
        let gitignore = url.appendingPathComponent(".gitignore")
        hasGitIgnore = FileManager.default.fileExists(atPath: gitignore.path)
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
