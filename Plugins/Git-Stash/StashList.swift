import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 显示stash列表的视图组件
struct StashList: View, SuperLog, SuperThread {
    /// 日志标识符
    nonisolated static let emoji = "📦"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static let shared = StashList()

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var data: DataProvider

    @State private var stashes: [(index: Int, message: String)] = []
    @State private var isLoading = true
    @State private var showStashForm = false
    @State private var stashMessage = ""

    private init() {}

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            stashListView
        }
        .sheet(isPresented: $showStashForm) {
            stashFormView
        }
        .onAppear(perform: onAppear)
        .onProjectDidCommit(perform: onProjectDidCommit)
    }
}

// MARK: - View

extension StashList {
    /// 头部栏：显示stash数量和添加按钮
    private var headerBar: some View {
        HStack {
            Text("Stash")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "archivebox")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))

                Text("\(stashes.count) 个暂存")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                showStashForm = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .disabled(data.project == nil)
            .help("创建新暂存")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    /// stash列表视图
    private var stashListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if isLoading {
                    ProgressView("加载暂存列表...")
                        .padding()
                } else if stashes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("暂无stash")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("点击上方 + 按钮创建第一个stash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(stashes, id: \.index) { stash in
                        StashRow(
                            stash: stash,
                            onApply: { applyStash(at: stash.index) },
                            onPop: { popStash(at: stash.index) },
                            onDrop: { dropStash(at: stash.index) }
                        )
                        .id(stash.index)
                    }
                }
            }
        }
    }

    /// 创建stash的表单视图
    private var stashFormView: some View {
        VStack(spacing: 16) {
            Text("创建Stash")
                .font(.headline)

            TextField("暂存描述（可选）", text: $stashMessage)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack {
                Button("取消") {
                    stashMessage = ""
                    showStashForm = false
                }

                Button("创建") {
                    createStash()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350)
    }
}

// MARK: - Action

extension StashList {
    /// 创建新的stash
    private func createStash() {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                let message = await self.stashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                try await project.stashSave(message: message.isEmpty ? nil : message)

                await MainActor.run {
                    // TODO: 显示成功消息
                    self.stashMessage = ""
                    self.showStashForm = false
                    self.loadStashes()
                }
            } catch {
                await MainActor.run {
                    // TODO: 显示错误消息
                }
            }
        }
    }

    /// 应用stash
    private func applyStash(at index: Int) {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try await project.stashApply(index: index)

                await MainActor.run {
                    // TODO: 显示成功消息
                    self.loadStashes()
                }
            } catch {
                await MainActor.run {
                    // TODO: 显示错误消息
                }
            }
        }
    }

    /// 弹出stash
    private func popStash(at index: Int) {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try await project.stashPop(index: index)

                await MainActor.run {
                    // TODO: 显示成功消息
                    self.loadStashes()
                }
            } catch {
                await MainActor.run {
                    // TODO: 显示错误消息
                }
            }
        }
    }

    /// 删除stash
    private func dropStash(at index: Int) {
        guard let project = data.project else { return }

        Task.detached(priority: .userInitiated) {
            do {
                try await project.stashDrop(index: index)

                await MainActor.run {
                    // TODO: 显示成功消息
                    self.loadStashes()
                }
            } catch {
                await MainActor.run {
                    // TODO: 显示错误消息
                }
            }
        }
    }

    /// 加载stash列表
    private func loadStashes() {
        guard let project = data.project else {
            stashes = []
            isLoading = false
            return
        }

        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                let stashList = try await project.stashList()

                await MainActor.run {
                    self.stashes = stashList
                    self.isLoading = false
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t)❌ Failed to load stashes: \(error)")
                }
                await MainActor.run {
                    self.stashes = []
                    self.isLoading = false
                    // TODO: 显示错误消息
                }
            }
        }
    }
}

// MARK: - Event Handler

extension StashList {
    /// 视图出现时的事件处理
    func onAppear() {
        loadStashes()
    }

    /// 项目提交完成时的事件处理
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        // 只有stash相关的操作才需要刷新stash列表
        if ["stashSave", "stashApply", "stashPop", "stashDrop"].contains(eventInfo.operation) {
            loadStashes()
        }
    }
}