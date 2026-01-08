import AppKit
import MagicDiffView
import MagicAlert
import MagicKit

import OSLog
import SwiftUI

struct FileDetail: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    @State private var oldText = ""
    @State private var newText = ""

    static let emoji = "🌍"

    private var verbose = false

    var body: some View {
        VStack(spacing: 0) {
            if let file = data.file {
                // 文件路径显示组件
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text(file.file)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.background)
            }

            MagicDiffView(oldText: oldText, newText: newText, verbose: false)
                .background(.background)
        }
        .onChange(of: data.file, onFileChange)
        .onChange(of: data.commit, onCommitChange)
        .onAppear(perform: onAppear)
        .frame(maxHeight: .infinity)
    }

    func updateDiffView(reason: String) {
        if verbose {
            os_log("\(self.t)🍋 UpdateDiffView(\(reason))")
        }

        guard let file = data.file, let project = data.project else {
            return
        }

        do {
            if let commit = data.commit {
                let (beforeContent, afterContent) = try project.fileContentChange(at: commit.hash, file: file.file)
                self.oldText = beforeContent ?? ""
                self.newText = afterContent ?? ""
            } else {
                let (beforeContent, afterContent) = try project.uncommittedFileContentChange(file: file.file)
                self.oldText = beforeContent ?? ""
                self.newText = afterContent ?? ""
            }
        } catch {
            self.m.error(error)
        }
    }
}

// MARK: - Event

extension FileDetail {
    func onFileChange() {
        self.bg.async {
            updateDiffView(reason: "File Change")
        }
    }

    func onCommitChange() {
        self.bg.async {
            updateDiffView(reason: "Commit Change")
        }
    }

    func onAppear() {
        self.bg.async {
            updateDiffView(reason: "Appear")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
