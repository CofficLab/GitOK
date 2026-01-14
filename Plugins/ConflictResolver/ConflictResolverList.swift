import MagicKit
import OSLog
import SwiftUI

/// 显示冲突文件列表的视图组件
struct ConflictResolverList: View, SuperLog, SuperThread {
    /// 日志标识符
    nonisolated static let emoji = "⚔️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static let shared = ConflictResolverList()

    @EnvironmentObject var data: DataProvider

    @State private var conflictFiles: [String] = []
    @State private var isLoading = true
    @State private var isMerging = false
    @State private var selectedFile: String?

    private init() {}

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            conflictListView
        }
        .onAppear(perform: onAppear)
        .onProjectDidMerge(perform: onProjectDidMerge)
    }
}

// MARK: - View

extension ConflictResolverList {
    /// 头部栏：显示冲突状态和操作按钮
    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("冲突解决")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if isMerging {
                    HStack(spacing: 8) {
                        Button(action: {
                            continueMerge()
                        }) {
                            Text("继续合并")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(conflictFiles.isEmpty == false) // 还有冲突时禁用

                        Button(action: {
                            abortMerge()
                        }) {
                            Text("中止合并")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isMerging {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("发现 \(conflictFiles.count) 个冲突文件需要解决")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    /// 冲突文件列表视图
    private var conflictListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if isLoading {
                    ProgressView("检查冲突状态...")
                        .padding()
                } else if !isMerging {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("没有正在进行的合并")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("当您执行合并操作遇到冲突时，此处会显示需要解决的文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else if conflictFiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("所有冲突已解决")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("点击上方\"继续合并\"按钮完成合并操作")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(conflictFiles, id: \.self) { file in
                        ConflictResolverRow(
                            filePath: file,
                            isSelected: selectedFile == file,
                            onSelect: { selectedFile = file }
                        )
                        .id(file)
                    }
                }
            }
        }
    }
}

// MARK: - Action

extension ConflictResolverList {
    /// 继续合并操作
    private func continueMerge() {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                // TODO: 需要获取当前合并的分支名
                try await project.continueMerge(branchName: "unknown")

                await MainActor.run {
                    // TODO: 显示成功消息
                    self.loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    // TODO: 显示错误消息
                }
            }
        }
    }

    /// 中止合并操作
    private func abortMerge() {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try await project.abortMerge()

                await MainActor.run {
                    // TODO: 显示成功消息
                    self.loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    // TODO: 显示错误消息
                }
            }
        }
    }

    /// 加载冲突状态
    private func loadConflictStatus() {
        guard let project = data.project else {
            conflictFiles = []
            isMerging = false
            isLoading = false
            return
        }

        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                let merging = try await project.isMerging()
                let conflicts = merging ? try await project.getMergeConflictFiles() : []

                await MainActor.run {
                    self.isMerging = merging
                    self.conflictFiles = conflicts
                    self.isLoading = false
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t)❌ Failed to load conflict status: \(error)")
                }
                await MainActor.run {
                    self.conflictFiles = []
                    self.isMerging = false
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Event Handler

extension ConflictResolverList {
    /// 视图出现时的事件处理
    func onAppear() {
        loadConflictStatus()
    }

    /// 项目合并事件处理
    func onProjectDidMerge(_ eventInfo: ProjectEventInfo) {
        loadConflictStatus()
    }
}