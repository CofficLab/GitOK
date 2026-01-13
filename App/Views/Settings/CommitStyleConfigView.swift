import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// Commit 风格配置视图
struct CommitStyleConfigView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider

    /// 当前项目的 commit 风格绑定
    @Binding var commitStyle: CommitStyle

    /// 全局默认 commit 风格绑定
    @Binding var globalCommitStyle: CommitStyle

    /// 数据提供者
    let dataProvider: DataProvider

    /// 状态仓库
    private var stateRepo: any StateRepoProtocol {
        dataProvider.repoManager.stateRepo
    }

    /// 初始化 Commit 风格配置视图
    /// - Parameters:
    ///   - commitStyle: 项目 commit 风格绑定
    ///   - globalCommitStyle: 全局 commit 风格绑定
    ///   - dataProvider: 数据提供者
    init(
        commitStyle: Binding<CommitStyle>,
        globalCommitStyle: Binding<CommitStyle>,
        dataProvider: DataProvider
    ) {
        self._commitStyle = commitStyle
        self._globalCommitStyle = globalCommitStyle
        self.dataProvider = dataProvider
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置 Commit 消息风格")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("项目配置优先级高于全局配置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 全局默认配置
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("全局默认风格")
                            .font(.headline)
                    }

                    Text("应用于所有新项目的默认风格")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("风格")
                            .font(.subheadline)

                        Spacer()

                        Picker("", selection: $globalCommitStyle) {
                            ForEach(CommitStyle.allCases, id: \.self) { style in
                                Text(style.label)
                                    .tag(style as CommitStyle?)
                            }
                        }
                        .frame(width: 120)
                        .pickerStyle(.automatic)
                        .onChange(of: globalCommitStyle) { _, _ in
                            saveGlobalCommitStyle()
                        }
                    }

                    // 全局风格预览
                    VStack(alignment: .leading, spacing: 6) {
                        Text("预览")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach([
                                (category: CommitCategory.Chore, message: "Update dependencies"),
                                (category: CommitCategory.Feature, message: "Add user authentication")
                            ], id: \.category) { item in
                                let fullMessage = "\(item.category.text(style: globalCommitStyle))\(globalCommitStyle.isLowercase ? item.message.lowercased() : item.message)"
                                Text(fullMessage)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)

                // 当前项目配置
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.orange)
                        Text("当前项目风格")
                            .font(.headline)
                    }

                    if let project = dataProvider.project {
                        Text("项目：\(project.title)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("风格")
                                .font(.subheadline)

                            Spacer()

                            Picker("", selection: $commitStyle) {
                                ForEach(CommitStyle.allCases, id: \.self) { style in
                                    Text(style.label)
                                        .tag(style as CommitStyle?)
                                }
                            }
                            .frame(width: 120)
                            .pickerStyle(.automatic)
                            .onChange(of: commitStyle) { _, _ in
                                saveCommitStyle()
                            }
                        }

                        // 项目风格预览
                        VStack(alignment: .leading, spacing: 6) {
                            Text("预览")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach([
                                    (category: CommitCategory.Chore, message: "Update dependencies"),
                                    (category: CommitCategory.Feature, message: "Add user authentication")
                                ], id: \.category) { item in
                                    let fullMessage = "\(item.category.text(style: commitStyle))\(commitStyle.isLowercase ? item.message.lowercased() : item.message)"
                                    Text(fullMessage)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    } else {
                        Text("未打开项目")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
        }
    }

    // MARK: - Load & Save

    func loadCommitStyle() {
        // 加载全局默认风格
        globalCommitStyle = stateRepo.globalCommitStyle

        // 加载当前项目风格
        commitStyle = dataProvider.project?.commitStyle ?? .emoji
    }

    func saveCommitStyle() {
        // 保存到当前项目
        if let project = dataProvider.project {
            project.commitStyle = commitStyle
        }
    }

    func saveGlobalCommitStyle() {
        // 保存全局默认风格
        stateRepo.setGlobalCommitStyle(globalCommitStyle)
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
