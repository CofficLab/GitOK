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
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}