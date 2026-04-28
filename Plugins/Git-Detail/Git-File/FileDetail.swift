import AppKit
import MagicDiffView
import MagicAlert
import MagicKit

import OSLog
import SwiftUI

struct FileDetail: View, SuperLog, SuperEvent, SuperThread {
    
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var unifiedDiffText = ""

    static let emoji = "🌍"

    private var verbose = false

    var body: some View {
        VStack(spacing: 0) {
            if let file = vm.file {
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

            MagicDiffView(diffOutput: unifiedDiffText)
                .background(.background)
        }
        .onChange(of: vm.file, onFileChange)
        .onChange(of: data.commit, onCommitChange)
        .onAppear(perform: onAppear)
        .frame(maxHeight: .infinity)
    }

    func updateDiffView(reason: String) {
        if verbose {
            os_log("\(self.t)🍋 UpdateDiffView(\(reason))")
        }

        guard let file = vm.file, let project = vm.project else {
            return
        }

        do {
            if let commit = data.commit {
                // 使用 git diff 输出，而不是纯文本内容对比
                // 这样行号匹配与 GitHub Desktop 完全一致
                self.unifiedDiffText = try project.fileDiff(at: commit.hash, file: file.file)
            } else {
                // 未提交的变更也使用 git diff 输出
                self.unifiedDiffText = try project.uncommittedFileDiff(file: file.file)
            }
        } catch {
            os_log(.error, "\(Self.t)❌ 更新差异视图失败: \(error.localizedDescription)")
            alert_error(error)
            self.unifiedDiffText = ""
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
