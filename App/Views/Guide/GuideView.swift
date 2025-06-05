import SwiftUI

/// 通用的引导提示视图组件
/// 用于显示带有图标和文本的提示界面
struct GuideView: View {
    @EnvironmentObject var g: DataProvider

    let systemImage: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?

    /// 初始化引导视图
    /// - Parameters:
    ///   - systemImage: SF Symbol 图标名称
    ///   - title: 主标题
    ///   - subtitle: 副标题（可选）
    ///   - action: 操作按钮的回调（可选）
    ///   - actionLabel: 操作按钮的标签（可选）
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(title)
                .font(.title2)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            if let projectPath = g.project?.path {
                Text("当前项目：\(projectPath)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    RootView {
        GuideView(
            systemImage: "folder.badge.questionmark",
            title: "No Project",
            subtitle: "Please select or create a project",
            action: { print("Action tapped") },
            actionLabel: "Create Project"
        )
    }
    .frame(width: 400, height: 300)
}

#Preview("Simple") {
    RootView {
        GuideView(
            systemImage: "exclamationmark.triangle",
            title: "Not a Git Repository"
        )
    }
    .frame(width: 400, height: 300)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
