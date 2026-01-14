
import SwiftUI

/// 提交状态指示器组件
/// 显示当前的提交活动状态信息
struct CommitStatusTile: View {
    /// 环境对象：数据提供者
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let status = g.activityStatus, status.isEmpty == false {
            StatusBarTile(icon: "arrow.triangle.2.circlepath") {
                Text(status)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Preview

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
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

