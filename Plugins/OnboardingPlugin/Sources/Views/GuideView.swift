import GitOKAppCore
import AppKit
import GitCoreKit
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

private enum GuideBackgroundRunner {
    struct UnsafeTransfer<Value>: @unchecked Sendable {
        let value: Value
    }
}

/// 通用的引导提示视图组件
/// 用于显示带有图标和文本的提示界面
public struct GuideView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "🧭"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM

    let systemImage: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?
    let iconColor: Color?

    @State private var remoteInfo: [GitRemote] = []

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

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()

                // 主标题和图标
                VStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 64))
                        .foregroundColor(iconColor ?? .gray)

                    Text(title)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)

                // 操作按钮
                if let action = action, let actionLabel = actionLabel {
                    AppButton(
                        LocalizedStringKey(actionLabel),
                        style: .primary,
                        action: action
                    )
                }

                // 项目信息区域
                if let project = vm.project {
                    VStack(alignment: .center) {
                        if vm.projectExists {
                            // 仓库信息（本地、远程、分支）
                            RepositoryInfoView(
                                project: project,
                                remotes: remoteInfo,
                                branch: g.branch
                            )

                            // 当前项目 Git 用户配置
                            CurrentUserConfigView(project: project)

                            // Git 用户预设管理
                            GitUserPresetView()

                            // Commit 风格预设管理
                            CommitStylePresetView()

                        } else {
                            // 项目不存在时的删除按钮
                            ProjectNotFoundView(project: project)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 600)
                    .inMagicHStackCenter()
                    .inMagicVStackCenter()
                }

                Spacer()
            }
        }
        .background(Color(.windowBackgroundColor))
        .onAppear(perform: loadRemoteInfo)
        .onChange(of: vm.project?.path) {
            loadRemoteInfo()
        }
        .onProjectGitRefsDidChange { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            loadRemoteInfo()
        }
    }
}

// MARK: Modifiers

public extension GuideView {
    /// 设置图标颜色的链式调用方法
    /// - Parameter color: 图标颜色
    /// - Returns: 新的 GuideView 实例
    func setIconColor(_ color: Color) -> GuideView {
        // 通过重新创建来设置颜色（SwiftUI View 的不可变性）
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

    private func loadRemoteInfo() {
        guard let loadedProject = vm.project else {
            remoteInfo = []
            return
        }
        let projectTransfer = GuideBackgroundRunner.UnsafeTransfer(value: loadedProject)

        Task.detached(priority: .utility) {
            do {
                let remotes = try await projectTransfer.value.remoteListAsync()
                Task { @MainActor in
                    remoteInfo = remotes
                }
            } catch {
                let message = error.localizedDescription
                Task { @MainActor in
                    remoteInfo = []
                    if Self.verbose {
                        os_log("\(Self.t)❌ Failed to get remote info: \(message)")
                    }
                }
            }
        }
    }
}

// MARK: - Preview


