import LumiUI
import ProviderAutoPush
import ProviderProjects
import SwiftUI

/// 自动推送状态图标：绿=启用，灰=关闭；点击弹配置（对齐旧版 AutoPushStatusIcon）。
public struct AutoPushStatusIcon: View {
    let projects: any ProjectProviding
    let autoPush: any AutoPushProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isSheetPresented = false

    public init(projects: any ProjectProviding, autoPush: any AutoPushProviding) {
        self.projects = projects
        self.autoPush = autoPush
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    private var isEnabled: Bool {
        guard let project = projects.currentProject else { return false }
        return autoPush.isEnabled(for: project.url)
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Image(systemName: isEnabled ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(isEnabled ? theme.success : theme.textTertiary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isSheetPresented.toggle()
                    }
                    .help(isEnabled
                        ? "Auto-push is enabled - Click to manage"
                        : "Auto-push is disabled - Click to configure")
                    .sheet(isPresented: $isSheetPresented) {
                        AutoPushConfigView(projects: projects, autoPush: autoPush)
                            .frame(minWidth: 460, minHeight: 260)
                    }
            }
        }
        .onReceive(observation.$revision) { _ in }
        .onReceive(observation.$lastEvent) { event in
            if case .dataChanged = event {
                isSheetPresented = false
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
}

/// 自动推送配置视图：当前项目/分支开关。
public struct AutoPushConfigView: View {
    let projects: any ProjectProviding
    let autoPush: any AutoPushProviding
    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled = false

    public init(projects: any ProjectProviding, autoPush: any AutoPushProviding) {
        self.projects = projects
        self.autoPush = autoPush
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Auto Push")
                .font(.headline)

            if let project = projects.currentProject {
                AppSettingRow(
                    title: "Auto-push after commit",
                    description: project.title,
                    icon: "arrow.up.circle"
                ) {
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                }
                Text("When enabled, GitOK pushes the current branch after every successful commit.")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            } else {
                Text("Please select a project first")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }

            HStack {
                Spacer()
                AppButton("Cancel", style: .secondary, size: .small) {
                    dismiss()
                }
                AppButton(
                    "Save",
                    systemImage: "square.and.arrow.down",
                    style: .primary,
                    size: .small
                ) {
                    if let project = projects.currentProject {
                        autoPush.setEnabled(isEnabled, for: project.url)
                    }
                    dismiss()
                }
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            if let project = projects.currentProject {
                isEnabled = autoPush.isEnabled(for: project.url)
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
