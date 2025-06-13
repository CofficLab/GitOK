import AppKit
import MagicCore
import OSLog
import SwiftUI

struct FileList: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    @State var files: [GitDiffFile] = []
    @State var isLoading = false
    @State var selection: GitDiffFile?
    var verbose = true

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
            .padding(.horizontal, 12)
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
                    FileTile(file: $0)
                        .tag($0 as GitDiffFile?)
                }
                .background(.blue)
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
        .onNotification(.projectDidCommit, perform: onProjectDidCommit)
    }
}

// MARK: - Action

extension FileList {
    func refresh(reason: String) {
        self.isLoading = true

        if verbose {
            os_log("\(self.t)🍋 Refresh\(reason)")
        }

        guard let project = data.project else {
            self.isLoading = false
            return
        }

        do {
            if let commit = data.commit {
                self.files = try project.fileList(atCommit: commit.hash)
            } else {
                self.files = try project.untrackedFiles()
            }

            self.data.setFile(self.files.first)
            self.selection = self.data.file
            self.isLoading = false
        } catch {
            self.m.error(error.localizedDescription)
        }
    }
}

// MARK: - Event

extension FileList {
    func onAppear() {
        self.refresh(reason: "OnAppear")
    }

    func onCommitChange() {
        self.refresh(reason: "OnCommitChanged(to -> \(self.data.commit?.hash ?? "nil"))")
    }

    func onSelectionChange() {
        self.data.setFile(self.selection)
    }

    func onProjectDidCommit(_ notification: Notification) {
        self.refresh(reason: "OnProjectDidCommit")
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
