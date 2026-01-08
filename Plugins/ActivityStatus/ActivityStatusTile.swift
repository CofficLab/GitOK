
import SwiftUI

struct ActivityStatusTile: View {
    @EnvironmentObject var data: DataProvider

    var body: some View {
        if let status = data.activityStatus, status.isEmpty == false {
            StatusBarTile(icon: "arrow.triangle.2.circlepath") {
                Text(status)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
        }
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
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

