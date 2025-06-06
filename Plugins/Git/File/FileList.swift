import AppKit
import MagicCore
import OSLog
import SwiftUI

struct FileList: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MessageProvider

    @State var files: [File] = []
    @State var isLoading = false

    @Binding var file: File?

    var commit: GitCommit

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
                            .scaleEffect(0.6)
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
                List(files, id: \.self, selection: self.$file) {
                    FileTile(file: $0, commit: commit)
                        .tag($0 as File?)
                        .listRowBackground(getBackground(file: $0))
                }
                .task {
                    self.refresh(scrollProxy)
                }
                .onChange(of: commit, {
                    refresh(scrollProxy)
                })
                .onChange(of: files, {
                    withAnimation {
                        // 在主线程中调用 scrollTo 方法
                        scrollProxy.scrollTo(self.file, anchor: .top)
                    }
                })
                .background(.blue)
            }
        }
    }

    func refresh(_ scrollProxy: ScrollViewProxy) {
        self.isLoading = true

        let verbose = true
        if verbose {
            os_log("\(self.t)Refresh")
        }

        let files = commit.getFiles(reason: "FileList.Refresh")

        self.files = files
        self.isLoading = false
        self.file = self.files.first
    }

    func getBackground(file: File) -> some View {
        Group {
            switch file.type {
            case .modified:
                MagicBackground.orange.opacity(0.1)
            case .add:
                MagicBackground.forest.opacity(0.1)
            case .delete:
                MagicBackground.cherry.opacity(0.1)
            }
        }
    }
}

#Preview("Big Screen") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
