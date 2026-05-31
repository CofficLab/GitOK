import SwiftUI

/// 主窗口左侧项目侧边栏。
struct SidebarView: View {
    @EnvironmentObject var themeProvider: AppThemeVM

    var body: some View {
        Projects()
            .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
            .background(themeProvider.activeChromeTheme.sidebarBackgroundColor())
            .toolbar {
                ToolbarItem {
                    BtnAdd()
                }
            }
    }
}

#Preview("Sidebar") {
    NavigationSplitView {
        SidebarView()
    } detail: {
        Text("Detail")
    }
    .inRootView()
    .frame(width: 800, height: 600)
}
