import SwiftUI

/// 空状态提示视图 - 用于显示选择或创建Banner的提示
struct EmptyBannerTip: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("选择或创建一个Banner")
                .font(.title2)
                .foregroundColor(.secondary)
            
            BannerBtnAdd()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
