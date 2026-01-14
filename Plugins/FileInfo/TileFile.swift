import AppKit

import LibGit2Swift
import MagicAlert
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 状态栏文件信息 Tile：显示当前选中文件的文件名。
struct TileFile: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider

    static let shared = TileFile()

    private init() {}

    var file: GitDiffFile? { data.file }

    @State private var isPopoverPresented = false
    @State private var cachedComponents: [String] = []

    var body: some View {
        if let file = file {
            let components = cachedComponents.isEmpty ? file.file.split(separator: "/").map(String.init) : cachedComponents
            StatusBarTile(icon: "doc.text", onTap: { isPopoverPresented.toggle() }) {
                HStack(spacing: 4) {
                    ForEach(Array(components.enumerated()), id: \.offset) { idx, comp in
                        Text(comp)
                            .font(.footnote.weight(idx == components.count - 1 ? .semibold : .regular))
                            .foregroundColor(idx == components.count - 1 ? .primary : .secondary)
                        if idx < components.count - 1 {
                            Text("›")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }.frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
            .onChange(of: data.file) { _, newFile in
                // 更新缓存的路径组件
                if let newFile = newFile {
                    cachedComponents = newFile.file.split(separator: "/").map(String.init)
                } else {
                    cachedComponents = []
                }
            }
            .popover(isPresented: $isPopoverPresented) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文件操作")
                        .font(.headline)
                        .padding(.bottom, 4)

                    MagicButton.simple {
                        revealInFinder()
                        isPopoverPresented = false
                    }
                    .magicTitle("在 Finder 中展示")
                    .magicSize(.auto)
                    .magicIcon(.iconFinder)
                    .frame(width: 200)
                    .frame(height: 40)
                    MagicButton.simple {
                        openInVSCode()
                        isPopoverPresented = false
                    }
                    .magicTitle("用 VS Code 打开")
                    .magicSize(.auto)
                    .magicIcon(.iconTerminal)
                    .frame(width: 200)
                    .frame(height: 40)

                    MagicButton.simple {
                        copyPath()
                        isPopoverPresented = false
                    }
                    .magicTitle("复制路径")
                    .magicSize(.auto)
                    .magicIcon(.iconCopy)
                    .frame(width: 200)
                    .frame(height: 40)
                }
                .padding()
                .frame(width: 220)
            }
        }
    }

    private var targetFileURL: URL? {
        guard let file = file, let project = data.project else { return nil }
        let baseURL = URL(fileURLWithPath: project.path)
        return URL(fileURLWithPath: file.file, relativeTo: baseURL).standardizedFileURL
    }

    private func revealInFinder() {
        guard let url = targetFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openInVSCode() {
        guard let url = targetFileURL else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["open", "-a", "Visual Studio Code", url.path]
        try? process.run()
    }

    private func copyPath() {
        guard let url = targetFileURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        m.info("已复制路径")
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
