import SwiftUI
import AppKit
import MagicKit
import MagicUI

/// 通用的引导提示视图组件
/// 用于显示带有图标和文本的提示界面
struct GuideView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🧭"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var g: DataProvider

    let systemImage: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?
    let iconColor: Color?

    /// 初始化引导视图
    /// - Parameters:
    ///   - systemImage: SF Symbol 图标名称
    ///   - title: 主标题
    ///   - subtitle: 副标题（可选）
    ///   - action: 操作按钮的回调（可选）
    ///   - actionLabel: 操作按钮的标签（可选）
    ///   - iconColor: 图标颜色（可选，默认为灰色）
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        iconColor: Color? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundColor(iconColor ?? .gray)

            Text(title)
                .font(.largeTitle)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            if let projectPath = g.project?.path {
                Text("当前项目：\(projectPath)")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let branch = g.branch {
                    Text("当前分支：\(branch.name)")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                }
                .buttonStyle(.borderedProminent)
            }
            
            UserView()
                .padding()
                .frame(width: 500)

            if let path = g.project?.path {
                MagicButton.simple {
                    openInFinder(path)
                }
                .magicTitle("在 Finder 中打开")
                .magicSize(.auto)
                .magicIcon(.iconFinder)
                .magicBackground(MagicBackground.forest)
                .frame(width: 200)
                .frame(height: 40)
                .padding(.top, 20)
            }

            if g.projectExists == false, let p = g.project {
                BtnDeleteProject(project: p)
                    .frame(width: 200)
                    .frame(height: 40)
                    .padding(.top, 50)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: Modifiers

extension GuideView {
    /// 设置图标颜色的链式调用方法
    /// - Parameter color: 图标颜色
    /// - Returns: 新的 GuideView 实例
    func setIconColor(_ color: Color) -> GuideView {
        return GuideView(
            systemImage: self.systemImage,
            title: self.title,
            subtitle: self.subtitle,
            action: self.action,
            actionLabel: self.actionLabel,
            iconColor: color
        )
    }

    private func openInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
