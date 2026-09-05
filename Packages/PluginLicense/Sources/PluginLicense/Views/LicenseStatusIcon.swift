import LumiUI
import ProviderProjects
import SwiftUI

/// LICENSE 状态图标：存在时点击查看内容（对齐旧版 LicenseStatusIcon）。
public struct LicenseStatusIcon: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var hasLicense = false
    @State private var isSheetPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isSheetPresented.toggle()
                    }
                    .help(hasLicense ? "View LICENSE" : "LICENSE not found, click to create")
                    .sheet(isPresented: $isSheetPresented) {
                        LicenseViewer(projects: projects)
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
            hasLicense = false
            return
        }
        let license = url.appendingPathComponent("LICENSE")
        hasLicense = FileManager.default.fileExists(atPath: license.path)
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
