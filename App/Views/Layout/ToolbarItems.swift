import MagicCore
import OSLog
import SwiftData
import SwiftUI

/// `ToolbarItems` 是一个包含项目相关工具栏按钮的视图组件。
/// 它显示一组用于操作当前项目的按钮，如在不同编辑器中打开项目、在Finder中显示、
/// 打开终端、同步项目等功能。
struct ToolbarItems: View {
    // MARK: - Public Properties
    
    /// 消息绑定，用于显示操作结果
    @Binding var message: String
    
    /// 当前项目
    var project: Project
    
    /// 是否显示工具栏项目
    var isVisible: Bool
    
    // MARK: - Body
    
    var body: some View {
        if isVisible {
            BtnOpenXcode(url: project.url)
            BtnOpen(url: project.url)
            BtnOpenCursor(url: project.url)
            BtnOpenTrae(url: project.url)
            BtnFinder(url: project.url)
            BtnOpenTerminal(url: project.url)
            BtnOpenRemote(message: $message, path: project.path)
            BtnSync(message: $message, path: project.path)
            if project.isGit {
                Branches()
            }
        }
    }
}

#Preview("Default") {
    AppPreview()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
