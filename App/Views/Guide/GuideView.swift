import AppKit
import LibGit2Swift
import MagicKit
import MagicUI
import OSLog
import SwiftUI

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
                    Button(action: action) {
                        Text(actionLabel)
                    }
                    .buttonStyle(.borderedProminent)
                }

                // 项目信息区域
                if let project = g.project {
                    VStack(alignment: .center) {
                        // 当前项目信息
                        MagicSettingSection(title: "当前项目", titleAlignment: .leading) {
                            VStack(spacing: 0) {
                                MagicSettingRow(
                                    title: project.title,
                                    description: project.path,
                                    icon: .iconFolder
                                ) {
                                    MagicButton.simple {
                                        project.url.openFolder()
                                    }
                                    .magicIcon(.iconFinder)
                                }
                            }
                        }

                        // 当前分支信息
                        if let branch = g.branch {
                            MagicSettingSection(title: "当前分支", titleAlignment: .leading) {
                                MagicSettingRow(
                                    title: branch.name,
                                    description: "当前检出的分支",
                                    icon: .iconLog
                                ) {
                                }
                            }
                        }

                        // 远程仓库信息
                        if let remotes = getRemoteInfo() {
                            MagicSettingSection(title: "远程仓库", titleAlignment: .leading) {
                                VStack(spacing: 0) {
                                    ForEach(remotes) { remote in
                                        MagicSettingRow(
                                            title: remote.name,
                                            description: remote.url,
                                            icon: .iconCloud
                                        ) {
                                        }

                                        if remote != remotes.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        // 用户信息
                        UserView()
                            .frame(maxWidth: 600)

                        // 项目不存在时的删除按钮
                        if !g.projectExists {
                            VStack(spacing: 12) {
                                Text("项目路径不存在")
                                    .font(.headline)
                                    .foregroundColor(.red)

                                BtnDeleteProject(project: project)
                                    .frame(width: 200, height: 40)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 600)
                    .inMagicHStackCenter()
                }
                
                Spacer()
            }
        }
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

    /// 获取远程仓库信息
    /// - Returns: 远程仓库信息数组，如果获取失败则返回 nil
    private func getRemoteInfo() -> [GitRemote]? {
        guard let project = g.project else {
            return nil
        }

        do {
            let remotes = try project.remoteList()
            return remotes.isEmpty ? nil : remotes
        } catch {
            if Self.verbose {
                os_log("\(Self.t)❌ Failed to get remote info: \(error)")
            }
            return nil
        }
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
