import AppKit
import MagicCore
import MagicAlert
import OSLog
import SwiftUI

struct FileList: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    @State var files: [GitDiffFile] = []
    @State var isLoading = true
    @State var selection: GitDiffFile?
    @State private var refreshTask: Task<Void, Never>?
    var verbose = false

    var body: some View {
        VStack(spacing: 0) {
            // 文件信息栏
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text("\(files.count) 个文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.small)
                        Text("加载中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )

            // 文件列表
            ScrollViewReader { scrollProxy in
                List(files, id: \.self, selection: $selection) {
                    FileTile(
                        file: $0,
                        onDiscardChanges: data.commit == nil ? {
                            discardChanges(for: $0)
                        } : nil
                    )
                    .tag($0 as GitDiffFile?)
                    .listRowInsets(.init()) // 移除 List 的默认内边距
                }
                .listStyle(.plain) // 使用 plain 样式移除额外的 padding
                .onChange(of: files, {
                    withAnimation {
                        // 在主线程中调用 scrollTo 方法
                        scrollProxy.scrollTo(data.file, anchor: .top)
                    }
                })
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: data.commit, onCommitChange)
        .onChange(of: selection, onSelectionChange)
        .onProjectDidCommit(perform: onProjectDidCommit)
    }
}

// MARK: - Action

extension FileList {
    func discardChanges(for file: GitDiffFile) {
        guard let project = data.project else { return }
        
        Task.detached {
            do {
                try project.discardFileChanges(file.file)
                
                await MainActor.run {
                    self.m.info("已丢弃文件更改: \(file.file)")
                }
                
                // 刷新文件列表
                await self.refresh(reason: "AfterDiscardChanges")
            } catch {
                await MainActor.run {
                    self.m.error("丢弃更改失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func refresh(reason: String) async {
        // 取消之前的任务
        refreshTask?.cancel()
        
        // 创建新的任务
        refreshTask = Task {
            await performRefresh(reason: reason)
        }
        
        // 等待任务完成
        await refreshTask?.value
    }
    
    private func performRefresh(reason: String) async {
        self.isLoading = true

        if verbose {
            os_log("\(self.t)🍋 Refreshing \(reason)")
        }

        guard let project = data.project else {
            self.isLoading = false
            return
        }

        do {
            // 检查任务是否被取消
            try Task.checkCancellation()
            
            if let commit = data.commit {
                self.files = try await project.fileList(atCommit: commit.hash)
            } else {
                self.files = try await project.untrackedFiles()
            }
            
            // 再次检查任务是否被取消
            try Task.checkCancellation()
            
            self.selection = self.files.first
            DispatchQueue.main.async {
                self.data.setFile(self.selection)
            }
        } catch is CancellationError {
            // 任务被取消，不做任何处理
            if verbose {
                os_log("\(self.t)🐜 Refresh cancelled: \(reason)")
            }
        } catch {
            self.m.error(error.localizedDescription)
        }
        
        self.isLoading = false
    }
}

// MARK: - Event

extension FileList {
    func onAppear() {
        Task {
            await self.refresh(reason: "OnAppear")
        }
    }

    func onCommitChange() {
        Task {
            await self.refresh(reason: "OnCommitChanged")
        }
    }

    func onSelectionChange() {
        self.data.setFile(self.selection)
    }

    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        Task {
            await self.refresh(reason: "OnProjectDidCommit")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
