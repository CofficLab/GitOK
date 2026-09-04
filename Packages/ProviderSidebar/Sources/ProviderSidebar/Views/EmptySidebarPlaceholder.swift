import SwiftUI

/// 侧边栏暂无条目时的占位视图。
struct EmptySidebarPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            Text("No Items")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
