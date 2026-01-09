import MagicKit
import OSLog
import SwiftUI

/// 添加项目按钮组件
struct BtnAdd: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "➕"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 数据提供者环境对象
    @EnvironmentObject var g: DataProvider

    /// 按钮视图主体
    var body: some View {
        Button(action: open) {
            Label("添加项目", systemImage: "plus")
        }
    }

    /// 打开文件选择面板
    private func open() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            addURL(url)
        } else {
        }
    }

    /// 添加项目URL
    /// - Parameter url: 项目目录URL
    private func addURL(_ url: URL) {
        withAnimation {
            g.addProject(url: url, using: g.repoManager.projectRepo)
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
