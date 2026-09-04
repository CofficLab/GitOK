import LumiUI
import ProviderProjects
import SwiftUI

/// 单个「在当前项目中打开」的工具栏按钮。
///
/// 按钮样式与 `SettingsButtonView` 对齐：使用 `AppIconButton`（纯图标按钮，
/// `.regular` 尺寸）。订阅 `ProjectProviding` 观察者事件：无当前项目时隐藏
/// （保留与按钮一致的占位尺寸，避免工具栏跳动）；有项目时点击调用
/// `AppLauncher` 打开。
struct OpenInButton: View {
    let target: OpenTarget
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel

    init(target: OpenTarget, projects: any ProjectProviding) {
        self.target = target
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    var body: some View {
        if let project = projects.currentProject {
            AppIconButton(systemImage: target.systemImage, size: .regular) {
                AppLauncher.open(target, projectURL: project.url)
            }
            .help(target.helpText)
        } else {
            // 无当前项目：保留与 AppIconButton(.regular) 一致的占位尺寸，
            // 避免工具栏布局跳动。
            Color.clear
                .frame(width: 30, height: 30)
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
