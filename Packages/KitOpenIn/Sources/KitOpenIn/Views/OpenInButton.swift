import LumiUI
import ProviderProjects
import SwiftUI

/// 单个「在当前项目中打开」的工具栏按钮。
///
/// 按钮外壳与 `AppIconButton(.regular)`（设置按钮同一套样式）一致，
/// 但图标内容为**目标应用的真实图标**（与旧版 `PluginOpen*` 的
/// `Image.xcodeApp` / `Image.cursorApp` 等一致）：未安装或无法解析时
/// 回退到 `target.systemImage`（SF Symbol）。订阅 `ProjectProviding`
/// 观察者事件：无当前项目时隐藏（保留与按钮一致的占位尺寸，避免工具栏跳动）；
/// 有项目时点击调用 `AppLauncher` 打开。
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
            OpenInAppIconButton(
                image: AppLauncher.iconImage(for: target),
                systemImage: target.systemImage
            ) {
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

/// 展示真实应用图标的图标按钮。
///
/// 视觉外壳与 `AppIconButton(.regular)` 完全一致（8pt padding、
/// `DesignTokens.Radius.sm` 圆角、hover 背景/边框、hover scale）；
/// 唯一差异是图标内容：优先渲染 `image`（真实应用图标，不做 tint，
/// 保留应用原本配色），为 `nil` 时回退 `systemImage`（SF Symbol，套用
/// 与 `AppIconButton` 相同的前景色）。
private struct OpenInAppIconButton: View {
    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isHovered = false

    let image: Image?
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let image {
                    image
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 14, height: 14)
                }
            }
            .foregroundStyle(theme.textSecondary.opacity(0.8))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .scaleEffect(isHovered && motionPreference.allowsMotion ? LumiMotion.hoverScale : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            LumiMotion.animate(LumiMotion.enabled(LumiMotion.hover, preference: motionPreference)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        if isHovered {
            theme.textSecondary.opacity(0.12)
        } else {
            theme.textSecondary.opacity(0.08)
        }
    }

    private var borderColor: Color {
        if isHovered {
            theme.textSecondary.opacity(0.14)
        } else {
            .clear
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
